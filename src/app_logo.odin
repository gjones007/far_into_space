package main

import "core:fmt"
import "core:math"
import "core:strings"

/////////////WASM
// import "raylib"
// import b2 "box2dw"
/////////////NOT WASM
import b2 "box2d"
import "vendor:raylib"

import "core:time"

selected_player_ship := 0
key_cooldown: f32 = 0.0

SLIDER_WIDTH := 10
SLIDER_PADDING := 10
BORDER_WIDTH := 10
KEY_COOLDOWN :: 0.25

// MAIN_MENU := []cstring{"Campaign", "Arcade", "Options", "Quit"}
MAIN_MENU := []cstring{"Arcade", "Options", "Quit"}
// OOF
MAIN_MENU_R := []cstring{"Resume Game", MAIN_MENU[0], MAIN_MENU[1], MAIN_MENU[2]}
MAIN_MENU_ID :: enum {
	RESUME_GAME,
	// NEW_CAMPAIN,
	ARCADE,
	OPTIONS,
	QUIT,
}


ARCADE_MENU := []cstring{"Reaper", "Nova", "Dark Star", "Back to main menu"}
ARCADE_MENU_ID :: enum {
	SHIP1,
	SHIP2,
	SHIP3,
	BACK,
}

OPTIONS_MENU := []cstring{"Music", "Background Shader", "Back to main menu"}
OPTIONS_MENU_ID :: enum {
	TOGGLE_MUSIC,
	TOGGLE_SHADER,
	BACK,
}

RESTART_MENU := []cstring{"Restart", "Back to main menu"}
RESTART_MENU_ID :: enum {
	RESTART,
	BACK,
}

Ui :: struct {
	items:                ^[]cstring,
	opacity:              f32,
	font_size:            f32,
	font_spacing:         f32,
	scale_factor:         f32,
	width:                f32,
	height:               f32,
	pos_x:                f32,
	pos_y:                f32,
	pad_left:             f32,
	pad_top:              f32,
	pad_slot_factor:      f32,
	column_count:         int,
	row_count:            int,
	slot_size_x:          f32,
	slot_size_y:          f32,
	pad_slot_x:           f32,
	pad_slot_y:           f32,
	pad_text:             f32,
	pad_text_slot_size_x: f32,
	pad_text_slot_size_y: f32,
	pad_hover:            f32,
}

UiSlider :: struct {
	width:   f32,
	padding: f32,
}

// this is a box picker for menus
ui_box_selector :: proc(items: ^[]cstring, column_count: int, pad_left: f32, pad_top: f32) -> Ui {
	using raylib

	screen_half_width := GetScreenWidth() / 2
	screen_half_height := GetScreenHeight() / 2

	ui: Ui
	ui.items = items
	ui.opacity = 0.6
	ui.font_size = 60
	ui.font_spacing = 1.50
	ui.scale_factor = 0.70
	ui.width = f32(GetScreenWidth()) * ui.scale_factor
	ui.height = f32(GetScreenHeight()) * ui.scale_factor
	ui.pos_x = f32(screen_half_width) - ui.width / 2.0
	ui.pos_y = f32(screen_half_height) - ui.height / 2.0
	ui.pad_left = pad_left
	ui.pad_top = pad_top
	ui.pad_slot_factor = 0.1
	ui.column_count = column_count
	ui.row_count = ((len(ui.items) + (ui.column_count - 1)) / ui.column_count)
	ui.slot_size_x = ((ui.width - ui.pad_left * 2) / f32(ui.column_count))
	ui.slot_size_y = ((ui.height - ui.pad_left * 2) / f32(ui.row_count))
	ui.pad_slot_x = (ui.slot_size_x * ui.pad_slot_factor)
	ui.pad_slot_y = (ui.slot_size_y * ui.pad_slot_factor)
	ui.column_count = column_count
	ui.pad_text = 10
	ui.pad_text_slot_size_x = 15
	ui.pad_text_slot_size_y = 5
	ui.pad_hover = 5

	return ui
}

slot_selected := -1
prev_slot_selected := -1
menu_selected := -2
ui_loop :: proc(ui: ^Ui, start_offset: int = 0) -> int {
	using raylib

	selected_rect_grow := Rectangle {
		-ui.pad_hover,
		-ui.pad_hover,
		ui.pad_hover * 2,
		ui.pad_hover * 2,
	}

	for i in 0 ..< len(ui.items) {
		shift_right := f32(i % ui.column_count)
		shift_down := f32(i / ui.column_count)

		slot_pos := Vector2 {
			ui.pad_left + shift_right * ui.slot_size_x + ui.pos_x,
			ui.pad_top + shift_down * ui.slot_size_y + ui.pos_y,
		}

		slot_rect := Rectangle {
			x      = slot_pos.x + ui.pad_slot_x / 2,
			y      = slot_pos.y + ui.pad_slot_y / 2,
			width  = ui.slot_size_x - ui.pad_slot_x,
			height = ui.slot_size_y - ui.pad_slot_y,
		}

		// support mouse
		if CheckCollisionPointRec(GetMousePosition(), slot_rect) || slot_selected == i {
			slot_selected = i
			if prev_slot_selected != i {
				PlaySound(sfxs[int(SFX_ID.MENU_BLIP)])
				prev_slot_selected = i
			}
			DrawRectangleRounded(
				raylib.Rectangle {
					f32(slot_rect.x - ui.pad_hover),
					f32(slot_rect.y - ui.pad_hover),
					f32(slot_rect.width + ui.pad_hover * 2),
					f32(slot_rect.height + ui.pad_hover * 2),
				},
				0.1,
				0,
				WHITE,
			)
			if key_cooldown == 0 && (input_processed.primary_fire || input_processed.menu_continue) {
				menu_selected = i
				key_cooldown = KEY_COOLDOWN
			}
		} else {
			DrawRectangleRounded(slot_rect, 0.1, 0, Fade(WHITE, ui.opacity))
		}

		// support touch
		if key_cooldown == 0 && GetTouchPointCount() > 0 {
			tpc := GetTouchPointCount()
			for t in 0 ..= tpc {
				if CheckCollisionPointRec(Vector2{f32(GetTouchX()), f32(GetTouchY())}, slot_rect) {
					key_cooldown = KEY_COOLDOWN
					menu_selected = i
				}
			}
		}

		// support keyboard
		if slot_selected == -1 {
			if input_processed.move_down && key_cooldown == 0 {
				slot_selected = 0
				key_cooldown = KEY_COOLDOWN
			}
			if input_processed.move_up && key_cooldown == 0 {
				slot_selected = len(ui.items) - 1
				key_cooldown = KEY_COOLDOWN
			}
		} else {
			if input_processed.move_up && key_cooldown == 0 && slot_selected > 0 {
				slot_selected -= 1
				key_cooldown = KEY_COOLDOWN
			}
			if input_processed.move_down && key_cooldown == 0 && slot_selected < len(ui.items) - 1 {
				slot_selected += 1
				key_cooldown = KEY_COOLDOWN
			}
		}

		txt := ui.items[i]
		measure_text_size := MeasureTextEx(default_font, txt, ui.font_size, ui.font_spacing)
		text_pos := Vector2 {
			math.floor(f32(slot_pos.x - 0.5 * measure_text_size.x)),
			math.floor(f32(slot_pos.y - 0.5 * measure_text_size.y)),
		}
		text_pos += Vector2{slot_rect.width / 2, slot_rect.height / 2}
		text_pos += Vector2{ui.pad_text_slot_size_x, ui.pad_text_slot_size_y}
		DrawTextEx(default_font, txt, text_pos, ui.font_size, ui.font_spacing, RED)
	}
	return menu_selected + start_offset
}

app_loop_title :: proc(dt: f32) {
	using raylib
	process_user_input(&input_processed)

	if music_enabled {
		if music_id_playing != .MENU {
			StopMusicStream(musics[music_id_playing])
			music_id_playing = .MENU
			PlayMusicStream(musics[music_id_playing])
		}
	}

	text_size: f32 = 100
	measure_text_size := MeasureTextEx(default_font, TITLE_TEXT, text_size, 20)
	pos := Vector2{f32(GetScreenWidth() / 2), f32(GetScreenHeight() / 4)}
	title_text_pos := Vector2 {
		math.floor(f32(pos.x - 0.5 * measure_text_size.x)),
		math.floor(f32(pos.y - 0.5 * measure_text_size.y)),
	}

	menu := &MAIN_MENU
	if game.is_running {
		menu = &MAIN_MENU_R
	}

	if input_processed.exit && game.is_running {
		trans_to_state = APP_STATE.GAMEPLAY
	}

	ui := ui_box_selector(menu, 1, 100, 200)

	new_app_state := app_current_state

	BeginDrawing()
	ClearBackground(BLACK)
	liTime := GetShaderLocation(shaders[int(SHADERS_ID.GALAXYTRIP)], "iTime")
	SetShaderValue(
		shaders[int(SHADERS_ID.GALAXYTRIP)],
		raylib.ShaderLocationIndex(liTime),
		&shader_iTime,
		raylib.ShaderUniformDataType(SHADER_UNIFORM_FLOAT),
	)
	BeginShaderMode(shaders[int(SHADERS_ID.GALAXYTRIP)])
	DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), BLACK)
	EndShaderMode()

	DrawTextEx(default_font, TITLE_TEXT, title_text_pos, text_size, 20, WHITE)
	switch ui_loop(&ui, game.is_running ? 0 : 1) {
	case int(MAIN_MENU_ID.RESUME_GAME):
		{
			trans_to_state = APP_STATE.GAMEPLAY
		}
	// case int(MAIN_MENU_ID.NEW_CAMPAIN):
	// 	{
	// 		init_player(PLAYER_SHIPS_DEFS[int(selected_player_ship)])
	// 		init_campain()
	// 		trans_to_state = APP_STATE.GAMEPLAY
	// 	}
	case int(MAIN_MENU_ID.ARCADE):
		{
			trans_to_state = APP_STATE.ARCADE_SELECT
		}
	case int(MAIN_MENU_ID.OPTIONS):
		{
			trans_to_state = APP_STATE.OPTIONS
		}
	case int(MAIN_MENU_ID.QUIT):
		{
			trans_to_state = APP_STATE.QUIT
		}
	}
	EndDrawing()
}

app_loop_arcade_select :: proc(dt: f32) {
	using raylib
	process_user_input(&input_processed)

	if music_enabled {
		if music_id_playing != .MENU {
			StopMusicStream(musics[music_id_playing])
			music_id_playing = .MENU
			PlayMusicStream(musics[music_id_playing])
		}
	}

	main_text: cstring = "Arcade"
	text_size: f32 = 100
	measure_text_size := MeasureTextEx(default_font, main_text, text_size, 20)
	pos := Vector2{f32(GetScreenWidth() / 2), f32(GetScreenHeight() / 4)}
	title_text_pos := Vector2 {
		math.floor(f32(pos.x - 0.5 * measure_text_size.x)),
		math.floor(f32(pos.y - 0.5 * measure_text_size.y)),
	}
	ui := ui_box_selector(&ARCADE_MENU, 1, 100, 200)

	new_app_state := app_current_state

	BeginDrawing()
	ClearBackground(BLACK)
	liTime := GetShaderLocation(shaders[int(SHADERS_ID.GALAXYTRIP)], "iTime")
	SetShaderValue(
		shaders[int(SHADERS_ID.GALAXYTRIP)],
		raylib.ShaderLocationIndex(liTime),
		&shader_iTime,
		raylib.ShaderUniformDataType(SHADER_UNIFORM_FLOAT),
	)
	BeginShaderMode(shaders[int(SHADERS_ID.GALAXYTRIP)])
	DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), BLACK)
	EndShaderMode()
	DrawTextEx(default_font, main_text, title_text_pos, text_size, 20, WHITE)
	switch ui_loop(&ui) {
	case int(ARCADE_MENU_ID.SHIP1):
		{
			game.player_ship_def = .PLAYER_SHIP1
			init_player()
			init_freeplay()
			trans_to_state = .GAMEPLAY
		}
	case int(ARCADE_MENU_ID.SHIP2):
		{
			game.player_ship_def = .PLAYER_SHIP2
			init_player()
			init_freeplay()
			trans_to_state = .GAMEPLAY
		}
	case int(ARCADE_MENU_ID.SHIP3):
		{
			game.player_ship_def = .PLAYER_SHIP3
			init_player()
			init_freeplay()
			trans_to_state = .GAMEPLAY
		}
	case int(ARCADE_MENU_ID.BACK):
		{
			trans_to_state = .TITLE
		}
	}
	EndDrawing()
}

app_loop_options :: proc(dt: f32) {
	using raylib
	process_user_input(&input_processed)

	if music_enabled {
		if music_id_playing != .MENU {
			StopMusicStream(musics[music_id_playing])
			music_id_playing = .MENU
			PlayMusicStream(musics[music_id_playing])
		}
	}

	main_text: cstring = "Options"
	text_size: f32 = 100
	measure_text_size := MeasureTextEx(default_font, main_text, text_size, 20)
	pos := Vector2{f32(GetScreenWidth() / 2), f32(GetScreenHeight() / 4)}
	title_text_pos := Vector2 {
		math.floor(f32(pos.x - 0.5 * measure_text_size.x)),
		math.floor(f32(pos.y - 0.5 * measure_text_size.y)),
	}
	ui := ui_box_selector(&OPTIONS_MENU, 1, 100, 200)

	new_app_state := app_current_state

	BeginDrawing()
	ClearBackground(BLACK)
	liTime := GetShaderLocation(shaders[int(SHADERS_ID.GALAXYTRIP)], "iTime")
	SetShaderValue(
		shaders[int(SHADERS_ID.GALAXYTRIP)],
		raylib.ShaderLocationIndex(liTime),
		&shader_iTime,
		raylib.ShaderUniformDataType(SHADER_UNIFORM_FLOAT),
	)
	BeginShaderMode(shaders[int(SHADERS_ID.GALAXYTRIP)])
	DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), BLACK)
	EndShaderMode()
	DrawTextEx(default_font, main_text, title_text_pos, text_size, 20, WHITE)
	switch ui_loop(&ui) {
	case int(OPTIONS_MENU_ID.TOGGLE_MUSIC):
		{
			music_enabled = !music_enabled
		}
	case int(OPTIONS_MENU_ID.TOGGLE_SHADER):
		{
			disable_background_shader = !disable_background_shader
		}
	case int(OPTIONS_MENU_ID.BACK):
		{
			trans_to_state = .TITLE
		}
	}
	EndDrawing()
}


seconds_to_duration :: proc(seconds: f64) -> (int, int) {
	minutes := math.floor(seconds / 60)
	seconds := math.floor(seconds - minutes * 60)
	return int(minutes), int(seconds)
	//return fmt.ctprintf("%0d:%02d", int(minutes), int(seconds))
}

// app_loop_instructions :: proc() {
// 	main_text: cstring = "WASD To Move"
// 	main_text: cstring = "Left CTRL To Shoot"
// 	main_text: cstring = "Z To fire secondary weapon, missles and the like"
//  main_text: cstring = "1-4 to use powerups"
// 	main_text: cstring = "Mousewheel to zoom in and out"
// 	main_text: cstring = "Hold Left Shift to boost speed"
// 	main_text: cstring = "Press P to pause"
// 	main_text: cstring = "Press M to stop music"
// }

app_loop_restart :: proc() {
	using raylib
	process_user_input(&input_processed)

	if music_enabled {
		if music_id_playing != .MENU {
			StopMusicStream(musics[music_id_playing])
			music_id_playing = .MENU
			PlayMusicStream(musics[music_id_playing])
		}
	}

	if input_processed.menu_continue {
		app_current_state = APP_STATE.TITLE
	}

	main_text: cstring = "Game Over"
	text_size: f32 = 100
	measure_text_size := MeasureTextEx(default_font, main_text, text_size, 20)

	if game.is_running {
		game.is_running = false
		// stopwatch doesn't work on wasm?
		game.stopwatch_stop = game.current_time
	}

	SCORE_AND_TIME_POS_Y :: 290

	pos := Vector2{f32(GetScreenWidth() / 2), f32(GetScreenHeight() / 4)}
	title_text_pos := Vector2 {
		math.floor(f32(pos.x - 0.5 * measure_text_size.x)),
		math.floor(f32(pos.y - 0.5 * measure_text_size.y)),
	}
	ui := ui_box_selector(&RESTART_MENU, 1, 100, 300)

	new_app_state := app_current_state

	BeginDrawing()
	ClearBackground(BLACK)
	liTime := GetShaderLocation(shaders[int(SHADERS_ID.GALAXYTRIP)], "iTime")
	SetShaderValue(
		shaders[int(SHADERS_ID.GALAXYTRIP)],
		raylib.ShaderLocationIndex(liTime),
		&shader_iTime,
		raylib.ShaderUniformDataType(SHADER_UNIFORM_FLOAT),
	)
	BeginShaderMode(shaders[int(SHADERS_ID.GALAXYTRIP)])
	DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), BLACK)
	EndShaderMode()
	DrawTextEx(default_font, main_text, title_text_pos, text_size, 20, WHITE)
	switch ui_loop(&ui) {
	case int(RESTART_MENU_ID.RESTART):
		{
			game_resources_clear()
			init_player()
			init_freeplay()
			trans_to_state = .GAMEPLAY
		}
	case int(RESTART_MENU_ID.BACK):
		{
			trans_to_state = .TITLE
		}
	}

	time_text := fmt.ctprintf("Time: %0d:%02d", seconds_to_duration(game.stopwatch_stop - game.stopwatch_start))
	center_print(time_text, title_text_pos.y + 120, 30, 1)

	if !game.is_in_mission {
		score_text := fmt.caprintf("Score: %d", game.score)
		center_print(score_text, title_text_pos.y + 150, 30, 1)
	}

	EndDrawing()
}

center_print :: proc (str: cstring, ypos: f32, font_size: f32, font_spacing: f32) {
	using raylib
	measure_text_size := MeasureTextEx(default_font, str, font_size, font_spacing)
	pos := Vector2{f32(GetScreenWidth() / 2), f32(GetScreenHeight() / 2)}
	text_pos := Vector2 {
		math.floor(f32(pos.x - 0.5 * measure_text_size.x)),
		ypos,
	}
	DrawTextEx(default_font, str, text_pos, font_size, font_spacing, WHITE)
}
