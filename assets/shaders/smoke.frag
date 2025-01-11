#version 460 core

#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iSeed;
uniform vec2 iTime;

// Made by Darko Supe (omegasbk)

float rand(vec2 coord) {
    return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 15.5453 * iSeed);
}

float noise(vec2 uv)
{
    return fract(sin(uv.x * 113. + uv.y * 412.) * rand(uv) * 6339.);
}

vec3 noiseSmooth(vec2 uv)
{
    vec2 index = floor(uv);

    vec2 pq = fract(uv);
    pq = smoothstep(0., 1., pq);

    float topLeft = noise(index);
    float topRight = noise(index + vec2(1, 0.));
    float top = mix(topLeft, topRight, pq.x);

    float bottomLeft = noise(index + vec2(0, 1));
    float bottomRight = noise(index + vec2(1, 1));
    float bottom = mix(bottomLeft, bottomRight, pq.x);

    return vec3(mix(top, bottom, pq.y));
}

void main()
{
    vec2 fragCoord = FlutterFragCoord();

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord / iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;

    vec3 sky = vec3(0.0, 0.0, 0.0) * ((1. - uv.y) + 1.5) / 2.;

    uv += iTime / 40.;

    vec2 uv2 = uv;
    uv2 += iTime / 10.;

    vec2 uv3 = uv;
    uv3 += iTime / 30.;

    vec3 col = noiseSmooth(uv * 4.);

    col += noiseSmooth(uv * 8.) * 0.5;
    col += noiseSmooth(uv2 * 16.) * 0.25;
    col += noiseSmooth(uv3 * 32.) * 0.125;
    col += noiseSmooth(uv3 * 64.) * 0.0625;

    col /= 2.;

    col *= smoothstep(0.2, .6, col);

    col = mix(1. - (col / 7.), sky, 1. - col);

    float d = 1 - distance(uv, vec2(0.5)) * 2;

    // Output to screen
    //    fragColor = vec4(vec3(col), d);
    if (d < 0.1) {
        fragColor = vec4(0, 0, 0, 0);
    } else {
        vec3 c = col * d;
        fragColor = vec4(c, d / 2);
        fragColor.x *= d;
        fragColor.y *= d;
        fragColor.z *= d;
    }
}
