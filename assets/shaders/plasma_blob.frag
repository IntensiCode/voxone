// https://www.shadertoy.com/view/l3jXRy

#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform float iTime;

out vec4 fragColor;

float getRythm () {
    return 2.15 * sin(2. * iTime);
}

float distanceFromSphere (in vec3 pos, in vec3 sphere, float radius) {
    return length(pos - sphere) - radius;
}

float calcDisplace (in float pos) {
    return sin(1.0 * pos + iTime * 4.0);
}

float mapWorld (in vec3 pos, in vec4 sphere)
{
    float sphere0 = distanceFromSphere(pos, sphere.xyz, sphere.w);
    float displacement = calcDisplace(pos.x) *  calcDisplace(pos.y) * calcDisplace(pos.z) * 0.25;

    return sphere0 + displacement;
}

vec3 calculateNormal (in vec3 pos, in vec4 sphere)
{
    const vec3 small_step = vec3(0.001, 0.0, 0.0);

    float gradient_x = mapWorld(pos + small_step.xyy, sphere) - mapWorld(pos - small_step.xyy, sphere);
    float gradient_y = mapWorld(pos + small_step.yxy, sphere) - mapWorld(pos - small_step.yxy, sphere);
    float gradient_z = mapWorld(pos + small_step.yyx, sphere) - mapWorld(pos - small_step.yyx, sphere);

    vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

vec3 raymarch(in vec3 rayOrigin, in vec3 rayDirection, in vec3 lightSource, in vec4 sphere, in vec2 uv) {

    float distanceTraveled = 0.0;
    float closestDistance = iResolution.x + iResolution.y;

    const int NUMBER_OF_STEPS = 3;
    const float MINIMUM_HIT_DISTANCE = 0.001;
    const float MAXIMUM_TRACE_DISTANCE = 100.0;

    for (int i = 0; i < NUMBER_OF_STEPS; ++i) {

        vec3 currentPos = rayOrigin + distanceTraveled * rayDirection;

        float distanceToClosest = mapWorld(currentPos, sphere);

        if (distanceToClosest < MINIMUM_HIT_DISTANCE) {

            vec3 normal = calculateNormal(currentPos, sphere);
            vec3 directionToLight = normalize(currentPos - lightSource);

            float diffuseIntensity = max(0.0, dot(normal, directionToLight));

            return vec3(1.0);// * diffuseIntensity * 2.0;
        }

        if (closestDistance > distanceToClosest) {
            closestDistance = distanceToClosest;
        }

        if (distanceTraveled > MAXIMUM_TRACE_DISTANCE) {
            break;
        }

        distanceTraveled += distanceToClosest;
    }

    return vec3(
    0.5 * cos(1.0 * iTime) + 1.5,
    0.5 * cos(1.0 * iTime + 1.0) + 1.5,
    0.5 * cos(1.0 * iTime + 2.0) + 1.5
    ) / pow(closestDistance, 2.0);
}

void main () {

    vec2 fragCoord = FlutterFragCoord();

    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;

    vec3 cameraPosition = vec3(0.0, 0.0, -5.0);
    vec3 rayOrigin = cameraPosition;
    vec3 rayDirection = vec3(uv, 1.0);

    vec3 lightSource = vec3(3.0, -5.0, 5.0);

    vec3 spherePos = vec3(0.0, 0.0, 2.0);// Position
    vec4 sphere = vec4(spherePos, 3.0);// Radius

    vec3 color = raymarch(rayOrigin, rayDirection, lightSource, sphere, uv);

    // Output to screen
    fragColor = vec4(color, 1.0);
    if (fragColor.r < 0.4) {
        fragColor.a = 0.0;
        fragColor.r = 0.0;
        fragColor.g = 0.0;
        fragColor.b = 0.0;
    }
}
