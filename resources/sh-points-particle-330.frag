#version 330

uniform vec4 color;

in vec4 pColor;
out vec4 finalColor;

void main()
{
    finalColor = vec4(pColor.xyz, pColor.w * (1 - length(gl_PointCoord.xy - vec2(0.5))*2));
}