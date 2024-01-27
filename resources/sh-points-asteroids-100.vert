#version 100

attribute vec3 vertexPosition;

uniform mat4 mvp;
uniform float iTime;
uniform float iZoom;

varying float iSize;

void main()
{
    vec2  pos  = vertexPosition.xy;
    float size = vertexPosition.z;
    iSize = vertexPosition.z/100.0;
    gl_Position = mvp * vec4(pos, 0, 1.0);
    gl_PointSize = size * iZoom * 2.0;
}