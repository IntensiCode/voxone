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

const int OCTAVES = 10;
const float should_dither = 1.0;

vec2 light_origin = vec2(0.39, 0.39);
float time_speed = 0.2;
float dither_size = 2.0;
float light_border_1 = 0.4;
float light_border_2 = 0.6;

out vec4 fragColor;

float rand(vec2 coord) {
    coord = mod(coord, vec2(1.0, 1.0) * round(size));
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
}

float noise(vec2 coord) {
    vec2 i = floor(coord);
    vec2 f = fract(coord);

    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    vec2 cubic = f * f * (3.0 - 2.0 * f);

    return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord) {
    float value = 0.0;
    float scale = 0.5;

    for (int i = 0; i < OCTAVES; i++) {
        value += noise(coord) * scale;
        coord *= 2.0;
        scale *= 0.5;
    }
    return value;
}

bool dither(vec2 uv1, vec2 uv2) {
    return mod(uv1.x + uv2.y, 2.0 / pixels) <= 1.0 / pixels;
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

    bool dith = dither(uv, UV);
    uv = rotate(uv, rotation);

    // get a noise value with light distance added
    // this creates a moving dynamic shape
    float fbm1 = fbm(uv);
    d_light += fbm(uv * size + fbm1 + vec2(time * time_speed, 0.0)) * 0.3; // change the magic 0.3 here for different light strengths

    // size of edge in which colors should be dithered
    float dither_border = (1.0 / pixels) * dither_size;

    // now we can assign colors based on distance to light origin
    vec4 col = colors[0];
    if (d_light > light_border_1) {
        col = colors[1];
        if (d_light < light_border_1 + dither_border && (dith || should_dither != 1.0)) {
            col = colors[0];
        }
    }
    if (d_light > light_border_2) {
        col = colors[2];
        if (d_light < light_border_2 + dither_border && (dith || should_dither != 1.0)) {
            col = colors[1];
        }
    }

    float aa = a * col.a;
    fragColor = vec4(col.rgb, aa);
    if (a < 0.2) {
        fragColor.x *= a;
        fragColor.y *= a;
        fragColor.z *= a;
    }
}
