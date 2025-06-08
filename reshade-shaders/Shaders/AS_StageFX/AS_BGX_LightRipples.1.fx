/**
 * AS_BGX_LightRipples.1.fx - Kaleidoscopic rippling light effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *  * CREDITS:
 * Based on "Creation by Silexars" by Danguafer/Danilo Guanabara
 * Shadertoy: https://www.shadertoy.com/view/XsXXDn
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a mesmerizing, rippling kaleidoscopic light pattern effect.
 * Suitable as a dynamic background or overlay. Includes controls for animation,
 * distortion, color palettes, audio reactivity, and scene integration.
 *
 * FEATURES:
 * - Rippling kaleidoscopic light patterns
 * - Customizable distortion parameters (amplitude, frequencies)
 * - Adjustable animation speed
 * - Optional color palettes with cycling
 * - Audio reactivity support
 * - Depth-aware rendering
 * - Adjustable rotation
 * - Standard blending options
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates distortion patterns based on distance and time
 * 2. Applies channel-specific time offsets for RGB separation
 * 3. Creates cell-centered patterns with customizable intensity * 4. Processes color through mathematical or palette-based methods
 * 5. Applies audio reactivity to key parameters
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_LightRipples_1_fx
#define __AS_BGX_LightRipples_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"     
#include "AS_Palette.1.fxh"  

namespace ASLightRipples {

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Pattern/Distortion ---
static const float Z_OFFSET_PER_CHANNEL_MIN = 0.0;
static const float Z_OFFSET_PER_CHANNEL_MAX = 0.5;
static const float Z_OFFSET_PER_CHANNEL_STEP = 0.01;
static const float Z_OFFSET_PER_CHANNEL_DEFAULT = 0.07;

static const float DISTORT_SIN_Z_AMP_MIN = 0.0;     // Min value for sin(z) is -1. +1 makes it 0.
static const float DISTORT_SIN_Z_AMP_MAX = 2.0;     // Max value for sin(z) is 1. +1 makes it 2.
static const float DISTORT_SIN_Z_AMP_STEP = 0.05;
static const float DISTORT_SIN_Z_AMP_DEFAULT = 1.0; // This matches the '+1.0' in the original

static const float DISTORT_SIN_L_FREQ_MIN = 1.0;
static const float DISTORT_SIN_L_FREQ_MAX = 25.0;
static const float DISTORT_SIN_L_FREQ_STEP = 0.5;
static const float DISTORT_SIN_L_FREQ_DEFAULT = 9.0;

static const float DISTORT_SIN_Z_FREQ_MIN = 0.0;
static const float DISTORT_SIN_Z_FREQ_MAX = 5.0;
static const float DISTORT_SIN_Z_FREQ_STEP = 0.1;
static const float DISTORT_SIN_Z_FREQ_DEFAULT = 2.0; // Matches '-z-z' -> '-2.0*z'

static const float CHANNEL_INTENSITY_NUMERATOR_MIN = 0.001;
static const float CHANNEL_INTENSITY_NUMERATOR_MAX = 0.1;
static const float CHANNEL_INTENSITY_NUMERATOR_STEP = 0.001;
static const float CHANNEL_INTENSITY_NUMERATOR_DEFAULT = 0.01;

static const float FINAL_DISTANCE_FADE_FACTOR_MIN = 0.1;
static const float FINAL_DISTANCE_FADE_FACTOR_MAX = 5.0;
static const float FINAL_DISTANCE_FADE_FACTOR_STEP = 0.05;
static const float FINAL_DISTANCE_FADE_FACTOR_DEFAULT = 1.0; // Original just divides by l (factor = 1.0)

// --- Animation ---
static const float ANIMATION_SPEED_MIN = 0.0;
static const float ANIMATION_SPEED_MAX = 5.0;
static const float ANIMATION_SPEED_STEP = 0.01;
static const float ANIMATION_SPEED_DEFAULT = 1.0;
static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_STEP = 0.1;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// --- Position ---
static const float POSITION_MIN = -1.5;
static const float POSITION_MAX = 1.5;
static const float POSITION_STEP = 0.01;
static const float POSITION_DEFAULT = 0.0;
static const float SCALE_MIN = 0.1;
static const float SCALE_MAX = 5.0;
static const float SCALE_STEP = 0.01;
static const float SCALE_DEFAULT = 1.0;

// --- Audio ---
static const int AUDIO_TARGET_DEFAULT = 4;
static const float AUDIO_MULTIPLIER_DEFAULT = 1.0;
static const float AUDIO_MULTIPLIER_MAX = 2.0;

// --- Palette & Style ---
static const float ORIG_COLOR_INTENSITY_DEFAULT = 1.0;
static const float ORIG_COLOR_INTENSITY_MAX = 3.0;
static const float ORIG_COLOR_SATURATION_DEFAULT = 1.0;
static const float ORIG_COLOR_SATURATION_MAX = 2.0;
static const float COLOR_CYCLE_SPEED_DEFAULT = 0.1;
static const float COLOR_CYCLE_SPEED_MAX = 2.0;

// --- Internal Constants ---
static const float EPSILON = 1e-5f; // Adjusted epsilon slightly
static const float HALF_POINT = 0.5f; 
static const int MAX_LOOP_ITERATIONS = 3; // Fixed loop count from original

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Pattern/Distortion ---
uniform float UI_ZOffsetPerChannel < ui_type = "slider"; ui_label = "RGB Time Offset"; ui_tooltip = "Time offset between RGB channels, affects color separation."; ui_min = Z_OFFSET_PER_CHANNEL_MIN; ui_max = Z_OFFSET_PER_CHANNEL_MAX; ui_step = Z_OFFSET_PER_CHANNEL_STEP; ui_category = "Pattern/Distortion"; > = Z_OFFSET_PER_CHANNEL_DEFAULT;
uniform float UI_DistortSinZAmp < ui_type = "slider"; ui_label = "Distortion Amplitude (Time)"; ui_tooltip = "Amplitude of time-based distortion wave (sin(z)+Amp)."; ui_min = DISTORT_SIN_Z_AMP_MIN; ui_max = DISTORT_SIN_Z_AMP_MAX; ui_step = DISTORT_SIN_Z_AMP_STEP; ui_category = "Pattern/Distortion"; > = DISTORT_SIN_Z_AMP_DEFAULT;
uniform float UI_DistortSinLFreq < ui_type = "slider"; ui_label = "Distortion Frequency (Distance)"; ui_tooltip = "Frequency of distance-based distortion wave (sin(l*Freq - ...))."; ui_min = DISTORT_SIN_L_FREQ_MIN; ui_max = DISTORT_SIN_L_FREQ_MAX; ui_step = DISTORT_SIN_L_FREQ_STEP; ui_category = "Pattern/Distortion"; > = DISTORT_SIN_L_FREQ_DEFAULT;
uniform float UI_DistortSinZFreq < ui_type = "slider"; ui_label = "Distortion Frequency (Time)"; ui_tooltip = "Frequency of time component in distance distortion wave (sin(... - Freq*z))."; ui_min = DISTORT_SIN_Z_FREQ_MIN; ui_max = DISTORT_SIN_Z_FREQ_MAX; ui_step = DISTORT_SIN_Z_FREQ_STEP; ui_category = "Pattern/Distortion"; > = DISTORT_SIN_Z_FREQ_DEFAULT;
uniform float UI_ChannelIntensityNumerator < ui_type = "slider"; ui_label = "Line Brightness/Thickness"; ui_tooltip = "Numerator controlling brightness/thickness of pattern lines (Num / dist_to_cell_center)."; ui_min = CHANNEL_INTENSITY_NUMERATOR_MIN; ui_max = CHANNEL_INTENSITY_NUMERATOR_MAX; ui_step = CHANNEL_INTENSITY_NUMERATOR_STEP; ui_category = "Pattern/Distortion"; > = CHANNEL_INTENSITY_NUMERATOR_DEFAULT;
uniform float UI_FinalDistanceFadeFactor < ui_type = "slider"; ui_label = "Center Fade Strength"; ui_tooltip = "Multiplier for fading effect towards the center (Mult / distance_from_center)."; ui_min = FINAL_DISTANCE_FADE_FACTOR_MIN; ui_max = FINAL_DISTANCE_FADE_FACTOR_MAX; ui_step = FINAL_DISTANCE_FADE_FACTOR_STEP; ui_category = "Pattern/Distortion"; > = FINAL_DISTANCE_FADE_FACTOR_DEFAULT;

// --- Palette & Style ---
uniform bool UseOriginalColors < ui_label = "Use Original Math Colors"; ui_tooltip = "When enabled, uses the mathematically calculated RGB colors instead of palettes."; ui_category = "Palette & Style"; > = true;
uniform float OriginalColorIntensity < ui_type = "slider"; ui_label = "Original Color Intensity"; ui_tooltip = "Adjusts the intensity of original colors when enabled."; ui_min = 0.1; ui_max = ORIG_COLOR_INTENSITY_MAX; ui_step = 0.01; ui_category = "Palette & Style"; ui_spacing = 0; > = ORIG_COLOR_INTENSITY_DEFAULT;
uniform float OriginalColorSaturation < ui_type = "slider"; ui_label = "Original Color Saturation"; ui_tooltip = "Adjusts the saturation of original colors when enabled."; ui_min = 0.0; ui_max = ORIG_COLOR_SATURATION_MAX; ui_step = 0.01; ui_category = "Palette & Style"; > = ORIG_COLOR_SATURATION_DEFAULT;
AS_PALETTE_SELECTION_UI(PalettePreset, "Color Palette", AS_PALETTE_NEON, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(LightRipples_, "Palette & Style")
uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast palette colors cycle. 0 = static."; ui_min = -COLOR_CYCLE_SPEED_MAX; ui_max = COLOR_CYCLE_SPEED_MAX; ui_step = 0.1; ui_category = "Palette & Style"; > = COLOR_CYCLE_SPEED_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_UI(LightRipples_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(LightRipples_AudioMultiplier, "Audio Intensity", AUDIO_MULTIPLIER_DEFAULT, AUDIO_MULTIPLIER_MAX, "Audio Reactivity")
uniform int LightRipples_AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_items = "None\0Animation Speed\0Distortion Amplitude (Time)\0Distortion Frequency (Distance)\0Line Brightness\0"; ui_category = "Audio Reactivity"; > = AUDIO_TARGET_DEFAULT;

// --- Animation ---
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// --- Stage/Position ---
AS_POSITION_SCALE_UI(Position, Scale)
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendStrength)

// --- Debug ---
AS_DEBUG_UI("Off\0Show Audio Reactivity\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get color from the currently selected palette
float3 getLightRipplesColor(float t, float time) {
    if (ColorCycleSpeed != 0.0) {
        float cycleRate = ColorCycleSpeed * 0.1;
        t = frac(t + cycleRate * time);
    }
    t = saturate(t); 
    
    if (PalettePreset == AS_PALETTE_CUSTOM) { // Use custom palette
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(LightRipples_, t);
    }
    return AS_getInterpolatedColor(PalettePreset, t); // Use preset palette
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 LightRipplesPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
    // Get original pixel color and depth
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);

    // Apply depth test
    if (depth < EffectDepth) {
        return originalColor;
    }

    // Apply audio reactivity to selected parameters
    float animSpeed = AnimationSpeed;
    float distortSinZAmp = UI_DistortSinZAmp;
    float distortSinLFreq = UI_DistortSinLFreq;
    float channelIntensityNumerator = UI_ChannelIntensityNumerator;
    
    float audioReactivity = AS_applyAudioReactivity(1.0, LightRipples_AudioSource, LightRipples_AudioMultiplier, true);
    
    // Map audio target combo index to parameter adjustment
    if (LightRipples_AudioTarget == 1) animSpeed *= audioReactivity;
    else if (LightRipples_AudioTarget == 2) distortSinZAmp *= audioReactivity;
    else if (LightRipples_AudioTarget == 3) distortSinLFreq *= audioReactivity;
    else if (LightRipples_AudioTarget == 4) channelIntensityNumerator *= audioReactivity;

    // Calculate animation time with the standardized helper function
    float iTime = AS_getAnimationTime(animSpeed, AnimationKeyframe);

    // Get rotation in radians from snap and fine controls
    float rotationRadians = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
    
    // --- POSITION HANDLING ---
    // Step 1: Center and correct for aspect ratio
    float2 p_centered = (texcoord - 0.5) * 2.0;          // Center coordinates (-1 to 1)
    p_centered.x *= ReShade::AspectRatio;                // Correct for aspect ratio
    
    // Step 2: Apply rotation around center FIRST (negative rotation for clockwise)
    float sinRot, cosRot;
    sincos(-rotationRadians, sinRot, cosRot); // Negative sign for clockwise rotation
    float2 p_rotated = float2(
        p_centered.x * cosRot - p_centered.y * sinRot,
        p_centered.x * sinRot + p_centered.y * cosRot
    );
    
    // Step 3: Apply position and scale AFTER rotation
    float2 p_aspect = p_rotated / Scale - Position;
    
    // Calculate distance 'l' and normalized direction 'p_norm' once
    float l = length(p_aspect);
    float2 p_norm = (l > EPSILON) ? p_aspect / l : float2(0.0f, 0.0f);

    // Initialization for loop
    float3 accumulated_c = float3(0.0f, 0.0f, 0.0f); 
    float z = iTime; 

    // Loop 3 times for R, G, B channels
    [loop] // Hint to compiler
    for (int i = 0; i < MAX_LOOP_ITERATIONS; ++i) 
    {
        // Apply the rotation to the texcoord for distortion calculation to keep arms aligned
        float2 rotated_texcoord = texcoord;
        // Center the coordinates for rotation
        rotated_texcoord = rotated_texcoord - 0.5;
        // Apply the rotation
        rotated_texcoord = float2(
            rotated_texcoord.x * cosRot - rotated_texcoord.y * sinRot,
            rotated_texcoord.x * sinRot + rotated_texcoord.y * cosRot
        );
        // Move back to [0,1] range
        rotated_texcoord = rotated_texcoord + 0.5;
        
        float2 uv = rotated_texcoord; 
        z += UI_ZOffsetPerChannel; 

        // Calculate UV distortion - use the rotated direction vector
        float distortion_magnitude = (sin(z) + distortSinZAmp) * abs(sin(l * distortSinLFreq - UI_DistortSinZFreq * z));
        uv += p_norm * distortion_magnitude;

        // Calculate channel value based on distance from wrapped cell center
        float2 wrapped_uv_centered = frac(uv) - HALF_POINT; 
        float dist_cell_center = length(wrapped_uv_centered);
        dist_cell_center = max(dist_cell_center, EPSILON); // Avoid division by zero

        float channel_val = channelIntensityNumerator / dist_cell_center;

        // Assign to R, G, or B component
        if (i == 0) accumulated_c.r = channel_val;
        else if (i == 1) accumulated_c.g = channel_val;
        else accumulated_c.b = channel_val; 
    }

    // --- Final Color Processing ---
    l = max(l, EPSILON); // Avoid division by zero if pixel is exactly at center
    float3 raw_rgb = (accumulated_c / l) * UI_FinalDistanceFadeFactor;

    float3 finalRGB;
    if (UseOriginalColors) {
        // Use the raw math-based colors, adjusted by user controls
        finalRGB = raw_rgb * OriginalColorIntensity;
        
        // Apply saturation adjustment
        float3 grayColor = dot(finalRGB, float3(0.299f, 0.587f, 0.114f)); // Luma calculation
        finalRGB = lerp(grayColor, finalRGB, OriginalColorSaturation);
    } else {
        // Use palette-based colors
        // Map intensity to palette (using length as a simple measure)
        float intensity = saturate(length(raw_rgb) / sqrt(3.0f)); // Normalize intensity roughly
        float3 paletteColor = getLightRipplesColor(intensity, iTime); // Use helper function
        finalRGB = paletteColor * (intensity * 0.8f + 0.2f); // Apply intensity back to palette color
    }
    
    // Ensure final color is valid
    finalRGB = saturate(finalRGB); // Clamp to [0,1] range

    float4 effectColor = float4(finalRGB, 1.0f);

    // --- Final Blending & Debug ---
    float4 finalColor = float4(AS_applyBlend(effectColor.rgb, originalColor.rgb, BlendMode), 1.0f);
    finalColor = lerp(originalColor, finalColor, BlendStrength);
    
    // Show debug overlay if enabled
    if (DebugMode != AS_DEBUG_OFF) {
        float4 debugMask = float4(0, 0, 0, 0);
        if (DebugMode == 1) { // Show Audio Reactivity
             debugMask = float4(audioReactivity, audioReactivity, audioReactivity, 1.0);
        }
        
        float2 debugCenter = float2(0.1f, 0.1f); // Example position
        float debugRadius = 0.08f;
        if (length(texcoord - debugCenter) < debugRadius) {
            return debugMask;
        }
    }
    
    return finalColor;
}

} // namespace ASLightRipples

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_LightRipples < ui_label="[AS] BGX: Light Ripples"; ui_tooltip="Kaleidoscopic rippling light effect by Danilo Guanabara, ported by Leon Aquitaine.";>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ASLightRipples::LightRipplesPS;
    }
}

#endif // __AS_BGX_LightRipples_1_fx


