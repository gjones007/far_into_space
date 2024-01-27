#version 330
//others/raylib_opengl_interop.c

layout (location = 0) in vec3 vertexPosition; 
layout (location = 1) in vec4 vertexColor; 

uniform mat4 mvp;
uniform float iTime;

out vec4 pColor;

// NOTE: Add here your custom variables

void main()
{
    // Unpack data from vertexPosition
    vec2  pos    = vertexPosition.xy;
    float period = vertexPosition.z;
    pColor = vertexColor;

    // Calculate final vertex position (jiggle it around a bit horizontally)
    pos += sin(period * iTime);
    gl_Position = mvp * vec4(pos, 0.0, 1.0);

    // Calculate the screen space size of this particle (also vary it over time)
    gl_PointSize = period - 5 * abs(sin(period * iTime));
}