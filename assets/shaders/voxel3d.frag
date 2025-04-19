#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Input texture (atlas)
uniform sampler2D uImageSrc0; 

// Uniforms mapping Kage 'var's
uniform mat4 uVoxelModelMatrixInverse;
uniform vec3 uLightDirection;
uniform vec2 uFrameSize; // Size of one frame/slice in the atlas
uniform float uFrames;   // Number of frames/slices
uniform int uRenderMode; // 0=Color, 1=Shadow, 2=Hit Highlight

// Uniforms replacing Kage built-ins
uniform vec2 uDstOrigin; // Corresponds to imageDstOrigin()
uniform vec2 uDstSize;   // Corresponds to imageDstSize()
uniform vec2 uSrcOrigin; // Corresponds to imageSrc0Origin()

out vec4 fragColor;

// --- Forward declarations ---
vec2 calculateScreenUV(vec2 fragCoord);
float random(vec2 st);
vec4 marchRay(vec3 startPos, vec3 localLightDirection);
vec4 sampleShadedVolume(vec3 posUnrotated);
vec4 volumeMap(vec3 pos);
bool isOutOfBounds(vec3 pos);
vec2 calculateAtlasUV(vec3 pos);
float calculateShadowFactor(vec3 pos, vec3 lightDirection);


// --- Main function ---
void main() {
	vec2 screenUV = calculateScreenUV(FlutterFragCoord().xy);
	float rnd = random(screenUV) * 0.0025;
	vec3 startPos = vec3(screenUV.x, screenUV.y, 0.5 + rnd); // Start slightly randomized in depth

	// Transform light direction to local space
	vec3 localLightDirection = normalize((uVoxelModelMatrixInverse * vec4(uLightDirection, 0.0)).xyz);

	// Return the result from the ray marching
	fragColor = marchRay(startPos, localLightDirection);
}

// --- Helper: Calculate normalized screen UV (-0.5 to 0.5) ---
vec2 calculateScreenUV(vec2 fragCoord) {
	// Kage: (fragCoord - imageDstOrigin()) / imageDstSize() - 0.5
	vec2 uv = (fragCoord - uDstOrigin) / uDstSize - 0.5;
	return uv;
}

// --- Simple pseudo-random noise based on screen position ---
float random(vec2 st) {
	// Kage: fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123)
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// --- Core: March a ray and accumulate color ---
vec4 marchRay(vec3 pos, vec3 lightDirection) {
	vec4 accumulatedColor = vec4(0.0); // Premultiplied alpha
	int accumulations = 0;

	const int numSteps = 128;
	const float stepSize = 1.0 / float(numSteps);

	for (int i = 0; i < numSteps; i++) {
		vec4 baseColor = sampleShadedVolume(pos);

		if (baseColor.a > 0.0) {
			if (uRenderMode == 0) { // Color Mode
                vec3 rotatedScaledPos = (uVoxelModelMatrixInverse * vec4(pos, 1.0)).xyz;
				float shadowFactor = calculateShadowFactor(rotatedScaledPos, lightDirection);
				baseColor.rgb *= shadowFactor; // Apply shadow

				if (baseColor.a == 1.0) { // Fully opaque voxel hit
					if (accumulations > 0) {
                        // Blend current opaque color with accumulated semi-transparent colors behind it
						accumulatedColor /= float(accumulations); // Average accumulated colors
                        float a = (1.0 - accumulatedColor.a) / float(accumulations); // Calculate blend factor based on transparency gap
						baseColor.rgb *= a; // Apply blend factor to opaque color
						accumulatedColor.rgb *= (1.0 - a); // Apply inverse blend factor to accumulated color
						accumulatedColor.a = 1.0; // Result is now opaque
						fragColor = accumulatedColor + baseColor;
						return fragColor;
					} else {
                        // First hit is opaque, just return its color
						fragColor = baseColor;
						return fragColor;
					}
				} else {
					// Accumulate semi-transparent color
                    accumulatedColor += baseColor;
					accumulations++;
				}
			} else if (uRenderMode == 1) { // Shadow Mode
				fragColor = vec4(0.0, 0.0, 0.0, 0.5); // Simple shadow representation
				return fragColor;
			} else if (uRenderMode == 2) { // Hit Highlight Mode
				fragColor = vec4(1.0); // Highlight color
				return fragColor;
			}
		}

		pos.z -= stepSize; // Move ray deeper into the volume
		if (pos.z < -0.5) { // Stop if ray exits the back of the volume
			break;
		}
	}

	if (accumulations > 0) {
        // If we finished marching without hitting an opaque voxel, average the accumulated colors
		accumulatedColor /= float(accumulations);
        fragColor = accumulatedColor;
		return fragColor;
	}

	fragColor = vec4(0.0); // No voxels hit
    return fragColor;
}

// --- Core: Sample volume and apply shadow ---
vec4 sampleShadedVolume(vec3 posUnrotated) {
    // Transform position using the inverse model matrix to get local coordinates
	vec3 rotatedScaledPos = (uVoxelModelMatrixInverse * vec4(posUnrotated, 1.0)).xyz;
	// Sample the volume texture at the local coordinates
	return volumeMap(rotatedScaledPos);
}

// --- Core: Sample the 3D volume texture atlas ---
vec4 volumeMap(vec3 pos) {
	if (isOutOfBounds(pos)) {
		return vec4(0.0); // Return transparent black if outside the standard -0.5 to 0.5 cube
	}
	vec2 uv = calculateAtlasUV(pos); // Calculate UV in the texture atlas
	// Kage: imageSrc0At(uv)
	return texture(uImageSrc0, uv); // Sample the texture
}

// --- Helper: Check if position is within the standard -0.5 to 0.5 cube ---
bool isOutOfBounds(vec3 pos) {
	return pos.x < -0.5 || pos.x > 0.5 ||
		   pos.y < -0.5 || pos.y > 0.5 ||
		   pos.z < -0.5 || pos.z > 0.5;
}

// --- Helper: Calculate texture UV coordinates from a local position ---
vec2 calculateAtlasUV(vec3 pos) {
	// Kage: uv = imageSrc0Origin()
	vec2 uv = uSrcOrigin; 
    // Kage: uv.x += (pos.x + 0.5) * FrameSize.x
	uv.x += (pos.x + 0.5) * uFrameSize.x;
    // Kage: uv.y += (pos.z + 0.5) * FrameSize.y
	uv.y += (pos.z + 0.5) * uFrameSize.y;
	// Kage: slice = floor((pos.y + 0.5) * Frames)
    // Calculate the slice index based on the y-coordinate (depth in original model space)
	float slice = floor((pos.y + 0.5) * uFrames);
    // Kage: offset = slice * FrameSize.y
    // Calculate the vertical offset in the atlas for the current slice
	float offset = slice * uFrameSize.y;
    // Kage: uv.y += offset
	uv.y += offset;
	return uv; // Return the calculated UV coordinates
}

// --- Helper: Calculate the shadow factor based on light direction ---
float calculateShadowFactor(vec3 pos, vec3 lightDirection) {
	const float stepSize = 1.0 / 64.0; // Smaller step size for shadow calculation
	vec3 shadowOffset = lightDirection * stepSize; // Step direction along the light ray

	const int numSteps = 16; // Number of steps to check for occlusion
	const float darknessMin = 0.8; // Minimum shadow intensity (higher value means lighter shadow)
	const float darknessStep = (1.0 - darknessMin) / float(numSteps); // How much darkness increases per step
	float darkness = darknessMin; // Start with minimum darkness

	bool hitBefore = false; // Flag to track if a voxel has been hit along the shadow ray
	for (int i = 0; i < numSteps; i++) {
		pos -= shadowOffset; // Step backwards along the light direction
		if (volumeMap(pos).a > 0.0) { // Check if this position hits a voxel
            if (hitBefore) {
                // If we've already hit a voxel further along the light ray, this point is fully shadowed
                return darkness; 
            }
            hitBefore = true; // Mark that we've hit a voxel
		}
		darkness += darknessStep; // Gradually increase darkness (lighten shadow) as we step further
	}

	return 1.0; // If no voxel was hit along the shadow ray, the point is fully lit
} 