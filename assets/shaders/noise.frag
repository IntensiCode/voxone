#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iScrSize;
uniform float iTime;

out vec4 fragColor;

// Created by Dave_Hoskins in 2013-09-20
// https://www.shadertoy.com/view/4dlGW2

// Tileable noise, for creating useful textures. By David Hoskins, Sept. 2013.
// It can be extrapolated to other types of randomised texture.

#define SHOW_TILING
#define TILES 2.0// Use 1.0 for normal tiling across whole texture.

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
    p += vec2(sin(iTime * .7), cos(iTime * .45))*(.1);//  + iMouse.xy*.1/iResolution.xy;
    float f = 0.0;
    // Change starting scale to any integer value...
    float scale = 13.;
    p = mod(p, scale);
    float amp   = 0.9;

    for (int i = 0; i < 12; i++)
    {
        f += Noise(p, scale) * amp;
        amp *= .2;
        // Scale must be multiplied by an integer value...
        scale *= 4.;
    }
    // Clamp it just in case....
    return min(f, 1.0);
}

//----------------------------------------------------------------------------------------
void main()
{
    vec2 uv = FlutterFragCoord().xy / iScrSize.xy;

    // Do the noise cloud (fractal Brownian motion)
    float bri = fBm(uv);
    float h = bri.x;
    h *= 10;
    h = h - fract(h);
    h /= 10;
//    h = 1.4 - h * 1.5;

    fragColor = vec4(0.1 + h * 0.9, 0.05 + h * 0.6, 0.01 + h * 0.2, 1.0);
}
