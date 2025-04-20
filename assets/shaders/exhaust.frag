#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

// Uniforms matching Kage variables + Flutter specifics
uniform vec2 uResolution;// Texture dimensions (width, height)
uniform sampler2D uTextureSampler;// Input texture
uniform float Time;

uniform vec4 TargetColor;
uniform float ColorVariance;
uniform float ExhaustLength;
uniform vec3 Color0;
uniform vec3 Color1;
uniform vec3 Color2;
uniform vec3 Color3;
uniform vec3 Color4;

out vec4 fragColor;// Output color for Flutter/Impeller

// Helper to sample texture using pixel coordinates
vec4 textureLookupPixel(vec2 pixelCoord) {
    // Check bounds to avoid sampling outside the texture
    if (pixelCoord.x < 0.0 || pixelCoord.x >= uResolution.x || pixelCoord.y < 0.0 || pixelCoord.y >= uResolution.y) {
        return vec4(0.0);// Return transparent black if out of bounds
    }
    vec2 uv = pixelCoord / uResolution.xy;
    return texture(uTextureSampler, uv);
}

// Checks if a color matches the TargetColor within the variance
bool isColorMatch(vec4 color) {
    vec3 diff = abs(color.rgb - TargetColor.rgb);
    // Also check alpha if TargetColor.a is significant, otherwise ignore source alpha
    float alphaDiff = abs(color.a - TargetColor.a);
    bool alphaMatch = (TargetColor.a < 0.01) || (alphaDiff < ColorVariance);
    return diff.r < ColorVariance && diff.g < ColorVariance && diff.b < ColorVariance && alphaMatch && color.a > 0.01;// Ensure source pixel is not fully transparent
}

// Searches nearby pixels for the TargetColor
// Returns minimum squared distance if found, otherwise -1
float checkExhaustArea(vec2 currentPixelCoord) {
    float maxLengthSq = ExhaustLength * ExhaustLength;
    float minDistSq = maxLengthSq + 1.0;// Initialize higher than max

    // Kage original: Fixed search radius
    const int maxRadius = 4;

    // Replicate Kage loop structure exactly
    for (int dy = 0; dy <= maxRadius; ++dy) {
        float floatDy = float(dy);
        float dySq = floatDy * floatDy;

        for (int dx = -maxRadius; dx <= maxRadius; ++dx) {

            float floatDx = float(dx);
            float dxSq = floatDx * floatDx;
            float distSq = dxSq + dySq;

            // Skip if distance is already too great (optimization)
            if (distSq > maxLengthSq) { continue; }

            vec2 checkPixelCoord = currentPixelCoord + vec2(floatDx/2, floatDy * 2);
            vec4 checkColor = textureLookupPixel(checkPixelCoord);

            if (isColorMatch(checkColor)) {
                // Original Kage logic: Only check if it's closer
                if (distSq < minDistSq) {
                    minDistSq = distSq;
                }
            }
        }
    }

    // Only return a valid distance if we found a match within range
    // Kage logic: Check minDistSq is <= maxLengthSq AND > 0 (although > 0 is implicit if found)
    if (minDistSq <= maxLengthSq) { // Simplified: Kage checks > 0 && <= max, but if <= max it must have been updated from > max, so >0 is implied.
        return minDistSq;
    }

    return -1.0;
}

// Creates the flame color based on distance from the source
vec4 createFlameEffect(vec2 currentPixelCoord, float distSq) {
    vec3 color = vec3(0.0);

    // Animation factor based on time and position
    float anim = sin(Time * 9.42477 + currentPixelCoord.x * 1.3183 + currentPixelCoord.y * 0.1771);
    float color_anim = 0.1 + 1.5 * anim;

    float normDist = sqrt(distSq) / ExhaustLength;
    normDist += normDist * color_anim;

    float phase = clamp(normDist, 0.0, 1.0);// Keep phase within 0-1 for color mixing
    if (phase > anim + 0.75) {
        return vec4(0.0);// No flame effect if phase is too high
    }

    // 5-Color Gradient (4 segments)
    const float segLen = 0.25;// 1.0 / 4 segments
    if (phase < segLen) { // 0.0 to 0.25
        float localPhase = phase / segLen;
        color = mix(Color0, Color1, localPhase);
    } else if (phase < segLen * 2.0) { // 0.25 to 0.5
        float localPhase = (phase - segLen) / segLen;
        color = mix(Color1, Color2, localPhase);
    } else if (phase < segLen * 3.0) { // 0.5 to 0.75
        float localPhase = (phase - segLen * 2.0) / segLen;
        color = mix(Color2, Color3, localPhase);
    } else { // 0.75 to 1.0
        float localPhase = (phase - segLen * 3.0) / segLen;
        color = mix(Color3, Color4, localPhase);
    }

    // Alpha fades out with distance
    float alpha = clamp(1.0 - normDist/2, 0.0, 1.0);
    //    float i = (color.r + color.g + color.b) / 1.0;
    //    if (alpha > i) { alpha = i; }

    return vec4(color, alpha);
}

void main() {
    vec2 currentPixelCoord = FlutterFragCoord().xy;
    vec4 currentColor = textureLookupPixel(currentPixelCoord);

    // Check if the current pixel IS the target color (and not transparent)
    if (isColorMatch(currentColor)) {
        // Render target pixels directly using Color0 and fixed alpha
        fragColor = vec4(Color0, 0.8);
        return;
    }

    // If not the target, check if we're in an exhaust area OF a nearby target
    // Only check if the current pixel is transparent or very dim alpha
    if (currentColor.a < 0.1) {
        float distSq = checkExhaustArea(currentPixelCoord);
        if (distSq >= 0.0) { // Check against >= 0 as distSq can be 0
            // Calculate flame effect
            vec4 flameColor = createFlameEffect(currentPixelCoord, distSq);
            if (flameColor.a > 0.01) { // Only draw if flame has some alpha
                // Blend flame over transparent background
                fragColor = flameColor;
                return;
            }
        }
    }

    // Otherwise, return the original pixel color (handles non-target, non-exhaust areas)
    fragColor = currentColor;

    //    fragColor.xyz *= fragColor.a; // Premultiply alpha
}
