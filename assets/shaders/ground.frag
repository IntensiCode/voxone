#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform vec2 iMouse;

out vec4 fragColor;

const float steps = 10.;

float u_step = 1 / iResolution.x / 0.25;
float v_step = 1 / iResolution.y / 0.25;

// Created by Dave_Hoskins in 2013-09-20
// https://www.shadertoy.com/view/4dlGW2

//----------------------------------------------------------------------------------------
float Hash(in vec2 p, in float scale)
{
    // This is tiling part, adjusts with the scale...
    p = mod(p, scale);
    return fract(sin(dot(p, vec2(27.16898, 38.90563))) * 5151.5473453);
}

//----------------------------------------------------------------------------------------
float Noise(in vec2 p, in float scale)
{
    vec2 f;

    p *= scale;

    f = fract(p);// Separate integer from fractional
    p = floor(p);

    f = f*f*(3.0-2.0*f);// Cosine interpolation approximation

    float res = mix(mix(Hash(p, scale),
    Hash(p + vec2(1.0, 0.0), scale), f.x),
    mix(Hash(p + vec2(0.0, 1.0), scale),
    Hash(p + vec2(1.0, 1.0), scale), f.x), f.y);
    return res;
}

//----------------------------------------------------------------------------------------
float fBm(in vec2 p)
{
    p += iMouse;
    p /= 10;

    float f = 0.0;
    // Change starting scale to any integer value...
    float scale = 15.;
    p = mod(p, scale);
    float amp   = 0.9;

    for (int i = 0; i < 12; i++)
    {
        f += Noise(p, scale) * amp;
        amp *= .075;
        // Scale must be multiplied by an integer value...
        scale *= 7.;
    }
    // Clamp it just in case....
    return min(0.25 + f * 1.25, 1.25);
}

float plane(in vec2 uv) {
    float h = fBm(uv);
    h *= steps;
    h = round(h);
    h /= steps;
    return h;
}

void main() {
    vec2 uv = FlutterFragCoord().xy;
    uv.x /= iResolution.x;
    uv.y /= iResolution.y;

    float c1 = plane(uv);
    fragColor = vec4(c1 * 0.8, c1 * 0.5, c1 * 0.2, 1);

    uv.y += v_step;
    float c2 = plane(uv);
    if (c1 > c2) {
        fragColor.x *= 0.5;
        fragColor.y *= 0.5;
        fragColor.z *= 0.5;
        fragColor.a = 1;
    }

    uv.x += u_step;
    float c3 = plane(uv);
    if (c1 > c3) {
        fragColor.x *= 0.5;
        fragColor.y *= 0.5;
        fragColor.z *= 0.5;
        fragColor.a = 1;
    }
}
