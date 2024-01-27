#version 100
//others/raylib_opengl_interop.c

attribute vec3 vertexPosition;
attribute vec4 vertexColor;

uniform mat4 mvp;
uniform float iTime;

varying vec4 p_color;

// NOTE: Add here your custom variables

void main()
{
    // Unpack data from vertexPosition
    vec2  pos    = vertexPosition.xy;
    float period = vertexPosition.z;
    p_color = vertexColor;

    // Calculate final vertex position (jiggle it around a bit horizontally)
    pos += sin(period * iTime);
    gl_Position = mvp * vec4(pos, 0.0, 1.0);

    // Calculate the screen space size of this particle (also vary it over time)
    gl_PointSize = period - 5.0 * abs(sin(period * iTime));
}