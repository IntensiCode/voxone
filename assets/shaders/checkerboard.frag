#version 460 core

#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec4 color1;
uniform vec4 color2;
uniform vec2 resolution;
uniform float size;
uniform float d;
uniform float x_off;
uniform float y_off;
uniform float z_off;

out vec4 fragColor;

const float merge_col = 32.0;

void main() {
    vec2 uv = FlutterFragCoord().xy;
    float x = uv.x - resolution.x / 2.0;
    float y = uv.y;

    float y_world = y_off * 4.0;
    float z_world = y_world * d / y / 4.0;
    float x_world = x / d * z_world + x_off;

    float x_tile = mod(floor((x_world + size * 2.0) / size / 4.0), 2.0);
    float z_tile = mod(floor((z_world - z_off / 4.0) / size), 2.0);

    bool alt = x_tile != z_tile;
    vec4 col = alt ? color2 : color1;
    vec4 other = alt ? color1 : color2;

    float merge_ = clamp((y - resolution.y / merge_col) / resolution.y, 0.0, 1.0);
    col = mix(col, other, 0.5 - merge_);

    fragColor = col;
}
