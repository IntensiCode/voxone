#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 resolution;
uniform float pixels;
uniform float rotation;
uniform vec4[3] colors;
uniform float size;
uniform float seed;
uniform float time;

vec2 light_origin = vec2(0.39, 0.39);
float time_speed = 0.2;
float light_border = 0.6;

out vec4 fragColor;

float rand(vec2 coord) {
    coord = mod(coord, vec2(1.0, 1.0) * round(size));
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

// by Leukbaars from https://www.shadertoy.com/view/4tK3zR
float circleNoise(vec2 uv) {
    float uv_y = floor(uv.y);
    uv.x += uv_y * .31;
    vec2 f = fract(uv);
    float h = rand(vec2(floor(uv.x), floor(uv_y)));
    float m = (length(f - 0.25 - (h * 0.5)));
    float r = h * 0.25;
    return m = smoothstep(r - .10 * r, r, m);
}

float crater(vec2 uv) {
    float c = 1.0;
    for (int i = 0; i < 2; i++) {
        c *= circleNoise((uv * size) + (float(i + 1) + 10.) + vec2(time * time_speed, 0.0));
    }
    return 1.0 - c;
}

vec2 spherify(vec2 uv) {
    vec2 centered = uv * 2.0 - 1.0;
    float z = sqrt(1.0 - dot(centered.xy, centered.xy));
    vec2 sphere = centered / (z + 1.0);
    return sphere * 0.5 + 0.5;
}

vec2 rotate(vec2 coord, float angle) {
    coord -= 0.5;
    coord *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
    return coord + 0.5;
}

void main() {
    float x = FlutterFragCoord().x;
    float y = FlutterFragCoord().y;
    vec2 UV = vec2(x, y) / resolution;

    //pixelize uv
    vec2 uv = floor(UV * pixels) / pixels;

    // check distance from center & distance to light
    float d_circle = distance(uv, vec2(0.5));
    float d_light = distance(uv, vec2(light_origin));
    // cut out a circle
    // stepping over 0.5 instead of 0.49999 makes some pixels a little buggy
    float a = step(d_circle, 0.49999);

    uv = rotate(uv, rotation);
    uv = spherify(uv);

    float c1 = crater(uv);
    float c2 = crater(uv + (light_origin - 0.5) * 0.03);
    vec4 col = colors[0];

    a *= step(0.5, c1);
    if (c2 < c1 - (0.5 - d_light) * 2.0) {
        col = colors[1];
    }
    if (d_light > light_border) {
        col = colors[1];
    }

    // cut out a circle
    a *= step(d_circle, 0.5);
    float aa = a * col.a;
    fragColor = vec4(col.rgb, aa);
    if (a < 0.1) {
        fragColor.x *= a;
        fragColor.y *= a;
        fragColor.z *= a;
    }
}
