package main

import b2 "vendor:box2d"
import rl "vendor:raylib"

import "core:math/linalg"

when !IS_WASM {
    debug_panel :: proc() {
        dpos := rl.Vector2{f32(rl.GetScreenWidth() - 60), f32(rl.GetScreenHeight() - 525)}
        dbox := rl.Vector2{50, 15}
        dpos_index: f32 = 20
        debug_b2_world_stats := b2.World_GetCounters(game.world_id)
        ValueBOx001EditMode := false

        rl.GuiCheckBox(rl.Rectangle{dpos.x - 100, dpos.y, dbox.x, dbox.y}, "draw_shapes", &draw_shapes)
        dpos.y += dpos_index
        rl.GuiCheckBox(rl.Rectangle{dpos.x - 100, dpos.y, dbox.x, dbox.y}, "draw_aabbs", &draw_aabbs)
        dpos.y += dpos_index
        rl.GuiCheckBox(rl.Rectangle{dpos.x - 100, dpos.y, dbox.x, dbox.y}, "draw_mass", &draw_mass)
        dpos.y += dpos_index

        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "body_count ",
                   &debug_b2_world_stats.bodyCount,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}
        dpos.y += dpos_index
        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "byte_count ",
                   &debug_b2_world_stats.byteCount,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}
        dpos.y += dpos_index

        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "stack_used ",
                   &debug_b2_world_stats.stackUsed,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}
        dpos.y += dpos_index

        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "contact_count ",
                   &debug_b2_world_stats.contactCount,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}
        dpos.y += dpos_index

        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "island_count ",
                   &debug_b2_world_stats.islandCount,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}
        dpos.y += dpos_index

        asteroid_count := i32(len(game.asteroids))
        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "asteroid count ",
                   &asteroid_count,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}
        dpos.y += dpos_index

        space_objects_count := i32(len(game.space_objects))
        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "space_object count ",
                   &space_objects_count,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}
        dpos.y += dpos_index

        enemy_count := i32(len(game.enemies))
        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "enemy count ",
                   &enemy_count,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}
        dpos.y += dpos_index

        bullets_count: i32 = i32(len(game.bullets))
        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "bullets count ",
                   &bullets_count,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}
        dpos.y += dpos_index

        missles_count := i32(len(game.missles))
        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "missles count ",
                   &missles_count,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}
        dpos.y += dpos_index

        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "asteroid vbo count ",
                   &asteroid_draw_index,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}

        dpos.y += dpos_index

        arena_peak_used: i32 = i32(arena.peak_used)
        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "arena peak used ",
                   &arena_peak_used,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}

        dpos.y += dpos_index

        arena_temp_count: i32 = i32(arena.temp_count)
        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "arena temp_count ",
                   &arena_temp_count,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}

        dpos.y += dpos_index

        cpu_particles_count: i32 = i32(len(game.cpu_particles))
        if (rl.GuiValueBox(
                   rl.Rectangle{dpos.x, dpos.y, dbox.x, dbox.y},
                   "cpu_particles_count ",
                   &cpu_particles_count,
                   0,
                   100,
                   ValueBOx001EditMode,
               ) >
               0) {ValueBOx001EditMode = !ValueBOx001EditMode}

        dpos.y += dpos_index
        rl.DrawTextEx(
            default_font,
            rl.TextFormat("camera ", game.camera.target),
            rl.Vector2{dpos.x - 430, dpos.y},
            20,
            1,
            rl.WHITE,
        )
        dpos.y += dpos_index
        rl.DrawTextEx(
            default_font,
            rl.TextFormat("offset ", game.camera.offset),
            rl.Vector2{dpos.x - 430, dpos.y},
            20,
            1,
            rl.WHITE,
        )
        dpos.y += dpos_index
        rl.DrawTextEx(default_font, rl.TextFormat("zoom %f", game.camera.zoom), rl.Vector2{dpos.x - 430, dpos.y}, 20, 1, rl.WHITE)
        // dpos.y += dpos_index
        // rl.DrawTextEx(
        // 	default_font,
        // 	rl.TextFormat("aabb ", &lower_bound, " ", &upper_bound),
        // 	rl.Vector2{dpos.x - 430, dpos.y},
        // 	20,
        // 	1,
        // 	rl.WHITE,
        // )

    }

    // 	ValueBOx001EditMode: bool
    debug_b2_world_stats: b2.Counters

    // Draw a closed polygon provided in CCW order.
    draw_polygon :: proc "cdecl" (vertices: [^]linalg.Vector2f32, vertex_count: i32, color: b2.HexColor, context_: rawptr) {
        for i in 0 ..< vertex_count {
            rl.DrawLineV(vertices[i] * RE_SCALE, vertices[(i + 1) % vertex_count] * RE_SCALE, rl.RED)
        }
    }

    // Draw a solid closed polygon provided in CCW order.
    draw_solid_polygon :: proc "cdecl" (
        transform: b2.Transform,
        vertices: [^]linalg.Vector2f32,
        vertex_count: i32,
        radius: f32,
        color: b2.HexColor,
        context_: rawptr,
    ) {
        for i in 0 ..< vertex_count {
            rl.DrawLineV(vertices[i] * RE_SCALE, vertices[(i + 1) % vertex_count] * RE_SCALE, rl.RED)
        }
    }

    // Draw a rounded polygon provided in CCW order.
    draw_rounded_polygon :: proc "cdecl" (
        vertices: [^]linalg.Vector2f32,
        vertex_count: i32,
        radius: f32,
        line_color, fill_color: b2.HexColor,
        context_: rawptr,
    ) {

    }

    // Draw a circle.
    draw_circle :: proc "cdecl" (center: linalg.Vector2f32, radius: f32, color: b2.HexColor, context_: rawptr) {
        rl.DrawCircleV(center * RE_SCALE, radius * 2, rl.Fade(rl.WHITE, 0.5))
    }

    // Draw a solid circle.
    draw_solid_circle :: proc "cdecl" (transform: b2.Transform, radius: f32, color: b2.HexColor, context_: rawptr) {
        pos := transform.p
        rl.DrawCircleV(pos * RE_SCALE, radius * RE_SCALE, rl.Fade(rl.WHITE, 0.5))
    }

    // Draw a capsule.
    draw_capsule :: proc "cdecl" (p1, p2: linalg.Vector2f32, radius: f32, color: b2.HexColor, context_: rawptr) {
        // using raylib
        // DrawLineV(p1, p2, RED)
    }

    // Draw a solid capsule.
    draw_solid_capsule :: proc "cdecl" (p1, p2: linalg.Vector2f32, radius: f32, color: b2.HexColor, context_: rawptr) {
        rl.DrawCircleV(p1 * RE_SCALE, radius * RE_SCALE, rl.Fade(rl.BLUE, 0.7))
        rl.DrawCircleV(p1 * RE_SCALE, radius * RE_SCALE, rl.Fade(rl.RED, 0.7))
    }

    // Draw a line segment.
    draw_segment :: proc "cdecl" (p1, p2: linalg.Vector2f32, color: b2.HexColor, context_: rawptr) {
        rl.DrawLineV(p1 * RE_SCALE, p2 * RE_SCALE, rl.ORANGE)
    }

    // Draw a transform. Choose your own length scale.
    // @param xf a transform.
    draw_transform :: proc "cdecl" (xf: b2.Transform, context_: rawptr) {
        // DrawLineV(xf.p, xf.p + xf.q.c, RED)
        // DrawLineV(xf.p, xf.p + xf.q.b, GREEN)
    }

    // Draw a point.
    draw_point :: proc "cdecl" (p: linalg.Vector2f32, size: f32, color: b2.HexColor, context_: rawptr) {
        rl.DrawCircleV(p * RE_SCALE, size, rl.Fade(rl.RED, 0.7))
    }

    // Draw a string.
    draw_string :: proc "cdecl" (p: linalg.Vector2f32, s: cstring, context_: rawptr) {
        rl.TraceLog(.WARNING, s)
        rl.DrawTextEx(default_font, s, p * RE_SCALE, 10, 1, rl.WHITE)
    }
}
