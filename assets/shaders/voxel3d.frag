#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Input texture (atlas)
uniform sampler2D uImageSrc0;

// Uniforms replacing Kage built-ins
uniform vec2 uDstOrigin;// Corresponds to imageDstOrigin()
uniform vec2 uDstSize;// Corresponds to imageDstSize()
uniform vec2 uSrcOrigin;// Corresponds to imageSrc0Origin()
uniform vec2 uAtlasSize;// Total size of the atlas texture (pixels)

// Uniforms mapping Kage 'var's
uniform float uFrames;// Number of frames/slices
uniform vec2 uFrameSize;// Size of one frame/slice in the atlas
uniform mat4 uVoxelModelMatrixInverse;
uniform vec3 uLightDirection;

uniform float uRenderMode;// USE float INSTEAD OF int FOR IMPELLER

out vec4 fragColor;

// --- Forward declarations - RESTORED ---
vec2 calculateScreenUV(vec2 fragCoord);
float random(vec2 st);
vec4 marchRay(vec3 pos, vec3 lightDirection);
vec4 sampleShadedVolume(vec3 posUnrotated);
vec4 volumeMap(vec3 pos);
bool isOutOfBounds(vec3 pos);
vec2 calculateAtlasUV(vec3 pos);
float calculateShadowFactor(vec3 pos, vec3 lightDirection);

// Debug Colors for Cube Faces
const vec4 CUBE_RIGHT = vec4(1.0, 0.0, 0.0, 0.1); // +X Red
const vec4 CUBE_LEFT = vec4(0.0, 1.0, 1.0, 0.1); // -X Cyan
const vec4 CUBE_TOP = vec4(0.0, 1.0, 0.0, 0.1); // +Y Green
const vec4 CUBE_BOTTOM = vec4(1.0, 0.0, 1.0, 0.1); // -Y Magenta
const vec4 CUBE_BACK = vec4(1.0, 1.0, 0.0, 0.1); // -Z Yellow
const vec4 CUBE_FRONT = vec4(1.0, 1.0, 1.0, 0.1); // +Z White
const vec4 CUBE_NONE = vec4(0.0, 0.0, 0.0, 0.1); // Black (Should not happen)

// Debug Colors for Cube Faces/Final Position
const vec4 POS_X_NEG = vec4(0.0, 1.0, 1.0, 1.0);// -X Cyan
const vec4 POS_X_POS = vec4(1.0, 0.0, 0.0, 1.0);// +X Red
const vec4 POS_Y_NEG = vec4(1.0, 0.0, 1.0, 1.0);// -Y Magenta
const vec4 POS_Y_POS = vec4(0.0, 1.0, 0.0, 1.0);// +Y Green
const vec4 POS_Z_NEG = vec4(1.0, 1.0, 0.0, 1.0);// -Z Yellow
const vec4 POS_Z_POS = vec4(1.0, 1.0, 1.0, 1.0);// +Z White (Unlikely)
const vec4 POS_INSIDE = vec4(0.5, 0.5, 0.5, 1.0);// Gray

// Procedural sphere color
const vec4 SPHERE_COLOR = vec4(0.2, 0.2, 0.2, 1.0); // Dark Gray

// --- Main function - RESTORED ---
void main() {
	vec2 uv = FlutterFragCoord().xy;
    vec2 screenUV = calculateScreenUV(FlutterFragCoord().xy);
    float rnd = 0; // random(screenUV) * 0.0025;
    vec3 startPos = vec3(screenUV.x, screenUV.y, 0.5 + rnd);// Start slightly randomized in depth

    // Transform light direction to local space - NOT NEEDED FOR FIXED RAY
    // vec3 localLightDirection = normalize((uVoxelModelMatrixInverse * vec4(uLightDirection, 0.0)).xyz);

    // Return the result from the ray marching - Pass only startPos
    fragColor = marchRay(startPos, uLightDirection);

    // Flutter needs premultiplied alpha in output:
    fragColor.xyz *= fragColor.a;

    // DEBUG - KEEP!!! - SHOW OUR 0.5 RADIUS FOR UV!
//    float l = length(screenUV);
//    if (l > 0.5) {
//        fragColor *= 0.5;
//        fragColor.a = 0.2;
//    }
}

// --- Helper: Calculate normalized screen UV (-0.5 to 0.5) - RESTORED ---
vec2 calculateScreenUV(vec2 fragCoord) {
    return (fragCoord - uDstOrigin) / uDstSize - 0.5;
}

// --- Simple pseudo-random noise based on screen position - RESTORED ---
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// --- Core: March a ray, check sphere/texture first, then cube boundaries ---
vec4 marchRay(vec3 pos, vec3 lightDirection) { // lightDirection still unused
	const int numSteps = 128;
	const float stepSize = 2.0 / float(numSteps); // Keep increased step size from user change

	for (int i = 0; i < numSteps; i++) {
        // 1. Check for hit on procedural sphere OR texture AT CURRENT view-space position
        // sampleShadedVolume will return sphere color, texture color, or transparent black.
        vec4 baseColor = sampleShadedVolume(pos); 
        if (baseColor.a > 0.0) {
            // Return sphere color OR texture color immediately if hit
            return baseColor; 
        }

        // 2. If sphere/texture NOT hit, check cube boundaries in LOCAL space
//        vec3 localPos = (uVoxelModelMatrixInverse * vec4(pos, 1.0)).xyz;
//        if (localPos.x > 0.5) return CUBE_RIGHT;
//        if (localPos.x < -0.5) return CUBE_LEFT;
//        if (localPos.y > 0.5) return CUBE_TOP;
//        if (localPos.y < -0.5) return CUBE_BOTTOM;
//        if (localPos.z < -0.5) return CUBE_BACK;
//        if (localPos.z > 0.5) return CUBE_FRONT;

		// 3. Step the VIEW-SPACE ray further back along the Z axis
		pos.z -= stepSize;
	}

	// If the loop finishes without hitting the sphere, texture, OR a boundary
    return CUBE_NONE; // Black
}

// --- Core: Sample volume - Check sphere in view space FIRST ---
vec4 sampleShadedVolume(vec3 posUnrotated) {
    // 1. Check for sphere hit in VIEW SPACE first
    if (length(posUnrotated) < 0.2) {
        // Return sphere color based on VIEW SPACE position
        return vec4(posUnrotated * 2.5 + 0.5, 1.0);
    }

    // 2. If not in sphere, transform to local space for texture lookup
	vec3 localPos = (uVoxelModelMatrixInverse * vec4(posUnrotated, 1.0)).xyz;

    // 3. Call volumeMap (which now only does texture lookup)
    // Skip isOutOfBounds for simplicity during debug
	// if (isOutOfBounds(localPos)) {
    //     return vec4(0.0);
    // }
	return volumeMap(localPos);
}

// --- Core: VolumeMap - Texture Lookup ONLY ---
vec4 volumeMap(vec3 pos) {
    /* // Sphere check REMOVED from here
    if (length(pos) < 0.2) {
        return vec4(pos * 2.5 + 0.5, 1.0);
    }
    */

    // Restore texture lookup logic
	vec2 uv = calculateAtlasUV(pos);
	vec4 textureColor = texture(uImageSrc0, uv);

    // Return texture color (or transparent)
    return textureColor;
}

// --- Helper: Check if position is within the standard -0.5 to 0.5 cube - RESTORED ---
bool isOutOfBounds(vec3 pos) {
    return pos.x < -0.5 || pos.x > 0.5 ||
    pos.y < -0.5 || pos.y > 0.5 ||
    pos.z < -0.5 || pos.z > 0.5;
}

// --- Helper: Calculate texture UV coordinates from a local position - RESTORED ---
vec2 calculateAtlasUV(vec3 pos) {
    // Clamp input position to the expected [-0.5, 0.5] range before calculations
    pos = clamp(pos, -0.5, 0.5);

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

// --- Helper: Calculate the shadow factor based on light direction - RESTORED ---
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
