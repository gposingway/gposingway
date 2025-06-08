/**
 * AS_BGX_TimeCrystal.1.fx - Fractal crystalline structure effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Time Crystal" by raphaeljmu
 * Shadertoy: https://www.shadertoy.com/view/lcl3z2
 * Created: 2023-12-22
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a hypnotic, crystalline fractal structure with dynamic animation and color cycling.
 * The effect generates a pattern reminiscent of crystalline structures or gems with depth and dimension.
 * Suitable for mystic or sci-fi backgrounds, portals, or energy fields.
 *
 * FEATURES:
 * - Fractal crystal-like patterns with customizable iterations
 * - Dynamic animation with controllable speed
 * - Adjustable pattern density and detail level
 * - Customizable color palettes with cycling
 * - Audio reactivity for pattern dynamics and colors
 * - Depth-aware rendering with standard blending options
 * - Adjustable position and rotation controls
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates iterative fractal patterns using domain folding techniques
 * 2. Calculates proximity functions for edge highlighting
 * 3. Applies time-based animation to pattern evolution
 * 4. Processes colors through mathematical or palette-based methods
 * 5. Applies audio reactivity to key parameters
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_TimeCrystal_1_fx
#define __AS_BGX_TimeCrystal_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"     
#include "AS_Palette.1.fxh"  

namespace ASTimeCrystal {
// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Tunable Constants ---
// Pattern
static const float ITERATIONS_MIN = 1.0;
static const float ITERATIONS_MAX = 12.0;
static const float ITERATIONS_STEP = 1.0;
static const float ITERATIONS_DEFAULT = 6.0;

static const float PATTERN_SCALE_MIN = 0.5;
static const float PATTERN_SCALE_MAX = 5.0;
static const float PATTERN_SCALE_STEP = 0.1;
static const float PATTERN_SCALE_DEFAULT = 1.0;

static const float EDGE_CURVE_MIN = 0.01;
static const float EDGE_CURVE_MAX = 1.0;
static const float EDGE_CURVE_STEP = 0.01;
static const float EDGE_CURVE_DEFAULT = 0.1;

static const float EDGE_MIN_X_MIN = 0.01;
static const float EDGE_MIN_X_MAX = 0.5;
static const float EDGE_MIN_X_STEP = 0.01;
static const float EDGE_MIN_X_DEFAULT = 0.1;

static const float EDGE_MIN_Y_MIN = 0.01;
static const float EDGE_MIN_Y_MAX = 0.5;
static const float EDGE_MIN_Y_STEP = 0.01;
static const float EDGE_MIN_Y_DEFAULT = 0.05;

static const float CENTER_FADE_MIN = 0.0;
static const float CENTER_FADE_MAX = 10.0;
static const float CENTER_FADE_STEP = 0.1;
static const float CENTER_FADE_DEFAULT = 3.0;

static const float PATTERN_FREQ_MIN = 0.1;
static const float PATTERN_FREQ_MAX = 10.0;
static const float PATTERN_FREQ_STEP = 0.1;
static const float PATTERN_FREQ_DEFAULT = 4.0;

// Animation
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_STEP = 0.01;
static const float ANIMATION_SPEED_DEFAULT = 1.0;

static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_STEP = 0.1;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// Audio (Defaults assumed, adjust as needed)
static const int AUDIO_TARGET_DEFAULT = 4; // Default to Center Fade
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0;
static const float AUDIO_MULTIPLIER_MAX = 3.0;

// Palette & Style (Defaults assumed, adjust as needed)
static const float ORIG_COLOR_INTENSITY_DEFAULT = 1.0;
static const float ORIG_COLOR_INTENSITY_MAX = 3.0;
static const float ORIG_COLOR_SATURATION_DEFAULT = 1.0;
static const float ORIG_COLOR_SATURATION_MAX = 2.0;
static const float COLOR_CYCLE_SPEED_DEFAULT = 0.5;
static const float COLOR_CYCLE_SPEED_MAX = 2.0;

// UI Declarations

// --- Pattern ---
uniform float UI_Iterations < ui_type = "slider"; ui_label = "Pattern Iterations"; ui_tooltip = "Number of fractal iterations. Higher values create more detailed patterns."; ui_min = ITERATIONS_MIN; ui_max = ITERATIONS_MAX; ui_step = ITERATIONS_STEP; ui_category = "Pattern"; > = ITERATIONS_DEFAULT;
uniform float UI_PatternScale < ui_type = "slider"; ui_label = "Pattern Scale"; ui_tooltip = "Overall scale of the crystal pattern."; ui_min = PATTERN_SCALE_MIN; ui_max = PATTERN_SCALE_MAX; ui_step = PATTERN_SCALE_STEP; ui_category = "Pattern"; > = PATTERN_SCALE_DEFAULT;
uniform float UI_EdgeCurve < ui_type = "slider"; ui_label = "Edge Curvature"; ui_tooltip = "Controls how sharp or smooth the crystal edges appear."; ui_min = EDGE_CURVE_MIN; ui_max = EDGE_CURVE_MAX; ui_step = EDGE_CURVE_STEP; ui_category = "Pattern"; > = EDGE_CURVE_DEFAULT;
uniform float UI_EdgeMinX < ui_type = "slider"; ui_label = "Edge Threshold X"; ui_tooltip = "Primary threshold for edge highlighting."; ui_min = EDGE_MIN_X_MIN; ui_max = EDGE_MIN_X_MAX; ui_step = EDGE_MIN_X_STEP; ui_category = "Pattern"; > = EDGE_MIN_X_DEFAULT;
uniform float UI_EdgeMinY < ui_type = "slider"; ui_label = "Edge Threshold Y"; ui_tooltip = "Secondary threshold for edge highlighting."; ui_min = EDGE_MIN_Y_MIN; ui_max = EDGE_MIN_Y_MAX; ui_step = EDGE_MIN_Y_STEP; ui_category = "Pattern"; > = EDGE_MIN_Y_DEFAULT;
uniform float UI_CenterFade < ui_type = "slider"; ui_label = "Center Fade"; ui_tooltip = "Fading effect towards the center. Higher values increase the fade."; ui_min = CENTER_FADE_MIN; ui_max = CENTER_FADE_MAX; ui_step = CENTER_FADE_STEP; ui_category = "Pattern"; > = CENTER_FADE_DEFAULT;
uniform float UI_PatternFrequency < ui_type = "slider"; ui_label = "Pattern Frequency"; ui_tooltip = "Frequency of patterns. Affects the detail density."; ui_min = PATTERN_FREQ_MIN; ui_max = PATTERN_FREQ_MAX; ui_step = PATTERN_FREQ_STEP; ui_category = "Pattern"; > = PATTERN_FREQ_DEFAULT;

// --- Palette & Style ---
uniform bool UseOriginalColors < ui_label = "Use Original Math Colors"; ui_tooltip = "When enabled, uses the mathematically calculated RGB colors instead of palettes."; ui_category = "Palette & Style"; > = true;
uniform float OriginalColorIntensity < ui_type = "slider"; ui_label = "Original Color Intensity"; ui_tooltip = "Adjusts the intensity of original colors when enabled."; ui_min = 0.1; ui_max = ORIG_COLOR_INTENSITY_MAX; ui_step = 0.01; ui_category = "Palette & Style"; ui_spacing = 0; > = ORIG_COLOR_INTENSITY_DEFAULT;
uniform float OriginalColorSaturation < ui_type = "slider"; ui_label = "Original Color Saturation"; ui_tooltip = "Adjusts the saturation of original colors when enabled."; ui_min = 0.0; ui_max = ORIG_COLOR_SATURATION_MAX; ui_step = 0.01; ui_category = "Palette & Style"; > = ORIG_COLOR_SATURATION_DEFAULT;
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(TimeCrystal_, "Palette & Style")
uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast palette colors cycle. 0 = static."; ui_min = -COLOR_CYCLE_SPEED_MAX; ui_max = COLOR_CYCLE_SPEED_MAX; ui_step = 0.1; ui_category = "Palette & Style"; > = COLOR_CYCLE_SPEED_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_UI(TimeCrystal_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(TimeCrystal_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int TimeCrystal_AudioTarget < 
    ui_type = "combo"; 
    ui_label = "Audio Target Parameter"; 
    ui_items = "None\0Animation Speed\0Pattern Frequency\0Edge Threshold\0Center Fade\0"; 
    ui_category = "Audio Reactivity"; 
> = AUDIO_TARGET_DEFAULT;

// --- Animation ---
uniform float AnimationKeyframe < ui_type = "slider"; ui_label = "Animation Keyframe"; ui_tooltip = "Sets a specific point in time for the animation. Useful for finding and saving specific patterns."; ui_min = ANIMATION_KEYFRAME_MIN; ui_max = ANIMATION_KEYFRAME_MAX; ui_step = ANIMATION_KEYFRAME_STEP; ui_category = "Animation"; > = ANIMATION_KEYFRAME_DEFAULT;
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall animation speed of the effect. Set to 0 to pause animation and use keyframe only."; ui_min = ANIMATION_SPEED_MIN; ui_max = ANIMATION_SPEED_MAX; ui_step = ANIMATION_SPEED_STEP; ui_category = "Animation"; > = ANIMATION_SPEED_DEFAULT;

// --- Stage ---
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)

// --- Final Mix ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// --- Debug ---
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Oscillate value between midpoint +/- amplitude
float oscillate(float midpoint, float amplitude, float phase) {
    return midpoint + amplitude * sin(phase * AS_PI);
}

// Original color calculation function (more mathematically precise)
float3 calculateOriginalColor(float t) {
    float3 e = float3(1.0, 1.0, 1.0);
    float3 a = 0.5 * e;
    float3 b = 0.5 * e;
    float3 c = 0.5 * e;
    float3 d = float3(0.263, 0.416, 0.557);

    return a + b * cos(2.0 * AS_PI * (c * t + d));
}

// Get color from the currently selected palette
float3 getTimeCrystalColor(float t, float time) {
    if (ColorCycleSpeed != 0.0) {
        float cycleRate = ColorCycleSpeed * 0.1;
        t = frac(t + cycleRate * time);
    }
    t = saturate(t);
    
    if (PalettePreset == AS_PALETTE_CUSTOM) { // Use custom palette
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(TimeCrystal_, t);
    }
    return AS_getInterpolatedColor(PalettePreset, t); // Use preset palette
}

// Calculate proximity function for edge highlighting
float proximity(float d, float curvature, float min_x, float min_y) {
    if (d <= min_x) {
        return 1.0;
    }

    float a = curvature;
    float X = min_x;
    float Y = min_y;
    float X2 = X * X;
    float Y2 = Y * Y;
    float XY = X * Y;

    float disc4 = 4.0 * (a * (XY - X - Y + 1.0) + XY);
    float disc2 = 2.0 * (X + Y) * (XY + 1.0);
    float disc = disc4 - disc2 + XY * XY + X2 + Y2 + 1.0;
    float c = ((X - 1.0) * (Y + 1.0) + sqrt(disc)) / (2.0 * (X - 1.0));

    float b = a / (1.0 - c) - X;

    return a / (d + b) + c;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 TimeCrystalPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET {
    // Get original pixel color and depth
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);

    // Apply depth test
    if (depth < EffectDepth) {
        return originalColor;
    }

    // Apply audio reactivity to selected parameters
    float animSpeed = AnimationSpeed;
    float patternFreq = UI_PatternFrequency;
    float edgeThreshold = UI_EdgeMinX;
    float centerFade = UI_CenterFade;
    
    float audioReactivity = AS_applyAudioReactivity(1.0, TimeCrystal_AudioSource, TimeCrystal_AudioMultiplier, true);
    
    // Map audio target combo index to parameter adjustment
    if (TimeCrystal_AudioTarget == 1) animSpeed *= audioReactivity;
    else if (TimeCrystal_AudioTarget == 2) patternFreq *= audioReactivity;
    else if (TimeCrystal_AudioTarget == 3) edgeThreshold *= audioReactivity;
    else if (TimeCrystal_AudioTarget == 4) centerFade *= audioReactivity;

    // Get time and calculate animation
    float time;
    if (AnimationSpeed <= 0.0001) {
        // When animation speed is effectively zero, use keyframe directly
        time = AnimationKeyframe;
    } else {
        // Otherwise use animated time plus keyframe offset
        time = (AS_getTime() * animSpeed) + AnimationKeyframe;
    }
    
    // Apply rotation to coordinates
    float2 screenCenter = float2(0.5, 0.5);
    float2 centeredCoord = texcoord - screenCenter;
    float aspectRatio = ReShade::ScreenSize.x / ReShade::ScreenSize.y;
    centeredCoord.x *= aspectRatio;
    
    float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    float s = sin(rotationRadians);
    float c = cos(rotationRadians);
    float2 rotatedCoord = float2(
        centeredCoord.x * c - centeredCoord.y * s,
        centeredCoord.x * s + centeredCoord.y * c
    );
    
    // Match original coordinate system
    float2 uv = (rotatedCoord * 2.0) * UI_PatternScale;
    float2 uv0 = uv; // Store original UV for later use

    // Generate fractal pattern
    float3 color = float3(0.0, 0.0, 0.0);
    float iterations = UI_Iterations;
    
    [loop]
    for (float i = 0.0; i < iterations; i++) {
        // Break if we've reached the max iterations
        if (i >= iterations) break;
        
        // Domain folding - fold UV space repeatedly
        uv = frac(uv) * 2.0 - 1.0;

        // Calculate distance field with center fade - matching original calculation
        float d = length(uv) * exp(-length(uv0) / centerFade);
        
        // Create pattern with time-based animation - matching original pattern frequency
        float d2 = sin(d * patternFreq * AS_PI + 2.0 * time);
        
        // Calculate edge proximity with original parameters for consistency
        float strength = proximity(abs(d2) + sin(AS_PI * d), UI_EdgeCurve, edgeThreshold, UI_EdgeMinY);

        // Get color for this iteration - match original color calculation
        float colorIndex = length(uv0) + i * 0.1 + 0.5 * time;
        
        // Accumulate color using the same approach as the original
        if (UseOriginalColors) {
            color += calculateOriginalColor(colorIndex) * strength;
        } else {
            color += getTimeCrystalColor(colorIndex, time) * strength;
        }
    }
    
    // Apply user controls to final color
    if (UseOriginalColors) {
        // Adjust intensity
        color *= OriginalColorIntensity;
        
        // Apply saturation adjustment
        float luminance = dot(color, float3(0.299, 0.587, 0.114));
        color = lerp(luminance, color, OriginalColorSaturation);
    }
    
    // Ensure color is valid
    color = saturate(color);
    
    // Create final effect color
    float4 effectColor = float4(color, 1.0);
    
    // Blend with original scene
    float4 finalColor = float4(AS_applyBlend(effectColor.rgb, originalColor.rgb, BlendMode), 1.0);
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

} // namespace ASTimeCrystal

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_TimeCrystal < ui_label="[AS] BGX: Time Crystal"; ui_tooltip="Fractal crystalline structure effect that evolves over time."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASTimeCrystal::TimeCrystalPS;
    }
}

#endif // __AS_BGX_TimeCrystal_1_fx


