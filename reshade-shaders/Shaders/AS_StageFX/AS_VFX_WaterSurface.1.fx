/**
 * AS_VFX_WaterSurface.1.fx - Depth-based water reflection horizon
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Adapted from Godot water shader techniques
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a water surface where reflection start points are based on object depth,
 * with distant objects reflecting at the horizon and closer objects reflecting lower.
 * Wave pattern scale adjusts based on distance from horizon. Includes reflection compression.
 *
 * FEATURES:
 * - Depth-based reflection start points
 * - Configurable water level (horizon)
 * - Simple wave animation for water surface with perspective scaling
 * - Adjustable reflection parameters including vertical compression
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Uses depth buffer to determine reflection start points per pixel
 * 2. Applies wave distortion with scale varying based on distance from horizon
 * 3. Compresses reflection vertically based on user parameter
 * 4. Applies water color blending
 *
 * ===================================================================================
 */

#ifndef __AS_VFX_WaterSurface_1_fx
#define __AS_VFX_WaterSurface_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// TEXTURES AND SAMPLERS
// ============================================================================

// Wave texture can be customized through preprocessor define
#ifndef WAVE_TEXTURE
#define WAVE_TEXTURE "perlin512x8Noise.png"
#endif

texture WaterSurface_WaveTexture < source = WAVE_TEXTURE; > { Width = 512; Height = 512; Format = RGBA8; };
sampler WaterSurface_WaveSampler { Texture = WaterSurface_WaveTexture; AddressU = WRAP; AddressV = WRAP; MipFilter = LINEAR; MinFilter = LINEAR; MagFilter = LINEAR; };

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float WAVE_SPEED_MIN = 0.01;
static const float WAVE_SPEED_MAX = 1.0;
static const float WAVE_SPEED_DEFAULT = 0.1;

static const float WAVE_SCALE_MIN = 1.0; // Minimum scale factor (applied furthest from horizon)
static const float WAVE_SCALE_MAX = 50.0; // Maximum scale factor (applied nearest to horizon)
static const float WAVE_SCALE_DEFAULT = 5.0; // Base scale factor

static const float DISTORTION_MIN = 0.0;
static const float DISTORTION_MAX = 0.1;
static const float DISTORTION_DEFAULT = 0.02;

static const float DEPTH_SCALE_MIN = 0.0;
static const float DEPTH_SCALE_MAX = 1.0;
static const float DEPTH_SCALE_DEFAULT = 0.27;

static const float REFLECT_COMPRESS_MIN = 1.0; 
static const float REFLECT_COMPRESS_MAX = 10.0; 
static const float REFLECT_COMPRESS_DEFAULT = 0.4; 

// ============================================================================
// EFFECT-SPECIFIC PARAMETERS
// ============================================================================
// --- Water Properties ---
uniform float3 WaterColor < ui_type = "color"; ui_label = "Water Color"; ui_tooltip = "Base color of the water."; ui_category = "Water"; > = float3(0.1, 0.35, 0.5);
uniform float WaterTransparency < ui_type = "slider"; ui_label = "Water Transparency"; ui_tooltip = "How transparent the water appears."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Water"; > = 1.0;
uniform float ReflectionIntensity < ui_type = "slider"; ui_label = "Reflection Intensity"; ui_tooltip = "Strength of the reflection effect."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Water"; > = 1.0;
uniform float ReflectionCompress < ui_type = "slider"; ui_label = "Reflection Compress"; ui_tooltip = "Compresses the reflection vertically (lower value = shorter reflection)."; ui_min = REFLECT_COMPRESS_MIN; ui_max = REFLECT_COMPRESS_MAX; ui_step = 0.01; ui_category = "Water"; > = REFLECT_COMPRESS_DEFAULT;

// --- Depth Settings ---
uniform float DepthScale < ui_type = "slider"; ui_label = "Depth Scale"; ui_tooltip = "How much object depth affects the reflection horizon (0 = flat reflection, 1 = maximum effect)."; ui_min = DEPTH_SCALE_MIN; ui_max = DEPTH_SCALE_MAX; ui_step = 0.01; ui_category = "Depth"; > = DEPTH_SCALE_DEFAULT;
uniform float DepthFalloff < ui_type = "slider"; ui_label = "Depth Falloff"; ui_tooltip = "How quickly the depth effect diminishes with distance (higher = faster falloff)."; ui_min = 0.1; ui_max = 10.0; ui_step = 0.1; ui_category = "Depth"; > = 1.0;
uniform float Perspective < ui_type = "slider"; ui_label = "Perspective"; ui_tooltip = "Modifies the depth offset for the reflection horizon."; ui_min = 0.5; ui_max = 5.0; ui_step = 0.01; ui_category = "Depth"; > = 1.0;

// --- Wave Settings ---
uniform float2 WaveDirection < ui_type = "slider"; ui_label = "Wave Direction"; ui_tooltip = "Direction of wave movement."; ui_min = -1.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Waves"; > = float2(1.0, 0.0);
uniform float WaveSpeed < ui_type = "slider"; ui_label = "Wave Speed"; ui_tooltip = "Speed of wave animation."; ui_min = WAVE_SPEED_MIN; ui_max = WAVE_SPEED_MAX; ui_step = 0.01; ui_category = "Waves"; > = WAVE_SPEED_DEFAULT;
uniform float WaveScale < ui_type = "slider"; ui_label = "Wave Scale"; ui_tooltip = "Base scale of wave pattern."; ui_min = WAVE_SCALE_MIN; ui_max = WAVE_SCALE_MAX; ui_step = 0.1; ui_category = "Waves"; > = WAVE_SCALE_DEFAULT;
uniform float WaveDistortion < ui_type = "slider"; ui_label = "Wave Distortion"; ui_tooltip = "Amount of distortion applied to reflection."; ui_min = DISTORTION_MIN; ui_max = DISTORTION_MAX; ui_step = 0.001; ui_category = "Waves"; > = DISTORTION_DEFAULT;
uniform float WaveScaleCurve < ui_type = "slider"; ui_label = "Wave Scale Curve"; ui_tooltip = "Controls how quickly wave scale increases near the horizon (logarithmic curve)."; ui_min = 0.1; ui_max = 5.0; ui_step = 0.01; ui_category = "Waves"; > = 0.1;

// --- Water Position ---
uniform float WaterLevel < ui_type = "slider"; ui_label = "Water Level"; ui_tooltip = "Position of the water horizon line (0.5 = middle of screen)."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Stage"; > = 0.5;
uniform float WaterFadeSize < ui_type = "slider"; ui_label = "Water Edge Fade"; ui_tooltip = "Size of the fade at the water's edge."; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_category = "Stage"; > = 0.005;

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Normal\0Wave Distortion\0Depth Map\0Reflection Horizon\0Wave Scale Factor\0Reflection Coord Y\0") // Updated Debug Mode

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
// Calculate distortion based on wave texture, applying scale curve
float2 GetWaveDistortion(float2 texcoord, float time, float reflectionHorizon)
{
    // Calculate normalized distance from horizon (0 at horizon, 1 at bottom)
    float norm = 0.0;
    // Avoid division by zero if horizon is at the bottom
    float horizonRange = max(1.0 - reflectionHorizon, AS_EPSILON);
    if (texcoord.y > reflectionHorizon)
    {
        norm = saturate((texcoord.y - reflectionHorizon) / horizonRange);
    }

    // Power curve for scale interpolation factor (higher curve = faster change near horizon)
    float curve = pow(norm, WaveScaleCurve);

    // Interpolate wave scale: Use base WaveScale at horizon (curve=0), WAVE_SCALE_MIN at bottom (curve=1)
    float currentWaveScale = lerp(WaveScale, WAVE_SCALE_MIN, curve);

    // Apply resolution scaling to make effect somewhat resolution independent
    float resolutionScale = BUFFER_HEIGHT / AS_RESOLUTION_BASE_HEIGHT; // Scale relative to base height

    // Calculate final UV for wave texture sampling
    float2 scaledCoord = texcoord * currentWaveScale * resolutionScale;
    float2 waveUV = scaledCoord + (normalize(WaveDirection + AS_EPSILON) * time * WaveSpeed); // Normalize direction safely

    // Sample wave texture
    float2 waveValue = tex2D(WaterSurface_WaveSampler, waveUV).rg;

    // Convert from 0-1 range to -1 to 1
    waveValue = waveValue * 2.0 - 1.0;

    // Apply distortion amount
    return waveValue * WaveDistortion;
}

// Calculate depth-based reflection horizon
float CalculateReflectionHorizon(float depth, float baseLevel)
{
    // Normalize and adjust depth (0 = near, 1 = far)
    float adjustedDepth = pow(saturate(depth), DepthFalloff);

    // Apply perspective scaling
    adjustedDepth = pow(adjustedDepth, max(AS_EPSILON, 3.0 - Perspective)); // Ensure exponent is positive

    // Calculate horizon offset (near = larger offset, far = smaller offset)
    float depthOffset = (1.0 - adjustedDepth) * DepthScale;

    // Calculate final horizon
    float reflectionHorizon = baseLevel + depthOffset;

    // Clamp to screen bounds
    return saturate(reflectionHorizon);
}

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float4 PS_WaterSurface(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // --- Initial Setup ---
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float time = AS_getTime();

    // Debug depth map
    if (DebugMode == 2) return float4(depth.xxx, 1.0);

    // --- Calculations ---
    float reflectionHorizon = CalculateReflectionHorizon(depth, WaterLevel);
    bool isWater = texcoord.y > reflectionHorizon;    // Debug reflection horizon line
    if (DebugMode == 3) {
        float horizonHighlight = abs(texcoord.y - reflectionHorizon) < 0.002 ? 1.0 : 0.0;
        return float4(horizonHighlight, 0.0, 0.0, 1.0) + originalColor * (1.0 - horizonHighlight);
    }

    // If not in water area, return original color
    if (!isWater) return originalColor;

    // Calculate water edge fade factor
    float edgeFade = 1.0;
    if (WaterFadeSize > 0.0) {
        edgeFade = saturate((texcoord.y - reflectionHorizon) / WaterFadeSize);
    }

    // Apply wave distortion (now includes scaling logic)
    float2 distortion = GetWaveDistortion(texcoord, time, reflectionHorizon);

    // Debug wave distortion
    if (DebugMode == 1) return float4(distortion * 0.5 + 0.5, 0.0, 1.0);

    // --- Debug Wave Scale Factor ---
    float dbg_scaleFactor = 0.0; // Need to calculate for debug mode 4
    if (DebugMode == 4) {
         float norm = 0.0;
         float horizonRange = max(1.0 - reflectionHorizon, AS_EPSILON);
         if (texcoord.y > reflectionHorizon) { norm = saturate((texcoord.y - reflectionHorizon) / horizonRange); }
         float curve = pow(norm, WaveScaleCurve);
         dbg_scaleFactor = lerp(WaveScale, WAVE_SCALE_MIN, curve);
         // Normalize scale factor for visualization (approximate)
         return float4(saturate((dbg_scaleFactor - WAVE_SCALE_MIN) / (WaveScale - WAVE_SCALE_MIN + AS_EPSILON)).xxx, 1.0);
    }

    // --- Reflection Calculation ---
    // Calculate the distance below the dynamic horizon for this pixel
    float distBelowHorizon = texcoord.y - reflectionHorizon;
    // Calculate the base mirrored Y position above the horizon
    // Apply the compression factor to the distance
    float reflectionY = reflectionHorizon - (distBelowHorizon * ReflectionCompress); // *** Apply Compression Here ***
    float2 reflectionCoord = float2(texcoord.x, reflectionY);

    // Debug Reflection Coordinate Y before distortion
    if (DebugMode == 5) return float4(saturate(reflectionCoord.y).xxx, 1.0);

    // Apply distortion to reflection coordinates
    reflectionCoord = reflectionCoord + distortion;
    reflectionCoord = clamp(reflectionCoord, 0.0, 1.0); // Clamp final coord

    // Sample reflected color
    float4 reflectionColor = tex2D(ReShade::BackBuffer, reflectionCoord);

    // --- Blending ---
    float3 waterWithReflection = lerp(WaterColor, reflectionColor.rgb, ReflectionIntensity * WaterTransparency);
    float3 blendedColor = AS_applyBlend(waterWithReflection, originalColor.rgb, BlendMode);
    float3 result = lerp(originalColor.rgb, blendedColor, edgeFade * BlendAmount);

    // Normal Mode Output
    if (DebugMode == 0) return float4(result, originalColor.a);

    // Fallback for debug mode (shouldn't be reached)
    return float4(1.0, 0.0, 1.0, 1.0); // Magenta error
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_WaterSurface < ui_label = "[AS] VFX: Water Surface"; ui_tooltip = "Simulates a water surface with depth-based reflections and animated waves."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_WaterSurface;
    }
}

#endif // __AS_VFX_WaterSurface_1_fx
