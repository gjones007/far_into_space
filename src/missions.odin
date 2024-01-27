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
import "core:math/ease"
import "core:time"


MissionDef :: struct {
	name:        cstring,
	description: cstring,
	synopsis:    cstring,
	tasks:       []MissionTaskDef,
	ship_def:    PLAYER_SHIPS_DEFS_ID,
}

MissionTaskDef :: struct {
	update_handler:         proc() -> bool,
	world_display_handler:  proc(),
	screen_display_handler: proc(),
	description:            cstring,
}

MISSIONS_DEFS := []MissionDef {
	MissionDef {
		name = "Training",
		description = "Follow the navigation arrow to the nearest waypoint.",
		synopsis = "Pickup the cargo box.",
		ship_def = PLAYER_SHIPS_DEFS_ID.PLAYER_SHIP1,
		tasks = []MissionTaskDef {
			MissionTaskDef {
				update_handler = mission_task_touch_asteroid,
				world_display_handler = world_display_waypoint,
				screen_display_handler = screen_navigation_waypoint_display,
				description = "Touch and asteroid",
			},
			MissionTaskDef {
				update_handler = mission_task_shoot_enemy,
				world_display_handler = world_display_waypoint,
				screen_display_handler = screen_navigation_waypoint_display,
				description = "Destroy and enemy ship",
			},
			MissionTaskDef {
				update_handler = mission_pickup_cargo,
				description = "Pickup a cargo box.",
			},
			MissionTaskDef {
				update_handler = mission_use_cargo,
				description = "Use the item in the cargo box.",
			},
			MissionTaskDef {
				update_handler = mission_return_to_base,
				description = "Return to base.",
			},
		},
	},
	// MissionDef {
	// 	name = "Mission 1",
	// 	description = "The milkrun. Recover the cargo and return to base.",
	// 	synopsis = "Some scavengers blasted a hole in a cargo ship. The decompression explosion caused the to crates scatter into space a fair way apart as their tracking beacons show. Having those back would make you a number of frinds on the base, so go and get it.",
	// 	ship_def = PLAYER_SHIPS_DEFS_ID.PLAYER_SHIP1,
	// 	tasks = []MissionTaskDef{
	// 		Waypoint {
	// 			pos = {2500, 1500},
	// 			description = "Naviate and pickup cargo.",
	// 		},
	// 		Waypoint {
	// 			pos = {4800, 5000},
	// 			description = "Proceed to next waypoint, get ready for trouble.",
	// 		},
	// 		Waypoint {
	// 			pos = {5700, -2000},
	// 			description = "Get the last cargo.",
	// 		},
	// 		Waypoint {
	// 			pos = {0.1, 0.1},
	// 			description = "Return to base.",
	// 		},
	// 	},
	// },
	// MissionDef {
	// 	name = "Mission 2",
	// 	description = "A diamond in the rough. Grapple and return with valuable mineral laden asteroid.",
	// 	synopsis = "A large asteroid has been found with a high concentration of valuable minerals. It is too large to move, but you can grapple it and tow it back to base.  Be careful, it is very heavy and will slow you down, and towing an asteroid might call attention to you from the scavengers, so be careful.",
	// 	ship_def = PLAYER_SHIPS_DEFS_ID.PLAYER_SHIP1,
	// 	tasks = []MissionTaskDef{
	// 		Waypoint {
	// 			pos = {2500, 1500},
	// 			description = "This asteroid is valuable.",
	// 		},
	// 		Waypoint {
	// 			pos = {4800, 5000},
	// 			description = "Grab the sparkly one.",
	// 		},
	// 		Waypoint {
	// 			pos = {5700, -2000},
	// 			description = "Last one.",
	// 		},
	// 		Waypoint {
	// 			pos = {0.1, 0.1},
	// 			description = "Return to base.",
	// 		},
	// 	},
	// },
}


mi_task_inited := false

mission_init :: proc() {
	flux := ease.flux_init(f32)
	mi_task_inited := true
}

mission_task_clear :: proc() {
	mi_task_inited = false
}

world_display_waypoint :: proc() {
	using raylib
	DrawCircleV(
		game.waypoint * RE_SCALE,
		1 * RE_SCALE,
		Fade(ORANGE, rand.float32_range(0.25, 0.45)),
	)
}


tint: f32 = 0

screen_navigation_waypoint_display :: proc() {
	using raylib

	NAV_LOCATION_POS := linalg.Vector2f32{10, f32(GetScreenHeight()-30)}
	NAV_LOCATION_SIZE :f32= 17

	if game.showing_waypoint_nav {
		//point the player towards the next waypoint
		playerpos := get_player_pos()

		waypoint_bearing := math.atan2_f32(
			game.waypoint.x - playerpos.x,
			game.waypoint.y - playerpos.y,
		)

		center := raylib.Vector2{f32(GetScreenWidth()/2), f32(GetScreenHeight()/2)}
		offset := linalg.Vector2f32{f32(textures[TEXTURES_ID.ARROW_UP_WHITE].width / 2), f32(textures[TEXTURES_ID.ARROW_UP_WHITE].height / 2)+100}

		// x := ease.flux_to(&flux, &tint, 1.0, .Sine_In_Out, time.Second, 0)
		// ease.flux_update(&flux, f64(game.current_time - game.previous_time));

		draw_texture_scale_rot_offset_scale(
			&textures[TEXTURES_ID.ARROW_UP_WHITE],
			center,
			waypoint_bearing,
			offset,
			Fade(WHITE, 0.75*math.sin(f32(game.current_time)*3)),
			1.5,
		)
		//location display
		if game.showing_display_panel || game.show_display_panel_forced_time > game.current_time {
		} else {
			DrawTextEx(default_font, TextFormat("%.2f", get_player_pos()), NAV_LOCATION_POS, NAV_LOCATION_SIZE, 1, RED)
		}

	} else {
		if game.showing_display_panel || game.show_display_panel_forced_time > game.current_time {
		} else {
			DrawTextEx(
				default_font,
				"[NAVIGATION OFFLINE]",
				NAV_LOCATION_POS,
				NAV_LOCATION_SIZE,
				1,
				RED,
			)
		}
	}
}

// Touch and asteroid
mission_task_touch_asteroid :: proc() -> bool {
	// find the closest asteroid
	if !mi_task_inited {
		mi_task_inited = true
		game.waypoint = get_player_pos() + raylib.Vector2{30, 0}
		// pos := get_player_pos()
		// for a in game.asteroids {
		// 	apos := b2.body_get_position(a.body_id)
		// 	if linalg.length(mpos - apos) < linalg.length(mpos - a.target) {
		// 		a.target = apos
		// 	}
		// }
	}
	if distance_to_player(game.waypoint) < 1 {
		return true
	}
	return false
}

// Destroy and enemy ship
mission_task_shoot_enemy :: proc() -> bool {
	// find the closest enemy
	if !mi_task_inited {
		mi_task_inited = true
		game.waypoint = get_player_pos() - raylib.Vector2{10, 10}
	}
	// pos := get_player_pos()
	// for e in game.enemies {
	// 	epos := b2.body_get_position(e.body_id)
	// 	if linalg.length(mpos - epos) < linalg.length(mpos - e.target) {
	// 		e.target = epos
	// 	}
	// }
	if distance_to_player(game.waypoint) < 1 {
		return true
	}
	return false
}

// Get the a cargo box
mission_pickup_cargo :: proc() -> bool {
	if len(game.player.cargo) > 0 {
		return true
	}
	return false
}

// Use the item in the cargo box.
mission_use_cargo :: proc() -> bool {
	return false
}

// Return to base.
mission_return_to_base :: proc() -> bool {
	return false
}

draw_mission_popup_panel :: proc() {
	using raylib
	DrawRectangle(
		0,
		raylib.GetScreenHeight() - 200,
		raylib.GetScreenWidth(),
		200,
		Fade(WHITE, 0.5),
	)
	DrawTextEx(
		default_font,
		MISSIONS_DEFS[game.mission].name,
		Vector2{10.0, f32(raylib.GetScreenHeight() - 150)},
		24,
		1,
		WHITE,
	)
	DrawTextEx(
		default_font,
		MISSIONS_DEFS[game.mission].description,
		Vector2{10.0, f32(raylib.GetScreenHeight() - 120)},
		20,
		1,
		WHITE,
	)
	last_msg: cstring
	if game.is_mission_complete {
		last_msg = "MISSION COMPLETE"
	} else if game.is_mission_failed {
		last_msg = "MISSION FAILED"
	} else {
		last_msg = MISSIONS_DEFS[game.mission].tasks[game.mission_task_index].description
	}
	DrawTextEx(
		default_font,
		last_msg,
		Vector2{10.0, f32(raylib.GetScreenHeight() - 90)},
		30,
		1,
		RED,
	)
	user_input_close_panel_txt :cstring= "[TAB]"
	DrawTextEx(
		default_font,
		user_input_close_panel_txt,
		Vector2{f32(raylib.GetScreenWidth() - 60), f32(raylib.GetScreenHeight() - 190)},
		22,
		1,
		RED,
	)
}
