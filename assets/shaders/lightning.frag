// https://www.shadertoy.com/view/dsXfDn

#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform float iTime;

out vec4 fragColor;

float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

mat2 rotate2d(float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    return mat2(
    c, -s,
    s, c
    );
}

float noise(vec2 p)
{
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float a = hash12(ip);
    float b = hash12(ip + vec2(1, 0));
    float c = hash12(ip + vec2(0, 1));
    float d = hash12(ip + vec2(1, 1));

    vec2 t = smoothstep(0.0, 1.0, fp);
    return mix(mix(a, b, t.x), mix(c, d, t.x), t.y);
}

float fbm(vec2 p, int octaveCount)
{
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < octaveCount; ++i)
    {
        value += amplitude * noise(p);
        p *= rotate2d(0.45);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    uv = 2.0 * uv - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    float s = uv.x;
    uv.x = uv.y;
    uv.y = s;

    uv += 0.5 * fbm(uv+0.8*iTime, 10) - 0.25;

    float dist = abs(uv.x);
    vec3 col = vec3(0.2, 0.3, 0.8) * pow(mix(0.0, 0.07, hash11(iTime)) / dist, 1.0);

    col = pow(col, vec3(1.0));
    // Output to screen
    fragColor = vec4(col,1.0);
}
