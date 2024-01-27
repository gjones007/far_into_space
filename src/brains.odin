package main

/////////////WASM
// import "raylib"
// import b2 "box2dw"
/////////////NOT WASM
import b2 "box2d"
import "vendor:raylib"

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

@(require_results)
angle_to :: #force_inline proc(a, b: linalg.Vector2f32) -> f32 {
	return math.atan2_f32(b.x - a.x, b.y - a.y)
}

@(require_results)
distance_to :: #force_inline proc(a, b: linalg.Vector2f32) -> f32 {
	return linalg.length(b - a)
}

@(require_results)
pos :: #force_inline proc(a: b2.Body_ID) -> linalg.Vector2f32 {
	return b2.body_get_position(a)
}

enemy_apply_thrust :: proc(e: ^Enemy) {
	velocityX :=
		b2.body_get_mass(e.body_id) *
		(e.thrust_vel / RE_SCALE) *
		math.sin(b2.body_get_angle(e.body_id))
	velocityY :=
		b2.body_get_mass(e.body_id) *
		(e.thrust_vel / RE_SCALE) *
		-math.cos(b2.body_get_angle(e.body_id))

	b2.body_apply_force_to_center(e.body_id, b2.Vec2{velocityX, velocityY}, true)
	velocity:= b2.body_get_linear_velocity(e.body_id)
	assert(linalg.length(b2.body_get_linear_velocity(e.body_id)) < 3000)
	thrust_burn_particles(b2.body_get_position(e.body_id), -b2.Vec2{velocityX, velocityY}, e.thrust_vel)	
	e.is_thrusting = true
}

//drives in a straight line, ignores everything, dumbfire missles, etc.
missle_apply_thrust :: proc(e: ^Missle, dt: f32) {
	velocityX :=
		b2.body_get_mass(e.body_id) *
		(e.thrust_vel / RE_SCALE) *
		math.sin(b2.body_get_angle(e.body_id))
	velocityY :=
		b2.body_get_mass(e.body_id) *
		(e.thrust_vel / RE_SCALE) *
		-math.cos(b2.body_get_angle(e.body_id))
	b2.body_apply_force_to_center(e.body_id, b2.Vec2{velocityX, velocityY}, true)
}

brain_missle_seeker_ai :: proc(m: ^Missle, dt: f32) {
	using raylib
	if m.ai_cooldown > game.current_time {
		missle_apply_thrust(m,dt)
		return
	}

	// TODO: use sensors, or aabb box to limit the number of enemies to check?
	// b2.world_query_aabb(game.world_id, b2.AABB{5-m.pos, 5-m.pos}, brain_missle_seeker_ai_query)
	missle_pos := pos(m.body_id)

	// target closest enemy
	if !b2.body_is_valid(m.target_id) && len(game.enemies) > 0 {
		m.target_id = game.enemies[0].body_id
		target_pos := pos(m.target_id)
		distance_to_target := distance_to(target_pos, missle_pos)
		for ne, i in game.enemies {
			dte := distance_to(pos(ne.body_id), missle_pos)
			if distance_to_target > dte {
				m.target_id = ne.body_id
				distance_to_target = dte
			}
		}
	}

	target_pos := pos(m.target_id)

	b2.body_set_transform(
		m.body_id,
		pos(m.body_id),
		-angle_to(target_pos, missle_pos),
	)

	//m.ai_cooldown = game.current_time + rand.float64_range(.1, .5)	
	missle_apply_thrust(m,dt)
}

brain_enemy_red :: proc(e: ^Enemy, dt: f32) {
	if e.ai_cooldown > game.current_time {
		enemy_apply_thrust(e)
		return
	} else {
		epos := b2.body_get_position(e.body_id)
		playerpos := get_player_pos()
		dtp := distance_to_player(epos)
		e.tint = raylib.WHITE
		if dtp > e.sensor_range {
			b2.body_apply_angular_impulse(e.body_id, rand.float32_range(-.6, .6), true)
			// e.ai_cooldown = game.current_time + rand.float64_range(.4, .6)	
			enemy_apply_thrust(e)
			return
		}
	
		absolute_bearing := math.atan2_f32(epos.x - playerpos.x, epos.y - playerpos.y)
		b2.body_set_transform(
			e.body_id,
			b2.body_get_position(e.body_id),
			-absolute_bearing,
		)
		enemy_apply_thrust(e)
	
		if e.primary_weapon_cooldown < game.current_time {
			handle_weapon_fire(e.primary_weapon, epos, e.body_id, -absolute_bearing)
			def_wep_cooldown := WEAPONS_DEFS[e.primary_weapon].cooldown
			e.primary_weapon_cooldown = game.current_time + f64(def_wep_cooldown)
		}
		e.ai_cooldown = game.current_time + rand.float64_range(.2, .3)	
	}
}

// destroys cargo crates
brain_enemy_black :: proc(e: ^Enemy, dt: f32) {
	if e.ai_cooldown > game.current_time {
		enemy_apply_thrust(e)
	} else {
		if len(game.space_objects) == 0 {
			e.ai_cooldown = game.current_time + rand.float64_range(0.25, 0.5)			
			enemy_apply_thrust(e)
			return
		}

		pos := b2.body_get_position(e.body_id)
		e.tint = raylib.WHITE

		if !b2.body_is_valid(e.target_id) {
			// find closest cargo crate, should be done via sensors
			e.target_id = game.space_objects[0].body_id
			target_pos := b2.body_get_position(e.target_id)
			distance_to_pos := linalg.length(target_pos - pos)
			for so, i in game.space_objects {
				if distance_to_pos > linalg.length(b2.body_get_position(so.body_id) - pos) {
					e.target_id = so.body_id
				}
			}
		}

		target_pos := b2.body_get_position(e.target_id)
		distance_to_pos := linalg.length(target_pos - pos)

		// turn towards target crate and move towards it
		absolute_bearing := math.atan2_f32(pos.x - target_pos.x, pos.y - target_pos.y)

		b2.body_set_transform(
			e.body_id,
			b2.body_get_position(e.body_id),
			-absolute_bearing + rand.float32_range(-.02, .04),
		)				
		
		if distance_to_pos < 4 && e.primary_weapon_cooldown < game.current_time {
			handle_weapon_fire(e.primary_weapon, pos, e.body_id, -absolute_bearing)
			def_wep_cooldown := WEAPONS_DEFS[e.primary_weapon].cooldown
			e.primary_weapon_cooldown = game.current_time + f64(def_wep_cooldown)
		}
		enemy_apply_thrust(e)
		e.ai_cooldown = game.current_time + rand.float64_range(0.25, 0.5)		
	}
}

brain_enemy_blue :: proc(e: ^Enemy, dt: f32) {
	if e.ai_cooldown > game.current_time {
		enemy_apply_thrust(e)
		return
	} else {
		epos := b2.body_get_position(e.body_id)
		playerpos := get_player_pos()
		dtp := distance_to_player(epos)
		e.tint = raylib.WHITE
		if dtp > e.sensor_range {
			b2.body_apply_angular_impulse(e.body_id, rand.float32_range(-.6, .6), true)
			// e.ai_cooldown = game.current_time + rand.float64_range(.4, .6)	
			enemy_apply_thrust(e)
			return
		}
		
		absolute_bearing := math.atan2_f32(epos.x - playerpos.x, epos.y - playerpos.y)

		if dtp < 6 {
			b2.body_set_transform(
				e.body_id,
				b2.body_get_position(e.body_id),
				-absolute_bearing + rand.float32_range(-.02, .04),
			)				
		}

		enemy_apply_thrust(e)
	
		if e.primary_weapon_cooldown < game.current_time {
			handle_weapon_fire(e.primary_weapon, epos, e.body_id, -absolute_bearing)
			def_wep_cooldown := WEAPONS_DEFS[e.primary_weapon].cooldown
			e.primary_weapon_cooldown = game.current_time + f64(def_wep_cooldown)
		}
		e.ai_cooldown = game.current_time + rand.float64_range(.4, .8)	
	}
}

brain_enemy_green :: proc(e: ^Enemy, dt: f32) {
	if e.ai_cooldown > game.current_time {
		enemy_apply_thrust(e)
	} else {
		//calculate the distance to the player
		dist := distance_to_player(b2.body_get_position(e.body_id))
		// avoid the player too close
		e.tint = raylib.WHITE
		if dist < 2 {
			hard_turn := rand.float32_range(.8, 1)
			if raylib.GetRandomValue(0, 1) == 0 {
				hard_turn *= -1
			}
			b2.body_apply_angular_impulse(e.body_id, hard_turn, true)
		} else if dist > 7 {
			// too far away, move closer to player
			b2.body_apply_angular_impulse(e.body_id, .4, true)
			//e.rotation += game.player.rotation 
			//e.vel = e.vel + (game.player.pos - e.pos) * e.thrust_vel * dt
		} else {
			//randomly move around
			turn := rand.float32_range(.4, 1)
			if raylib.GetRandomValue(0, 1) == 0 {
				turn *= -1
			}
			b2.body_apply_angular_impulse(e.body_id, turn, true)
		}
		enemy_apply_thrust(e)
		e.ai_cooldown = game.current_time + rand.float64_range(0.25, 0.5)		
	}
}
