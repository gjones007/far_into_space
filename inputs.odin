package main

import rl "vendor:raylib"

DEFAULT_MOVE_LEFT :: rl.KeyboardKey.LEFT
DEFAULT_MOVE_RIGHT :: rl.KeyboardKey.RIGHT
DEFAULT_MOVE_UP :: rl.KeyboardKey.UP
DEFAULT_MOVE_DOWN :: rl.KeyboardKey.DOWN

DEFAULT_MOVE_LEFT_ALT :: rl.KeyboardKey.A
DEFAULT_MOVE_RIGHT_ALT :: rl.KeyboardKey.D
DEFAULT_MOVE_UP_ALT :: rl.KeyboardKey.W
DEFAULT_MOVE_DOWN_ALT :: rl.KeyboardKey.S

DEFAULT_BOOST :: rl.KeyboardKey.LEFT_SHIFT

DEFAULT_PRIMARY_FIRE :: rl.KeyboardKey.LEFT_CONTROL
DEFAULT_SECONDARY_FIRE :: rl.KeyboardKey.Z

DEFAULT_TOGGLE_PAUSE :: rl.KeyboardKey.P
DEFAULT_TOGGLE_DEBUG :: rl.KeyboardKey.GRAVE

DEFAULT_MENU_CONTINUE :: rl.KeyboardKey.SPACE
DEFAULT_MENU_CONTINUE_ALT :: rl.KeyboardKey.ENTER

DEFAULT_TOGGLE_MUSIC :: rl.KeyboardKey.M
DEFAULT_DISPLAY_PANEL :: rl.KeyboardKey.TAB
DEFAULT_WAYPOINT_NAV :: rl.KeyboardKey.N
DEFAULT_EXIT :: rl.KeyboardKey.ESCAPE

DEFAULT_USE_ITEM1 :: rl.KeyboardKey.ONE
DEFAULT_USE_ITEM2 :: rl.KeyboardKey.TWO
DEFAULT_USE_ITEM3 :: rl.KeyboardKey.THREE
DEFAULT_USE_ITEM4 :: rl.KeyboardKey.FOUR

Input_Mapping_Keyboard :: struct {
	toggle_pause:      rl.KeyboardKey,
	toggle_music:      rl.KeyboardKey,
	toggle_debug:      rl.KeyboardKey,
	move_right:        rl.KeyboardKey,
	move_left:         rl.KeyboardKey,
	move_up:           rl.KeyboardKey,
	move_down:         rl.KeyboardKey,
	move_right_alt:    rl.KeyboardKey,
	move_left_alt:     rl.KeyboardKey,
	move_up_alt:       rl.KeyboardKey,
	move_down_alt:     rl.KeyboardKey,
	primary_fire:      rl.KeyboardKey,
	secondary_fire:    rl.KeyboardKey,
	boost:             rl.KeyboardKey,
	menu_continue:     rl.KeyboardKey,
	menu_continue_alt: rl.KeyboardKey,
	display_panel:     rl.KeyboardKey,
	waypoint_nav:      rl.KeyboardKey,
	exit:              rl.KeyboardKey,
	use_item1:         rl.KeyboardKey,
	use_item2:         rl.KeyboardKey,
	use_item3:         rl.KeyboardKey,
	use_item4:         rl.KeyboardKey,
}

Input_Processed :: struct {
	m_wheel:             f32,
	ms_pos:              rl.Vector2,
	mw_pos:              rl.Vector2,
	left_mouse_clicked:  bool,
	right_mouse_clicked: bool,
	toggle_pause:        bool,
	toggle_music:        bool,
	toggle_debug:        bool,
	move_right:          bool,
	move_left:           bool,
	move_up:             bool,
	move_down:           bool,
	primary_fire:        bool,
	secondary_fire:      bool,
	boost:               bool,
	menu_continue:       bool,
	display_panel:       bool,
	waypoint_nav:        bool,
	exit:                bool,
	use_item1:           bool,
	use_item2:           bool,
	use_item3:           bool,
	use_item4:           bool,
}

input_processed: Input_Processed

input_mapping := Input_Mapping_Keyboard {
	toggle_pause      = DEFAULT_TOGGLE_PAUSE,
	toggle_music      = DEFAULT_TOGGLE_MUSIC,
	toggle_debug      = DEFAULT_TOGGLE_DEBUG,
	move_right        = DEFAULT_MOVE_RIGHT,
	move_left         = DEFAULT_MOVE_LEFT,
	move_up           = DEFAULT_MOVE_UP,
	move_down         = DEFAULT_MOVE_DOWN,
	move_right_alt    = DEFAULT_MOVE_RIGHT_ALT,
	move_left_alt     = DEFAULT_MOVE_LEFT_ALT,
	move_up_alt       = DEFAULT_MOVE_UP_ALT,
	move_down_alt     = DEFAULT_MOVE_DOWN_ALT,
	primary_fire      = DEFAULT_PRIMARY_FIRE,
	secondary_fire    = DEFAULT_SECONDARY_FIRE,
	boost             = DEFAULT_BOOST,
	menu_continue     = DEFAULT_MENU_CONTINUE,
	menu_continue_alt = DEFAULT_MENU_CONTINUE_ALT,
	display_panel     = DEFAULT_DISPLAY_PANEL,
	waypoint_nav      = DEFAULT_WAYPOINT_NAV,
	exit              = DEFAULT_EXIT,
	use_item1         = DEFAULT_USE_ITEM1,
	use_item2         = DEFAULT_USE_ITEM2,
	use_item3         = DEFAULT_USE_ITEM3,
	use_item4         = DEFAULT_USE_ITEM4,
}

process_user_input :: proc(input_processed: ^Input_Processed) {
	key_cooldown -= rl.GetFrameTime()
	if key_cooldown < 0 {
		key_cooldown = 0
	}

	if gamepad_enabled {
		if rl.IsGamepadButtonDown(gamepad_num, .LEFT_TRIGGER_1) {
			input_processed^.primary_fire = true
		}
		if rl.IsGamepadButtonDown(gamepad_num, .RIGHT_TRIGGER_1) {
			input_processed^.secondary_fire = true
		}
		if rl.IsGamepadButtonDown(gamepad_num, .RIGHT_FACE_DOWN) {
			input_processed^.menu_continue = true
		}
	}

	if key_cooldown == 0 {
		input_processed^ = Input_Processed {
			m_wheel             = rl.GetMouseWheelMove(),
			ms_pos              = rl.GetMousePosition(), // In world space (camera mode)
			mw_pos              = rl.GetScreenToWorld2D(rl.GetMousePosition(), game.camera), // In screen space (camera mode)
			left_mouse_clicked  = rl.IsMouseButtonDown(.LEFT),
			right_mouse_clicked = rl.IsMouseButtonDown(.RIGHT),
			move_left           = rl.IsKeyDown(input_mapping.move_left) || rl.IsKeyDown(input_mapping.move_left_alt),
			move_right          = rl.IsKeyDown(input_mapping.move_right) || rl.IsKeyDown(input_mapping.move_right_alt),
			move_up             = rl.IsKeyDown(input_mapping.move_up) || rl.IsKeyDown(input_mapping.move_up_alt),
			move_down           = rl.IsKeyDown(input_mapping.move_down) || rl.IsKeyDown(input_mapping.move_down_alt),
			boost               = rl.IsKeyDown(input_mapping.boost),
			primary_fire        = rl.IsMouseButtonDown(.LEFT) || rl.IsKeyDown(input_mapping.primary_fire),
			secondary_fire      = rl.IsMouseButtonDown(.RIGHT) || rl.IsKeyPressed(input_mapping.secondary_fire),
			toggle_pause        = rl.IsKeyPressed(input_mapping.toggle_pause),
			toggle_debug        = rl.IsKeyPressed(input_mapping.toggle_debug),
			menu_continue       = rl.IsKeyPressed(input_mapping.menu_continue) || rl.IsKeyPressed(input_mapping.menu_continue_alt),
			toggle_music        = rl.IsKeyPressed(input_mapping.toggle_music),
			display_panel       = rl.IsKeyPressed(input_mapping.display_panel),
			waypoint_nav        = rl.IsKeyPressed(input_mapping.waypoint_nav),
			exit                = rl.IsKeyPressed(input_mapping.exit),
			use_item1           = rl.IsKeyPressed(input_mapping.use_item1),
			use_item2           = rl.IsKeyPressed(input_mapping.use_item2),
			use_item3           = rl.IsKeyPressed(input_mapping.use_item3),
			use_item4           = rl.IsKeyPressed(input_mapping.use_item4),
		}
	} else {
		input_processed^ = Input_Processed {
			left_mouse_clicked  = false,
			right_mouse_clicked = false,
			move_left           = false,
			move_right          = false,
			move_up             = false,
			move_down           = false,
			boost               = false,
			primary_fire        = false,
			secondary_fire      = false,
			toggle_pause        = false,
			toggle_debug        = false,
			menu_continue       = false,
			toggle_music        = false,
			display_panel       = false,
			waypoint_nav        = false,
			exit                = false,
			use_item1           = false,
			use_item2           = false,
			use_item3           = false,
			use_item4           = false,
		}
	}
}
