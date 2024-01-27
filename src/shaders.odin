package main

/////////////WASM
// import b2 "box2dw"
// import "raylib"
/////////////NOT WASM
import b2 "box2d"
import "vendor:raylib"

import "core:fmt"
import "core:math/linalg"

SHADER_UNIFORM_FLOAT :: 0 // Shader uniform type: float
SHADER_UNIFORM_VEC2 :: 1 // Shader uniform type: vec2 (2 float)
SHADER_UNIFORM_VEC3 :: 2 // Shader uniform type: vec3 (3 float)
SHADER_UNIFORM_VEC4 :: 3 // Shader uniform type: vec4 (4 float)
SHADER_UNIFORM_INT :: 4 // Shader uniform type: int
SHADER_UNIFORM_IVEC2 :: 5 // Shader uniform type: ivec2 (2 int)
SHADER_UNIFORM_IVEC3 :: 6 // Shader uniform type: ivec3 (3 int)
SHADER_UNIFORM_IVEC4 :: 7 // Shader uniform type: ivec4 (4 int)
SHADER_UNIFORM_SAMPLER2D :: 8 // Shader uniform type: sampler2d

ShadersFile :: struct {
	vert: cstring,
	frag: cstring,
}

SHADERS_FILES :: []ShadersFile {
	ShadersFile{vert = nil, frag = "sh-galaxy-trip"},
	ShadersFile{vert = nil, frag = "sh-star-nest"},
	ShadersFile{vert = "sh-points-asteroids", frag = "sh-points-asteroids"},
	ShadersFile{vert = "sh-points-particle", frag = "sh-points-particle"},
}

SHADERS_ID :: enum {
	GALAXYTRIP,
	STARNEST,
	POINTS_ASTEROIDS,
	POINTS_PARTICLES,
}

GPU_Asteroid :: struct {
	x:    f32,
	y:    f32,
	size: f32,
}

CPU_Particle :: struct {
	pos, vel: linalg.Vector2f32,
	color:    raylib.Color,
	lifetime: f32,
	size:     f32,
}

GPU_Particle :: struct {
	x:    f32,
	y:    f32,
	size: f32,
}

GPU_Particle_color :: struct {
	color: linalg.Vector4f32,
}

shaders: [dynamic]raylib.Shader

MAX_PARTICLE_COUNT :: 1000

VAO_Asteroids: u32
VBO_Asteroids: u32
vertexPositionLoc_Asteroids: i32

VAO_Particles: u32
VAO_Particles_colors: u32
VBO_Particles: u32
VBO_Particles_colors: u32
vertexPositionLoc_Particles: i32
vertexColorLoc_Particles: i32

shader_iTime: f32 = 0.0
shader_iResolution: raylib.Vector2

load_shaders :: proc() {
	using raylib
	shader_iResolution = raylib.Vector2{f32(GetScreenWidth()), f32(GetScreenHeight())}
	for s, i in SHADERS_FILES {
		fs := fmt.ctprintf("%s%s-%s.frag", RESOURCES_DIR, s.frag, GLSL_VERSION)
		if s.vert == nil {
			inject_at(&shaders, i, LoadShader(nil, fs))
		} else {
			vs := fmt.ctprintf("%s%s-%s.vert", RESOURCES_DIR, s.vert, GLSL_VERSION)
			inject_at(&shaders, i, LoadShader(vs, fs))
		}
		liResolution := GetShaderLocation(shaders[i], "iResolution")

		// TODO: we should check to see that a shader needs these before setting them
		SetShaderValue(
			shaders[i],
			raylib.ShaderLocationIndex(liResolution),
			&shader_iResolution,
			raylib.ShaderUniformDataType(SHADER_UNIFORM_VEC2),
		)
	}

	// gpu_asteroids
	vertexPositionLoc_Asteroids = GetShaderLocationAttrib(
		shaders[int(SHADERS_ID.POINTS_ASTEROIDS)],
		"vertexPosition",
	)

	VAO_Asteroids = rlLoadVertexArray()
	rlEnableVertexArray(VAO_Asteroids) //         glBindVertexArray(vaoId);

	VBO_Asteroids = rlLoadVertexBuffer(&game.gpu_asteroids, size_of(game.gpu_asteroids), false)
	rlSetVertexAttribute(
		u32(vertexPositionLoc_Asteroids),
		3,
		RL_FLOAT,
		false,
		size_of(GPU_Asteroid),
		nil,
	) // glVertexAttribPointer
	rlEnableVertexAttribute(u32(vertexPositionLoc_Asteroids))
	rlEnableVertexBuffer(VBO_Asteroids)

	// gpu_particles
	vertexPositionLoc_Particles = GetShaderLocationAttrib(
		shaders[int(SHADERS_ID.POINTS_PARTICLES)],
		"vertexPosition",
	)

	VAO_Particles = rlLoadVertexArray()
	rlEnableVertexArray(VAO_Particles)

	VBO_Particles = rlLoadVertexBuffer(&game.gpu_particles, size_of(game.gpu_particles), false)
	rlSetVertexAttribute(
		u32(vertexPositionLoc_Particles),
		3,
		RL_FLOAT,
		false,
		size_of(GPU_Particle),
		nil,
	)
	rlEnableVertexAttribute(u32(vertexPositionLoc_Particles))  //     glEnableVertexAttribArray(index);

	// gpu_particles colors
	vertexColorLoc_Particles = GetShaderLocationAttrib(
		shaders[int(SHADERS_ID.POINTS_PARTICLES)],
		"vertexColor",
	)
	VBO_Particles_colors = rlLoadVertexBuffer(
		&game.gpu_particles_colors,
		size_of(game.gpu_particles_colors),
		false,
	)

	rlSetVertexAttribute(
		u32(vertexColorLoc_Particles),
		4,
		RL_FLOAT,
		false,
		size_of(GPU_Particle_color),
		nil,
	)

	rlEnableVertexAttribute(u32(vertexColorLoc_Particles))
    rlEnableVertexBuffer(VBO_Particles)  //    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id);

	rlDisableVertexArray()
	rlDisableVertexBuffer()
}

draw_asteroids :: proc() {
	using raylib

	colorLoc := GetShaderLocation(shaders[int(SHADERS_ID.POINTS_ASTEROIDS)], "color")
	mvpLoc := GetShaderLocation(shaders[int(SHADERS_ID.POINTS_ASTEROIDS)], "mvp")
	liZoom := GetShaderLocation(shaders[int(SHADERS_ID.POINTS_ASTEROIDS)], "iZoom")
	liTime := GetShaderLocation(shaders[int(SHADERS_ID.POINTS_ASTEROIDS)], "iTime")

	rlDrawRenderBatchActive()
	// Nope, this isn't a standard part of rlgl
	// Some of this was added to rlgl.h, and bindings added to Odin/vendor/raylib/rlgl.odin
	// Hopefully I update the README.md with very minor changes needed to make this work
	rlEnablePointMode()
	BeginShaderMode(shaders[int(SHADERS_ID.POINTS_ASTEROIDS)])

	SetShaderValue(
		shaders[int(SHADERS_ID.POINTS_ASTEROIDS)],
		raylib.ShaderLocationIndex(liTime),
		&shader_iTime,
		raylib.ShaderUniformDataType(SHADER_UNIFORM_FLOAT),
	)

	SetShaderValue(
		shaders[int(SHADERS_ID.POINTS_ASTEROIDS)],
		raylib.ShaderLocationIndex(liZoom),
		&game.camera.zoom,
		raylib.ShaderUniformDataType(SHADER_UNIFORM_FLOAT),
	)
	modelViewProjection: Matrix = rlGetMatrixModelview() * rlGetMatrixProjection()
	rlSetUniformMatrix(mvpLoc, modelViewProjection)

	// Needs to be added to Odin/vendor/raylib/rlgl.odin bindings
	// Also needs to be added to raylib/rlgl.h
	// rlEnableVertexArray(VAO_Asteroids)
	rlBindVertexArray(VAO_Asteroids)
	rlDrawArrays(0, 0, asteroid_draw_index)
	rlDisableVertexArray()

	EndShaderMode()
	rlDisableWireMode()
}

update_asteroids :: proc(dt: f32) {
	raylib.rlUpdateVertexBuffer(VBO_Asteroids, &game.gpu_asteroids, size_of(game.gpu_asteroids), 0)
}

draw_particles :: proc() {
	using raylib

	liTime := GetShaderLocation(shaders[int(SHADERS_ID.POINTS_PARTICLES)], "iTime")
	mvpLoc := GetShaderLocation(shaders[int(SHADERS_ID.POINTS_PARTICLES)], "mvp")

	// rlEnablePointMode()
	BeginShaderMode(shaders[int(SHADERS_ID.POINTS_PARTICLES)])

	SetShaderValue(
		shaders[int(SHADERS_ID.POINTS_PARTICLES)],
		raylib.ShaderLocationIndex(liTime),
		&shader_iTime,
		raylib.ShaderUniformDataType(SHADER_UNIFORM_FLOAT),
	)

	modelViewProjection: Matrix = rlGetMatrixModelview() * rlGetMatrixProjection()
	rlSetUniformMatrix(mvpLoc, modelViewProjection)
	
	rlBindVertexArray(VAO_Particles)
	rlDrawArrays(0, 0, i32(len(game.cpu_particles))) //     glDrawArrays(mode, offset, count);

	EndShaderMode()
	rlDisableWireMode()
}

update_particles :: proc(dt: f32) {
	using raylib

	//update cpu_particles
	i := 0
	for i < len(game.cpu_particles) && i < MAX_PARTICLE_COUNT {
		game.cpu_particles[i].lifetime -= dt
		if game.cpu_particles[i].lifetime < 0 {
			unordered_remove(&game.cpu_particles, i)
			continue
		}
		game.cpu_particles[i].pos += game.cpu_particles[i].vel * dt
		game.gpu_particles[i].x = game.cpu_particles[i].pos.x * RE_SCALE
		game.gpu_particles[i].y = game.cpu_particles[i].pos.y * RE_SCALE * -1
		game.gpu_particles[i].size = game.cpu_particles[i].size * 10
		//TODO: fix this
		game.gpu_particles_colors[i].color = linalg.Vector4f32 {
			f32(game.cpu_particles[i].color.r / 255),
			f32(game.cpu_particles[i].color.g / 255),
			f32(game.cpu_particles[i].color.b / 255),
			f32(game.cpu_particles[i].color.a / 255),
		}
		i += 1
	}

	raylib.rlUpdateVertexBuffer(
		VBO_Particles,
		&game.gpu_particles,
		i32(len(game.cpu_particles) * size_of(GPU_Particle)),
		0,
	)
	raylib.rlUpdateVertexBuffer(
		VBO_Particles_colors,
		&game.gpu_particles_colors,
		i32(len(game.cpu_particles) * size_of(GPU_Particle_color)),
		0,
	)
}

// draws the starnest background shader
draw_background_shader :: proc() {
	using raylib
	liTime := GetShaderLocation(shaders[int(SHADERS_ID.STARNEST)], "iTime")

	SetShaderValue(
		shaders[int(SHADERS_ID.STARNEST)],
		raylib.ShaderLocationIndex(liTime),
		&shader_iTime,
		raylib.ShaderUniformDataType(SHADER_UNIFORM_FLOAT),
	)

	BeginShaderMode(shaders[int(SHADERS_ID.STARNEST)])

	DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), BLACK)
	EndShaderMode()
}
