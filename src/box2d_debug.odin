package main

/////////////WASM
// import b2 "box2dw"
// import "raylib"
/////////////NOT WASM
import b2 "box2d"
import "vendor:raylib"

import "core:math/linalg"

when !IS_WASM {
	debug_panel :: proc() {
		using raylib
		dpos := Vector2{f32(raylib.GetScreenWidth() - 60), f32(raylib.GetScreenHeight() - 525)}
		dbox := Vector2{50, 15}
		dpos_index: f32 = 20
		debug_b2_world_stats := b2.world_get_counters(game.world_id)

		GuiCheckBox(Rectangle{dpos.x - 100, dpos.y, dbox.x, dbox.y}, "draw_shapes", &draw_shapes)
		dpos.y += dpos_index
		GuiCheckBox(Rectangle{dpos.x - 100, dpos.y, dbox.x, dbox.y}, "draw_aabbs", &draw_aabbs)
		dpos.y += dpos_index
		GuiCheckBox(Rectangle{dpos.x - 100, dpos.y, dbox.x, dbox.y}, "draw_mass", &draw_mass)
		dpos.y += dpos_index

		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "body_count ",
				   &debug_b2_world_stats.body_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index
		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "byte_count ",
				   &debug_b2_world_stats.byte_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index

		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "stack_capacity ",
				   &debug_b2_world_stats.stack_capacity,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index

		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "stack_used ",
				   &debug_b2_world_stats.stack_used,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index

		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "contact_count ",
				   &debug_b2_world_stats.contact_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index

		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "island_count ",
				   &debug_b2_world_stats.island_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index

		asteroid_count := i32(len(game.asteroids))
		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "asteroid count ",
				   &asteroid_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index

		space_objects_count := i32(len(game.space_objects))
		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "space_object count ",
				   &space_objects_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index

		enemy_count := i32(len(game.enemies))
		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "enemy count ",
				   &enemy_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index

		bullets_count: i32 = i32(len(game.bullets))
		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "bullets count ",
				   &bullets_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index

		missles_count := i32(len(game.missles))
		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "missles count ",
				   &missles_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}
		dpos.y += dpos_index

		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "asteroid vbo count ",
				   &asteroid_draw_index,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}

		dpos.y += dpos_index

		arena_peak_used: i32 = i32(arena.peak_used)
		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "arena peak used ",
				   &arena_peak_used,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}

		dpos.y += dpos_index

		arena_temp_count: i32 = i32(arena.temp_count)
		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "arena temp_count ",
				   &arena_temp_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}

		dpos.y += dpos_index

		cpu_particles_count: i32 = i32(len(game.cpu_particles))
		if (GuiValueBox(
				   Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
				   "cpu_particles_count ",
				   &cpu_particles_count,
				   0,
				   100,
				   ValueBOx001EditMode,
			   ) >
			   0) {ValueBOx001EditMode = !ValueBOx001EditMode}

		dpos.y += dpos_index
		DrawTextEx(
			default_font,
			TextFormat("camera ", game.camera.target),
			Vector2{dpos.x - 430, dpos.y},
			20,
			1,
			WHITE,
		)
		dpos.y += dpos_index
		DrawTextEx(
			default_font,
			TextFormat("offset ", game.camera.offset),
			Vector2{dpos.x - 430, dpos.y},
			20,
			1,
			WHITE,
		)
		dpos.y += dpos_index
		DrawTextEx(
			default_font,
			TextFormat("zoom %f", game.camera.zoom),
			Vector2{dpos.x - 430, dpos.y},
			20,
			1,
			WHITE,
		)
		// dpos.y += dpos_index
		// DrawTextEx(
		// 	default_font,
		// 	TextFormat("aabb ", &lower_bound, " ", &upper_bound),
		// 	Vector2{dpos.x - 430, dpos.y},
		// 	20,
		// 	1,
		// 	WHITE,
		// )

	}

	ValueBOx001EditMode: bool
	debug_b2_world_stats: b2.Counters

	// Draw a closed polygon provided in CCW order.
	draw_polygon :: proc "cdecl" (
		vertices: [^]linalg.Vector2f32,
		vertex_count: i32,
		color: b2.Color,
		context_: rawptr,
	) {
		using raylib
		for i in 0 ..< vertex_count {
			DrawLineV(vertices[i] * RE_SCALE, vertices[(i + 1) % vertex_count] * RE_SCALE, RED)
		}
	}

	// Draw a solid closed polygon provided in CCW order.
	draw_solid_polygon :: proc "cdecl" (
		vertices: [^]linalg.Vector2f32,
		vertex_count: i32,
		color: b2.Color,
		context_: rawptr,
	) {
		using raylib
		for i in 0 ..< vertex_count {
			DrawLineV(vertices[i] * RE_SCALE, vertices[(i + 1) % vertex_count] * RE_SCALE, RED)
		}
	}

	// Draw a rounded polygon provided in CCW order.
	draw_rounded_polygon :: proc "cdecl" (
		vertices: [^]linalg.Vector2f32,
		vertex_count: i32,
		radius: f32,
		line_color, fill_color: b2.Color,
		context_: rawptr,
	) {

	}

	// Draw a circle.
	draw_circle :: proc "cdecl" (
		center: linalg.Vector2f32,
		radius: f32,
		color: b2.Color,
		context_: rawptr,
	) {
		using raylib
		DrawCircleV(center * RE_SCALE, radius * 2, Fade(WHITE, 0.5))
	}

	// Draw a solid circle.
	draw_solid_circle :: proc "cdecl" (
		center: linalg.Vector2f32,
		radius: f32,
		axis: linalg.Vector2f32,
		color: b2.Color,
		context_: rawptr,
	) {
		using raylib
		DrawCircleV(center * RE_SCALE, radius * RE_SCALE, Fade(WHITE, 0.5))
	}

	// Draw a capsule.
	draw_capsule :: proc "cdecl" (
		p1, p2: linalg.Vector2f32,
		radius: f32,
		color: b2.Color,
		context_: rawptr,
	) {
		// using raylib
		// DrawLineV(p1, p2, RED)
	}

	// Draw a solid capsule.
	draw_solid_capsule :: proc "cdecl" (
		p1, p2: linalg.Vector2f32,
		radius: f32,
		color: b2.Color,
		context_: rawptr,
	) {
		using raylib
		DrawCircleV(p1 * RE_SCALE, radius * RE_SCALE, Fade(BLUE, 0.7))
		DrawCircleV(p1 * RE_SCALE, radius * RE_SCALE, Fade(RED, 0.7))
	}

	// Draw a line segment.
	draw_segment :: proc "cdecl" (p1, p2: linalg.Vector2f32, color: b2.Color, context_: rawptr) {
		using raylib
		DrawLineV(p1 * RE_SCALE, p2 * RE_SCALE, ORANGE)
	}

	// Draw a transform. Choose your own length scale.
	// @param xf a transform.
	draw_transform :: proc "cdecl" (xf: b2.Transform, context_: rawptr) {
		using raylib
		// DrawLineV(xf.p, xf.p + xf.q.c, RED)
		// DrawLineV(xf.p, xf.p + xf.q.b, GREEN)
	}

	// Draw a point.
	draw_point :: proc "cdecl" (
		p: linalg.Vector2f32,
		size: f32,
		color: b2.Color,
		context_: rawptr,
	) {
		using raylib
		DrawCircleV(p * RE_SCALE, size, Fade(RED, 0.7))
	}

	// Draw a string.
	draw_string :: proc "cdecl" (p: linalg.Vector2f32, s: cstring, context_: rawptr) {
		using raylib
		TraceLog(.WARNING, s)
		DrawTextEx(default_font, s, p * RE_SCALE, 10, 1, WHITE)
	}
}
