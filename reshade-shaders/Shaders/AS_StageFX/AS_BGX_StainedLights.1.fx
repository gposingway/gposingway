/**
 * AS_BGX_StainedLights.1.fx - Stained Glass Light Patterns
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Stained Lights" by 104
 * Shadertoy: https://www.shadertoy.com/view/WlsSzM
 * Created: 2019-07-06
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates dynamic and colorful patterns reminiscent of stained glass illuminated by shifting light,
 * with multiple blurred layers enhancing the depth and visual complexity. The effect generates
 * layers of distorted, cell-like structures with vibrant, evolving colors and subtle edge
 * highlighting, overlaid with softer, floating elements. Suitable for creating abstract
 * backgrounds, energy fields, or mystical visuals with a sense of depth.
 *
 * FEATURES:
 * - Multi-layered pattern generation with adjustable iterations
 * - Dynamic animation with speed control
 * - Customizable pattern scaling and edge highlighting
 * - Audio reactivity for animation and pattern evolution
 * - Post-processing effects including curve adjustments and noise
 * - Implementation of blurred, floating layers for added visual depth
 * - Depth-aware rendering with standard blending options
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Implements a pseudo-random number generator for color variation
 * 2. Defines a pattern generation function to create cell-like patterns and edge highlighting
 * 3. Iteratively layers the pattern with scaling and transformations based on time
 * 4. Applies post-processing including clamping, curve adjustments, and noise
 * 5. The iterative layering with varying scales and offsets creates the appearance of floating layers
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_StainedLights_1_fx
#define __AS_BGX_StainedLights_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

namespace ASStainedLights {
// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Pattern ---
static const float PATTERN_SCALE_MIN = 1.0;
static const float PATTERN_SCALE_MAX = 16.0;
static const float PATTERN_SCALE_STEP = 0.1;
static const float PATTERN_SCALE_DEFAULT = 10.1; // Updated from 8.0

static const float EDGE_CURVE_MIN = 0.1;
static const float EDGE_CURVE_MAX = 1.0;
static const float EDGE_CURVE_STEP = 0.01;
static const float EDGE_CURVE_DEFAULT = 0.44;

static const float EDGE_BIAS_MIN = -1.0;
static const float EDGE_BIAS_MAX = 1.0;
static const float EDGE_BIAS_STEP = 0.01;
static const float EDGE_BIAS_DEFAULT = 0.28; // Updated from -0.3

static const int ITERATIONS_MIN = 1;
static const int ITERATIONS_MAX = 8;
static const int ITERATIONS_DEFAULT = 4;

// --- Animation ---
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 2.0;
static const float ANIMATION_SPEED_STEP = 0.01;
static const float ANIMATION_SPEED_DEFAULT = 0.60; // Updated from 0.6

static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_STEP = 0.1;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// --- Post Processing ---
static const float CURVE_INTENSITY_MIN = 1.0;
static const float CURVE_INTENSITY_MAX = 50.0;
static const float CURVE_INTENSITY_STEP = 1.0;
static const float CURVE_INTENSITY_DEFAULT = 30.0;

static const float NOISE_AMOUNT_MIN = 0.0;
static const float NOISE_AMOUNT_MAX = 0.1;
static const float NOISE_AMOUNT_STEP = 0.001;
static const float NOISE_AMOUNT_DEFAULT = 0.070; // Updated from 0.07

// --- Audio Reactivity ---
static const int AUDIO_TARGET_DEFAULT = 3; // Animation Speed
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0;
static const float AUDIO_MULTIPLIER_MAX = 3.0;

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)

// --- Pattern ---
uniform float PatternScale < ui_type = "slider"; ui_label = "Pattern Scale"; ui_tooltip = "Overall scale of the stained glass pattern."; ui_min = PATTERN_SCALE_MIN; ui_max = PATTERN_SCALE_MAX; ui_step = PATTERN_SCALE_STEP; ui_category = "Pattern"; > = PATTERN_SCALE_DEFAULT;
uniform float EdgeCurve < ui_type = "slider"; ui_label = "Edge Curvature"; ui_tooltip = "Controls the sharpness of the edges within the pattern."; ui_min = EDGE_CURVE_MIN; ui_max = EDGE_CURVE_MAX; ui_step = EDGE_CURVE_STEP; ui_category = "Pattern"; > = EDGE_CURVE_DEFAULT;
uniform float EdgeBias < ui_type = "slider"; ui_label = "Edge Bias"; ui_tooltip = "Adjusts the overall brightness of the edges."; ui_min = EDGE_BIAS_MIN; ui_max = EDGE_BIAS_MAX; ui_step = EDGE_BIAS_STEP; ui_category = "Pattern"; > = EDGE_BIAS_DEFAULT;
uniform int Iterations < ui_type = "slider"; ui_label = "Pattern Iterations"; ui_tooltip = "Number of iterations for pattern layering. Higher values create more detail but may affect performance."; ui_min = ITERATIONS_MIN; ui_max = ITERATIONS_MAX; ui_category = "Pattern"; > = ITERATIONS_DEFAULT;

// --- Animation ---
uniform float AnimationKeyframe < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = ANIMATION_KEYFRAME_MIN; ui_max = ANIMATION_KEYFRAME_MAX; ui_step = ANIMATION_KEYFRAME_STEP; ui_category = "Animation"; > = ANIMATION_KEYFRAME_DEFAULT;
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the speed at which the pattern evolves. Set to 0 to pause animation and use keyframe only."; ui_min = ANIMATION_SPEED_MIN; ui_max = ANIMATION_SPEED_MAX; ui_step = ANIMATION_SPEED_STEP; ui_category = "Animation"; > = ANIMATION_SPEED_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_UI(StainedLights_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(StainedLights_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int StainedLights_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_items = "None\0Animation Speed\0Pattern Scale\0Edge Curvature\0"; ui_category = "Audio Reactivity"; > = AUDIO_TARGET_DEFAULT;

// --- Post Processing ---
uniform float CurveIntensity < ui_type = "slider"; ui_label = "Curve Intensity"; ui_tooltip = "Applies a power curve to the output color for contrast."; ui_min = CURVE_INTENSITY_MIN; ui_max = CURVE_INTENSITY_MAX; ui_step = CURVE_INTENSITY_STEP; ui_category = "Post Processing"; > = CURVE_INTENSITY_DEFAULT;
uniform float NoiseAmount < ui_type = "slider"; ui_label = "Noise Amount"; ui_tooltip = "Adds a subtle noise texture to the final output."; ui_min = NOISE_AMOUNT_MIN; ui_max = NOISE_AMOUNT_MAX; ui_step = NOISE_AMOUNT_STEP; ui_category = "Post Processing"; > = NOISE_AMOUNT_DEFAULT;

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// --- Debug ---
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Use the standard hash function from AS_Utils if possible, or keep a specialized one if needed
float3 hash32(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));

    p3 += dot(p3, p3.yxz + 19.19);
    return frac((p3.xxy + p3.yzz) * p3.zyx);
}

// Pattern generation function
float4 generatePattern(float2 uv) {
    float v = abs(cos(uv.x * AS_PI * 2.0) + cos(uv.y * AS_PI * 2.0)) * 0.5;
    uv.x -= 0.5;
    float3 cid2 = hash32(floor(float2(uv.x - uv.y, uv.x + uv.y)));
    return float4(cid2, v);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 StainedLightsPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
    // Get original pixel color and depth
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);

    // Apply depth test
    if (depth < EffectDepth) {
        return originalColor;
    }

    // Apply audio reactivity
    float audioReactivity = AS_applyAudioReactivity(1.0, StainedLights_AudioSource, StainedLights_AudioMultiplier, true);
    
    float patternScaleFinal = PatternScale;
    float edgeCurveFinal = EdgeCurve;
    float animSpeedFinal = AnimationSpeed;
    
    // Map audio target to parameter adjustment
    if (StainedLights_AudioTarget == 1) {
        animSpeedFinal *= audioReactivity;
    }
    else if (StainedLights_AudioTarget == 2) {
        patternScaleFinal *= audioReactivity;
    }
    else if (StainedLights_AudioTarget == 3) {
        edgeCurveFinal *= audioReactivity;
    }

    // Get animation time
    float t;
    if (animSpeedFinal <= 0.0001f) {
        // When animation speed is effectively zero, use keyframe directly
        t = AnimationKeyframe;
    } else {
        // Otherwise use animated time plus keyframe offset
        t = (AS_getTime() * animSpeedFinal) + AnimationKeyframe;
    }

    // Setup UV coordinates for pattern generation
    float2 uv = texcoord - 0.5f; // Center texcoord (becomes -0.5 to 0.5 range)
    
    float current_aspectRatio = ReShade::ScreenSize.x / ReShade::ScreenSize.y;
    uv.x *= current_aspectRatio; // Correct aspect ratio to make coordinates square for pattern logic

    // Apply global rotation (to the square, centered UVs)
    float current_rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    if (abs(current_rotationRadians) > 0.001f) { // Apply rotation if significant
        float s_rot = sin(current_rotationRadians);
        float c_rot = cos(current_rotationRadians);
        uv = float2(
            uv.x * c_rot - uv.y * s_rot,
            uv.x * s_rot + uv.y * c_rot
        );
    }

    // Apply pattern scale (scales the density in the square, rotated space)
    uv *= patternScaleFinal;

    // Apply base animation offset/pan (in the scaled, rotated, square space)
    uv -= float2(t * 0.5f, -t * 0.3f);
    
    // Generate pattern
    float4 o = float4(1.0, 1.0, 1.0, 1.0);
    for (int i = 1; i <= Iterations; ++i) {
        uv /= i * 0.9;
        float4 d = generatePattern(uv);
        float curv = pow(d.a, edgeCurveFinal - ((1.0 / i) * EdgeBias));
        curv = pow(curv, 0.8 + (d.b * 2.0));
        o *= clamp(d * curv, 0.35, 1.0);
        uv += t * (i + 0.3);
    }

    // Post processing
    o = clamp(o, 0.0, 1.0);
    
    // Apply curve adjustment
    o = 1.0 - pow(1.0 - o, CurveIntensity);
    
    // Add noise
    o.rgb += hash32(texcoord * ReShade::ScreenSize.xy + AS_getTime()).r * NoiseAmount;
    o.a = 1.0; // Ensure alpha is 1 after all color operations

    // Blend with original scene
    float4 finalColor = float4(AS_applyBlend(o.rgb, originalColor.rgb, BlendMode), 1.0);
    finalColor = lerp(originalColor, finalColor, BlendStrength);
    
    // Show debug overlay if enabled
    if (DebugMode != AS_DEBUG_OFF) {
        float4 debugMask = float4(0, 0, 0, 0);
        if (DebugMode == 1) { // Show Audio Reactivity
             debugMask = float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
        
        float2 debugCenter = float2(0.1, 0.1);
        float debugRadius = 0.08;
        if (length(texcoord - debugCenter) < debugRadius) {
            return debugMask;
        }
    }
    
    return finalColor;
}

} // namespace ASStainedLights

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_StainedLights < ui_label="[AS] BGX: Stained Lights"; ui_tooltip="Dynamic stained glass light patterns."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASStainedLights::StainedLightsPS;
    }
}

#endif // __AS_BGX_StainedLights_1_fx

