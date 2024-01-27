package main

/////////////WASM
// import "raylib"
////import b2 "box2dw"
/////////////NOT WASM
////import b2 "box2d"
import "vendor:raylib"

DEFAULT_MOVE_LEFT :: raylib.KeyboardKey.LEFT
DEFAULT_MOVE_RIGHT :: raylib.KeyboardKey.RIGHT
DEFAULT_MOVE_UP :: raylib.KeyboardKey.UP
DEFAULT_MOVE_DOWN :: raylib.KeyboardKey.DOWN

DEFAULT_MOVE_LEFT_ALT :: raylib.KeyboardKey.A
DEFAULT_MOVE_RIGHT_ALT :: raylib.KeyboardKey.D
DEFAULT_MOVE_UP_ALT :: raylib.KeyboardKey.W
DEFAULT_MOVE_DOWN_ALT :: raylib.KeyboardKey.S

DEFAULT_BOOST :: raylib.KeyboardKey.LEFT_SHIFT

DEFAULT_PRIMARY_FIRE :: raylib.KeyboardKey.LEFT_CONTROL
DEFAULT_SECONDARY_FIRE :: raylib.KeyboardKey.Z

DEFAULT_TOGGLE_PAUSE :: raylib.KeyboardKey.P
DEFAULT_TOGGLE_DEBUG :: raylib.KeyboardKey.GRAVE

DEFAULT_MENU_CONTINUE :: raylib.KeyboardKey.SPACE
DEFAULT_MENU_CONTINUE_ALT :: raylib.KeyboardKey.ENTER

DEFAULT_TOGGLE_MUSIC :: raylib.KeyboardKey.M
DEFAULT_DISPLAY_PANEL :: raylib.KeyboardKey.TAB
DEFAULT_WAYPOINT_NAV :: raylib.KeyboardKey.N
DEFAULT_EXIT :: raylib.KeyboardKey.ESCAPE

DEFAULT_USE_ITEM1 :: raylib.KeyboardKey.ONE
DEFAULT_USE_ITEM2 :: raylib.KeyboardKey.TWO
DEFAULT_USE_ITEM3 :: raylib.KeyboardKey.THREE
DEFAULT_USE_ITEM4 :: raylib.KeyboardKey.FOUR

Input_Mapping_Keyboard :: struct {
	toggle_pause:      raylib.KeyboardKey,
	toggle_music:      raylib.KeyboardKey,
	toggle_debug:      raylib.KeyboardKey,
	move_right:        raylib.KeyboardKey,
	move_left:         raylib.KeyboardKey,
	move_up:           raylib.KeyboardKey,
	move_down:         raylib.KeyboardKey,
	move_right_alt:    raylib.KeyboardKey,
	move_left_alt:     raylib.KeyboardKey,
	move_up_alt:       raylib.KeyboardKey,
	move_down_alt:     raylib.KeyboardKey,
	primary_fire:      raylib.KeyboardKey,
	secondary_fire:    raylib.KeyboardKey,
	boost:             raylib.KeyboardKey,
	menu_continue:     raylib.KeyboardKey,
	menu_continue_alt: raylib.KeyboardKey,
	display_panel:     raylib.KeyboardKey,
	waypoint_nav:      raylib.KeyboardKey,
	exit:              raylib.KeyboardKey,
	use_item1:         raylib.KeyboardKey,
	use_item2:         raylib.KeyboardKey,
	use_item3:         raylib.KeyboardKey,
	use_item4:         raylib.KeyboardKey,
}

Input_Processed :: struct {
	m_wheel:             f32,
	ms_pos:              raylib.Vector2,
	mw_pos:              raylib.Vector2,
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
	using raylib

	key_cooldown -= GetFrameTime()
	if key_cooldown < 0 {
		key_cooldown = 0
	}

	if gamepad_enabled {
		if IsGamepadButtonDown(gamepad_num, .LEFT_TRIGGER_1) {
			input_processed^.primary_fire = true
		}
		if IsGamepadButtonDown(gamepad_num, .RIGHT_TRIGGER_1) {
			input_processed^.secondary_fire = true
		}
		if IsGamepadButtonDown(gamepad_num, .RIGHT_FACE_DOWN) {
			input_processed^.menu_continue = true
		}
	}

	if key_cooldown == 0 {
		input_processed^ = Input_Processed {
			m_wheel             = GetMouseWheelMove(),
			ms_pos              = GetMousePosition(), // In world space (camera mode)
			mw_pos              = GetScreenToWorld2D(GetMousePosition(), game.camera), // In screen space (camera mode)
			left_mouse_clicked  = IsMouseButtonDown(.LEFT),
			right_mouse_clicked = IsMouseButtonDown(.RIGHT),
			move_left           = IsKeyDown(input_mapping.move_left) || raylib.IsKeyDown(input_mapping.move_left_alt),
			move_right          = IsKeyDown(input_mapping.move_right) || raylib.IsKeyDown(input_mapping.move_right_alt),
			move_up             = IsKeyDown(input_mapping.move_up) || raylib.IsKeyDown(input_mapping.move_up_alt),
			move_down           = IsKeyDown(input_mapping.move_down) || raylib.IsKeyDown(input_mapping.move_down_alt),
			boost               = IsKeyDown(input_mapping.boost),
			primary_fire        = IsMouseButtonDown(.LEFT) || raylib.IsKeyDown(input_mapping.primary_fire),
			secondary_fire      = IsMouseButtonDown(.RIGHT) || raylib.IsKeyPressed(input_mapping.secondary_fire),
			toggle_pause        = IsKeyPressed(input_mapping.toggle_pause),
			toggle_debug        = IsKeyPressed(input_mapping.toggle_debug),
			menu_continue       = IsKeyPressed(input_mapping.menu_continue) || IsKeyPressed(input_mapping.menu_continue_alt),
			toggle_music        = IsKeyPressed(input_mapping.toggle_music),
			display_panel       = IsKeyPressed(input_mapping.display_panel),
			waypoint_nav        = IsKeyPressed(input_mapping.waypoint_nav),
			exit                = IsKeyPressed(input_mapping.exit),
			use_item1           = IsKeyPressed(input_mapping.use_item1),
			use_item2           = IsKeyPressed(input_mapping.use_item2),
			use_item3           = IsKeyPressed(input_mapping.use_item3),
			use_item4           = IsKeyPressed(input_mapping.use_item4),
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
