package main

IS_WASM :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

when IS_WASM {
	GLSL_VERSION :: "100"
	TextFormat :: proc(text: cstring, args: ..any) -> cstring {
		return cstring(fmt.ctprintf(string(text), ..args))
	}
} else {
	GLSL_VERSION :: "330"
}

/////////////WASM
// import "raylib"
// import b2 "box2dw"
/////////////NOT WASM
import b2 "box2d"
import "vendor:raylib"

STARTING_SCREEN_WIDTH :: 1280
STARTING_SCREEN_HEIGHT :: 720

import c "core:c"
import "core:fmt"
import "core:math"
import "core:math/ease"
import "core:math/linalg"
import "core:math/rand"
import "core:mem"
import "core:runtime"
import "core:slice"
import "core:time"

TITLE_TEXT :: "Far into Space"

// Box2d units to a world scale
RE_SCALE: f32 = 100

MAX_ENEMY_COUNT :: 30
MAX_SPACEOBJECT_COUNT :: 20
MAX_ASTEROID_COUNT :: 100

CARGO_PICKUP_DISTANCE :: 1.5

MOUSEWHEEL_ZOOM_SPEED :: f32(0.125)
CAMERA_ZOOM_MIN: f32 = 0.250
//CAMERA_ZOOM_MIN: f32 = 0.4

CAMERA_ZOOM_MAX: f32 = 2.0
CAMERA_FRACTION_SPEED: f32 = 8.0

WORLD_ACTIVE_DISTANCE: f32 = 50
THRUST_BOOST_BASE_MULTIPLIER: f32 = 2
SPECIAL_LIFETIME: f32 = 20

RESOURCES_DIR :: "resources/"

GameState :: struct {
	//box2d
	world_def:                      b2.World_Def,
	world_id:                       b2.World_ID,
	player_ship_def:			    PLAYER_SHIPS_DEFS_ID,

	//timing, runstate
	tick_rate:                      f32,
	previous_time:                  f64,
	current_time:                   f64,
	pause:                          bool,
	is_running:                     bool,
	menu_cursor:                    int,
	// doesn't work on WASM?
	//stopwatch:                      time.Stopwatch,
	stopwatch_start:                f64,
	stopwatch_stop:                 f64,
	//player
	player_entity:                  ^Entity,
	player:                         ^Player,
	score:                          uint,
	last_primary_fire:              f64, // for cooldown
	last_secondary_fire:            f64, // for cooldown
	has_boss:                       bool,

	//camera
	camera_follows:                 ^Entity,
	camera:                         raylib.Camera2D,
	camera_min_speed:               f32,
	camera_min_effect_length:       f32,
	camera_fraction_speed:          f32,
	camera_target_zoom:             f32,
	easing_camera_zoom_map:         ease.Flux_Map(f32),
	easing_camera_tween:            ^ease.Flux_Tween(f32),

	// missions
	is_mission_complete:            bool,
	is_mission_failed:              bool,
	is_in_mission:                  bool,
	mission:                        int,
	mission_task_index:             int,
	showing_display_panel:          bool,
	show_display_panel_forced_time: f64,
	showing_waypoint_nav:           bool,
	waypoint:                       linalg.Vector2f32,

	// resources
	asteroids:                      [dynamic]^Asteroid,
	bullets:                        [dynamic]^Bullet,
	missles:                        [dynamic]^Missle,
	enemies:                        [dynamic]^Enemy,
	space_objects:                  [dynamic]^SpaceObject,
	gpu_asteroids:                  [MAX_ASTEROID_COUNT]GPU_Asteroid,
	cpu_particles:                  [dynamic]CPU_Particle,
	gpu_particles:                  [MAX_PARTICLE_COUNT]GPU_Particle,
	gpu_particles_colors:           [MAX_PARTICLE_COUNT]GPU_Particle_color,
}

when !IS_WASM {
	draw_shapes: bool = true
	draw_aabbs: bool = false
	draw_mass: bool = false
}

SpaceObjectType :: enum {
	REPAIR,
	WEAPON,
	SPECIAL,
}

SpaceObjectItem :: struct {
	texture:       ^raylib.Texture2D,
	type:          SpaceObjectType,
	type_id:       int,
	time_lifetime: f64,
}

COLLISION_CATEGORY :: enum u32 {
	BLANK,
	PLAYER,
	ENEMY,
	ASTEROID,
	BULLET,
	MISSLE,
	SPACEOBJECT,
}
COLLISION_CATEGORY_SET :: bit_set[COLLISION_CATEGORY;u32]

Faction :: enum {
	PLAYER,
	ENEMY,
	NEUTRAL,
}

// shape def filtering
Faction_Set :: bit_set[Faction;u32]

new_entity :: proc($T: typeid) -> ^T {
	e := new(T)
	e.variant = e
	#partial switch e in e.variant {
	case ^Asteroid:
		append(&game.asteroids, e)
	case ^SpaceObject:
		append(&game.space_objects, e)
	case ^Missle:
		append(&game.missles, e)
	case ^Bullet:
		append(&game.bullets, e)
	case ^Enemy:
		append(&game.enemies, e)
	}

	return e
}

Entity :: struct {
	body_id:  b2.Body_ID,
	shape_id: b2.Shape_ID,
	texture:  ^raylib.Texture2D,
	variant:  union {
		^Asteroid,
		^SpaceObject,
		^Missle,
		^Bullet,
		^Enemy,
		^Player,
	},
}

Asteroid :: struct {
	using entity: Entity,
	size:         f32,
}

Bullet :: struct {
	using entity:     Entity,
	originator_id:    b2.Body_ID,
	contact_lifetime: u32,
	time_lifetime:    f64,
	damage_base:      f32,
}

Enemy :: struct {
	using entity:              Entity,
	life:                      f32,
	bullet_cooldown:           f32,
	faction:                   Faction,
	size:                      f32,
	thrust_pos:                linalg.Vector2f32,
	is_thrusting:              bool,
	thrust_texture_scale:      f32,
	thrust_vel:                f32,
	brain:                     proc(_: ^Enemy, _: f32),
	target_id:                 b2.Body_ID,
	ai_cooldown:               f64,
	thrust_texture:            ^raylib.Texture2D,
	is_boss:                   bool,
	sensor_range:              f32,
	primary_weapon:            WEAPONS_ID,
	secondary_weapon:          WEAPONS_ID,
	tint:                      raylib.Color,
	primary_weapon_cooldown:   f64, // for cooldown
	secondary_weapon_cooldown: f64, // for cooldown	
}

Player :: struct {
	using entity:         Entity,
	thrust_pos:           linalg.Vector2f32,
	life:                 f32,
	max_life:             f32,
	boost:                f32,
	max_boost:            f32,
	boost_cooldown:       f32,
	max_velocity:         f32,
	is_thrusting:         bool,
	is_boosting:          bool,
	thrust_texture_scale: f32,
	thrust_vel:           f32,
	thrust_texture:       ^raylib.Texture2D,
	primary_weapon:       WEAPONS_ID,
	secondary_weapon:     WEAPONS_ID,
	tint:                 raylib.Color,
	cargo_space:          int,
	cargo:                [dynamic]SpaceObjectItem,
}

SpaceObject :: struct {
	using entity:     Entity,
	scale:            f32,
	time_lifetime:    f64,
	final_event:      proc(),
	final_event_mod1: f32,
	type:             SpaceObjectType,
	type_id:          int,
	is_temp:          bool,
	is_cargo:         bool,
}

Missle :: struct {
	using entity:         Entity,
	texture:              ^raylib.Texture2D,
	thrust_texture:       ^raylib.Texture2D,
	thrust_pos:           linalg.Vector2f32,
	is_thrusting:         bool,
	thrust_scale:         f32,
	thrust_texture_scale: f32,
	max_velocity:         f32,
	thrust_vel:           f32,
	contact_lifetime:     u32,
	time_lifetime:        f64,
	damage_base:          f32,
	fire_for_effect:      bool,
	originator_id:        b2.Body_ID,
	final_event_mod1:     f32,
	final_event:          proc(_: linalg.Vector2f32, _: f32),
	brain:                proc(_: ^Missle, _: f32),
	target_id:		      b2.Body_ID,
	ai_cooldown:          f64,
}

game := GameState {
	camera = raylib.Camera2D {
		offset = raylib.Vector2{0, 0},
		target = raylib.Vector2{0, 0},
		rotation = 0,
		zoom = 0.75,
	},
	camera_min_speed = 30,
	camera_min_effect_length = 10,
	camera_fraction_speed = 1.8,
	camera_target_zoom = 0.75,
	player_ship_def = .PLAYER_SHIP1,
	tick_rate = 100,
	current_time = raylib.GetTime(),
	previous_time = raylib.GetTime(),
	pause = false,
	is_running = false,
	has_boss = false,
	is_mission_complete = false,
	is_mission_failed = false,
	is_in_mission = false,
	mission = -1,
	mission_task_index = 0,
	showing_display_panel = false,
	show_display_panel_forced_time = 0,
	showing_waypoint_nav = false,
	waypoint = linalg.Vector2f32{0, 0},
}

// from one state to another
app_current_state: APP_STATE = .TITLE
//framing for transitions
trans_from_state: APP_STATE = .TITLE
trans_to_state: APP_STATE = .TITLE
on_transition: bool = false
trans_fade_out: bool = false
trans_alpha: f32 = 1.0
trace_log_level: raylib.TraceLogLevel = .DEBUG

gamepad_num: i32 = -1
gamepad_enabled: bool = false

//performance tuning
disable_background_shader: bool

debug_enabled: bool = false
godmode_enabled: bool = false
music_enabled: bool = true
music_id_playing: MUSICS_ID = .MENU
default_font: raylib.Font
accumulator: f32 = 0.0

arena: mem.Arena
arena_memory: [2_000_000]byte

sfxs: [dynamic]raylib.Sound
textures: [dynamic]raylib.Texture2D
musics: [dynamic]raylib.Music

magnitude :: proc(v: linalg.Vector2f32) -> f32 {
	return math.sqrt(v.x * v.x + v.y * v.y)
}

v32_bump_x :: #force_inline proc(v: linalg.Vector2f32, x: f32) -> linalg.Vector2f32 {
	return linalg.Vector2f32{v.x + x, v.y}
}

v32_bump_y :: #force_inline proc(v: linalg.Vector2f32, y: f32) -> linalg.Vector2f32 {
	return linalg.Vector2f32{v.x, v.y + y}
}

v32_bump_xy :: #force_inline proc(v: linalg.Vector2f32, x: f32, y: f32) -> linalg.Vector2f32 {
	return linalg.Vector2f32{v.x + x, v.y + y}
}

get_mouse_to_box2d :: #force_inline proc() -> linalg.Vector2f32 {
	pos := raylib.GetScreenToWorld2D(raylib.GetMousePosition(), game.camera)
	return linalg.Vector2f32{pos.x / RE_SCALE, -pos.y / RE_SCALE}
}

get_player_pos :: #force_inline proc() -> linalg.Vector2f32 {
	return b2.body_get_position(game.player.body_id)
}

get_player_angle :: #force_inline proc() -> f32 {
	return b2.body_get_angle(game.player.body_id)
}

distance_to_player :: #force_inline proc(pos: linalg.Vector2f32) -> f32 {
	return linalg.length(pos - get_player_pos())
}

handle_object_item_pickup :: proc(space: ^SpaceObject) -> bool {
	remove := false

	if len(game.player.cargo) < game.player.cargo_space {
		so: SpaceObjectItem
		so.texture = space.texture
		so.type = space.type
		so.type_id = space.type_id
		append(&game.player.cargo, so)
		remove = true
		raylib.PlaySound(sfxs[int(SFX_ID.ITEMPICK1)])
		return remove
	}
	return remove
}

handle_contact_events :: proc(dt: f32) {
	swap := [?]bool{false, true}

	contact_events := b2.world_get_contact_events(game.world_id)

	for i := 0; i < int(contact_events.begin_count); i += 1 {
		e1 := cast(^Entity)b2.shape_get_user_data(contact_events.begin_events[i].shape_id_a)
		e2 := cast(^Entity)b2.shape_get_user_data(contact_events.begin_events[i].shape_id_b)

		for s in swap {
			if s {
				e1, e2 = e2, e1
			}
			switch ea in e1.variant {
			case ^SpaceObject:
				{
				}
			case ^Asteroid:
				{
				}
			case ^Enemy:
				{
					#partial switch eb in e2.variant {
					case ^Asteroid:
						{
							v := magnitude(b2.body_get_linear_velocity(ea.body_id))
							m := b2.body_get_mass(ea.body_id)
							ek := .5 * m * math.pow(v, 2)
							ea.life -= math.floor(ek * 100)
						}
					case ^Bullet:
						{
							ea.life -= eb.damage_base
							if eb.originator_id == game.player.body_id {
								game.score += 25
							}
							hit_sparks(b2.body_get_position(eb.body_id), 5.0)
						}
					case ^Missle:
						{
							ea.life -= eb.damage_base
							if eb.originator_id == game.player.body_id {
								game.score += 100
							}
						}
					}
				}
			case ^Player:
				{
					#partial switch eb in e2.variant {
					case ^Asteroid:
						{
							v := magnitude(b2.body_get_linear_velocity(ea.body_id))
							m := b2.body_get_mass(ea.body_id)
							// kenetic energy
							ek := .5 * m * math.pow(v, 2)
							ea.life -= math.floor(ek * 100)
						}
					case ^Bullet:
						{
							ea.life -= eb.damage_base
							hit_sparks(b2.body_get_position(eb.body_id), 5.0)
						}
					case ^Missle:
						{
							ea.life -= eb.damage_base
						}
					case ^SpaceObject:
						{
							if handle_object_item_pickup(eb) {
								eb.time_lifetime = 0
							}
						}
					}
				}
			case ^Bullet:
				{
					#partial switch eb in e2.variant {
						case ^Asteroid:
						{
							asteroid_hit_sparks(b2.body_get_position(ea.body_id), 1.0)
						}
						case ^SpaceObject:
						{
							eb.time_lifetime = game.current_time
							explosion(b2.body_get_position(eb.body_id), 3.0)
						}
					}
					ea.contact_lifetime -= 1
				}
			case ^Missle:
				{
					#partial switch eb in e2.variant {
						case ^SpaceObject:
							{
								eb.time_lifetime = game.current_time
								explosion(b2.body_get_position(eb.body_id), 3.0)
							}
					}
					ea.contact_lifetime -= 1
				}
			// crashes the compiler?
			// case ^SpaceObject: {
			// 	#partial switch eb in e2.variant {
			// 		case ^Player: {
			// 			// if handle_object_item_pickup(ea) {
			// 			// 	ea.lifetime = 0
			// 			// }
			// 		}
			// 	}
			// }
			}
		}
	}

	i := 0
	for i < len(game.bullets) {
		b := game.bullets[i]
		if b.time_lifetime < game.current_time || b.contact_lifetime <= 0 {
			if b2.body_is_valid(b.body_id) {
				b2.destroy_body(b.body_id)
			} else {
				raylib.TraceLog(.ERROR, "bullet without Body_ID?", b)
			}
			free(b)
			unordered_remove(&game.bullets, i)
			continue
		}
		i += 1
	}

	i = 0
	for i < len(game.missles) {
		b := game.missles[i]
		if b.time_lifetime < game.current_time || b.contact_lifetime <= 0 {
			if b.fire_for_effect || b.contact_lifetime <= 0 {
				b.final_event(b2.body_get_position(b.body_id), b.final_event_mod1)
			}

			if b2.body_is_valid(b.body_id) {
				b2.destroy_body(b.body_id)
			} else {
				raylib.TraceLog(.ERROR, "missle without Body_ID?", b)
			}
			free(b)
			unordered_remove(&game.missles, i)
			continue
		} else {
			// yep, missles can have no brains
			if b.brain != nil {
				b.brain(b, dt)
			}
		}
		i += 1
	}

	i = 0
	for i < len(game.enemies) {
		if distance_to_player(b2.body_get_position(game.enemies[i].body_id)) >
		   WORLD_ACTIVE_DISTANCE {
			b2.destroy_body(game.enemies[i].body_id)
			free(game.enemies[i])
			unordered_remove(&game.enemies, i)
			continue
		}
		b := game.enemies[i]
		if b.life <= 0 {
			if b.is_boss {
				game.has_boss = false
			}
			explosion(b2.body_get_position(b.body_id), 1.0)
			if b2.body_is_valid(b.body_id) {
				b2.destroy_body(b.body_id)
			} else {
				raylib.TraceLog(.ERROR, "enemy without Body_ID?", b)
			}
			raylib.PlaySound(sfxs[int(SFX_ID.MINOR_EXPLOSION)])
			free(b)
			unordered_remove(&game.enemies, i)
			continue
		} else {
			// yep, enemies can have no brains
			if b.brain != nil {
				b.brain(game.enemies[i], dt)
			}
		}
		i += 1
	}

	i = 0
	for i < len(game.space_objects) {
		if distance_to_player(b2.body_get_position(game.space_objects[i].body_id)) >
		   WORLD_ACTIVE_DISTANCE {
			b2.destroy_body(game.space_objects[i].body_id)
			free(game.space_objects[i])
			unordered_remove(&game.space_objects, i)
			continue
		}
		if game.space_objects[i].time_lifetime < game.current_time {
			if b2.body_is_valid(game.space_objects[i].body_id) {
				b2.destroy_body(game.space_objects[i].body_id)
			} else {
				raylib.TraceLog(.ERROR, "spaceobject without Body_ID?", game.space_objects[i])
			}
			free(game.space_objects[i])
			unordered_remove(&game.space_objects, i)
			continue
		}
		i += 1
	}

	i = 0
	for i < len(game.asteroids) {
		if distance_to_player(b2.body_get_position(game.asteroids[i].body_id)) >
		   WORLD_ACTIVE_DISTANCE {
			b2.destroy_body(game.asteroids[i].body_id)
			free(game.asteroids[i])
			unordered_remove(&game.asteroids, i)
			continue
		}
		i += 1
	}
}

asteroid_draw_index: i32 = 0

@(export, link_name = "draw_query_callback")
draw_query_callback :: proc "cdecl" (shape_id: b2.Shape_ID, context_: rawptr) -> bool {
	context = runtime.default_context()
	//context.allocator = mem.arena_allocator(&arena)
	using raylib

	#partial switch e in (cast(^Entity)b2.shape_get_user_data(shape_id)).variant {
	case ^Asteroid:
		{
			pos := b2.body_get_position(e.body_id)
			game.gpu_asteroids[asteroid_draw_index].x = pos.x * RE_SCALE
			game.gpu_asteroids[asteroid_draw_index].y = pos.y * RE_SCALE * -1
			game.gpu_asteroids[asteroid_draw_index].size = e.size * RE_SCALE
			asteroid_draw_index += 1
		}
	case ^Missle:
		{
			draw_texture_scale_rot(
				e.texture,
				b2.body_get_position(e.body_id) * RE_SCALE,
				b2.body_get_angle(e.body_id),
				WHITE,
			)
		}
	case ^SpaceObject:
		{
			draw_texture_scale_rot(
				e.texture,
				b2.body_get_position(e.body_id) * RE_SCALE,
				b2.body_get_angle(e.body_id),
				WHITE,
			)
		}
	case ^Bullet:
		{
			tint := Color{255, 255, 255, cast(u8)GetRandomValue(200, 255)}
			draw_texture_scale_rot(
				e.texture,
				b2.body_get_position(e.body_id) * RE_SCALE,
				b2.body_get_angle(e.body_id),
				tint,
			)
		}
	case ^Enemy:
		{
			if e.is_thrusting {
				tint := Color{255, 255, 255, cast(u8)GetRandomValue(10, 255)}
				draw_texture_scale_rot_offset(
					e.thrust_texture,
					b2.body_get_position(e.body_id) * RE_SCALE,
					b2.body_get_angle(e.body_id),
					e.thrust_pos,
					tint,
				)
			}
			draw_texture_scale_rot(
				e.texture,
				b2.body_get_position(e.body_id) * RE_SCALE,
				b2.body_get_angle(e.body_id),
				e.tint,
			)
		}
	case ^Player:
		{
			if e.is_thrusting {
				tint := Color{255, 255, 255, cast(u8)GetRandomValue(10, 255)}
				draw_texture_scale_rot_offset(
					e.thrust_texture,
					b2.body_get_position(e.body_id) * RE_SCALE,
					b2.body_get_angle(e.body_id),
					e.thrust_pos,
					tint,
				)
			}
			draw_texture_scale_rot(
				e.texture,
				b2.body_get_position(e.body_id) * RE_SCALE,
				b2.body_get_angle(e.body_id),
				e.tint,
			)
		}
	case:
		panic("unknown entity type")
	}

	return true
}

hit_sparks :: proc(pos: linalg.Vector2f32, size: f32 = 1.0) {
	//make a particle explosion
	for i := 0; i < 25; i += 1 {
		p: CPU_Particle
		p.pos = pos
		p.vel = linalg.Vector2f32{rand.float32_range(-size, size), rand.float32_range(-size, size)}
		grade := raylib.GetRandomValue(0, 1)
		switch grade {
		case 0:
			//yellow
			p.color = raylib.Color{255, 255, 0, 255}
		case 1:
			//black (grey)
			p.color = raylib.Color{55, 0, 55, 255}
		}
		p.lifetime = rand.float32_range(0.15, .35)
		p.size = rand.float32_range(.5, 2.0)
		append(&game.cpu_particles, p)
	}
}

asteroid_hit_sparks :: proc(pos: linalg.Vector2f32, size: f32 = 1.0) {
	//make a particle explosion
	for i := 0; i < 25; i += 1 {
		p: CPU_Particle
		p.pos = pos
		p.vel = linalg.Vector2f32{rand.float32_range(-size, size), rand.float32_range(-size, size)}
		grade := raylib.GetRandomValue(0, 1)
		switch grade {
		case 0:
			//white
			p.color = raylib.Color{255, 255, 255, 255}
		case 1:
			//black (grey)
			p.color = raylib.Color{55, 0, 55, 255}
		}
		//p.color = raylib.Color{rand.randi32(0, 255), rand.randi32(0, 255), rand.randi32(0, 255), 255}
		//p.color = raylib.Color{255, 255, 255, 255}
		p.lifetime = rand.float32_range(0.15, .35)
		p.size = rand.float32_range(.5, 2.0)
		append(&game.cpu_particles, p)
	}
}

explosion :: proc(pos: linalg.Vector2f32, size: f32 = 1.0) {
	//make a particle explosion
	for i := 0; i < 75; i += 1 {
		p: CPU_Particle
		p.pos = pos
		p.vel = linalg.Vector2f32{rand.float32_range(-size, size), rand.float32_range(-size, size)}
		grade := raylib.GetRandomValue(0, 3)
		switch grade {
		case 0:
			//red
			p.color = raylib.Color{255, 0, 0, 255}
		case 1:
			//yellow
			p.color = raylib.Color{255, 255, 0, 255}
		case 2:
			//white
			p.color = raylib.Color{255, 255, 255, 255}
		case 3:
			//black (grey)
			p.color = raylib.Color{55, 0, 55, 255}
		}
		p.lifetime = rand.float32_range(0.15, .35)
		p.size = rand.float32_range(.5, 2.0)
		append(&game.cpu_particles, p)
	}
	player_hears_sound(.EXPLOSIONS5, pos)
	// raylib.PlaySound(sfxs[int(SFX_ID.EXPLOSIONS5)])
}

emp_explosion :: proc(pos: linalg.Vector2f32, size: f32 = 1.0) {
	using raylib
	EMP_RADIUS :: 8

	for e, i in game.enemies {
		if linalg.length(b2.body_get_position(e.body_id) - pos) < EMP_RADIUS {
			game.enemies[i].ai_cooldown = game.current_time + 320
			game.enemies[i].tint = Fade(GREEN, 0.7)
			raylib.TraceLog(.INFO, "EMP'd enemy", e)
		}
	}
	//make a particle explosion
	//make a particle explosion
	for i := 0; i < 100; i += 1 {
		p: CPU_Particle
		p.pos += ring_positioning(pos, .1, EMP_RADIUS)
		p.vel = linalg.Vector2f32{rand.float32_range(-.8, .8), rand.float32_range(-.8, .8)}
		//p.color = raylib.Color{rand.randi32(0, 255), rand.randi32(0, 255), rand.randi32(0, 255), 255}
		p.color = raylib.Color{0, 255, 0, 255}
		p.lifetime = rand.float32_range(4.5, 6.5)
		p.size = rand.float32_range(1.5, 2.5)
		append(&game.cpu_particles, p)
	}
}

thrust_burn_particles :: proc(
	pos: linalg.Vector2f32,
	direction: linalg.Vector2f32,
	size: f32 = 1.0,
) {
	for i := 0; i < 2; i += 1 {
		p: CPU_Particle
		p.pos = pos
		p.vel = (direction * rand.float32_range(0.25, .5)) / RE_SCALE
		p.color = raylib.Color{255, 255, 255, 255}
		p.lifetime = rand.float32_range(0.1, 0.2)
		p.size = rand.float32_range(.5, 2.0)
		append(&game.cpu_particles, p)
	}
}

handle_weapon_fire :: proc(
	weapon: WEAPONS_ID,
	pos: linalg.Vector2f32,
	originator_id: b2.Body_ID,
	angle: f32,
) {
	w := WEAPONS_DEFS[weapon]
	switch w.type {
	case WEAPONS_TYPE.BULLET:
		{
			b := new_entity(Bullet)
			b.originator_id = originator_id
			b.contact_lifetime = w.contact_lifetime
			// TODO: attach special modifiers
			b.time_lifetime = f64(w.time_lifetime) + game.current_time
			b.damage_base = w.damage_base
			b.texture = &textures[w.texture_id]

			body_def := b2.DEFAULT_BODY_DEF
			body_def.user_data = rawptr(b)
			body_def.type = .Dynamic
			body_def.position = pos
			body_def.angle = angle
			body_def.linear_damping = 0.0
			body_def.angular_damping = 0.0
			b.body_id = b2.create_body(game.world_id, &body_def)

			shape_def := b2.DEFAULT_SHAPE_DEF
			shape_def.density = 0.01
			shape_def.friction = 0.01
			shape_def.user_data = rawptr(b)

			circle: b2.Circle
			circle.radius = .05
			shape_id := b2.create_circle_shape(b.body_id, &shape_def, &circle)
			b.shape_id = shape_id

			f: b2.Filter
			if originator_id == game.player.body_id {
				f.category_bits = u32(COLLISION_CATEGORY_SET{.PLAYER})
				f.mask_bits = ~u32(COLLISION_CATEGORY_SET{.PLAYER})
				f.group_index = 0
			} else {
				f.category_bits = u32(COLLISION_CATEGORY_SET{.ENEMY})
				f.mask_bits = ~u32(COLLISION_CATEGORY_SET{.ENEMY})
				f.group_index = 0
			}
			b2.shape_set_filter(shape_id, f)

			fired_velocity := b2.Vec2 {
				math.sin(angle) * (w.velocity / RE_SCALE),
				-math.cos(angle) * (w.velocity / RE_SCALE),
			}

			fired_velocity += b2.body_get_linear_velocity(originator_id)

			b2.body_set_linear_velocity(b.body_id, fired_velocity)
			if w.sound_id >= 0 {
				player_hears_sound(SFX_ID(w.sound_id), pos)
				// raylib.PlaySound(sfxs[w.sound_id])
			}

			// TODO: move cooldown into Player, and fix the right way
			if originator_id == game.player.body_id {
				for _, i in game.player.cargo {
					if game.player.cargo[i].time_lifetime != 0 &&
					   game.player.cargo[i].time_lifetime > game.current_time {
						game.last_primary_fire -= f64(w.cooldown / 2)
					}
				}
			}


		}
	case WEAPONS_TYPE.MISSLE:
		{
			b := new_entity(Missle)
			b.originator_id = originator_id
			b.thrust_vel = w.velocity
			b.damage_base = w.damage_base
			b.is_thrusting = true
			b.contact_lifetime = w.contact_lifetime
			b.time_lifetime = f64(w.time_lifetime) + game.current_time
			b.texture = &textures[w.texture_id]
			b.thrust_texture = &textures[w.thrust_texture_id]
			if w.brain_ai != nil {
				b.brain = w.brain_ai
			} else {
				b.brain = nil
			}
			// always, triggers if true, otherwise must hit something to trigger the final effect
			b.fire_for_effect = w.fire_for_effect
			b.final_event = w.final_event
			b.final_event_mod1 = w.final_event_mod1
			//weird offset to make the thrust look right
			b.thrust_pos =
				linalg.Vector2f32 {
					f32(b.texture.width / 2),
					f32(b.texture.height / 2) - f32(b.thrust_texture^.height),
				} -
				3

			body_def := b2.DEFAULT_BODY_DEF
			body_def.type = .Dynamic
			body_def.position = pos
			body_def.angle = angle
			body_def.user_data = rawptr(b)
			body_def.linear_damping = 2.0
			body_def.angular_damping = 1.0
			body_id := b2.create_body(game.world_id, &body_def)
			b.body_id = body_id

			shape_def := b2.DEFAULT_SHAPE_DEF
			shape_def.density = 0.01
			shape_def.friction = 0.03
			shape_def.user_data = rawptr(b)

			box := b2.make_box(.1, .2)
			shape_id := b2.create_polygon_shape(body_id, &shape_def, &box)
			b.shape_id = shape_id

			f: b2.Filter
			if originator_id == game.player.body_id {
				f.category_bits = u32(COLLISION_CATEGORY_SET{.PLAYER})
				f.mask_bits = ~u32(COLLISION_CATEGORY_SET{.PLAYER})
				f.group_index = 0
			} else {
				f.category_bits = u32(COLLISION_CATEGORY_SET{.ENEMY})
				f.mask_bits = ~u32(COLLISION_CATEGORY_SET{.ENEMY})
				f.group_index = 0
			}
			b2.shape_set_filter(shape_id, f)

			b2.body_set_linear_velocity(
				b.body_id,
				b2.Vec2 {
					math.sin(angle) * (w.velocity / RE_SCALE),
					-math.cos(angle) * (w.velocity / RE_SCALE),
				},
			)
			if w.sound_id >= 0 {
				player_hears_sound(SFX_ID(w.sound_id), pos)
			}
		}
	}
}

draw_texture_scale_rot :: proc(
	t: ^raylib.Texture2D,
	pos: linalg.Vector2f32,
	rotation: f32,
	color: raylib.Color,
) {
	rotation := rotation * raylib.RAD2DEG
	sprite_offset := linalg.Vector2f32{f32(t^.width / 2), f32(t^.height / 2)}
	raylib.DrawTexturePro(
		t^,
		raylib.Rectangle{0, 0, f32(t^.width), f32(t^.height)},
		raylib.Rectangle{pos.x, pos.y, f32(t^.width), f32(t^.height)},
		sprite_offset,
		rotation,
		color,
	)
}

draw_texture_scale_rot_offset :: proc(
	t: ^raylib.Texture2D,
	pos: linalg.Vector2f32,
	rotation: f32,
	sprite_offset: linalg.Vector2f32,
	color: raylib.Color,
) {
	rotation := rotation * raylib.RAD2DEG
	raylib.DrawTexturePro(
		t^,
		raylib.Rectangle{0, 0, f32(t^.width), f32(t^.height)},
		raylib.Rectangle{pos.x, pos.y, f32(t^.width), f32(t^.height)},
		sprite_offset,
		rotation,
		color,
	)
}

draw_texture_scale_rot_offset_scale :: proc(
	t: ^raylib.Texture2D,
	pos: linalg.Vector2f32,
	rotation: f32,
	sprite_offset: linalg.Vector2f32,
	color: raylib.Color,
	scale: f32,
) {
	rotation := rotation * raylib.RAD2DEG
	// todo fix the offset problem this creates
	raylib.DrawTexturePro(
		t^,
		raylib.Rectangle{0, 0, f32(t^.width), f32(t^.height)},
		raylib.Rectangle{pos.x, pos.y, f32(t^.width) * scale, f32(t^.height) * scale},
		sprite_offset,
		rotation,
		color,
	)
}

HUD_PRIMARY_WEAPONS_BOX_SIZE :: 60
HUD_PRIMARY_WEAPONS_BOX_PAD :: 10

draw_weapons_buttons :: proc(
	pos: linalg.Vector2f32,
	weapon: WEAPONS_ID,
	percent_cool: f32,
	tint: raylib.Color,
) {
	using raylib
	if percent_cool > 0 {
		DrawRectangleRec(
			raylib.Rectangle {
				pos.x,
				pos.y,
				HUD_PRIMARY_WEAPONS_BOX_SIZE,
				HUD_PRIMARY_WEAPONS_BOX_SIZE,
			},
			Fade(WHITE, 0.5),
		)
		DrawRectangleRec(
			raylib.Rectangle {
				pos.x,
				pos.y,
				HUD_PRIMARY_WEAPONS_BOX_SIZE,
				HUD_PRIMARY_WEAPONS_BOX_SIZE * percent_cool,
			},
			tint,
		)
	} else {
		DrawRectangleRec(
			raylib.Rectangle {
				pos.x,
				pos.y,
				HUD_PRIMARY_WEAPONS_BOX_SIZE,
				HUD_PRIMARY_WEAPONS_BOX_SIZE,
			},
			Fade(GREEN, 0.5),
		)
	}
	center := linalg.Vector2f32{HUD_PRIMARY_WEAPONS_BOX_SIZE / 2, HUD_PRIMARY_WEAPONS_BOX_SIZE / 2}
	half_texture_size := linalg.Vector2f32 {
		f32(textures[WEAPONS_DEFS[weapon].texture_id].width / 2),
		f32(textures[WEAPONS_DEFS[weapon].texture_id].height / 2),
	}
	// shadow of icon
	DrawTextureEx(
		textures[WEAPONS_DEFS[weapon].texture_id],
		pos +
		center -
		half_texture_size +
		linalg.Vector2f32{HUD_PRIMARY_WEAPONS_BOX_PAD + 9, HUD_PRIMARY_WEAPONS_BOX_PAD - 2},
		45,
		1,
		Fade(BLACK, 0.5),
	)
	// icon
	DrawTextureEx(
		textures[WEAPONS_DEFS[weapon].texture_id],
		pos +
		center -
		half_texture_size +
		linalg.Vector2f32{HUD_PRIMARY_WEAPONS_BOX_PAD + 10, HUD_PRIMARY_WEAPONS_BOX_PAD - 4},
		45,
		1,
		WHITE,
	)
	// text description
	DrawTextEx(
		default_font,
		TextFormat("%s", WEAPONS_DEFS[weapon].name),
		Vector2{pos.x + HUD_PRIMARY_WEAPONS_BOX_PAD, pos.y + 2},
		10,
		1,
		WHITE,
	)

	// cover edges with nice panel
	DrawTexturePro(
		textures[int(TEXTURES_ID.GLASSPANEL_CORNERBL)],
		Rectangle {
			0,
			0,
			f32(textures[int(TEXTURES_ID.GLASSPANEL_CORNERBL)].width),
			f32(textures[int(TEXTURES_ID.GLASSPANEL_CORNERBL)].height),
		},
		raylib.Rectangle{pos.x, pos.y, HUD_PRIMARY_WEAPONS_BOX_SIZE, HUD_PRIMARY_WEAPONS_BOX_SIZE},
		Vector2{0, 0},
		0,
		WHITE,
	)
}

draw_cargo_buttons :: proc(
	pos: linalg.Vector2f32,
	index: int,
	item: ^SpaceObjectItem,
	tint: raylib.Color,
) {
	using raylib

	if item == nil {
		DrawRectangleV(
			pos,
			raylib.Vector2{HUD_PRIMARY_WEAPONS_BOX_SIZE, HUD_PRIMARY_WEAPONS_BOX_SIZE},
			tint,
		)
	} else {
		center := linalg.Vector2f32 {
			HUD_PRIMARY_WEAPONS_BOX_SIZE / 2,
			HUD_PRIMARY_WEAPONS_BOX_SIZE / 2,
		}
		//	half_texture_size := linalg.Vector2f32{f32(textures[WEAPONS_DEFS[weapon].texture_id].width / 2), f32(textures[WEAPONS_DEFS[weapon].texture_id].height / 2)}
		half_texture_size := linalg.Vector2f32 {
			f32(item.texture^.width / 2),
			f32(item.texture^.height / 2),
		}

		// DrawRectangleRec(
		// 	raylib.Rectangle {
		// 		pos.x,
		// 		pos.y,
		// 		HUD_PRIMARY_WEAPONS_BOX_SIZE,
		// 		HUD_PRIMARY_WEAPONS_BOX_SIZE,
		// 	},
		// 	tint,
		// )

		// for anything that applies over time to use, we draw a progress bar
		// once time is set greater then 0 we are using
		if item.time_lifetime > 0 {
			percent_cool := f32(item.time_lifetime - game.current_time) / SPECIAL_LIFETIME
			DrawRectangleRec(
				raylib.Rectangle {
					pos.x,
					pos.y,
					HUD_PRIMARY_WEAPONS_BOX_SIZE,
					HUD_PRIMARY_WEAPONS_BOX_SIZE,
				},
				Fade(WHITE, 0.5),
			)
			tint := Fade(GREEN, 0.6)
			DrawRectangleRec(
				raylib.Rectangle {
					pos.x,
					pos.y,
					HUD_PRIMARY_WEAPONS_BOX_SIZE,
					HUD_PRIMARY_WEAPONS_BOX_SIZE * percent_cool,
				},
				tint,
			)
		} else {
			DrawRectangleRec(
				raylib.Rectangle {
					pos.x,
					pos.y,
					HUD_PRIMARY_WEAPONS_BOX_SIZE,
					HUD_PRIMARY_WEAPONS_BOX_SIZE,
				},
				Fade(GREEN, 0.5),
			)
			DrawTextureEx(
				item.texture^,
				pos + linalg.Vector2f32{4, HUD_PRIMARY_WEAPONS_BOX_PAD - 2},
				0,
				1.5,
				Fade(BLACK, 0.5),
			)
			DrawTextureEx(
				item.texture^,
				pos + linalg.Vector2f32{5, HUD_PRIMARY_WEAPONS_BOX_PAD - 4},
				0,
				1.5,
				WHITE,
			)
		}

		if item.type == .WEAPON  {
			weapon := WEAPONS_ID(item.type_id)
			// shadow of icon
			DrawTextureEx(
				textures[WEAPONS_DEFS[weapon].texture_id],
				pos +
				center -
				half_texture_size +
				linalg.Vector2f32 {
						HUD_PRIMARY_WEAPONS_BOX_PAD + 3,
						HUD_PRIMARY_WEAPONS_BOX_PAD - 3,
					},
				45,
				.75,
				Fade(BLACK, 0.5),
			)
			// icon
			DrawTextureEx(
				textures[WEAPONS_DEFS[weapon].texture_id],
				pos +
				center -
				half_texture_size +
				linalg.Vector2f32{HUD_PRIMARY_WEAPONS_BOX_PAD + 4, HUD_PRIMARY_WEAPONS_BOX_PAD},
				45,
				.75,
				WHITE,
			)
		}

		DrawTextEx(
			default_font,
			TextFormat("%i:%s", index + 1, item.type),
			Vector2{pos.x + 5, pos.y + 2},
			10,
			1,
			WHITE,
		)
	}
	// cover edges with nice panel
	DrawTexturePro(
		textures[int(TEXTURES_ID.GLASSPANEL_CORNERBL)],
		Rectangle {
			0,
			0,
			f32(textures[int(TEXTURES_ID.GLASSPANEL_CORNERBL)].width),
			f32(textures[int(TEXTURES_ID.GLASSPANEL_CORNERBL)].height),
		},
		raylib.Rectangle{pos.x, pos.y, HUD_PRIMARY_WEAPONS_BOX_SIZE, HUD_PRIMARY_WEAPONS_BOX_SIZE},
		Vector2{0, 0},
		0,
		WHITE,
	)
}

HUD_LIFE_BAR_POS_X :: 440
HUD_LIFE_BAR_POS_Y :: 10
HUD_LIFE_BAR_WIDTH :: 300
HUD_LIFE_BAR_HEIGHT :: 25

draw_hud :: proc() {
	using raylib

	DrawTextEx(
		default_font,
		TextFormat("Score: %d", game.score),
		Vector2{HUD_LIFE_BAR_POS_X, (HUD_LIFE_BAR_HEIGHT) + 10},
		HUD_LIFE_BAR_HEIGHT,
		1,
		WHITE,
	)

	// Player life bar
	DrawRectangleRounded(
		raylib.Rectangle {
			HUD_LIFE_BAR_POS_X - 2,
			HUD_LIFE_BAR_POS_Y - 2,
			HUD_LIFE_BAR_WIDTH,
			HUD_LIFE_BAR_HEIGHT,
		},
		0.1,
		0,
		Color{200, 200, 200, 200},
	)
	DrawRectangleRounded(
		raylib.Rectangle {
			HUD_LIFE_BAR_POS_X,
			HUD_LIFE_BAR_POS_Y,
			f32((game.player.life / game.player.max_life) * HUD_LIFE_BAR_WIDTH),
			HUD_LIFE_BAR_HEIGHT,
		},
		0.1,
		0,
		Fade(RED, 0.75),
	)

	DrawTextEx(
		default_font,
		TextFormat("%.1f", game.player.life),
		Vector2{HUD_LIFE_BAR_POS_X + 5, HUD_LIFE_BAR_POS_Y},
		HUD_LIFE_BAR_HEIGHT,
		1,
		WHITE,
	)

	//display for primary weapon
	tint: Color
	if (game.current_time - game.last_primary_fire) >
	   f64(WEAPONS_DEFS[game.player.primary_weapon].cooldown) {
		//callback for ready sound?
		tint = Fade(GREEN, 0.6)
	} else {
		tint = Fade(RED, 0.6)
	}

	draw_weapons_buttons(
		linalg.Vector2f32 {
			f32(raylib.GetScreenWidth()) -
			(2 * (HUD_PRIMARY_WEAPONS_BOX_SIZE + HUD_PRIMARY_WEAPONS_BOX_PAD)),
			HUD_PRIMARY_WEAPONS_BOX_PAD,
		},
		game.player.primary_weapon,
		(1 -
			f32(game.current_time - game.last_primary_fire) /
				f32(WEAPONS_DEFS[game.player.primary_weapon].cooldown)),
		tint,
	)

	//display for secondary weapon
	if (game.current_time - game.last_secondary_fire) >
	   f64(WEAPONS_DEFS[game.player.secondary_weapon].cooldown) {
		//callback for ready sound?
		tint = Fade(GREEN, 0.6)
	} else {
		tint = Fade(RED, 0.6)
	}
	draw_weapons_buttons(
		linalg.Vector2f32 {
			f32(raylib.GetScreenWidth()) -
			((HUD_PRIMARY_WEAPONS_BOX_SIZE + HUD_PRIMARY_WEAPONS_BOX_PAD)),
			HUD_PRIMARY_WEAPONS_BOX_PAD,
		},
		game.player.secondary_weapon,
		(1 -
			f32(game.current_time - game.last_secondary_fire) /
				f32(WEAPONS_DEFS[game.player.secondary_weapon].cooldown)),
		tint,
	)

	//display for cargo
	for i := 0; i < game.player.cargo_space; i += 1 {
		pos := linalg.Vector2f32 {
			f32(
				((f32(i) * HUD_PRIMARY_WEAPONS_BOX_SIZE) +
					(f32(i) * HUD_PRIMARY_WEAPONS_BOX_PAD)) +
				HUD_PRIMARY_WEAPONS_BOX_PAD,
			),
			HUD_PRIMARY_WEAPONS_BOX_PAD,
		}
		if i < len(game.player.cargo) {
			draw_cargo_buttons(pos, i, &game.player.cargo[i], Fade(GREEN, 0.6))
		} else {
			draw_cargo_buttons(pos, i, nil, Fade(RED, 0.6))
		}
		// draw_cargo_buttons(pos, i, game.player.cargo[i], tint)
	}
}

// UpdateCameraCenterSmoothFollow - core_2d_camera_platformer.c
update_camera_center_smooth_follow :: proc(
	camera: ^raylib.Camera2D,
	entity: ^Entity,
	delta: f32,
	width: i32,
	height: i32,
) {
	camera.offset = raylib.Vector2{f32(width / 2), f32(height / 2)}
	diff := b2.body_get_position(entity.body_id)

	d2 := linalg.Vector2f32{diff.x * RE_SCALE, -diff.y * RE_SCALE}

	length := linalg.length(d2)

	if length > game.camera_min_effect_length {
		speed := f32(math.max(game.camera_fraction_speed * length, game.camera_min_speed))
		camera.target = camera.target + (d2 - camera.target) * (speed * delta / length)
	}
}

player_hears_sound :: proc (sound_id: SFX_ID, pos: linalg.Vector2f32) {
	using raylib

	dist := distance_to_player(pos)
	if dist > 0 {
		volume := 1.0 / (dist * 0.15)
		if volume > 1.0 {
			volume = 1.0
		}
		raylib.SetSoundVolume(sfxs[int(sound_id)], volume)
		raylib.PlaySound(sfxs[int(sound_id)])
	} else {
		raylib.SetSoundVolume(sfxs[int(sound_id)], 1.0)
		raylib.PlaySound(sfxs[int(sound_id)])
	}
	//TraceLog(.INFO, TextFormat("player_hears_sound, dist: %f", dist))
}

// entry point, gets called once at startup
@(export)
init :: proc "c" () {
	context = runtime.default_context()
	mem.arena_init(&arena, arena_memory[:])
	context.allocator = mem.arena_allocator(&arena)

	// needed to setup some runtime type information in odin
	#force_no_inline runtime._startup_runtime()

	using raylib
	input_processed: Input_Processed

	SetConfigFlags(raylib.ConfigFlags{.WINDOW_RESIZABLE})
	InitWindow(STARTING_SCREEN_WIDTH, STARTING_SCREEN_HEIGHT, "Asteroids")
	InitAudioDevice()
	SetExitKey(nil)

	for i in 0 ..= 31 {
		if IsGamepadAvailable(i32(i)) {
			if gamepad_num == -1 {
				gamepad_enabled = true
				gamepad_num = i32(i)
			}
			TraceLog(.INFO, fmt.ctprintf("Gamepad %i: %s", i32(i), GetGamepadName(i32(i))))
		}
	}

	if gamepad_num == -1 {
		TraceLog(.INFO, "No gamepad detected")
	}

	default_font = raylib.LoadFontEx("resources/audiowide.ttf", 48, nil, 0)
	GenTextureMipmaps(&default_font.texture); 
	raylib.SetTextureFilter(default_font.texture, .BILINEAR)

	// only needed on desktop, update is only called once per frame on wasm
	when !IS_WASM {
		SetTargetFPS(60)
	}

	for i in SFXS_FILE {
		sfx := fmt.ctprintf("%s%s", RESOURCES_DIR, i)
		append(&sfxs, LoadSound(sfx))
	}

	for i in TEXTURES_FILE {
		texture := fmt.ctprintf("%s%s", RESOURCES_DIR, i)
		append(&textures, LoadTexture(texture))
	}

	for m in MUSICS_FILE {
		music := fmt.ctprintf("%s%s", RESOURCES_DIR, m)
		append(&musics, LoadMusicStream(music))
	}

	if music_enabled && len(musics) > 0 {
		PlayMusicStream(musics[int(MUSICS_ID.MENU)])
		SetMusicVolume(musics[int(music_id_playing)], 0.5)
	}
	load_shaders()
	game.is_running = false
}

// TODO:
app_loop_logo :: proc() {
}

game_resources_clear :: proc() {
	// resouces cleanup
	clear(&game.asteroids)
	clear(&game.cpu_particles)
	clear(&game.bullets)
	clear(&game.missles)
	clear(&game.enemies)
	clear(&game.space_objects)
}

init_player :: proc() {
	using raylib

	// nuke all of game? or just re-init the b2 world?
	if i32(game.world_id.index) != 0 {
		b2.destroy_world(game.world_id)
	}

	ship_def := PLAYER_SHIPS_DEFS[game.player_ship_def]

	game.world_def = b2.DEFAULT_WORLD_DEF
	game.world_def.gravity = linalg.Vector2f32{0, 0}
	game.world_id = b2.create_world(&game.world_def)

	// create player
	body_def := b2.DEFAULT_BODY_DEF
	body_def.type = .Dynamic
	body_def.position = linalg.Vector2f32{0, 0}
	body_def.linear_damping = 2.0
	body_def.angular_damping = 2.0
	game.player = new_entity(Player)
	body_def.user_data = rawptr(game.player)
	body_id := b2.create_body(game.world_id, &body_def)

	shape_def := b2.DEFAULT_SHAPE_DEF
	shape_def.density = 0.01
	shape_def.friction = 0.03
	shape_def.user_data = rawptr(game.player)

	circle: b2.Circle
	circle.radius = .5
	shape_id := b2.create_circle_shape(body_id, &shape_def, &circle)

	f: b2.Filter
	f.category_bits = u32(COLLISION_CATEGORY_SET{.PLAYER})
	f.mask_bits = ~u32(COLLISION_CATEGORY_SET{.PLAYER})
	f.group_index = 0
	b2.shape_set_filter(shape_id, f)

	game.player.body_id = body_id
	game.player.thrust_vel = ship_def.thrust_vel
	game.player.max_velocity = ship_def.max_velocity
	game.player.thrust_texture_scale = ship_def.thrust_texture_scale
	game.player.life = ship_def.max_life
	game.player.max_life = ship_def.max_life
	game.player.cargo_space = ship_def.cargo_space
	game.player.cargo = {}
	game.player.texture = &textures[ship_def.texture_id]
	game.player.tint = WHITE

	game.player.thrust_texture =
	&textures[raylib.GetRandomValue(i32(TEXTURES_ID.FIRE1), i32(TEXTURES_ID.FIRE6))]
	game.player.thrust_pos = linalg.Vector2f32 {
		f32(game.player.thrust_texture^.width / 2),
		f32(game.player.thrust_texture^.height / 2) - f32(game.player.texture^.height / 2) - 10,
	}
	game.player.primary_weapon = ship_def.primary_weapon
	game.player.secondary_weapon = ship_def.secondary_weapon
	game.camera_follows = game.player
	game.camera.target = linalg.Vector2f32{0, 0}
}

init_freeplay :: proc() {
	game_resources_clear()
	game.is_mission_complete = false
	game.is_mission_failed = false
	game.is_in_mission = false
	game.is_running = true
	game.showing_display_panel = false
	game.showing_waypoint_nav = false
	game.waypoint = linalg.Vector2f32{0, 0}
	game.mission = -1
	game.mission_task_index = -1
	game.score = 0
	game.easing_camera_zoom_map = ease.flux_init(f32)
	game.camera.target = linalg.Vector2f32{0, 0}
	gen_asteroids_ring_pos(get_player_pos(), 10, 50, 50, .5, 3.5)
	game.stopwatch_start = raylib.GetTime()
}

init_campain :: proc() {
	game_resources_clear()
	game.is_mission_complete = false
	game.is_mission_failed = false
	game.is_in_mission = true
	game.is_running = true
	game.showing_display_panel = false
	// at start of game, the panel should be shown for some seconds with the mission briefing
	game.show_display_panel_forced_time = game.current_time + 5
	game.showing_waypoint_nav = true
	game.waypoint = linalg.Vector2f32{0, 0}
	game.mission = 0
	game.mission_task_index = 0
	game.easing_camera_zoom_map = ease.flux_init(f32)
	game.camera.target = linalg.Vector2f32{0, 0}
	gen_asteroids_ring_pos(get_player_pos(), 10, 50, 50, .5, 3.5)
	game.stopwatch_start = raylib.GetTime()
	// enemies had to be queried or it would SIGSEGV?

	// time.stopwatch_reset(&game.stopwatch)
	// time.stopwatch_start(&game.stopwatch)
}

app_loop_gameplay :: proc(dt: f32) {
	using raylib
	handle_contact_events(dt)
	process_user_input(&input_processed)

	if music_enabled {
		if music_id_playing != .BACKGROUND {
			StopMusicStream(musics[music_id_playing])
			music_id_playing = .BACKGROUND
			PlayMusicStream(musics[music_id_playing])
		}
	}

	if input_processed.toggle_pause {
		game.pause = !game.pause
	}

	// panel is displayed for show_display_panel_forced_time
	// or can be toggled on/off with TAB (input_processed display_panel toggle)
	if input_processed.display_panel {
		if game.show_display_panel_forced_time > game.current_time {
			game.show_display_panel_forced_time = game.current_time
		} else {
			game.showing_display_panel = !game.showing_display_panel
		}
	}

	if input_processed.waypoint_nav {
		game.showing_waypoint_nav = !game.showing_waypoint_nav
	}

	if input_processed.exit {
		trans_to_state = .TITLE
		// this is menu key cooldown, so we don't consider **game** time
		key_cooldown = .5
		menu_selected = -2
	}

	if input_processed.use_item1 {
		if len(game.player.cargo) > 0 {
			consume_cargo_item(0)
		}
	}

	if input_processed.use_item2 {
		if len(game.player.cargo) > 1 {
			consume_cargo_item(1)
		}
	}

	if input_processed.use_item3 {
		if len(game.player.cargo) > 2 {
			consume_cargo_item(2)
		}
	}

	if input_processed.use_item4 {
		if len(game.player.cargo) > 3 {
			consume_cargo_item(3)
		}
	}

	if !game.pause {
		// should be based on game type, or mission type, this is testing
		generation_call()

		when !IS_WASM {
			if input_processed.toggle_debug {
				debug_enabled = !debug_enabled
			}
		}

		if input_processed.move_left {
			// b2.body_apply_angular_impulse(game.player.body_id, .5, true)
			b2.body_apply_torque(game.player.body_id, .02, true)
		}

		if input_processed.move_right {
			// b2.body_apply_angular_impulse(game.player.body_id, -.5, true)
			b2.body_apply_torque(game.player.body_id, -.02, true)
		}

		mousepos := get_mouse_to_box2d()
		playerpos := get_player_pos()
		
		// mouse wheel zooms the camera
		if (input_processed.m_wheel != 0) {
			game.camera_target_zoom += input_processed.m_wheel * MOUSEWHEEL_ZOOM_SPEED
			if game.camera_target_zoom >
			   CAMERA_ZOOM_MAX {game.camera_target_zoom = CAMERA_ZOOM_MAX}
			if game.camera_target_zoom <
			   CAMERA_ZOOM_MIN {game.camera_target_zoom = CAMERA_ZOOM_MIN}
			game.easing_camera_tween = ease.flux_to(
				&game.easing_camera_zoom_map,
				&game.camera.zoom,
				game.camera_target_zoom,
				.Sine_In_Out,
				100000000,
				0,
			)
			game.easing_camera_tween = ease.flux_to(
				&game.easing_camera_zoom_map,
				&game.camera.zoom,
				game.camera_target_zoom,
				.Sine_In_Out,
				100000000,
				0,
			)
		}

		if game.camera.zoom != game.camera_target_zoom {
			ease.flux_update(&game.easing_camera_zoom_map, f64(dt))
		}

		// ProcessGestureEvent() - see rgestures.h
		// should process Pinch events as zoom, same as mousewheel above

		// apply thrust to player
		if input_processed.move_up {
			thr := PLAYER_SHIPS_DEFS[int(selected_player_ship)].thrust_vel
			// max := PLAYER_SHIPS_DEFS[int(selected_player_ship)].max_velocity

			if input_processed.boost {
				thr =
					PLAYER_SHIPS_DEFS[int(selected_player_ship)].thrust_vel *
					THRUST_BOOST_BASE_MULTIPLIER
				// max =
				// 	PLAYER_SHIPS_DEFS[int(selected_player_ship)].max_velocity *
				// 	THRUST_BOOST_BASE_MULTIPLIER
				game.player.is_boosting = true
				game.player.is_thrusting = true
			} else {
				game.player.is_thrusting = true
				game.player.is_boosting = false
			}

			velocityX :=
				b2.body_get_mass(game.player.body_id) *
				(thr / RE_SCALE) *
				math.sin(b2.body_get_angle(game.player.body_id))
			velocityY :=
				b2.body_get_mass(game.player.body_id) *
				(thr / RE_SCALE) *
				-math.cos(b2.body_get_angle(game.player.body_id))
			b2.body_apply_force_to_center(game.player.body_id, b2.Vec2{velocityX, velocityY}, true)
			//b2.body_apply_force(game.player.body_id, {0, 5}, b2.body_get_position(game.player.body_id), true)
			thrust_burn_particles(get_player_pos(), b2.Vec2{velocityX, velocityY}, thr)
		} else {
			game.player.is_thrusting = false
			game.player.is_boosting = false
		}

		//primary fire controls for player, considers cooldown
		if input_processed.primary_fire &&
		   (game.current_time - game.last_primary_fire) >
			   f64(WEAPONS_DEFS[game.player.primary_weapon].cooldown) {
			game.last_primary_fire = game.current_time
			handle_weapon_fire(
				game.player.primary_weapon,
				get_player_pos(),
				game.player.body_id,
				-math.atan2_f32(playerpos.x - mousepos.x, playerpos.y - mousepos.y),
			)
		}

		//primary fire controls for player, considers cooldown
		if input_processed.secondary_fire &&
		   (game.current_time - game.last_secondary_fire) >
			   f64(WEAPONS_DEFS[game.player.secondary_weapon].cooldown) {
			game.last_secondary_fire = game.current_time
			handle_weapon_fire(
				game.player.secondary_weapon,
				get_player_pos(),
				game.player.body_id,
				-math.atan2_f32(playerpos.x - mousepos.x, playerpos.y - mousepos.y),
			)
		}

		// check for item being used, special (2x fire bonus, etc.)
		i := 0
		for i < len(game.player.cargo) {
			if game.player.cargo[i].time_lifetime != 0 &&
			   game.player.cargo[i].time_lifetime < game.current_time {
				unordered_remove(&game.player.cargo, i)
				continue
			}
			i += 1
		}
	}

	//camera follows player
	update_camera_center_smooth_follow(
		&game.camera,
		game.camera_follows,
		dt,
		raylib.GetScreenWidth(),
		raylib.GetScreenHeight(),
	)
	update_asteroids(dt)
	update_particles(dt)
	BeginDrawing()

	if !disable_background_shader {
		draw_background_shader()
	} else {
		ClearBackground(BLACK)
	}

	BeginMode2D(game.camera)

	//////////////////////////////////////////////
	raylib.rlPushMatrix()
	raylib.rlDisableBackfaceCulling()
	// invert the y axis
	raylib.rlScalef(1, -1, 1)

	draw_asteroids()
	asteroid_draw_index = 0
	draw_particles()

	if len(game.missles) > 0 {
		for m, i in game.missles {
			if b2.body_is_valid(game.missles[i].target_id) {
				raylib.DrawCircleV(
					b2.body_get_position(game.missles[i].target_id) * RE_SCALE,
					1 * RE_SCALE,
					Fade(ORANGE, rand.float32_range(0.25, 0.45)),
				)
			}	
		}
	}


	// TODO: actually calculate the aabb, not just blindly set it to something big enough
	upper_bound := b2.Vec2{game.camera.target.x + 2600, -game.camera.target.y + 2000} / RE_SCALE
	lower_bound := b2.Vec2{game.camera.target.x - 2600, -game.camera.target.y - 2000} / RE_SCALE

	b2.world_query_aabb(
		game.world_id,
		draw_query_callback,
		b2.AABB{lower_bound, upper_bound},
		b2.DEFAULT_QUERY_FILTER,
		nil,
	)

	// call mission display handler if we're in a mission, and it has one
	if game.is_in_mission {
		if MISSIONS_DEFS[game.mission].tasks[game.mission_task_index].world_display_handler !=
		   nil {
			MISSIONS_DEFS[game.mission].tasks[game.mission_task_index].world_display_handler()
		}
	}

	// DEBUG CONNECTIONs
	when !IS_WASM {
		if debug_enabled {
			debug_draw := b2.Debug_Draw {
				draw_polygon           = draw_polygon,
				draw_solid_polygon     = draw_solid_polygon,
				draw_circle            = draw_circle,
				draw_solid_circle      = draw_solid_circle,
				draw_capsule           = draw_capsule,
				draw_solid_capsule     = draw_solid_capsule,
				draw_segment           = draw_segment,
				draw_transform         = draw_transform,
				draw_point             = draw_point,
				draw_string            = draw_string,
				draw_shapes            = draw_shapes,
				draw_joints            = false,
				draw_aab_bs            = draw_aabbs,
				draw_mass              = draw_mass,
				draw_graph_colors      = false,
				draw_contact_normals   = false,
				draw_contact_impulses  = false,
				draw_friction_impulses = false,
			}
			b2.world_draw(game.world_id, &debug_draw)
			// DrawRectangleV(
			// 	Vector2{lower_bound.x, lower_bound.y} * RE_SCALE,
			// 	Vector2{upper_bound.x - lower_bound.x, upper_bound.y - lower_bound.y} * RE_SCALE,
			// 	Fade(RED, 0.15),
			// )
		}
	}

	//////////////////////////////////////////////
	raylib.rlDrawRenderBatchActive()
	raylib.rlEnableBackfaceCulling()
	raylib.rlPopMatrix()

	// targeting crosshairs, in world space
	// TODO: determine a minimum size, always draw at least this size
	sprite_offset := raylib.Vector2 {
		f32(textures[int(TEXTURES_ID.CROSSHAIR)].width / 2),
		f32(textures[3].height / 2),
	}
	DrawTexturePro(
		textures[int(TEXTURES_ID.CROSSHAIR)],
		raylib.Rectangle {
			0,
			0,
			f32(textures[int(TEXTURES_ID.CROSSHAIR)].width),
			f32(textures[int(TEXTURES_ID.CROSSHAIR)].height),
		},
		raylib.Rectangle {
			input_processed.mw_pos.x,
			input_processed.mw_pos.y,
			f32(textures[int(TEXTURES_ID.CROSSHAIR)].width),
			f32(textures[int(TEXTURES_ID.CROSSHAIR)].height),
		},
		raylib.Vector2{sprite_offset.x, sprite_offset.y},
		0,
		WHITE,
	)

	// SCREEN SPACE
	EndMode2D()

	if game.pause {
		DrawRectangle(
			0,
			(raylib.GetScreenHeight() / 2) - 100,
			raylib.GetScreenWidth(),
			200,
			Fade(WHITE, 0.5),
		)
		//TODO, really should be calculating the width of the text
		DrawTextEx(
			default_font,
			"PAUSED",
			Vector2{f32(raylib.GetScreenWidth() / 2), f32(raylib.GetScreenHeight() / 2) - 20},
			40,
			1,
			WHITE,
		)
	}

	draw_hud()

	if game.is_in_mission {
		if MISSIONS_DEFS[game.mission].tasks[game.mission_task_index].screen_display_handler !=
		   nil {
			MISSIONS_DEFS[game.mission].tasks[game.mission_task_index].screen_display_handler()
		}

		//mission task update hander
		if MISSIONS_DEFS[game.mission].tasks[game.mission_task_index].update_handler() {
			mission_task_clear()
			game.mission_task_index += 1
			game.show_display_panel_forced_time = game.current_time + 5
			if game.mission_task_index >= len(MISSIONS_DEFS[game.mission].tasks) {
				game.is_mission_complete = true
				game.is_in_mission = true
				game.show_display_panel_forced_time = game.current_time + 8
				// play mission complete sound
				raylib.PlaySound(sfxs[int(SFX_ID.WEIRD)])
			} else {
				// play task completion sound
				raylib.PlaySound(sfxs[int(SFX_ID.BING)])
			}
		}
		waypoint_rotation := linalg.normalize(game.waypoint - get_player_pos())

		if game.showing_display_panel || game.show_display_panel_forced_time > game.current_time {
			draw_mission_popup_panel()
		} else {
			// DrawRectangle(
			// 	raylib.GetScreenWidth() - 60,
			// 	raylib.GetScreenHeight() - 25,
			// 	60,
			// 	20,
			// 	Fade(WHITE, 0.5),
			// )
			// user_input_close_panel_txt :cstring= "[TAB]"
			// DrawTextEx(
			// 	default_font,
			// 	user_input_close_panel_txt,
			// 	Vector2{f32(raylib.GetScreenWidth() - 60), f32(raylib.GetScreenHeight() - 25)},
			// 	22,
			// 	1,
			// 	RED,
			// )			
		}
	}

	if IsKeyPressed(.F1) {
		godmode_enabled = !godmode_enabled
	}
	if IsKeyPressed(.F3) {
		disable_background_shader = !disable_background_shader
	}

	if godmode_enabled {
		user_input_close_panel_txt: cstring = "[GOD]"
		DrawTextEx(
			default_font,
			user_input_close_panel_txt,
			Vector2{f32(raylib.GetScreenWidth() - 60), f32(raylib.GetScreenHeight() - 25)},
			22,
			1,
			RED,
		)
	}

	// no plumbing to support Raygui under WASM
	// for ease of debugging, which I don't want WASM builds to do, then it is fine to use Raygui
	when !IS_WASM {
		if debug_enabled {
			debug_panel()
		}
	}

	EndDrawing()

	// check for player death
	if game.player.life < 0 {
		if godmode_enabled {
			game.player.life = 0
		} else {
			key_cooldown = 1
			menu_selected = -2
			trans_to_state = APP_STATE.RESTART
		}
	}
}

// TODO: hook up to game, probably about the time we get easing in
app_transition_to :: proc(new_state: APP_STATE) {
	on_transition = true
	trans_from_state = app_current_state
	trans_to_state = new_state
	trans_fade_out = false
	trans_alpha = 0.0
}

APP_STATE :: enum {
	LOGO,
	TITLE,
	GAMEPLAY,
	ARCADE_SELECT,
	OPTIONS,
	RESTART,
	QUIT,
}

@(export)
update :: proc "c" () {
	context = runtime.default_context()
	context.allocator = mem.arena_allocator(&arena)
	using raylib

	when !IS_WASM {
		if IsKeyPressed(.KP_ADD) {
			if int(trace_log_level) < int(raylib.TraceLogLevel.ERROR) {
				trace_log_level += TraceLogLevel(1)
				raylib.SetTraceLogLevel(trace_log_level)
			}
			TraceLog(trace_log_level, "TraceLog ", trace_log_level)
		}

		if IsKeyPressed(.KP_SUBTRACT) {
			trace_log_level -= TraceLogLevel(1)
			if trace_log_level < .ALL {
				trace_log_level = .ALL
			}
			TraceLog(trace_log_level, "TraceLog ", trace_log_level)
			raylib.SetTraceLogLevel(trace_log_level)
		}
	}

	game.previous_time = game.current_time
	game.current_time = raylib.GetTime()
	shader_iTime = f32(raylib.GetTime())
	dt := f32(game.current_time - game.previous_time)

	if raylib.IsWindowResized() {
		iResolution := raylib.Vector2{f32(GetScreenWidth()), f32(GetScreenHeight())}
		liResolution := GetShaderLocation(shaders[int(SHADERS_ID.STARNEST)], "iResolution")

		SetShaderValue(
			shaders[int(SHADERS_ID.STARNEST)],
			raylib.ShaderLocationIndex(liResolution),
			&iResolution,
			raylib.ShaderUniformDataType(SHADER_UNIFORM_VEC2),
		)
		SetShaderValue(
			shaders[int(SHADERS_ID.GALAXYTRIP)],
			raylib.ShaderLocationIndex(liResolution),
			&iResolution,
			raylib.ShaderUniformDataType(SHADER_UNIFORM_VEC2),
		)
	}

	if input_processed.toggle_music {
		if music_enabled {
			PauseMusicStream(musics[music_id_playing])
		} else {
			ResumeMusicStream(musics[music_id_playing])
		}
		music_enabled = !music_enabled
	}

	if music_enabled {
		// Update music buffer with new stream data
		UpdateMusicStream(musics[music_id_playing])
	}

	switch app_current_state {
	case .LOGO:
		app_loop_logo()
	case .TITLE:
		app_loop_title(dt)
	case .GAMEPLAY:
		if game.is_running && !game.pause {
			b2.world_step(game.world_id, dt, 8, 3)
		}
		app_loop_gameplay(dt)
	case .ARCADE_SELECT:
		app_loop_arcade_select(dt)
	case .OPTIONS:
		app_loop_options(dt)
	case .RESTART:
		app_loop_restart()
	case .QUIT:
		game_resources_clear()
		CloseAudioDevice()
		CloseWindow()
	}

	if app_current_state != trans_to_state {
		trans_from_state = app_current_state
		app_current_state = trans_to_state
		if trans_from_state == APP_STATE.GAMEPLAY {
			ShowCursor()
		}
		if trans_to_state == APP_STATE.GAMEPLAY {
			HideCursor()
		}
		// clear menu ui selections
		menu_selected = -2
	}
}

// raylib_sdl/raylib.odin
// 1342:   GenImagePerlinNoise    :: proc(width, height: c.int, offsetX, offsetY: c.int, scale: f32) -> Image  ---  
// draw_asteroids_3d :: proc() {
// }

// this actually doesnt get called in WASM
// only in native
main :: proc() {
	raylib.SetTraceLogLevel(trace_log_level)

	init()
	for !raylib.WindowShouldClose() {
		update()
	}
}
