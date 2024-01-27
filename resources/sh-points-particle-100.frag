#version 100

precision mediump float;

varying vec4 p_color;

void main()
{
    gl_FragColor = vec4(p_color.rgb, p_color.a * (1.0 - length(gl_PointCoord.xy - vec2(0.5))*2.0));
}