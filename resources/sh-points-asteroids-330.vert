#version 330

attribute vec3 vertexPosition;

uniform mat4 mvp;
uniform float iTime;
uniform float iZoom;

out float iSize;

void main()
{
    // Unpack data from vertexPosition
    vec2  pos  = vertexPosition.xy;
    float size = vertexPosition.z;
    iSize = vertexPosition.z/100;

    // Calculate final vertex position (jiggle it around a bit horizontally)
    //pos += vec2(100, 0) * sin(size * iTime);
    gl_Position = mvp * vec4(pos, 0, 1.0);

    // Calculate the screen space size of this particle (also vary it over time)
    gl_PointSize = size * iZoom * 2.0;
}