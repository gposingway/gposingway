/**
 * AS_VFX_StencilMask.1.fx - Creates a stencil mask effect with borders and shadows.
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Isolates foreground subjects based on depth and applies customizable borders
 * and projected shadows around them. Includes options for various border styles,
 * shadow appearance, and audio reactivity for dynamic effects.
 *
 * FEATURES:
 * - Depth-based subject isolation.
 * - Multiple border styles (Solid, Glow, Pulse, Dash, Double Line).
 * - Customizable border color, opacity, thickness, and smoothing.
 * - Optional projected shadow with customizable color, opacity, offset, and blur (blur/expand not yet implemented).
 * - Audio reactivity via Listeningway for border thickness, pulse, and shadow movement.
 * - Debug modes for visualizing masks.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Create a binary mask based on depth (ForegroundPlane).
 * 2. Dilate the mask based on BorderThickness and BorderSmoothing settings.
 * 3. Apply optional smoothing (MeltStrength) to the dilated mask.
 * 4. Apply selected BorderStyle, potentially using audio input (Pulse).
 * 5. Calculate a similar mask for the shadow at an offset (ShadowOffset), potentially moved by audio.
 * 6. Composite the shadow, border, and original subject color.
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_StencilMask_1_fx
#define __AS_VFX_StencilMask_1_fx

#include "AS_Utils.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
// Using AS_PI from AS_Utils instead of local PI definition
static const int MAX_SHADOW_SAMPLES = 16; // Note: Not currently used, consider removing if final
static const float MAX_EDGE_BIAS = 10.0; // Note: Not currently used, consider removing if final
static const float FOREGROUNDPLANE_MIN = 0.0;
static const float FOREGROUNDPLANE_MAX = 1.0;
static const float FOREGROUNDPLANE_DEFAULT = 0.05;
static const float BORDEROPACITY_MIN = 0.0;
static const float BORDEROPACITY_MAX = 1.0;
static const float BORDEROPACITY_DEFAULT = 1.0;
static const float BORDERTHICKNESS_MIN = 0.0;
static const float BORDERTHICKNESS_MAX = 0.25;
static const float BORDERTHICKNESS_DEFAULT = 0.02;
static const float MELTSTRENGTH_MIN = 0.0;
static const float MELTSTRENGTH_MAX = 1.0;
static const float MELTSTRENGTH_DEFAULT = 0.0;
static const float SHADOWOPACITY_MIN = 0.0;
static const float SHADOWOPACITY_MAX = 1.0;
static const float SHADOWOPACITY_DEFAULT = 0.5;
static const float SHADOWOFFSET_MIN = -0.05;
static const float SHADOWOFFSET_MAX = 0.05;
static const float SHADOWOFFSET_DEFAULT_X = 0.003;
static const float SHADOWOFFSET_DEFAULT_Y = 0.003;
static const float SHADOWBLUR_MIN = 0.0;
static const float SHADOWBLUR_MAX = 20.0;
static const float SHADOWBLUR_DEFAULT = 4.0;
static const float SHADOWEXPAND_MIN = 0.0;
static const float SHADOWEXPAND_MAX = 5.0;
static const float SHADOWEXPAND_DEFAULT = 1.5;

// --- Subject Detection ---
uniform float ForegroundPlane < ui_type = "slider"; ui_label = "Foreground Plane"; ui_tooltip = "Depth threshold for foreground subjects."; ui_min = FOREGROUNDPLANE_MIN; ui_max = FOREGROUNDPLANE_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = FOREGROUNDPLANE_DEFAULT;

// --- Border Settings ---
uniform int BorderStyle < ui_type = "combo"; ui_label = "Border Style"; ui_items = "Solid\0Glow\0Dash\0"; ui_category = "Effect-Specific Appearance"; > = 0; // Category updated
uniform float3 BorderColor < ui_type = "color"; ui_label = "Border Color"; ui_category = "Effect-Specific Appearance"; > = float3(1.0, 1.0, 1.0); // Category updated
uniform float BorderOpacity < ui_type = "slider"; ui_label = "Border Opacity"; ui_min = BORDEROPACITY_MIN; ui_max = BORDEROPACITY_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = BORDEROPACITY_DEFAULT; // Renamed, Label updated, Category updated
uniform float BorderThickness < ui_type = "slider"; ui_label = "Border Thickness"; ui_min = BORDERTHICKNESS_MIN; ui_max = BORDERTHICKNESS_MAX; ui_step = 0.001; ui_category = "Effect-Specific Appearance"; > = BORDERTHICKNESS_DEFAULT; // Category updated
uniform float MeltStrength < ui_type = "slider"; ui_label = "Border Melt"; ui_tooltip = "Smooths/melts jagged border ends. 0 = off, higher = more smoothing."; ui_min = MELTSTRENGTH_MIN; ui_max = MELTSTRENGTH_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = MELTSTRENGTH_DEFAULT; // Category updated
// 0: 4 dir, 1: 8 dir, 2: 16 dir, 3: 32 dir, 4: 64 dir
uniform int BorderSmoothing < ui_type = "combo"; ui_label = "Border Smoothing"; ui_items = "Potato\0Low\0Medium\0High\0AI Overlord\0"; ui_category = "Effect-Specific Appearance"; > = 2; // Category updated

// --- Shadow Settings ---
uniform bool EnableShadow < ui_label = "Enable Shadow"; ui_category = "Effect-Specific Appearance"; > = true; // Category updated
uniform float3 ShadowColor < ui_type = "color"; ui_label = "Shadow Color"; ui_category = "Effect-Specific Appearance"; > = float3(0.0, 0.0, 0.0); // Category updated
uniform float ShadowOpacity < ui_type = "slider"; ui_label = "Shadow Opacity"; ui_min = SHADOWOPACITY_MIN; ui_max = SHADOWOPACITY_MAX; ui_step = 0.01; ui_category = "Effect-Specific Appearance"; > = SHADOWOPACITY_DEFAULT; // Renamed, Label updated, Category updated
uniform float2 ShadowOffset < ui_type = "slider"; ui_min = SHADOWOFFSET_MIN; ui_max = SHADOWOFFSET_MAX; ui_step = 0.001; ui_label = "Shadow Offset"; ui_category = "Effect-Specific Appearance"; > = float2(SHADOWOFFSET_DEFAULT_X, SHADOWOFFSET_DEFAULT_Y); // Category updated
uniform float ShadowBlur < ui_type = "slider"; ui_label = "Shadow Blur"; ui_min = SHADOWBLUR_MIN; ui_max = SHADOWBLUR_MAX; ui_step = 0.1; ui_category = "Effect-Specific Appearance"; > = SHADOWBLUR_DEFAULT; // Category updated // Note: Not currently used, consider implementing or removing
uniform float ShadowExpand < ui_type = "slider"; ui_label = "Shadow Expand"; ui_min = SHADOWEXPAND_MIN; ui_max = SHADOWEXPAND_MAX; ui_step = 0.1; ui_category = "Effect-Specific Appearance"; > = SHADOWEXPAND_DEFAULT; // Category updated // Note: Not currently used, consider implementing or removing

// --- Audio Reactivity ---
// Use standard AS_Utils audio macros and controls
uniform float AudioIntensity < ui_type = "slider"; ui_label = "Audio Intensity"; ui_tooltip = "Scales the audio input for all audio-reactive features."; ui_min = 0.0; ui_max = 3.0; ui_step = 0.01; ui_category = "Audio Reactivity"; > = 1.0;

// Audio source selectors for each reactive parameter
uniform int BorderPulseSource < ui_type = "combo"; ui_label = "Border Pulse Source"; ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0Mid\0"; ui_tooltip = "Audio source that controls border pulsing effect."; ui_category = "Audio Reactivity"; > = 3; // Default to Beat

uniform int BorderThicknessSource < ui_type = "combo"; ui_label = "Border Thickness Source"; ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0Mid\0"; ui_tooltip = "Audio source that controls border thickness modulation."; ui_category = "Audio Reactivity"; > = 2; // Default to Volume

uniform int ShadowMovementSource < ui_type = "combo"; ui_label = "Shadow Movement Source"; ui_items = "Off\0Solid\0Volume\0Beat\0Bass\0Treble\0Mid\0"; ui_tooltip = "Audio source that controls shadow movement."; ui_category = "Audio Reactivity"; > = 4; // Default to Bass

// --- Debug ---
// Direct uniform for debug dropdown to bypass macro issues
uniform int DebugMode < ui_type = "combo"; ui_label = "Debug View"; ui_items = "Off\0Subject Mask\0Border Only\0Shadow Only\0Audio\0"; ui_category = "Debug"; > = 0;

// --- Helper Functions ---
namespace AS_StencilMask {

    // Create subject mask (1.0 for subject, 0.0 for background)
    float subjectMask(float2 texcoord) {
        float depth = ReShade::GetLinearizedDepth(texcoord);
        return depth < ForegroundPlane ? 1.0 : 0.0;
    }

    // Helper to get minimum screen dimension
    float minScreenDim() {
        return min(ReShade::ScreenSize.x, ReShade::ScreenSize.y);
    }

    // 2D Dilation with variable directions
    float dilateMask_2D(float2 texcoord, float thicknessNorm, int directions) {
        float2 pixelSize = ReShade::PixelSize;
        float minDim = minScreenDim();
        float radius = thicknessNorm * minDim;
        float maxMask = 0.0;
        for (int i = 0; i < directions; i++) {
            float angle = (AS_PI * 2.0 / directions) * i;
            float2 offset = float2(cos(angle), sin(angle)) * pixelSize * radius;
            float mask = subjectMask(texcoord + offset);
            maxMask = max(maxMask, mask);
        }
        maxMask = max(maxMask, subjectMask(texcoord));
        return maxMask;
    }

    // Smoothing (melt) for the dilated mask only
    float smoothDilatedMask(float2 texcoord, float thicknessNorm, int smoothingMode, float meltStrength) {
        int directions = 4;
        if (smoothingMode == 1) directions = 8;
        else if (smoothingMode == 2) directions = 16;
        else if (smoothingMode == 3) directions = 32;
        else if (smoothingMode == 4) directions = 64;
        if (meltStrength <= 0.0) {
            return dilateMask_2D(texcoord, thicknessNorm, directions);
        }
        float2 pixelSize = ReShade::PixelSize;
        float sum = 0.0;
        float weightSum = 0.0;
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                float2 offset = float2(x, y) * pixelSize * meltStrength;
                float sampleValue = dilateMask_2D(texcoord + offset, thicknessNorm, directions);
                float weight = 1.0;
                sum += sampleValue * weight;
                weightSum += weight;
            }
        }
        return sum / weightSum;
    }    // Animated border styles
    float applyBorderStyle(float borderMask, float time, int style, float audioPulse, float2 texcoord) {
        if (style == 0) return borderMask; // Solid
        if (style == 1) return borderMask * (0.75 + AS_QUARTER * sin(time * 2.0)); // Glow
        // style == 2 is now Dash
        if (style == 2) { // Dash
            float dash = sin(texcoord.x * 50.0 + time * 2.0) * AS_HALF + AS_HALF;
            return borderMask * smoothstep(0.4, 0.6, dash);
        }
        return borderMask;
    }

    // Note: meltBorder function was complex and potentially inefficient for single-pass.
    // The smoothDilatedMask function with MeltStrength achieves a similar goal more directly.
    // Removing meltBorder to simplify.

} // end namespace AS_StencilMask

// --- Main Effect ---
float4 PS_StencilMask(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    if (DebugMode == 4) {
        // Use AS_getAudioSource instead of direct Listeningway_Beat reference
        float audioValue = AS_getAudioSource(AS_AUDIO_BEAT);
        return float4(audioValue, audioValue, audioValue, 1.0);
    }
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float time = AS_getTime();

    // --- Audio Reactivity Values ---
    float audioPulse = 0.0;
    float shadowMovement = 0.0;
    float borderThicknessAudio = 0.0;
    
    // Get audio values based on selected sources using AS_Utils functions
    // Border Pulse
    audioPulse = AS_getAudioSource(BorderPulseSource);
    
    // Shadow Movement
    shadowMovement = AS_getAudioSource(ShadowMovementSource);
    
    // Border Thickness
    borderThicknessAudio = AS_getAudioSource(BorderThicknessSource);
    
    // Apply audio intensity multiplier
    audioPulse *= AudioIntensity;
    shadowMovement *= AudioIntensity;
    borderThicknessAudio *= AudioIntensity;

    // --- Subject Mask ---
    float subjectMask = AS_StencilMask::subjectMask(texcoord);

    // --- Border Calculation ---
    float borderMask = 0.0;
    float borderThicknessReactive = BorderThickness + borderThicknessAudio * 0.1; // scale as needed
    borderThicknessReactive = max(0.0, borderThicknessReactive);
    float dilatedMask = AS_StencilMask::smoothDilatedMask(texcoord, borderThicknessReactive, BorderSmoothing, MeltStrength);
    borderMask = AS_StencilMask::applyBorderStyle(dilatedMask, time, BorderStyle, audioPulse, texcoord);

    // --- Shadow Calculation ---
    float shadowMask = 0.0;
    float2 dynamicOffset = ShadowOffset;
    dynamicOffset += float2(
        sin(time * 2.0) * shadowMovement * 0.01,
        cos(time * 1.7) * shadowMovement * 0.01
    );
    if (EnableShadow) {
        float2 shadowCoord = texcoord + dynamicOffset;
        float dilatedMaskShadow = AS_StencilMask::smoothDilatedMask(shadowCoord, borderThicknessReactive, BorderSmoothing, MeltStrength);
        shadowMask = AS_StencilMask::applyBorderStyle(dilatedMaskShadow, time, BorderStyle, audioPulse, shadowCoord);
    }

    // --- Debug Modes ---
    if (DebugMode == 1) return float4(subjectMask.xxx, 1.0);
    if (DebugMode == 2) return float4(BorderColor, borderMask * BorderOpacity);
    if (DebugMode == 3 && EnableShadow) return float4(ShadowColor, shadowMask * ShadowOpacity);

    // --- Compositing ---
    float4 result = originalColor;
    if (EnableShadow && shadowMask > 0.01) {
        result.rgb = lerp(result.rgb, ShadowColor, saturate(shadowMask * ShadowOpacity));
    }
    if (borderMask > 0.01) {
        result.rgb = lerp(result.rgb, BorderColor, saturate(borderMask * BorderOpacity));
    }
    float subjectBlendFactor = subjectMask;
    result.rgb = lerp(result.rgb, originalColor.rgb, subjectBlendFactor);
    result.a = originalColor.a;
    return result;
}

technique AS_StencilMask < ui_label = "[AS] VFX: Stencil Mask"; ui_tooltip = "Creates a stencil mask effect that isolates subjects with customizable borders and projected shadows."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_StencilMask;
    }
}

AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

#endif // __AS_VFX_StencilMask_1_fx
