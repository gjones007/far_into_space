package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

weapon_switch_grade :: proc(grade: i32) -> WEAPONS_ID {
    switch grade {
    case 0 ..= 1:
        return WEAPONS_ID.ES
    case 2:
        return WEAPONS_ID.EM
    case 3:
        return WEAPONS_ID.EL
    }
    return WEAPONS_ID.ES
}

//this is just for testing
generation_call :: proc() {

    player_pos := get_player_pos()
    switch rl.GetRandomValue(0, 2000) {
    case 1000 ..= 1200:
        if len(game.asteroids) < MAX_ASTEROID_COUNT {
            gen_asteroids_ring_pos(get_player_pos(), 30, 50, 3, .5, 3.5)
        }
    case 11 ..= 30:
        {
            if len(game.enemies) < MAX_ENEMY_COUNT {
                grade := rl.GetRandomValue(0, 3)
                pos := ring_positioning(get_player_pos(), 30, 50)
                size := rand.float32_range(0.70, 1.5)
                texture := TEXTURES_ID(int(TEXTURES_ID.ENEMY_BLACK1) + int(grade))
                thrust_texture := TEXTURES_ID.FIRE3
                life := 50 + f32((grade + 1) * 50)
                thrust_velocity := 400 + (200 * f32(grade))
                sensor_range := rand.float32_range(9, 14) + f32(grade)
                weapon := weapon_switch_grade(grade)
                gen_enemy(pos, size, texture, thrust_texture, life, thrust_velocity, brain_enemy_black, weapon, sensor_range)
                //sensor_attach_enemy(i, 10)
            }
        }

    case 41 ..= 50:
        {
            if len(game.enemies) < MAX_ENEMY_COUNT {
                grade := rl.GetRandomValue(0, 3)
                pos := ring_positioning(get_player_pos(), 30, 50)
                size := rand.float32_range(0.70, 1.5)
                texture := TEXTURES_ID(int(TEXTURES_ID.ENEMY_RED1) + int(grade))
                thrust_texture := TEXTURES_ID.FIRE5
                life := 50 + f32((grade + 1) * 100)
                thrust_velocity := 600 + (200 * f32(grade))
                sensor_range := rand.float32_range(9, 14) + f32(grade)
                weapon := weapon_switch_grade(grade)
                gen_enemy(pos, size, texture, thrust_texture, life, thrust_velocity, brain_enemy_red, weapon, sensor_range)
                // sensor_attach_enemy(i, 10)
            }
        }

    case 51 ..= 60:
        {
            if len(game.enemies) < MAX_ENEMY_COUNT {
                grade := rl.GetRandomValue(0, 3)
                pos := ring_positioning(get_player_pos(), 30, 50)
                size := rand.float32_range(0.70, 1.5)
                texture := TEXTURES_ID(int(TEXTURES_ID.ENEMY_BLUE1) + int(grade))
                thrust_texture := TEXTURES_ID.FIRE5
                life := 50 + f32((grade + 1) * 100)
                thrust_velocity := 600 + (200 * f32(grade))
                sensor_range := rand.float32_range(9, 14) + f32(grade)
                weapon := WEAPONS_ID.DF
                gen_enemy(pos, size, texture, thrust_texture, life, thrust_velocity, brain_enemy_blue, weapon, sensor_range)
                // sensor_attach_enemy(i, 10)
            }
        }

    case 61 ..= 70:
        {
            if len(game.enemies) < MAX_ENEMY_COUNT {
                grade := rl.GetRandomValue(0, 3)
                pos := ring_positioning(get_player_pos(), 30, 50)
                size := rand.float32_range(0.70, 1.5)
                texture := TEXTURES_ID(int(TEXTURES_ID.ENEMY_GREEN1) + int(grade))
                thrust_texture := TEXTURES_ID.FIRE5
                life := 100 + f32((grade + 1) * 100)
                thrust_velocity := 600 + (200 * f32(grade))
                sensor_range := rand.float32_range(9, 14) + f32(grade)
                weapon := weapon_switch_grade(grade)
                gen_enemy(pos, size, texture, thrust_texture, life, thrust_velocity, brain_enemy_green, weapon, sensor_range)
                // sensor_attach_enemy(i, 10)
            }
        }


    // case 21 ..= 25:
    // 	{
    // 		grade := rl.GetRandomValue(0, 4)
    // 		pos := ring_positioning(get_player_pos(), 30, 50)
    // 		size := rand.float32_range(0.70, 1.5)
    // 		texture := TEXTURES_ID(int(TEXTURES_ID.SPACE_ROCKET1) + int(grade))
    // 		thrust_texture := TEXTURES_ID.FIRE8
    // 		life := 500 + f32((grade + 1) * 100)
    // 		thrust_velocity := 700 + (200 * f32(grade))
    // 		sensor_range := rand.float32_range(7, 12)
    // 		weapon := WEAPONS_ID.EL
    // 		gen_enemy(
    // 			pos,
    // 			size,
    // 			texture,
    // 			thrust_texture,
    // 			life,
    // 			thrust_velocity,
    // 			brain_goal_bot,
    // 			weapon,
    // 			sensor_range,
    // 		)
    // 	}
    case 36 ..= 37:
        {
            // if game.has_boss {
            // 	break
            // }
            grade := rl.GetRandomValue(0, 4)
            pos := ring_positioning(get_player_pos(), 30, 50)
            size: f32 = 2
            texture := TEXTURES_ID.RED_BOSS_ENEMY
            thrust_texture := TEXTURES_ID.FIRE3
            life: f32 = 2000.
            thrust_velocity := 400 + (200 * f32(grade))
            sensor_range := rand.float32_range(7, 11) + f32(grade)
            weapon := WEAPONS_ID.BOSS1
            gen_enemy(pos, size, texture, thrust_texture, life, thrust_velocity, brain_enemy_red, weapon, sensor_range)
            // game.enemies[i].is_boss = true
            // game.has_boss = true
        }
    // case 138..=339: {
    // 	// if game.has_boss {
    // 	// 	break
    // 	// }
    // 	grade := rl.GetRandomValue(0, 4)
    // 	pos:= ring_positioning(get_player_pos(), 20, 30) 
    // 	size:f32= 2
    // 	texture := TEXTURES_ID.RED_BOSS_ENEMY
    // 	thrust_texture := TEXTURES_ID.FIRE3
    // 	life :f32= 2000.
    // 	thrust_velocity := 400 + (200 * f32(grade))
    // 	sensor_range := rand.float32_range(7, 11) + f32(grade)
    // 	weapon := WEAPONS_ID.AS
    // 	i := gen_enemy(pos, size, texture, thrust_texture, life, thrust_velocity, brain_enemy_red, weapon, sensor_range)
    // 	// game.enemies[i].is_boss = true
    // 	// game.has_boss = true
    // }
    case 91 ..= 301:
        {
            if len(game.space_objects) < MAX_SPACEOBJECT_COUNT {
                pos := ring_positioning(get_player_pos(), 30, 50)
                lifetime := rand.float32_range(10, 120)
                grade := rl.GetRandomValue(0, 2)
                switch grade {
                case 0:
                    gen_spaceobject_crate(pos, .REPAIR, lifetime)
                case 1:
                    gen_spaceobject_crate(pos, .WEAPON, lifetime)
                case 2:
                    gen_spaceobject_crate(pos, .SPECIAL, lifetime)
                }
            }
        }
    }
}

consume_cargo_item :: proc(id: int) {
    item := &game.player.cargo[id]
    if item.time_lifetime > 0 {
        return
    }

    switch item.type {
    case .REPAIR:
        {
            game.player.life += 1000
            if game.player.life > game.player.max_life {
                game.player.life = game.player.max_life
            }
            game.score += 50
            unordered_remove(&game.player.cargo, id)
            // TODO: play a sound
        }
    case .WEAPON:
        {
            game.player.secondary_weapon = WEAPONS_ID(item.type_id)
            game.score += 100
            unordered_remove(&game.player.cargo, id)
            // TODO: play a sound
        }
    case .SPECIAL:
        {
            item.time_lifetime = game.current_time + 20
            // game.player.primary_weapon = WEAPONS_ID(item.type_id)
            game.score += 100
        }
    }
}

gen_spaceobject_crate :: proc(pos: linalg.Vector2f32, type: SpaceObjectType, lifetime: f32) {
    if len(game.space_objects) > MAX_SPACEOBJECT_COUNT {
        return
    }

    o := new_entity(SpaceObject)

    o.time_lifetime = game.current_time + f64(lifetime)

    body_def := b2.DefaultBodyDef()
    body_def.type = .dynamicBody
    body_def.position = pos
    body_def.isAwake = true
    body_def.userData = rawptr(o)
    // body_def.rotation = rand.float32_range(0, 1)
    body_def.linearDamping = 0.1
    body_def.angularDamping = 0.1
    o.body_id = b2.CreateBody(game.world_id, body_def)
    shape_def := b2.DefaultShapeDef()
    shape_def.density = 0.01
    shape_def.friction = 0.01
    shape_def.restitution = 0.01
    // shape_def.userData = rawptr(o)

    switch type {
    case SpaceObjectType.REPAIR:
        {
            shape_def.userData = &textures[int(TEXTURES_ID.POWERUPRED)]
            // o.texture = &textures[int(TEXTURES_ID.POWERUPRED)]
            o.type = .REPAIR
            o.is_cargo = true
            box := b2.MakeBox(.17, .17)
            shape_id := b2.CreatePolygonShape(o.body_id, shape_def, box)
        }
    case SpaceObjectType.WEAPON:
        {
            shape_def.userData = &textures[int(TEXTURES_ID.POWERUPBLUE)]
            // o.texture = &textures[int(TEXTURES_ID.POWERUPBLUE)]
            o.type = .WEAPON
            if len(missle_weapon_defs) == 0 {
                missle_weapon_def_list()
            }
            type_id := rl.GetRandomValue(0, i32(len(missle_weapon_defs)) - 1)
            o.type_id = int(missle_weapon_defs[type_id])
            o.is_cargo = true
            box := b2.MakeBox(.17, .17)
            shape_id := b2.CreatePolygonShape(o.body_id, shape_def, box)
        }
    case SpaceObjectType.SPECIAL:
        {
            shape_def.userData = &textures[int(TEXTURES_ID.POWERUPYELLOW_BOLT)]
            // o.texture = &textures[int(TEXTURES_ID.POWERUPYELLOW_BOLT)]
            o.type = .SPECIAL
            if len(bullets_weapon_defs) == 0 {
                bullets_weapon_def_list()
            }
            type_id := rl.GetRandomValue(0, i32(len(bullets_weapon_defs)) - 1)
            o.type_id = int(bullets_weapon_defs[type_id])
            o.is_cargo = true
            box := b2.MakeBox(.17, .17)
            shape_id := b2.CreatePolygonShape(o.body_id, shape_def, box)
        }
    }
}

missle_weapon_defs: [dynamic]int
bullets_weapon_defs: [dynamic]int

missle_weapon_def_list :: proc() {
    for w, i in WEAPONS_DEFS {
        if w.type == .MISSLE {
            append(&missle_weapon_defs, i)
        }
    }
}

bullets_weapon_def_list :: proc() {
    for w, i in WEAPONS_DEFS {
        if w.type == .BULLET {
            append(&bullets_weapon_defs, i)
        }
    }
}

gen_asteroid :: proc(pos: linalg.Vector2f32, min_size: f32, max_size: f32) {
    if len(game.asteroids) >= MAX_ASTEROID_COUNT {
        return
    }

    a := new_entity(Asteroid)
    a.size = rand.float32_range(min_size, max_size)

    body_def := b2.DefaultBodyDef()
    body_def.type = .dynamicBody
    body_def.position = pos
    body_def.linearDamping = 0.01
    body_def.angularDamping = 0.01
    body_def.userData = rawptr(a)
    //body_def.angle = rand.float32_range(0, 2 * math.PI)
    body_def.linearVelocity = b2.Vec2{rand.float32_range(-1, 1), rand.float32_range(-1, 1)}
    body_def.angularVelocity = rand.float32_range(0, 2 * math.PI)
    a.body_id = b2.CreateBody(game.world_id, body_def)

    shape_def := b2.DefaultShapeDef()
    shape_def.density = 0.1
    shape_def.friction = 0.3
    shape_def.userData = rawptr(a)

    circle: b2.Circle
    circle.radius = a.size
    shape_id := b2.CreateCircleShape(a.body_id, shape_def, circle)

    // category_bits: COLLISION_CATEGORY_SET = {.ASTEROID}
    // f: b2.Filter
    // f.category_bits = i32(category_bits)
    // f.mask_bits = 0x0001
    // f.group_index = 0

    // f: b2.Filter
    // f.category_bits = -3
    // f.mask_bits = -1
    // f.group_index = 2
    // b2.shape_set_filter(shape_id, f)

    // filter1 := b2.shape_get_filter(shape_id);
    // fmt.println("filter 1 ", filter1);
}

// generate asteroids in a ring around a position
gen_asteroids_ring_pos :: proc(
    pos: linalg.Vector2f32,
    inner_ring: f32,
    outer_ring: f32,
    count: int,
    aster_min_size: f32,
    aster_max_size: f32,
) {
    for i in 0 ..< count {
        gen_asteroid(ring_positioning(pos, inner_ring, outer_ring), aster_min_size, aster_max_size)
    }
}

ring_positioning :: proc(pos: linalg.Vector2f32, inner_ring: f32, outer_ring: f32) -> linalg.Vector2f32 {
    assert(outer_ring > inner_ring)
    center := pos
    for true {
        center = pos + linalg.Vector2f32{rand.float32_range(-outer_ring, outer_ring), rand.float32_range(-outer_ring, outer_ring)}
        if linalg.length(center - pos) < inner_ring {
            continue
        }
        break
    }
    return center
}

gen_enemy :: proc(
    pos: linalg.Vector2f32,
    size: f32,
    texture: TEXTURES_ID,
    thrust_texture: TEXTURES_ID,
    life: f32,
    thrust_velocity: f32,
    brain: proc(_: ^Enemy, _: f32),
    weapon: WEAPONS_ID,
    sensor_range: f32,
) {
    e := new_entity(Enemy)
    e.ai_cooldown = game.current_time
    e.life = life
    e.size = size
    e.faction = .ENEMY
    e.thrust_vel = thrust_velocity
    e.brain = brain
    e.is_thrusting = false
    e.is_boss = false
    e.primary_weapon = weapon
    e.tint = rl.WHITE

    body_def := b2.DefaultBodyDef()
    body_def.userData = rawptr(e)
    body_def.type = .dynamicBody
    body_def.position = pos
    body_def.linearDamping = 2.0
    body_def.angularDamping = 1.0
    e.body_id = b2.CreateBody(game.world_id, body_def)

    shape_def := b2.DefaultShapeDef()
    shape_def.density = 0.01
    shape_def.friction = 0.03
    // shape_def.userData = rawptr(e)
    shape_def.userData = &textures[int(texture)]

    circle: b2.Circle
    circle.radius = .5 * size
    // e.shape_id = b2.create_circle_shape(e.body_id, &shape_def, &circle)
    shape_id := b2.CreateCircleShape(e.body_id, shape_def, circle)

    shape_def2 := b2.DefaultShapeDef()
    shape_def2.density = 0.01
    shape_def2.friction = 0.03
    // shape_def.userData = rawptr(e)
    shape_def2.userData = &textures[int(texture) + 1]

    circle2: b2.Circle
    circle2.radius = .5 * size
    // e.shape_id = b2.create_circle_shape(e.body_id, &shape_def, &circle)
    shape_id2 := b2.CreateCircleShape(e.body_id, shape_def2, circle2)

    f: b2.Filter
    f.categoryBits = u32(COLLISION_CATEGORY_SET{.ENEMY})
    f.maskBits = ~u32(COLLISION_CATEGORY_SET{.ENEMY})
    f.groupIndex = 0
    // b2.shape_set_filter(e.shape_id, f)
    b2.Shape_SetFilter(shape_id, f)

    e.thrust_texture_scale = rand.float32_range(0.70, 1.5)
    e.thrust_texture = &textures[int(thrust_texture)]
    e.thrust_pos = linalg.Vector2f32 {
        f32(e.thrust_texture^.width / 2),
        f32(e.thrust_texture^.height / 2) - f32(e.thrust_texture^.height / 2) - 10,
    }
    e.sensor_range = sensor_range
    // e.texture = &textures[int(texture)]
}

sensor_attach_enemy :: proc(id: int, size: f32) {
    // add radar sensor to ship
    shape_def := b2.DefaultShapeDef()
    // shape_def.density = 0.00
    // shape_def.friction = 0.00
    shape_def.isSensor = true
    shape_def.enableContactEvents = false
    // shape_def.filter.group_index = -1
    // shape_def.filter.category_bits = 0x0002

    circle: b2.Circle
    circle.radius = size
    // b2.create_circle_shape(game.enemies[id].body_id, &shape_def, &circle)
}
