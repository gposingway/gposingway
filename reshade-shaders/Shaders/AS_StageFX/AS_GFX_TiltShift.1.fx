/**
 * AS_GFX_TiltShift.1.fx - A high-quality, depth-aware Tilt-Shift / DoF shader.
 *
 * Author: Leon Aquitaine
 * License: CC BY 4.0
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader simulates a realistic camera lens by applying a high-quality,
 * depth-aware blur. Unlike simple screen-space effects, this shader uses the
 * scene's depth buffer to allow for precise focusing. You can select a focal
 * point in the scene's depth, and objects closer or further away will be smoothly
 * blurred, creating a beautiful and realistic "bokeh" or "tilt-shift" effect.
 *
 * FEATURES:
 * - Depth-based focusing allows you to pick any point in the scene to be sharp.
 * - A "Focus Zone" control to define the size of the in-focus area (depth of field).
 * - High-quality, performant two-pass Gaussian blur driven by the depth calculation.
 * - Depth-aware edge detection that correctly handles foreground and background blur
 * bleeding for a more realistic effect.
 * * IMPLEMENTATION OVERVIEW:
 * 1.  (Pass 1) Calculates a "Circle of Confusion" (CoC) value for each pixel based
 * on its distance from the selected 'Focus Depth' and 'Focus Zone'. This CoC value
 * (0.0 for sharp, 1.0 for blurry) is stored in the alpha channel of as_TiltShiftTex0.
 * 2.  (Pass 2) A horizontal Gaussian blur is applied. The blur radius is determined
 * by the CoC value. A depth check ensures foreground blur can bleed over the background.
 * 3.  (Pass 3) A vertical Gaussian blur is applied to the result of Pass 2, again
 * using the per-pixel CoC value and depth-aware logic to produce the final image.
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_TiltShift_1_fx
#define __AS_GFX_TiltShift_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// INTERMEDIATE TEXTURES
// ============================================================================

// as_TiltShiftTex0 will store: R, G, B, CoC
// as_TiltShiftTex1 will store: H-Blurred R, G, B, CoC
texture as_TiltShiftTex0 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler s_as_TiltShiftTex0 { Texture = as_TiltShiftTex0; };
texture as_TiltShiftTex1 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler s_as_TiltShiftTex1 { Texture = as_TiltShiftTex1; };

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================
static const float BLUR_EXP_COEFF_EPSILON = 1e-5; // For Gaussian blur denominator stability
static const float BLUR_AXIS_SCALE = 2.0;         // Used for blur offset scaling
static const float BLUR_OFFSET_BIAS = 0.5;        // Bias for blur sample offsets
static const float DEPTH_BLEED_FACTOR = 10.0;     // Controls depth-aware anti-bleed sensitivity
static const float FOCUS_ZONE_SCALE = 0.5;        // Scale factor for focus zone calculation

// UI Range Constants
static const float FOCUS_DEPTH_MIN = 0.0;
static const float FOCUS_DEPTH_MAX = 1.0;
static const float FOCUS_DEPTH_DEFAULT = 0.1;
static const float FOCUS_ZONE_MIN = 0.0;
static const float FOCUS_ZONE_MAX = 0.2;
static const float FOCUS_ZONE_DEFAULT = 0.01;
static const float FOCUS_FALLOFF_MIN = 1.0;
static const float FOCUS_FALLOFF_MAX = 200.0;
static const float FOCUS_FALLOFF_DEFAULT = 20.0;
static const float MAX_BLUR_MIN = 0.0;
static const float MAX_BLUR_MAX = 25.0;
static const float MAX_BLUR_DEFAULT = 15.0;

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// -- Focus Settings --
uniform float FocusDepth < ui_type = "slider"; ui_label = "Focus Depth"; ui_tooltip = "Selects the distance from the camera to keep in focus.\n0.0 = close, 1.0 = far."; ui_min = FOCUS_DEPTH_MIN; ui_max = FOCUS_DEPTH_MAX; ui_step = 0.001; ui_category = "Focus Settings"; > = FOCUS_DEPTH_DEFAULT;
uniform float FocusZoneSize < ui_type = "slider"; ui_label = "Focus Zone Size"; ui_tooltip = "The size of the area around the Focus Depth that remains perfectly sharp."; ui_min = FOCUS_ZONE_MIN; ui_max = FOCUS_ZONE_MAX; ui_step = 0.001; ui_category = "Focus Settings"; > = FOCUS_ZONE_DEFAULT;
uniform float FocusFalloff < ui_type = "slider"; ui_label = "Focus Falloff Curve"; ui_tooltip = "Controls how quickly the blur applies outside the focus zone. Higher values are more aggressive."; ui_min = FOCUS_FALLOFF_MIN; ui_max = FOCUS_FALLOFF_MAX; ui_category = "Focus Settings"; > = FOCUS_FALLOFF_DEFAULT;

// -- Blur Quality --
uniform float MaxBlurAmount < ui_type = "slider"; ui_label = "Max Blurriness"; ui_tooltip = "The maximum blur amount applied to objects completely out of focus."; ui_min = MAX_BLUR_MIN; ui_max = MAX_BLUR_MAX; ui_category = "Blur Quality"; > = MAX_BLUR_DEFAULT;

// -- Debug Controls --
uniform bool EnableFocusLineDebug < ui_type = "input"; ui_text = "Hold Left Mouse Button"; ui_label = "Show Focus Line"; ui_tooltip = "Shows a yellow line over pixels at the exact focus depth while left mouse button is held."; ui_category = "Debug"; ui_category_closed = true; > = false;

// ============================================================================
// Final Mix
// ============================================================================
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// ============================================================================
// PIXEL SHADERS
// ============================================================================

// PASS 1: Calculate Circle of Confusion (CoC)
float4 PS_TiltShift_CoC(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 color = tex2D(ReShade::BackBuffer, texcoord);
    float linear_depth = ReShade::GetLinearizedDepth(texcoord);

    // Calculate distance from focus plane, creating a sharp zone in the middle
    float depth_diff = abs(linear_depth - FocusDepth) - (FocusZoneSize * FOCUS_ZONE_SCALE);

    // Calculate CoC (0.0 = sharp, 1.0 = blurry)
    float coc = saturate(depth_diff * FocusFalloff);

    return float4(color.rgb, coc);
}

// PASS 2: Horizontal Gaussian Blur
float4 PS_TiltShift_BlurH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 centerTap = tex2D(s_as_TiltShiftTex0, texcoord);
    float coc = centerTap.a;
    float center_depth = ReShade::GetLinearizedDepth(texcoord);
    int nSteps = floor(coc * MaxBlurAmount);

    if (nSteps <= 0) return centerTap;

    float3 gaussianSum = centerTap.rgb;
    float gaussianSumWeight = 1.0;

    const float expCoeff = -2.0 / (nSteps * nSteps + BLUR_EXP_COEFF_EPSILON);
    const float2 blurAxisScaled = float2(ReShade::PixelSize.x, 0.0);

    for (float iStep = -nSteps; iStep <= nSteps; iStep++)
    {
        if (iStep == 0) continue;

        float offset = BLUR_AXIS_SCALE * iStep - BLUR_OFFSET_BIAS;
        float2 sample_coord = texcoord + blurAxisScaled * offset;
        float4 currentTap = tex2Dlod(s_as_TiltShiftTex0, float4(sample_coord, 0, 0));

        float weight = exp(iStep * iStep * expCoeff);
        
        // --- Depth-Aware Anti-Bleed Logic ---
        float tap_depth = ReShade::GetLinearizedDepth(sample_coord);
        if (tap_depth > center_depth) // If sample is BEHIND the center pixel
        {
            // Reduce weight to prevent background bleeding over foreground
            weight *= saturate(1.0 - (currentTap.a - coc) * DEPTH_BLEED_FACTOR);
        }
        // If sample is IN FRONT, full weight is used, allowing foreground to bleed.

        gaussianSum += currentTap.rgb * weight;
        gaussianSumWeight += weight;
    }

    return float4(gaussianSum / gaussianSumWeight, coc);
}

// PASS 3: Vertical Gaussian Blur and Final Composite
float4 PS_TiltShift_BlurV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 centerTap = tex2D(s_as_TiltShiftTex1, texcoord);
    float coc = centerTap.a;
    float center_depth = ReShade::GetLinearizedDepth(texcoord);
    int nSteps = floor(coc * MaxBlurAmount);

    float3 blurred_color;
    if (nSteps <= 0) {
        blurred_color = centerTap.rgb;
    } else {
        float3 gaussianSum = centerTap.rgb;
        float gaussianSumWeight = 1.0;

        const float expCoeff = -2.0 / (nSteps * nSteps + BLUR_EXP_COEFF_EPSILON);
        const float2 blurAxisScaled = float2(0.0, ReShade::PixelSize.y);

        for (float iStep = -nSteps; iStep <= nSteps; iStep++)
        {
            if (iStep == 0) continue;

            float offset = BLUR_AXIS_SCALE * iStep - BLUR_OFFSET_BIAS;
            float2 sample_coord = texcoord + blurAxisScaled * offset;
            float4 currentTap = tex2Dlod(s_as_TiltShiftTex1, float4(sample_coord, 0, 0));

            float weight = exp(iStep * iStep * expCoeff);

            // --- Depth-Aware Anti-Bleed Logic ---
            float tap_depth = ReShade::GetLinearizedDepth(sample_coord);
            if (tap_depth > center_depth) // If sample is BEHIND the center pixel
            {
                // Reduce weight to prevent background bleeding over foreground
                weight *= saturate(1.0 - (currentTap.a - coc) * DEPTH_BLEED_FACTOR);
            }
            // If sample is IN FRONT, full weight is used, allowing foreground to bleed.

            gaussianSum += currentTap.rgb * weight;
            gaussianSumWeight += weight;
        }        blurred_color = gaussianSum / gaussianSumWeight;
    }

    // Apply blend controls
    float4 original_color = tex2D(ReShade::BackBuffer, texcoord);
    float3 final_color = AS_applyBlend(blurred_color, original_color.rgb, BlendMode);
    final_color = lerp(original_color.rgb, final_color, BlendStrength);

    // Debug: Show focus line when left mouse button is held
    if (EnableFocusLineDebug) {
        float current_depth = ReShade::GetLinearizedDepth(texcoord);
        float depth_tolerance = 0.005; // Small tolerance for depth matching
        
        // Check if current pixel depth is very close to focus depth
        if (abs(current_depth - FocusDepth) < depth_tolerance) {
            // Overlay yellow line with some transparency
            final_color = lerp(final_color, float3(1.0, 1.0, 0.0), 0.6);
        }
    }

    return float4(final_color, 1.0);
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_TiltShift <
    ui_label = "[AS] GFX: Tilt Shift";
    ui_tooltip = "High-quality, depth-aware tilt-shift effect with realistic bokeh.\n"
                 "Creates selective focus by blurring objects outside the chosen depth plane.";
 requires_depth = true; >
{
    pass CoC_Pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_TiltShift_CoC;
        RenderTarget = as_TiltShiftTex0;
    }
    pass BlurH_Pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_TiltShift_BlurH;
        RenderTarget = as_TiltShiftTex1;
    }
    pass BlurV_Pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_TiltShift_BlurV;
    }
}

#endif // __AS_GFX_TiltShift_1_fx
