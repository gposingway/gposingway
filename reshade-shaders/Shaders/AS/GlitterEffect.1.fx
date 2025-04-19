/**
 * GlitterEffect.1.fx - Dynamic Sparkle Effect Shader Version 1.0 *
 * Copyright (c) 2025 Leon Aquitaine
 * MODIFIED: Default values and slider ranges adjusted per user settings.
 * NO OTHER FIXES APPLIED - Use original code base provided by user.
 *
 * This work is licensed under the Creative Commons Attribution 4.0 International License.
 * You are free to use, share, and adapt this shader for any purpose, including commercially,
 * as long as you provide attribution to the original author.
 *
 * To view a copy of this license, visit http://creativecommons.org/licenses/by/4.0/
 * or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader creates a realistic glitter/sparkle effect that dynamically responds
 * to scene lighting, depth, and camera movement. It simulates tiny reflective
 * particles that pop in, glow, and fade out, creating the appearance of sparkles
 * on surfaces.
 *
 * FEATURES:
 * - Multi-layered voronoi noise for natural sparkle distribution
 * - Dynamic sparkle animation with customizable lifetime
 * - Depth-based masking for placement control
 * - High-quality bloom with adjustable quality settings
 * - Normal-based fresnel effect for realistic light interaction
 * - Multiple blend modes and color options
 *
 * IMPLEMENTATION OVERVIEW:
 * This shader uses a multi-pass architecture:
 * 1. First Pass (PS_RenderSparkles): Generates the sparkle pattern and applies depth/normal-based effects
 * 2. Second Pass (PS_BloomH): Applies horizontal gaussian blur to create a bloom effect
 * 3. Third Pass (PS_BloomV): Applies vertical gaussian blur and blends the final result with the scene
 *
 * The separation of sparkle generation, bloom processing and blending allows for:
 * - Better performance optimization with targeted quality settings
 * - Cleaner debug visualizations
 * - More options for how the effect integrates with the scene
 *
 * HOW IT WORKS:
 * 1. The shader uses multiple layers of Voronoi noise at different scales to
 * generate the base sparkle pattern
 * 2. Each sparkle has its own lifecycle (fade in, sustain, fade out) based on
 * its position and the animation time
 * 3. Surface normals are reconstructed from the depth buffer to apply fresnel
 * effects, making sparkles appear more prominently at glancing angles
 * 4. A two-pass gaussian bloom is applied for a soft, natural glow effect
 * 5. Multiple blend modes allow for different integration with the scene
 *
 * ===================================================================================
 */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ListeningwayUniforms.fxh" // For robust, annotation-based audio uniforms

#define NUM_BANDS 16

//=====================================================================================//
// UNIFORMS AND PARAMETERS - Modified Defaults & Ranges per user request               //
//=====================================================================================//
uniform int frameCount < source = "framecount"; >;

// --- Appearance ---
uniform float GlitterDensity < ui_type = "slider"; ui_label = "Density"; ui_tooltip = "Controls how many sparkles are generated on the screen. Higher values increase the number of sparkles."; ui_min = 0.1; ui_max = 20.0; ui_step = 0.1; ui_category="Sparkle Appearance"; > = 10.0;
uniform float GlitterSize < ui_type = "slider"; ui_label = "Size"; ui_tooltip = "Adjusts the size of each individual sparkle. Larger values make sparkles appear bigger."; ui_min = 0.1; ui_max = 10.0; ui_step = 0.1; ui_category="Sparkle Appearance"; > = 5.0;
uniform float GlitterBrightness < ui_type = "slider"; ui_label = "Brightness"; ui_tooltip = "Sets the overall brightness of the sparkles. Higher values make sparkles more intense and visible."; ui_min = 0.1; ui_max = 12.0; ui_step = 0.1; ui_category="Sparkle Appearance"; > = 6.0;
uniform float GlitterSharpness < ui_type = "slider"; ui_label = "Sharpness"; ui_tooltip = "Controls how crisp or soft the edges of sparkles appear. Higher values make sparkles more defined."; ui_min = 0.1; ui_max = 2.1; ui_step = 0.05; ui_category="Sparkle Appearance"; > = 1.1;

// --- Animation ---
uniform float GlitterSpeed < ui_type = "slider"; ui_label = "Speed"; ui_tooltip = "Sets how quickly sparkles animate and move. Higher values increase animation speed."; ui_min = 0.1; ui_max = 1.5; ui_step = 0.05; ui_category="Animation"; > = 0.8;
uniform float GlitterLifetime < ui_type = "slider"; ui_label = "Lifetime"; ui_tooltip = "Determines how long each sparkle remains visible before fading out."; ui_min = 1.0; ui_max = 20.0; ui_step = 0.1; ui_category="Animation"; > = 10.0;
uniform float TimeScale < ui_type = "slider"; ui_label = "Time Scale"; ui_tooltip = "Scales the overall animation timing for all sparkles. Use to speed up or slow down the effect globally."; ui_min = 1.0; ui_max = 17.0; ui_step = 0.5; ui_category = "Animation"; > = 9.0;

// --- Bloom Effect ---
uniform bool EnableBloom < ui_label = "Bloom"; ui_tooltip = "Enables or disables the bloom (glow) effect around sparkles for a softer, more radiant look."; ui_category = "Bloom Effect"; > = true;
uniform float BloomIntensity < ui_type = "slider"; ui_label = "Intensity"; ui_tooltip = "Controls how strong the bloom (glow) effect appears around sparkles."; ui_min = 0.1; ui_max = 3.1; ui_step = 0.05; ui_category = "Bloom Effect"; ui_spacing = 1; ui_bind = "EnableBloom"; > = 1.6;
uniform float BloomRadius < ui_type = "slider"; ui_label = "Radius"; ui_tooltip = "Sets how far the bloom effect extends from each sparkle. Larger values create a wider glow."; ui_min = 1.0; ui_max = 10.2; ui_step = 0.2; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = 5.6;
uniform float BloomDispersion < ui_type = "slider"; ui_label = "Dispersion"; ui_tooltip = "Adjusts how quickly the bloom fades at the edges. Higher values make the glow softer and more gradual."; ui_min = 1.0; ui_max = 3.0; ui_step = 0.05; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = 2.0;
uniform int BloomQuality < ui_type = "combo"; ui_label = "Quality"; ui_tooltip = "Selects the quality level for the bloom effect. Higher quality reduces artifacts but may impact performance."; ui_items = "Potato\0Low\0Medium\0High\0Ultra\0AI Overlord\0"; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = 2;
uniform bool BloomDither < ui_label = "Dither"; ui_tooltip = "Adds subtle noise to the bloom to reduce color banding and grid patterns."; ui_category = "Bloom Effect"; ui_bind = "EnableBloom"; > = true;

// --- Listeningway Integration ---
uniform bool EnableListeningway < ui_label = "Enable Integration"; ui_tooltip = "Enable audio-reactive controls using the Listeningway addon. When enabled, sparkles and bloom will respond to music and sound. [Learn more](https://github.com/gposingway/Listeningway)"; ui_category = "Listeningway Integration"; > = false;
uniform int Listeningway_SparkleSource < ui_type = "combo"; ui_label = "Sparkle Source"; ui_items = "Volume\0Beat\0Bass\0Treble\0"; ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway"; > = 1;
uniform float Listeningway_SparkleMultiplier < ui_type = "slider"; ui_label = "Sparkle Intensity"; ui_tooltip = "Controls how much the selected audio source increases sparkle brightness."; ui_min = 0.0; ui_max = 5.0; ui_step = 0.05; ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway"; > = 1.5;
uniform int Listeningway_BloomSource < ui_type = "combo"; ui_label = "Bloom Source"; ui_items = "Volume\0Beat\0Bass\0Treble\0"; ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway"; > = 1;
uniform float Listeningway_BloomMultiplier < ui_type = "slider"; ui_label = "Bloom Intensity"; ui_tooltip = "Controls how much the selected audio source increases bloom intensity."; ui_min = 0.0; ui_max = 10.0; ui_step = 0.1; ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway"; > = 10.0;
uniform int Listeningway_TimeScaleSource < ui_type = "combo"; ui_label = "Time Source"; ui_items = "Volume\0Beat\0Bass\0Treble\0"; ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway"; > = 1;
uniform float Listeningway_TimeScaleBand1Multiplier < ui_type = "slider"; ui_label = "Time Intensity"; ui_tooltip = "Controls how much the selected audio source increases animation speed."; ui_min = 0.0; ui_max = 5.0; ui_step = 0.05; ui_category = "Listeningway Integration"; ui_bind = "EnableListeningway"; > = 1.0;

// --- Color Settings ---
uniform float3 GlitterColor < ui_type = "color"; ui_label = "Color"; ui_tooltip = "Sets the base color of all sparkles."; ui_category = "Color Settings"; > = float3(1.0, 1.0, 1.0);
uniform bool DepthColoringEnable < ui_label = "Depth Color"; ui_tooltip = "If enabled, sparkles will change color based on their distance from the camera."; ui_category = "Color Settings"; > = true;
uniform float3 NearColor < ui_type = "color"; ui_label = "Near Color"; ui_tooltip = "Color for sparkles close to the camera."; ui_category = "Color Settings"; > = float3(1.0, 204/255.0, 153/255.0);
uniform float3 FarColor < ui_type = "color"; ui_label = "Far Color"; ui_tooltip = "Color for sparkles far from the camera."; ui_category = "Color Settings"; > = float3(153/255.0, 204/255.0, 1.0);

// --- Depth Masking ---
uniform float NearPlane < ui_type = "slider"; ui_label = "Near"; ui_tooltip = "Controls the minimum distance from the camera where sparkles can appear. Lower values allow sparkles closer to the camera."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Depth Masking"; > = 0.0;
uniform float FarPlane < ui_type = "slider"; ui_label = "Far"; ui_tooltip = "Controls the maximum distance from the camera where sparkles can appear. Lower values bring the cutoff closer."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Depth Masking"; > = 1.0;
uniform float DepthCurve < ui_type = "slider"; ui_label = "Curve"; ui_tooltip = "Adjusts how quickly sparkles fade out with distance. Higher values make the fade sharper."; ui_min = 0.1; ui_max = 10.0; ui_step = 0.1; ui_category = "Depth Masking"; > = 1.0;
uniform bool AllowInfiniteCutoff < ui_label = "Infinite Cutoff"; ui_tooltip = "If enabled, sparkles can appear all the way to the horizon. If disabled, sparkles beyond the cutoff distance are hidden."; ui_category = "Depth Masking"; > = true;

// --- Blending ---
uniform int BlendMode < ui_type = "combo"; ui_label = "Blend"; ui_tooltip = "Selects how sparkles blend with the scene. Try different modes for unique looks."; ui_items = "Add\0Screen\0Color Dodge\0"; ui_category = "Blending"; > = 0;
uniform float BlendStrength < ui_type = "slider"; ui_label = "Strength"; ui_tooltip = "Controls how strongly the effect is blended with the original scene."; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Blending"; > = 1.0;

// --- Debug Mode ---
uniform int DebugMode < ui_type = "combo"; ui_label = "Debug"; ui_tooltip = "Shows different debug visualizations to help diagnose issues with the effect."; ui_items = "Off\0Depth\0Normal\0Sparkle\0Mask\0Force On\0"; ui_category = "Debug"; ui_spacing = 3; > = 0;

// --- Occlusion Control ---
uniform bool ObeyOcclusion < ui_label = "Occlusion"; ui_tooltip = "If enabled, sparkles and bloom will be masked by scene depth, so they do not appear through objects."; ui_category = "Effect Control"; > = true;

//=====================================================================================//
// TEXTURES AND SAMPLERS                                                               //
//=====================================================================================//
texture GlitterRT { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler GlitterSampler { Texture = GlitterRT; };
texture GlitterBloomRT { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16F; };
sampler GlitterBloomSampler { Texture = GlitterBloomRT; };

//=====================================================================================//
// HELPER FUNCTIONS                                                                    //
//=====================================================================================//
// NOTE: Uses hardcoded PI values, no #define needed unless functions change
float Gaussian(float x, float sigma)
{
    return (1.0 / (sqrt(2.0 * 3.14159265359) * sigma)) * exp(-(x * x) / (2.0 * sigma * sigma));
}

float calculateSparkleLifecycle(float time, float sparkleID, float speedMod, float lifeDuration) {
    float cycle = frac((time * speedMod + sparkleID * (10.0 + 5.0 * speedMod)) / lifeDuration);
    float fadeInEnd = 0.2; float fadeOutStart = 0.8; float brightness = 1.0;
    if (cycle < fadeInEnd) { brightness = smoothstep(0.0, fadeInEnd, cycle) / fadeInEnd; }
    else if (cycle > fadeOutStart) { brightness = 1.0 - smoothstep(fadeOutStart, 1.0, cycle) / (1.0 - fadeOutStart); }
    return brightness;
}

float getBloomStepSize(int quality) {
    switch(quality) { case 0: return 2.0; case 1: return 1.0; case 2: return 0.5; case 3: return 0.25; default: return 1.0; }
}

float2 calculateDitherNoise(float2 texcoord, float2 seeds, float stepSize) {
    float2 noise = frac(sin(dot(texcoord, seeds)) * 43758.5453); noise = noise * 2.0 - 1.0; noise *= 0.25 * stepSize; return noise;
}

float3 applyBlendMode(float3 original, float3 sparkle, int blendMode) {
    float3 result = original;
    switch(blendMode) { case 0: result = original + sparkle; break; case 1: result = 1.0 - (1.0 - original) * (1.0 - sparkle); break; case 2: result = original / (1.0 - sparkle + 1e-6); break; } // Added safe divide
    return result;
}

// Helper function to select the audio source
float GetListeningwaySource(int source) {
    if (source == 0) return Listeningway_Volume;
    if (source == 1) return Listeningway_Beat;
    if (source == 2) return Listeningway_FreqBands[0]; // Bass
    if (source == 3) return Listeningway_FreqBands[7]; // Treble
    return 0.0;
}

//=====================================================================================//
// NOISE FUNCTIONS                                                                     //
//=====================================================================================//
float hash21(float2 p) { p = frac(p * float2(123.34, 345.56)); p += dot(p, p + 34.23); return frac(p.x * p.y); }
float3 hash33(float3 p3) { p3 = frac(p3 * float3(0.1031, 0.11369, 0.13787)); p3 += dot(p3, p3.yxz + 19.19); return -1.0 + 2.0 * frac(float3( (p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x )); }
float2 voronoi(float2 x, float offset) {
    float2 n = floor(x); float2 f = frac(x); float2 mg, mr; float md = 8.0;
    for(int j = -1; j <= 1; j++) { for(int i = -1; i <= 1; i++) {
            float2 g = float2(float(i), float(j));
            // NOTE: Original code with constructor error potentially still here
            float2 o = hash33(float3(n + g, hash21(n + g) * 10.0 + offset)).xy * 0.5 + 0.5;
            float2 r = g + o - f; float d = dot(r, r);
            if(d < md) { md = d; mr = r; mg = g; } } }
    return float2(sqrt(md), hash21(n + mg));
}
float star(float2 p, float size, float points, float angle) {
    float2 uv = p; float a = atan2(uv.y, uv.x) + angle; float r = length(uv);
    float f = cos(a * points) * 0.5 + 0.5;
    return 1.0 - smoothstep(f * size, f * size + 0.01, r);
}

//=====================================================================================//
// SPARKLE GENERATOR                                                                   //
//=====================================================================================//
float sparkle(float2 uv, float time) {
    float sparkleSum = 0.0; float2 voronoiResult;
    float sparkleScale = GlitterSize * 0.4; float sharpnessFactor = GlitterSharpness;
    float lifeDuration = 1.0 + GlitterLifetime * 0.2;
    // Layer 1
    voronoiResult = voronoi(uv * GlitterDensity * 0.5, time * 0.1);
    float sparkleID1 = voronoiResult.y; float dist1 = voronoiResult.x;
    float brightness1 = calculateSparkleLifecycle(time, sparkleID1, 1.0, lifeDuration); brightness1 = pow(brightness1, 0.5);
    float sparkleShape1 = (1.0 - smoothstep(0.0, 0.05 * sparkleScale / sharpnessFactor, dist1)) * brightness1;
    // Layer 2
    voronoiResult = voronoi(uv * GlitterDensity, time * 0.15);
    float sparkleID2 = voronoiResult.y; float dist2 = voronoiResult.x;
    float brightness2 = calculateSparkleLifecycle(time, sparkleID2, 1.2, lifeDuration); brightness2 = pow(brightness2, 0.7);
    float sparkleShape2 = (1.0 - smoothstep(0.0, 0.03 * sparkleScale / sharpnessFactor, dist2)) * brightness2;
    // Layer 3
    voronoiResult = voronoi(uv * GlitterDensity * 2.0, time * 0.2);
    float sparkleID3 = voronoiResult.y; float dist3 = voronoiResult.x;
    float brightness3 = calculateSparkleLifecycle(time, sparkleID3, 0.8, lifeDuration); brightness3 = pow(brightness3, 0.9);
    float sparkleShape3 = (1.0 - smoothstep(0.0, 0.02 * sparkleScale / sharpnessFactor, dist3)) * brightness3;
    // Star Overlay
    if (dist1 < 0.05 * sparkleScale / sharpnessFactor) {
        // NOTE: Uses voronoiResult from Layer 3, should use Layer 1
        float starMask = star(uv - (uv - voronoiResult.xy), 0.03 * sparkleScale / sharpnessFactor, 4.0, sparkleID1 * 6.28); // Uses 6.28 instead of PI
        sparkleShape1 = max(sparkleShape1, starMask * brightness1 * 2.0);
    }
    // Combine Layers
    sparkleSum = sparkleShape1 * 1.0 + sparkleShape2 * 0.7 + sparkleShape3 * 0.3;
    sparkleSum *= GlitterDensity * 0.1;
    return saturate(sparkleSum);
}

//=====================================================================================//
// FIRST PASS - SPARKLE PATTERN GENERATION                                             //
//=====================================================================================//
float4 PS_RenderSparkles(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 color = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    bool forceEnable = (DebugMode == 5); if (forceEnable) { depth = 0.5; }
    float depthMask = smoothstep(NearPlane, FarPlane, depth); depthMask = 1.0 - pow(depthMask, DepthCurve); if (forceEnable) { depthMask = 1.0; }
    // Hide particles after cutoff if not allowing infinite cutoff
    if (!AllowInfiniteCutoff && depth >= FarPlane) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
    float3 normal = float3(0, 0, 1);
    if (!forceEnable) {
         // NOTE: This line contains the float3 constructor error from original code
         float3 offset = float3(ReShade::PixelSize.xy, 0.0);
         float2 posCenter = texcoord;
         float depthCenter = ReShade::GetLinearizedDepth(posCenter);
         float depthLeft = ReShade::GetLinearizedDepth(posCenter - offset.xz * 2.0); float depthRight = ReShade::GetLinearizedDepth(posCenter + offset.xz * 2.0);
         float depthTop = ReShade::GetLinearizedDepth(posCenter - offset.zy * 2.0); float depthBottom = ReShade::GetLinearizedDepth(posCenter + offset.zy * 2.0);
         float3 dx = float3(offset.x * 4.0, 0.0, depthRight - depthLeft); float3 dy = float3(0.0, offset.y * 4.0, depthBottom - depthTop);
         // NOTE: Original unsafe normalize and remapping
         normal = normalize(cross(dx, dy)); normal = normal * 0.5 + 0.5; normal = normal * 2.0 - 1.0;
    }
    float actualTimeScale = TimeScale / 333.33;
    if (EnableListeningway) {
        actualTimeScale += GetListeningwaySource(Listeningway_TimeScaleSource) * Listeningway_TimeScaleBand1Multiplier / 333.33;
    }
    float time = frameCount * 0.005 * actualTimeScale; // Original timing logic
    float positionHash = hash21(floor(texcoord * 10.0)) * 10.0;
    float2 noiseCoord = texcoord * ReShade::ScreenSize * 0.005;
    float sparkleIntensity = sparkle(noiseCoord, positionHash + time); // Uses positionHash + scaled time
    if (EnableListeningway) {
        sparkleIntensity *= (1.0 + GetListeningwaySource(Listeningway_SparkleSource) * Listeningway_SparkleMultiplier);
    }
    float3 viewDir = float3(0.0, 0.0, 1.0); float fresnel = pow(1.0 - saturate(dot(normal, viewDir)), 5.0);
    if (!forceEnable && ObeyOcclusion) { sparkleIntensity *= fresnel * depthMask; }
    else if (!forceEnable && !ObeyOcclusion) { sparkleIntensity *= fresnel; }
    sparkleIntensity *= GlitterBrightness; // Applies brightness here
    if (DebugMode == 1) return float4(depth.xxx, 1.0); else if (DebugMode == 2) return float4(normal * 0.5 + 0.5, 1.0); else if (DebugMode == 3) return float4(sparkleIntensity.xxx, 1.0); else if (DebugMode == 4) return float4(depthMask.xxx, 1.0);
    float3 finalGlitterColor = GlitterColor;
    if (DepthColoringEnable && !forceEnable) { float depthFactor = smoothstep(NearPlane, FarPlane, depth); finalGlitterColor = lerp(NearColor, FarColor, depthFactor); }
    float3 sparkleContribution = finalGlitterColor * sparkleIntensity * 5.0; // Multiplied by 5.0 here
    return float4(sparkleContribution, sparkleIntensity > 0.05 ? 1.0 : 0.0); // Alpha threshold check
}

//=====================================================================================//
// SECOND PASS - HORIZONTAL BLOOM                                                      //
//=====================================================================================//
float4 PS_BloomH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 color = 0.0; float weightSum = 0.0; if (DebugMode > 0 && DebugMode < 5) { return tex2D(GlitterSampler, texcoord); }
    float sigma = BloomRadius / BloomDispersion; // Potential divide by zero
    float range = ceil(BloomRadius * 2.0); float stepSize = getBloomStepSize(BloomQuality);
    float2 noise = float2(1.0, 1.0); if (BloomDither) { noise = calculateDitherNoise(texcoord, float2(12.9898, 78.233), stepSize); }
    float bloomIntensity = BloomIntensity;
    if (EnableListeningway) {
        bloomIntensity += (GetListeningwaySource(Listeningway_BloomSource) * Listeningway_BloomMultiplier);
    }
    // Depth/occlusion mask for bloom
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = smoothstep(NearPlane, FarPlane, depth);
    depthMask = pow(depthMask, DepthCurve); // Remove 1.0 - ... to fix inversion
    if (ObeyOcclusion) {
        color *= (1.0 - depthMask); // Invert mask so occluded areas are masked out
    }
    for(float x = -range; x <= range; x += stepSize) { float weight = Gaussian(x, sigma); weightSum += weight; float2 sampleOffset = float2(x / BUFFER_WIDTH, 0.0) * BloomRadius; if (BloomDither) { sampleOffset += float2(noise.x * 0.001, 0.0); } color += tex2D(GlitterSampler, texcoord + sampleOffset) * weight; }
    color /= max(weightSum, 1e-6); // Added safe divide
    color *= bloomIntensity; return color;
}

//=====================================================================================//
// THIRD PASS - VERTICAL BLOOM AND FINAL BLEND                                         //
//=====================================================================================//
float4 PS_BloomV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord); if (DebugMode > 0 && DebugMode < 5) { return tex2D(GlitterSampler, texcoord); }
    float4 sparkleColor = tex2D(GlitterSampler, texcoord);
    if (!EnableBloom) { float3 result = applyBlendMode(originalColor.rgb, sparkleColor.rgb, BlendMode); float finalBlendStrength = DebugMode == 5 ? 1.0 : BlendStrength; result = lerp(originalColor.rgb, result, finalBlendStrength); return float4(result, originalColor.a); }
    float4 bloomColor = 0.0; float weightSum = 0.0; float sigma = BloomRadius / BloomDispersion; // Potential divide by zero
    float range = ceil(BloomRadius * 2.0); float stepSize = getBloomStepSize(BloomQuality);
    float2 noise = float2(1.0, 1.0); if (BloomDither) { noise = calculateDitherNoise(texcoord, float2(78.233, 12.9898), stepSize); }
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = smoothstep(NearPlane, FarPlane, depth);
    depthMask = pow(depthMask, DepthCurve); // Remove 1.0 - ... to fix inversion
    for(float y = -range; y <= range; y += stepSize) { float weight = Gaussian(y, sigma); weightSum += weight; float2 sampleOffset = float2(0.0, y / BUFFER_HEIGHT) * BloomRadius; if (BloomDither) { sampleOffset += float2(0.0, noise.y * 0.001); } bloomColor += tex2D(GlitterBloomSampler, texcoord + sampleOffset) * weight; }
    bloomColor /= max(weightSum, 1e-6); // Added safe divide
    if (ObeyOcclusion) {
        bloomColor *= (1.0 - depthMask); // Invert mask so occluded areas are masked out
    }
    float4 finalSparkleColor = max(sparkleColor, bloomColor); float3 result = applyBlendMode(originalColor.rgb, finalSparkleColor.rgb, BlendMode);
    float finalBlendStrength = DebugMode == 5 ? 1.0 : BlendStrength; result = lerp(originalColor.rgb, result, finalBlendStrength); return float4(result, originalColor.a);
}

//=====================================================================================//
// LEGACY SUPPORT                                                                      //
//=====================================================================================//
float4 PS_Glitter(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target { return tex2D(ReShade::BackBuffer, texcoord); }

//=====================================================================================//
// TECHNIQUE DEFINITION                                                                //
//=====================================================================================//
technique GlitterEffect < ui_label = "Glitter Effect"; ui_tooltip = "Adds dynamic sparkles that pop in, glow, and fade out"; >
{ pass RenderSparkles { VertexShader = PostProcessVS; PixelShader = PS_RenderSparkles; RenderTarget = GlitterRT; }
  pass BloomH { VertexShader = PostProcessVS; PixelShader = PS_BloomH; RenderTarget = GlitterBloomRT; }
  pass BloomV { VertexShader = PostProcessVS; PixelShader = PS_BloomV; } }