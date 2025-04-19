#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform sampler2D uImageSrc0;// Input texture (atlas)

uniform vec2 uDstOrigin;// Corresponds to imageDstOrigin() in kage
uniform vec2 uDstSize;// Corresponds to imageDstSize() in kage
uniform vec2 uSrcOrigin;// Corresponds to imageSrc0Origin() in kage
uniform vec2 uAtlasSize;// Total size of the atlas texture (pixels)

uniform float uFrames;// Number of frames/slices
uniform vec2 uFrameSize;// Size of one frame/slice in the atlas

uniform mat4 uVoxelModelMatrixInverse;// TODO: Good comment here!
uniform vec3 uLightDirection;

uniform float uRenderMode;// Legacy: 0 model, 1 white/hit, 2, black/shadow

out vec4 fragColor;

vec2 calculateScreenUV(vec2 fragCoord);
float random(vec2 st);
vec4 marchRay(vec3 pos, vec3 lightDirection);
vec4 sampleShadedVolume(vec3 posUnrotated);
vec4 volumeMap(vec3 pos);
bool isOutOfBounds(vec3 pos);
vec2 calculateAtlasUV(vec3 pos);
float calculateShadowFactor(vec3 pos, vec3 lightDirection);

void main() {
    vec2 uv = FlutterFragCoord().xy;
    vec2 screenUV = calculateScreenUV(FlutterFragCoord().xy);

    // Start slightly randomized in depth: (Attempted fix for shading noise. Working only badly.)
    float rnd = random(screenUV) * 0.0025;
    vec3 startPos = vec3(screenUV.x, screenUV.y, 0.5 + rnd);

    // Transform light direction to local space - NOT NEEDED FOR FIXED RAY
    // vec3 localLightDirection = normalize((uVoxelModelMatrixInverse * vec4(uLightDirection, 0.0)).xyz);

    // Return the result from the ray marching - Pass only startPos
    fragColor = marchRay(startPos, uLightDirection);

    // Flutter needs premultiplied alpha in output:
    fragColor.xyz *= fragColor.a;
}

// --- Helper: Calculate normalized screen UV (-0.5 to 0.5) ---
vec2 calculateScreenUV(vec2 fragCoord) {
    return (fragCoord - uDstOrigin) / uDstSize - 0.5;
}

// --- Simple pseudo-random noise based on screen position ---
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec4 marchRay(vec3 pos, vec3 lightDirection) { // TODO: lightDirection still unused
    const int numSteps = 128;
    const float stepSize = 1.0 / float(numSteps);// Keep increased step size from user change

    for (int i = 0; i < numSteps; i++) {
        // Check for hit on texture AT CURRENT view-space position.
        // sampleShadedVolume will return texture color, or transparent.
        vec4 baseColor = sampleShadedVolume(pos);
        if (baseColor.a > 0.0) { return baseColor; }

        // Step the VIEW-SPACE ray further back along the Z axis
        pos.z -= stepSize;
    }

    // If the loop finishes without hitting the sphere, texture, OR a boundary
    return vec4(0);
}

// --- Core: Sample volume ---
vec4 sampleShadedVolume(vec3 posUnrotated) {
    // Transform position using the inverse model matrix to get local coordinates
    vec3 localPos = (uVoxelModelMatrixInverse * vec4(posUnrotated, 1.0)).xyz;

    // Restore bounds check
    if (isOutOfBounds(localPos)) {
        return vec4(0.0);
    }
    // Call volumeMap (which now only does texture lookup)
    return volumeMap(localPos);
}

// --- Core: VolumeMap - Texture Lookup ONLY ---
vec4 volumeMap(vec3 pos) {
    // Restore texture lookup logic ONLY
    vec2 uv = calculateAtlasUV(pos);
    vec4 textureColor = texture(uImageSrc0, uv);

    // Return texture color (or transparent)
    return textureColor;
}

// --- Helper: Check if position is within the standard -0.5 to 0.5 cube  ---
bool isOutOfBounds(vec3 pos) {
    return pos.x < -0.5 || pos.x > 0.5 ||
    pos.y < -0.5 || pos.y > 0.5 ||
    pos.z < -0.5 || pos.z > 0.5;
}

// --- Helper: Calculate texture UV coordinates from a local position  ---
vec2 calculateAtlasUV(vec3 pos) {
    vec2 pixel_uv;
    pixel_uv.x = (pos.x + 0.5) * uFrameSize.x;
    pixel_uv.y = (pos.z + 0.5) * uFrameSize.y;
    float slice = floor((pos.y + 0.5) * uFrames);
    float pixel_offset_y = slice * uFrameSize.y;
    pixel_uv.y += pixel_offset_y;
    pixel_uv += uSrcOrigin;
    vec2 atlasSize = uAtlasSize;
    return pixel_uv / atlasSize;
}

// --- Helper: Calculate the shadow factor based on light direction  ---
float calculateShadowFactor(vec3 pos, vec3 lightDirection) {
    const float stepSize = 1.0 / 64.0;
    vec3 shadowOffset = lightDirection * stepSize;
    const int numSteps = 16;
    const float darknessMin = 0.8;
    const float darknessStep = (1.0 - darknessMin) / float(numSteps);
    float darkness = darknessMin;
    bool hitBefore = false;
    for (int i = 0; i < numSteps; i++) {
        pos -= shadowOffset;
        if (volumeMap(pos).a > 0.0) {
            if (hitBefore) {
                return darkness;
            }
            hitBefore = true;
        }
        darkness += darknessStep;
    }
    return 1.0;
}

// --- UNUSED FUNCTIONS --- 
/*
float random(vec2 st) { ... }
vec4 marchRay(vec3 startPos, vec3 localLightDirection) { ... }
vec4 sampleShadedVolume(vec3 posUnrotated) { ... }
vec4 volumeMap(vec3 pos) { ... }
bool isOutOfBounds(vec3 pos) { ... }
vec2 calculateAtlasUV(vec3 pos) { ... }
float calculateShadowFactor(vec3 pos, vec3 lightDirection) { ... }
*/ 
