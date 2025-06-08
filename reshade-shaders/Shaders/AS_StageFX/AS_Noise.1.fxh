/**
 * AS_Noise.1.fxh - Procedural Noise Library for AS StageFX Shader Collection
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This header file provides procedural noise functions used across the AS StageFX
 * shader collection. It includes various noise algorithms, hash functions, and
 * procedural pattern generators for creating organic textures and effects.
 *
 * FEATURES:
 * - Fast hash functions for consistent pseudo-random number generation
 * - Perlin noise implementation with 2D variants
 * - FBM (Fractal Brownian Motion) noise functions for natural textures
 * - Domain warping techniques for complex fluid-like patterns
 * - Voronoi/cellular noise for cell-like patterns
 * - Animated variants of all noise functions
 *
 * IMPLEMENTATION OVERVIEW:
 * This file is organized in sections:
 * 1. Hash functions for random number generation
 * 2. Basic noise algorithms (Value, Perlin)
 * 3. Advanced noise algorithms (FBM, Domain Warping)
 * 4. Specialized patterns (Voronoi/cellular)
 * 5. Animated versions of all noise types
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_Noise_1_fxh
#define __AS_Noise_1_fxh

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// HASH FUNCTIONS
// ============================================================================

// --- Fast Hash Functions ---
// 1D->1D hash
float AS_hash11(float p) {
    p = frac(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

// 2D->1D hash
float AS_hash21(float2 p) {
    float3 p3 = frac(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

// 1D->2D hash
float AS_hash12(float2 p) {
    // Simple dot product version
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// 2D->1D visual noise function - gives more random looking/contrasting results than hash21
// Particularly useful for jittering/dithering type effects
float AS_randomNoise21(float2 p) {
    // Using trig functions for more visual randomness
    return frac(dot(sin(p * 752.322 + p.yx * 653.842), float2(254.652, 254.652)));
}

// 2D->2D hash
float2 AS_hash22(float2 p) {
    float3 p3 = frac(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.xx + p3.yz) * p3.zy);
}

float3 AS_hash33(float3 p3) {
    p3 = frac(p3 * float3(0.1031, 0.11369, 0.13787)); // Magic numbers from Inigo Quilez
    p3 += dot(p3, p3.yxz + 19.19);
    return -1.0 + 2.0 * frac(float3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

// --- Shadertoy Compatible Hash Functions ---
// These provide exact compatibility with common Shadertoy implementations

// Shadertoy-style 2D->2D hash (used in QuadtreeTruchet and other ported shaders)
float2 AS_Hash22VariantB(float2 p) {
    float n = sin(dot(p, float2(57, 27)));
    return frac(float2(262144, 32768) * n);
}

// ============================================================================
// VALUE NOISE
// ============================================================================

// --- Value Noise ---
// 2D Value noise (simplified)
float AS_valueNoise2D(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    
    // Four corners in 2D of a tile
    float a = AS_hash21(i);
    float b = AS_hash21(i + float2(1.0, 0.0));
    float c = AS_hash21(i + float2(0.0, 1.0));
    float d = AS_hash21(i + float2(1.0, 1.0));

    // Cubic Hermine curve for smooth interpolation
    float2 u = f * f * (3.0 - 2.0 * f);
    
    // Mix 4 corners
    return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Animatable version of Value noise
float AS_valueNoise2DA(float2 p, float time) {
    return AS_valueNoise2D(p + time);
}

// ============================================================================
// PERLIN NOISE
// ============================================================================

// --- Perlin Noise ---
// Classic 2D Perlin noise
float AS_PerlinNoise2D(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    
    // Quintic interpolation curve
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    // Get random vectors at the corners
    float2 ga = AS_hash22(i) * 2.0 - 1.0;
    float2 gb = AS_hash22(i + float2(1.0, 0.0)) * 2.0 - 1.0;
    float2 gc = AS_hash22(i + float2(0.0, 1.0)) * 2.0 - 1.0;
    float2 gd = AS_hash22(i + float2(1.0, 1.0)) * 2.0 - 1.0;
    
    // Calculate dot products
    float va = dot(ga, f);
    float vb = dot(gb, f - float2(1.0, 0.0));
    float vc = dot(gc, f - float2(0.0, 1.0));
    float vd = dot(gd, f - float2(1.0, 1.0));
    
    // Interpolate the four corners
    return va + u.x * (vb - va) + u.y * (vc - va) + u.x * u.y * (va - vb - vc + vd);
}

// Animatable version of Perlin noise
float AS_PerlinNoise2DA(float2 p, float time) {
    return AS_PerlinNoise2D(p + time);
}

// --- Perlin Noise 3D ---
// Classic 3D Perlin noise implementation
float AS_PerlinNoise3D(float3 p) {
    float3 i = floor(p);
    float3 f = frac(p);
    
    // Quintic interpolation curve
    float3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    // Calculate grid point coordinate hashes
    float n000 = dot(AS_hash33(i), f);
    float n100 = dot(AS_hash33(i + float3(1.0, 0.0, 0.0)), f - float3(1.0, 0.0, 0.0));
    float n010 = dot(AS_hash33(i + float3(0.0, 1.0, 0.0)), f - float3(0.0, 1.0, 0.0));
    float n110 = dot(AS_hash33(i + float3(1.0, 1.0, 0.0)), f - float3(1.0, 1.0, 0.0));
    float n001 = dot(AS_hash33(i + float3(0.0, 0.0, 1.0)), f - float3(0.0, 0.0, 1.0));
    float n101 = dot(AS_hash33(i + float3(1.0, 0.0, 1.0)), f - float3(1.0, 0.0, 1.0));
    float n011 = dot(AS_hash33(i + float3(0.0, 1.0, 1.0)), f - float3(0.0, 1.0, 1.0));
    float n111 = dot(AS_hash33(i + float3(1.0, 1.0, 1.0)), f - float3(1.0, 1.0, 1.0));
    
    // Interpolate along x
    float nx00 = lerp(n000, n100, u.x);
    float nx01 = lerp(n001, n101, u.x);
    float nx10 = lerp(n010, n110, u.x);
    float nx11 = lerp(n011, n111, u.x);
    
    // Interpolate along y
    float nxy0 = lerp(nx00, nx10, u.y);
    float nxy1 = lerp(nx01, nx11, u.y);
    
    // Interpolate along z and normalize output to [-1, 1] range
    return lerp(nxy0, nxy1, u.z) * 0.5 + 0.5;
}

// Animatable version of 3D Perlin noise
float AS_PerlinNoise3DA(float3 p, float time) {
    // Add time to z-coordinate for smooth animation
    return AS_PerlinNoise3D(p + float3(0.0, 0.0, time));
}

// ============================================================================
// FBM (FRACTAL BROWNIAN MOTION)
// ============================================================================

// --- Fractal Brownian Motion ---
// FBM builds on top of Perlin noise to create natural-looking textures
float AS_Fbm2D(float2 p, int octaves, float lacunarity, float gain) {
    float sum = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    // Prevent zero or negative octaves
    octaves = max(octaves, 1);
    
    for(int i = 0; i < octaves; i++) {
        sum += amp * AS_PerlinNoise2D(p * freq);
        freq *= lacunarity;
        amp *= gain;
    }
    
    return sum;
}

// Simplified FBM with default parameters
float AS_Fbm2D(float2 p) {
    return AS_Fbm2D(p, 5, 2.0, 0.5);
}

// Animated version of FBM
float AS_Fbm2DA(float2 p, float time, int octaves, float lacunarity, float gain) {
    float sum = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    // Prevent zero or negative octaves
    octaves = max(octaves, 1);
    
    for(int i = 0; i < octaves; i++) {
        // Add time-based motion with different speeds per octave for more organic movement
        float2 offset = float2(time * 0.4 * (1.0 - 0.2 * i), time * 0.3 * (1.0 - 0.2 * i));
        sum += amp * AS_PerlinNoise2D((p + offset) * freq);
        freq *= lacunarity;
        amp *= gain;
    }
    
    return sum;
}

// Simplified animated FBM with default parameters
float AS_Fbm2DA(float2 p, float time) {
    return AS_Fbm2DA(p, time, 5, 2.0, 0.5);
}

// ============================================================================
// DOMAIN WARPING
// ============================================================================

// --- Domain Warping ---
// Domain warping creates complex fluid-like patterns by deforming the coordinate space
float2 AS_DomainWarp2D(float2 p, float intensity, float scale) {
    // First layer of deformation
    float2 offset1 = float2(
        AS_PerlinNoise2D(p * scale),
        AS_PerlinNoise2D(p * scale + float2(5.2, 1.3))
    );
    
    // Second layer using deformed coordinates for more complexity
    float2 offset2 = float2(
        AS_PerlinNoise2D((p + offset1 * intensity * 0.5) * scale * 2.0),
        AS_PerlinNoise2D((p + offset1 * intensity * 0.5) * scale * 2.0 + float2(9.8, 3.7))
    );
    
    // Return warped coordinates
    return p + offset2 * intensity;
}

// Sample Perlin noise with domain warping applied
float AS_DomainWarpedNoise2D(float2 p, float intensity, float scale) {
    float2 warped = AS_DomainWarp2D(p, intensity, scale);
    return AS_PerlinNoise2D(warped);
}

// Animated domain warping
float2 AS_DomainWarp2DA(float2 p, float time, float intensity, float scale) {
    // First layer of deformation with time
    float2 offset1 = float2(
        AS_PerlinNoise2DA(p * scale, time * 0.3),
        AS_PerlinNoise2DA(p * scale + float2(5.2, 1.3), time * 0.4)
    );
    
    // Second layer using deformed coordinates for more complexity
    float2 offset2 = float2(
        AS_PerlinNoise2DA((p + offset1 * intensity * 0.5) * scale * 2.0, time * 0.5),
        AS_PerlinNoise2DA((p + offset1 * intensity * 0.5) * scale * 2.0 + float2(9.8, 3.7), time * 0.6)
    );
    
    // Return warped coordinates
    return p + offset2 * intensity;
}

// Sample Perlin noise with animated domain warping applied
float AS_DomainWarpedNoise2DA(float2 p, float time, float intensity, float scale) {
    float2 warped = AS_DomainWarp2DA(p, time, intensity, scale);
    return AS_PerlinNoise2D(warped);
}

// ============================================================================
// VORONOI / CELLULAR NOISE
// ============================================================================

// --- Voronoi Noise ---
// Cellular/Voronoi noise creates cell-like patterns
float AS_voronoiNoise2D(float2 p, out float2 cellPoint) {
    float2 i = floor(p);
    float2 f = frac(p);
    
    float minDist = 8.0; // Initialize with a large distance
    cellPoint = float2(0, 0);
    
    // Search in 3x3 neighborhood for the closest feature point
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            float2 neighbor = float2(x, y);
            float2 point1 = AS_hash22(i + neighbor);
            
            // Randomize position within the cell
            float2 diff = neighbor + point1 - f;
            float dist = length(diff);
            
            if(dist < minDist) {
                minDist = dist;
                cellPoint = point1;
            }
        }
    }
    
    return minDist;
}

// Simplified version without returning cell point
float AS_voronoiNoise2D(float2 p) {
    float2 cellPoint;
    return AS_voronoiNoise2D(p, cellPoint);
}

// Advanced Voronoi with distance and cell color
float4 AS_voronoiNoise2D_Detailed(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    
    float minDist = 8.0;  // Distance to closest point
    float2 minPoint = float2(0, 0);  // Closest point
    float minPointID = 0.0;  // Identifier for closest point (for coloring)
    
    // Search in 3x3 neighborhood for the closest feature point
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            float2 neighbor = float2(x, y);
            float2 point = AS_hash22(i + neighbor);
            
            // Randomize position within the cell
            float2 diff = neighbor + point - f;
            float dist = length(diff);
            
            if(dist < minDist) {
                minDist = dist;
                minPoint = point;
                // Use a hash of the cell coordinates as a unique cell identifier
                minPointID = AS_hash21(i + neighbor);
            }
        }
    }
    
    // Return distance, cell point, and cell ID
    return float4(minDist, minPoint, minPointID);
}

// Animated Voronoi
float AS_VoronoiNoise2DA(float2 p, float time) {
    // Add a time-based offset to the points within cells
    float2 i = floor(p);
    float2 f = frac(p);
    
    float minDist = 8.0;
    
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            float2 neighbor = float2(x, y);
            
            // Get the base point
            float2 point = AS_hash22(i + neighbor);
            
            // Add time animation (circular motion within cells)
            float angle = time * AS_TWO_PI * (0.5 + 0.5 * AS_hash21(i + neighbor));
            float radius = 0.3 * AS_hash21(i + neighbor + 5.33);
            point += radius * float2(cos(angle), sin(angle));
            
            // Calculate distance
            float2 diff = neighbor + point - f;
            float dist = length(diff);
            
            if(dist < minDist) {
                minDist = dist;
            }
        }
    }
    
    return minDist;
}

// ============================================================================
// TURBULENCE & PATTERN VARIATIONS
// ============================================================================

// --- Turbulence ---
// Absolute value of Perlin noise creates ridge-like patterns
float AS_TurbulenceNoise2D(float2 p, int octaves, float lacunarity, float gain) {
    float sum = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    octaves = max(octaves, 1);
    
    for(int i = 0; i < octaves; i++) {
        sum += amp * abs(AS_PerlinNoise2D(p * freq) * 2.0 - 1.0);
        freq *= lacunarity;
        amp *= gain;
    }
    
    return sum;
}

// Simplified turbulence with default parameters
float AS_TurbulenceNoise2D(float2 p) {
    return AS_TurbulenceNoise2D(p, 5, 2.0, 0.5);
}

// --- Ridge Noise ---
// A variant of turbulence that creates sharp ridges
float AS_RidgeNoise2D(float2 p, int octaves, float lacunarity, float gain, float offset) {
    float sum = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    float prev = 1.0;
    octaves = max(octaves, 1);
    
    for(int i = 0; i < octaves; i++) {
        float n = 1.0 - abs(AS_PerlinNoise2D(p * freq) * 2.0 - 1.0);
        n = n * n; // Sharpen the ridges
        sum += amp * n * prev;
        prev = n;
        freq *= lacunarity;
        amp *= gain;
    }
    
    return sum;
}

// Simplified ridge noise with default parameters
float AS_RidgeNoise2D(float2 p) {
    return AS_RidgeNoise2D(p, 5, 2.0, 0.5, 1.0);
}

// ============================================================================
// SPECIALIZED PATTERNS
// ============================================================================

// --- Wood Grain Pattern ---
float AS_WoodPattern(float2 p, float rings, float turbulence) {
    // Create base ring pattern
    float distFromCenter = length(p);
    float basePattern = frac(distFromCenter * rings);
    
    // Add turbulence if requested
    if (turbulence > 0.0) {
        basePattern += turbulence * AS_PerlinNoise2D(p * 3.0) * 0.1;
    }
    
    // Create wood grain effect
    return basePattern;
}

// --- Wave Pattern ---
float AS_WavePattern(float2 p, float frequency, float amplitude, float phase) {
    return sin(dot(p, float2(0.0, 1.0)) * frequency + phase) * amplitude;
}

// --- Cloud Pattern ---
float AS_CloudPattern(float2 p, float coverage, float sharpness) {
    // Use FBM for cloud shapes
    float n = AS_Fbm2D(p);
    
    // Apply sharpness and coverage control
    return saturate(pow(n + coverage, sharpness));
}

// Animated cloud pattern
float AS_CloudPatternA(float2 p, float time, float coverage, float sharpness) {
    // Use animated FBM for moving clouds
    float n = AS_Fbm2DA(p, time);
    
    // Apply sharpness and coverage control
    return saturate(pow(n + coverage, sharpness));
}

// --- Marble Pattern ---
float AS_MarblePattern(float2 p, float scale, float sharpness) {
    float n = AS_PerlinNoise2D(p) * scale;
    return saturate(pow(0.5 + 0.5 * sin(p.x + n), sharpness));
}

// Animated marble pattern
float AS_MarblePatternA(float2 p, float time, float scale, float sharpness) {
    // Add time-based movement
    p.y += time * 0.1;
    float n = AS_PerlinNoise2D(p) * scale;
    return saturate(pow(0.5 + 0.5 * sin(p.x + n), sharpness));
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

// --- Map noise range ---
// Remap a noise value from [-1,1] to [0,1]
float AS_remapNoiseZeroToOne(float noise) {
    return 0.5 + 0.5 * noise;
}

// --- Octave noise mixer ---
// Mix different octaves of noise with weights
float AS_MixNoiseOctaves(float2 p, float weight1, float weight2, float weight3, float weight4) {
    // Normalize weights
    float totalWeight = weight1 + weight2 + weight3 + weight4;
    if (totalWeight < 0.001) return 0.0;
    float invTotalWeight = 1.0 / totalWeight;
    
    // Mix octaves
    return (
        weight1 * AS_PerlinNoise2D(p) + 
        weight2 * AS_PerlinNoise2D(p * 2.0) + 
        weight3 * AS_PerlinNoise2D(p * 4.0) + 
        weight4 * AS_PerlinNoise2D(p * 8.0)
    ) * invTotalWeight;
}

// --- Noise octave selector ---
// Select a specific octave of Perlin noise
float AS_NoiseOctave(float2 p, int octave) {
    float freq = pow(2.0, float(octave));
    return AS_PerlinNoise2D(p * freq);
}

#endif // __AS_Noise_1_fxh

