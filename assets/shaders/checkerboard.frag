#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec4 color1;
uniform vec4 color2;
uniform vec2 resolution;
uniform float size;
uniform float d;
uniform float x_off;
uniform float y_off;
uniform float z_off;

out vec4 fragColor;

const float merge_col = 64;

float do_mod(float a, float b) {
    return a - (b * floor(a / b));
}

void main() {
    float x = FlutterFragCoord().x - resolution.x / 2;
    float y = FlutterFragCoord().y - resolution.y;

    float y_world = y_off * 4;
    float z_world = y_world * d / y / 4;
    float x_world = x / d * z_world + x_off;

    float x_tile = do_mod(floor(x_world / size / 4), 2);
    float z_tile = do_mod(floor((z_world - z_off / 8) / size), 2);
    // why the 8 for it to look square?

    vec4 col = color1;
    vec4 other = color2;
    if (x_tile != z_tile) {
        col = color2;
        other = color1;
    }

    float merge_ = (y - resolution.y / merge_col) / resolution.y;
    if (merge_ < 0) merge_ = 0;
    col = mix(col, other, 0.5 - merge_);

    col.x *= col.a;
    col.y *= col.a;
    col.z *= col.a;
    fragColor = col;
}
