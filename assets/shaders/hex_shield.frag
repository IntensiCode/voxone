// https://www.shadertoy.com/view/M32GW3

#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform vec2 unused;
uniform float iTime;

out vec4 fragColor;

#define o fragColor
#define u FlutterFragCoord()

void main() {
    float t = iTime, z;
    vec2  R = iResolution.xy,
    p = 1.* (u+u - R) / R.x;// centered coords
    p /= .2 + .3* sqrt(z = max(1.-dot(p, p), 0.)), // sphere. z = depth
    p.y += fract(ceil(p.x = p.x/.9 + t) / 2.) + t*.2, // hexa: offset odd rows
    p = abs(fract(p) - .5), // tiling + symmetries
    o =   vec4(2, 3, 5, 1)/20. * z// pseudo-shading
    / (.1 + abs(max(p, p.x*1.5) + p - 1.).y);// pattern: draw 2 lines
}
