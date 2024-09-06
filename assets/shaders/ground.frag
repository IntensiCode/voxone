#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform sampler2D iImage;

uniform vec2 iScrOffset;
uniform vec2 iScrSize;
uniform vec2 iImageSize;

out vec4 fragColor;

const int steps = 32;

float u_step = 1 / iScrSize.x / 2;
float v_step = 1 / iScrSize.y;

void main() {
    vec2 uv = FlutterFragCoord().xy;
    uv.x *= 1;
    uv.y *= 2;
    uv.x = mod(uv.x + iScrOffset.x, iImageSize.x);
    uv.y = mod(uv.y + iScrOffset.y, iImageSize.y);
    uv.x /= iScrSize.x;
    uv.x *= iScrSize.x / iImageSize.x;
    uv.y /= iScrSize.y;
    uv.y *= iScrSize.y / iImageSize.y;

    vec4 c1 = texture(iImage, uv);
    fragColor = c1;

    uv.y += v_step;
    vec4 c2 = texture(iImage, uv);
    if (c1.x < c2.x) {
        fragColor.x *= 0.5;
        fragColor.y *= 0.5;
        fragColor.z *= 0.5;
        fragColor.a = 1;
    }

    uv.x += u_step;
    vec4 c3 = texture(iImage, uv);
    if (c1.x < c3.x) {
        fragColor.x *= 0.5;
        fragColor.y *= 0.5;
        fragColor.z *= 0.5;
        fragColor.a = 1;
    }
}
