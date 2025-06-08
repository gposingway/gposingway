/**
 * AS_VFX_CircularSpectrum.1.fx - Circular Audio Spectrum Dots Visualizer
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on "Circular audio visualizer" by AIandDesign (2025-05-24)
 * Shadertoy: https://www.shadertoy.com/view/tcyGW1
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader renders a circular audio visualizer as dots of light. It displays 
 * frequency bands as series of dots radiating from the center. The number of lit 
 * dots and their color (derived from the AS_Palette.1.fxh system) react to audio input 
 * from ListeningWay's FreqBands array via AS_Utils.1.fxh. Features include mirroring,
 * positioning, scaling, depth culling, palette controls, and standard blending.
 *
 * FEATURES:
 * - Audio-reactive "dots of light" from ListeningWay FreqBands.
 * - Integrated AS_Palette.1.fxh system for dot coloring, supporting predefined and custom palettes.
 * - Optional mirroring of the frequency spectrum display.
 * - Customizable sensitivity, scaling, dot appearance.
 * - Position, scale, and depth controls.
 * - Standard AS-StageFX blend modes.
 * - Adjustable bloom effect for glow.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Transforms screen coordinates using EffectCenter and EffectScale.
 * 2. Performs depth culling based on EffectDepth.
 * 3. Iterates through each visual "spoke" (angular division).
 * 4. For each spoke, determines its audio amplitude using interpolated frequency band sampling.
 * 5. Interpolates between adjacent frequency bands for smooth transitions when spokes > bands.
 * 6. Calculates how many "dots" should be lit along that spoke.
 * 7. For each lit dot, fetches an interpolated color from the selected AS_Palette 
 * (predefined or custom) based on its radial position and amplitude.
 * 8. Renders the dot if the pixel is close to the dot's center, using a circular falloff.
 * 9. Applies a multi-layer bloom effect, also using palette colors.
 * 10. Blends the final visualizer with the scene using standard AS_StageFX blend controls.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_VFX_CIRCULARSPECTRUMDOTS_1_FX
#define __AS_VFX_CIRCULARSPECTRUMDOTS_1_FX

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" 
#include "AS_Palette.1.fxh" // For AS_PALETTE_SELECTION_UI, AS_DECLARE_CUSTOM_PALETTE, etc.

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

// --- Audio Response ---
static const float AUDIO_MULT_MIN = AS_RANGE_AUDIO_MULT_MIN;
static const float AUDIO_MULT_MAX = AS_RANGE_AUDIO_MULT_MAX;
static const float AUDIO_MULT_DEFAULT = 1.4;

static const float SENSITIVITY_MIN = 0.5;
static const float SENSITIVITY_MAX = 5.0;
static const float SENSITIVITY_DEFAULT = 1.8;

// --- Audio Target Constants ---
static const int AUDIO_TARGET_NONE = 0;
static const int AUDIO_TARGET_DOT_SIZE = 1;
static const int AUDIO_TARGET_BLOOM_SIZE = 2;
static const int AUDIO_TARGET_BLOOM_INTENSITY = 3;
static const int AUDIO_TARGET_BLOOM_FALLOFF = 4;

// --- Animation ---
static const float ANIMATION_SPEED_MIN = AS_ANIMATION_SPEED_MIN;
static const float ANIMATION_SPEED_MAX = AS_ANIMATION_SPEED_MAX;
static const float ANIMATION_SPEED_DEFAULT = 1.0;

static const float ANIMATION_KEYFRAME_MIN = 0.0;
static const float ANIMATION_KEYFRAME_MAX = 100.0;
static const float ANIMATION_KEYFRAME_DEFAULT = 0.0;

// --- Dot Appearance ---
static const float DOT_SIZE_MIN = 0.25; 
static const float DOT_SIZE_MAX = 2.0;
static const float DOT_SIZE_DEFAULT = 0.75;

static const float RADIAL_GAP_MIN = 0.0; 
static const float RADIAL_GAP_MAX = 3.0;
static const float RADIAL_GAP_DEFAULT = 0.4;

static const int NUM_SPOKES_MIN = 16;
static const int NUM_SPOKES_MAX = 128; 
static const int NUM_SPOKES_DEFAULT = 64; 

static const int MAX_DOTS_PER_SPOKE_MIN = 5; 
static const int MAX_DOTS_PER_SPOKE_MAX = 30;
static const int MAX_DOTS_PER_SPOKE_DEFAULT = 15;

// --- Palette ---
static const int PALETTE_DEFAULT_SELECTION = AS_PALETTE_CUSTOM; 

// --- Effect Constants ---
static const float INNER_RADIUS_SCALE = 0.1;
static const float BASE_RADIAL_STEP_SCALE = 0.02;
static const float DOT_RADIUS_FACTOR = 0.45;
static const float RADIAL_GAP_FACTOR = 0.25;
static const float BLOOM_SIZE_DIVISOR = 50.0;

// --- LOD Constants ---
static const float LOD_DISTANCE_THRESHOLD = 0.4;
static const float LOD_MIN_QUALITY = 0.25;
static const int LOD_MIN_SPOKES = 8;
static const int LOD_MIN_DOTS = 3;

// --- Scaling Constants ---
static const float UI_POSITION_SCALE = AS_UI_POSITION_SCALE;

// --- Appearance ---
static const float BRIGHTNESS_MIN = 1.0;
static const float BRIGHTNESS_MAX = 8.0;
static const float BRIGHTNESS_DEFAULT = 3.5;
static const float BLOOM_SIZE_MIN = 1.0;
static const float BLOOM_SIZE_MAX = 15.0;
static const float BLOOM_SIZE_DEFAULT = 4.5;
static const float BLOOM_INTENSITY_MIN = 0.1;
static const float BLOOM_INTENSITY_MAX = 2.0;
static const float BLOOM_INTENSITY_DEFAULT = 0.7;
static const float BLOOM_FALLOFF_MIN = 1.0;
static const float BLOOM_FALLOFF_MAX = 4.0;
static const float BLOOM_FALLOFF_DEFAULT = 2.0;

// ============================================================================
// UNIFORMS
// ============================================================================

// --- Position ---
AS_POS_UI(EffectCenter) 
AS_SCALE_UI(EffectScale) 

// --- Palette & Style ---
AS_PALETTE_SELECTION_UI(PaletteSelection, "Dot Palette", PALETTE_DEFAULT_SELECTION, "Palette & Style") //
AS_DECLARE_CUSTOM_PALETTE(CircularSpectrum_, "Palette & Style") // Defines CircularSpectrum_CustomPaletteColor0..4

// --- Dot Appearance ---
uniform bool MirrorFreqBands < ui_label = "Mirror Frequency Bands"; ui_tooltip = "If true, spectrum is mirrored (0-Max-0 around circle). If false, linear (0-Max)."; ui_category = "Pattern"; > = false;
uniform float DotSizeMultiplier < ui_label = "Dot Size Multiplier"; ui_tooltip = "Adjusts the visual size of the dots. Range: 0.25 to 2.0"; ui_type = "slider"; ui_min = DOT_SIZE_MIN; ui_max = DOT_SIZE_MAX; ui_step = 0.05; ui_category = "Pattern"; > = DOT_SIZE_DEFAULT;
uniform float RadialGapMultiplier < ui_label = "Radial Gap Multiplier"; ui_tooltip = "Controls the radial spacing between dot centers. Range: 0.0 to 3.0"; ui_type = "slider"; ui_min = RADIAL_GAP_MIN; ui_max = RADIAL_GAP_MAX; ui_step = 0.05; ui_category = "Pattern"; > = RADIAL_GAP_DEFAULT;
uniform int NumSpokes < ui_label = "Number of Spokes"; ui_tooltip = "Number of angular spokes for the visualizer. Range: 16 to 128"; ui_type = "slider"; ui_min = NUM_SPOKES_MIN; ui_max = NUM_SPOKES_MAX; ui_step = 1; ui_category = "Pattern"; > = NUM_SPOKES_DEFAULT;
uniform int MaxDotsPerSpoke < ui_label = "Max Dots Per Spoke"; ui_tooltip = "Maximum number of dots radially outward per spoke. Range: 5 to 30"; ui_type = "slider"; ui_min = MAX_DOTS_PER_SPOKE_MIN; ui_max = MAX_DOTS_PER_SPOKE_MAX; ui_step = 1; ui_category = "Pattern"; > = MAX_DOTS_PER_SPOKE_DEFAULT;

// --- Animation Controls ---
AS_ANIMATION_UI(AnimationSpeed, AnimationKeyframe, "Animation")

// --- Audio Reactivity ---
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Intensity", AUDIO_MULT_DEFAULT, AUDIO_MULT_MAX, "Audio Reactivity")
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_tooltip = "Which parameter reacts to audio input"; ui_items = "None\0Dot Size Multiplier\0Bloom Size\0Bloom Intensity\0Bloom Falloff Rate\0"; ui_category = "Audio Reactivity"; > = 0;
uniform float Sensitivity < ui_label = "Audio Sensitivity"; ui_tooltip = "Controls responsiveness to audio. Range: 0.5 to 5.0"; ui_type = "slider"; ui_min = SENSITIVITY_MIN; ui_max = SENSITIVITY_MAX; ui_step = 0.1; ui_category = "Audio Reactivity"; > = SENSITIVITY_DEFAULT;
uniform bool UseLogScale < ui_label = "Use Logarithmic Scale"; ui_tooltip = "True = logarithmic audio scaling, False = linear."; ui_category = "Audio Reactivity"; > = false;

// --- Effect Settings ---
uniform float Brightness < ui_label = "Overall Brightness"; ui_tooltip = "Overall brightness of the effect. Range: 1.0 to 8.0"; ui_type = "slider"; ui_min = BRIGHTNESS_MIN; ui_max = BRIGHTNESS_MAX; ui_step = 0.1; ui_category = "Effect Settings"; > = BRIGHTNESS_DEFAULT;
uniform float BloomSize < ui_label = "Bloom Size"; ui_tooltip = "Size of the bloom/glow effect. Range: 1.0 to 15.0"; ui_type = "slider"; ui_min = BLOOM_SIZE_MIN; ui_max = BLOOM_SIZE_MAX; ui_step = 0.1; ui_category = "Effect Settings"; > = BLOOM_SIZE_DEFAULT;
uniform float BloomIntensity < ui_label = "Bloom Intensity"; ui_tooltip = "Intensity of the bloom. Range: 0.1 to 2.0"; ui_type = "slider"; ui_min = BLOOM_INTENSITY_MIN; ui_max = BLOOM_INTENSITY_MAX; ui_step = 0.05; ui_category = "Effect Settings"; > = BLOOM_INTENSITY_DEFAULT;
uniform float BloomFalloff < ui_label = "Bloom Falloff Rate"; ui_tooltip = "How quickly the bloom fades. Range: 1.0 to 4.0"; ui_type = "slider"; ui_min = BLOOM_FALLOFF_MIN; ui_max = BLOOM_FALLOFF_MAX; ui_step = 0.1; ui_category = "Effect Settings"; > = BLOOM_FALLOFF_DEFAULT;

// --- Stage Controls ---
AS_STAGEDEPTH_UI(EffectDepth) 
AS_ROTATION_UI(SnapRotation, FineRotation)

// --- Final Mix ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN) 
AS_BLENDAMOUNT_UI(BlendAmount)        

// ============================================================================
// HELPER FUNCTION for Interpolated Audio Band Fetching
// ============================================================================
float getMirroredFreqBand(float spoke_angle_rad, bool mirror_active)
{
    int num_actual_bands = AS_getFreqBands();
    if (num_actual_bands <= 0) return 0.0f;

    float normalized_angle_around_circle = AS_mod(spoke_angle_rad, AS_TWO_PI) / AS_TWO_PI;

    float effective_progress_for_band_lookup;
    if (mirror_active)
    {
        effective_progress_for_band_lookup = 1.0 - abs(1.0 - 2.0 * normalized_angle_around_circle); 
    }
    else
    {
        effective_progress_for_band_lookup = normalized_angle_around_circle; 
    }
    
    effective_progress_for_band_lookup = saturate(effective_progress_for_band_lookup);

    // Calculate exact floating-point band position for interpolation
    float exact_band_position = effective_progress_for_band_lookup * (num_actual_bands - 1);
    
    // Get the two adjacent band indices
    int band_index_low = clamp((int)floor(exact_band_position), 0, num_actual_bands - 1);
    int band_index_high = clamp(band_index_low + 1, 0, num_actual_bands - 1);
    
    // Calculate interpolation factor
    float interpolation_factor = exact_band_position - floor(exact_band_position);
    
    // Get values from both bands
    float freq_low = AS_getFreq(band_index_low);
    float freq_high = AS_getFreq(band_index_high);
    
    // Interpolate between the two frequency values
    return lerp(freq_low, freq_high, interpolation_factor);
}

// ============================================================================
// OPTIMIZED PIXEL SHADER - Combined passes with LOD optimization
// ============================================================================
float4 PS_CircularSpectrumDots(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);    if (sceneDepth < EffectDepth - AS_DEPTH_EPSILON) 
    {
                return originalColor;    }

    // Standard AS coordinate transformation using AS_transformCoord
    float globalRotation = AS_getRotationRadians(SnapRotation, FineRotation);
    float2 uv = AS_transformCoord(texcoord, EffectCenter, EffectScale, globalRotation);    // Level-of-detail optimization: reduce quality for pixels far from center
    float2 center_offset = uv - float2(0.0, 0.0);
    float distance_from_center = length(center_offset);
    
    // Calculate LOD factor (1.0 = full quality, 0.5 = half quality, etc.)
    float lod_factor = saturate(1.0 - (distance_from_center - LOD_DISTANCE_THRESHOLD) / LOD_DISTANCE_THRESHOLD);
    lod_factor = max(LOD_MIN_QUALITY, lod_factor); // Minimum quality to avoid complete falloff
    
    // Adjust spoke count and dots per spoke based on LOD
    int effective_num_spokes = max(LOD_MIN_SPOKES, int(float(NumSpokes) * lod_factor));
    int effective_max_dots = max(LOD_MIN_DOTS, int(float(MaxDotsPerSpoke) * lod_factor));    float3 effectColor = 0.0; 
    float3 bloomAccumulator = 0.0;    // Get animation time for time-based effects
    float time = AS_getAnimationTime(AnimationSpeed, AnimationKeyframe);

    // Apply audio target parameter modulation
    float dotSizeMultiplier_final = DotSizeMultiplier;
    float bloomSize_final = BloomSize;
    float bloomIntensity_final = BloomIntensity;
    float bloomFalloff_final = BloomFalloff;
    
    if (AudioTarget != AUDIO_TARGET_NONE) {
        // Get a general audio value for parameter modulation (using beat detection)
        float audioValue = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true) - 1.0;
        
        // Apply audio modulation to the selected parameter
        if (AudioTarget == AUDIO_TARGET_DOT_SIZE) {
            dotSizeMultiplier_final = DotSizeMultiplier + (DotSizeMultiplier * audioValue * 0.5);
            dotSizeMultiplier_final = clamp(dotSizeMultiplier_final, DOT_SIZE_MIN, DOT_SIZE_MAX);
        }
        else if (AudioTarget == AUDIO_TARGET_BLOOM_SIZE) {
            bloomSize_final = BloomSize + (BloomSize * audioValue * 0.8);
            bloomSize_final = clamp(bloomSize_final, BLOOM_SIZE_MIN, BLOOM_SIZE_MAX);
        }
        else if (AudioTarget == AUDIO_TARGET_BLOOM_INTENSITY) {
            bloomIntensity_final = BloomIntensity + (BloomIntensity * audioValue * 1.0);
            bloomIntensity_final = clamp(bloomIntensity_final, BLOOM_INTENSITY_MIN, BLOOM_INTENSITY_MAX);
        }
        else if (AudioTarget == AUDIO_TARGET_BLOOM_FALLOFF) {
            bloomFalloff_final = BloomFalloff + (BloomFalloff * audioValue * 0.6);
            bloomFalloff_final = clamp(bloomFalloff_final, BLOOM_FALLOFF_MIN, BLOOM_FALLOFF_MAX);
        }
    }

    // Pre-calculate constants - Scale these values WITH EffectScale
    float innerRadius = INNER_RADIUS_SCALE * EffectScale; 
    float base_radial_step_size = BASE_RADIAL_STEP_SCALE * EffectScale; 
    float dot_base_diameter = base_radial_step_size;
    float actual_radial_step = base_radial_step_size * (1.0 + RadialGapMultiplier * RADIAL_GAP_FACTOR); 
    float bandAngleWidth = AS_TWO_PI / float(effective_num_spokes);
    
    // Pre-calculate dot radius and squared radius for distance checks (using audio-modulated value)
    float current_dot_radius = (dot_base_diameter * DOT_RADIUS_FACTOR) * dotSizeMultiplier_final;
    float dot_radius_sq = current_dot_radius * current_dot_radius;
      // Pre-calculate bloom constants (using audio-modulated values)
    float baseBloomEffectSize = BASE_RADIAL_STEP_SCALE * EffectScale;
    float scaledBloomVisualSize = baseBloomEffectSize * (bloomSize_final / BLOOM_SIZE_DIVISOR);
    float bloom_falloff_1 = bloomFalloff_final / scaledBloomVisualSize;
    float bloom_falloff_2 = (bloomFalloff_final * 0.5) / (scaledBloomVisualSize * 2.0);
    float bloom_falloff_3 = (bloomFalloff_final * 0.25) / (scaledBloomVisualSize * 4.0);
    float bloom_intensity_1 = bloomIntensity_final;
    float bloom_intensity_2 = bloomIntensity_final * 0.5;
    float bloom_intensity_3 = bloomIntensity_final * 0.25;
    
    // Early termination distance for bloom (optimization)
    float max_bloom_radius = 5.0 * scaledBloomVisualSize;
    float max_bloom_radius_sq = max_bloom_radius * max_bloom_radius;
    
    // Calculate spoke step for LOD (skip spokes for lower quality)
    int spoke_step = max(1, NumSpokes / effective_num_spokes);
      // --- Combined Pass - Calculate both sharp dots and bloom in single loop ---
    for (int i = 0; i < NumSpokes; i += spoke_step) { 
        // Pre-calculate trigonometric values for this spoke with optional time-based rotation
        float base_spoke_angle = float(i) * (AS_TWO_PI / float(NumSpokes)) + (AS_TWO_PI / float(NumSpokes)) * 0.5;
        float spoke_center_angle = base_spoke_angle + (time * 0.1); // Slow rotation based on animation time
        float cos_angle = cos(spoke_center_angle - AS_PI);
        float sin_angle = sin(spoke_center_angle - AS_PI);        // Get amplitude once per spoke (eliminates redundant audio processing)
        // Use base angle for audio sampling to maintain frequency band mapping
        float raw_amp = getMirroredFreqBand(base_spoke_angle, MirrorFreqBands);
        
        // Apply standard audio reactivity with user controls
        float audio_multiplied = AS_applyAudioReactivity(raw_amp, AudioSource, AudioMultiplier, true);
        float amp_processed = audio_multiplied * Sensitivity;
        if (UseLogScale) {
            amp_processed = log(1.0 + amp_processed * 9.0) / log(10.0);
        }
        amp_processed = pow(amp_processed, 0.7); 
        amp_processed = saturate(amp_processed);
        int lit_dots = min(int(amp_processed * float(MaxDotsPerSpoke)), effective_max_dots);

        // Pre-calculate brightness values for this spoke
        float baseBrightness = Brightness * (1.5 + amp_processed * 2.5);

        for (int seg = 0; seg < lit_dots; seg++) {
            float dot_center_radius = innerRadius + float(seg) * actual_radial_step + dot_base_diameter * 0.5;
            
            // Calculate dot position once
            float2 dot_cartesian_center = float2(
                dot_center_radius * cos_angle,
                dot_center_radius * sin_angle
            );

            float2 diff_uv_dot = uv - dot_cartesian_center;
            float dist_sq_to_dot = dot(diff_uv_dot, diff_uv_dot);
            
            // Early termination for bloom if too far away
            if (dist_sq_to_dot > max_bloom_radius_sq) continue;
            
            // Calculate palette value once per dot
            float palette_map_value;
            if (MaxDotsPerSpoke <= 1) {
                palette_map_value = amp_processed;
            } else {
                palette_map_value = saturate(float(seg) / (MaxDotsPerSpoke - 1.0f));
            }
            
            // Get color once per dot
            float3 dot_color;
            if (PaletteSelection == AS_PALETTE_CUSTOM) {
                dot_color = AS_GET_INTERPOLATED_CUSTOM_COLOR(CircularSpectrum_, palette_map_value);
            } else {
                dot_color = AS_getInterpolatedColor(PaletteSelection, palette_map_value);
            }

            // Sharp dot contribution (only if within dot radius)
            if (dist_sq_to_dot < dot_radius_sq) { 
                float normalized_dist = sqrt(dist_sq_to_dot) / current_dot_radius;
                float current_dot_intensity_falloff = pow(saturate(1.0 - normalized_dist), 2.0); 
                float brightness_boost = 1.0 + (float(seg) / float(MaxDotsPerSpoke)) * amp_processed * 1.5; 
                effectColor += dot_color * current_dot_intensity_falloff * baseBrightness * brightness_boost;
            }
            
            // Bloom contribution (optimized single calculation)
            float dist_to_dot_center = sqrt(dist_sq_to_dot);
            float glow1 = exp(-dist_to_dot_center * bloom_falloff_1) * bloom_intensity_1;
            float glow2 = exp(-dist_to_dot_center * bloom_falloff_2) * bloom_intensity_2;
            float glow3 = exp(-dist_to_dot_center * bloom_falloff_3) * bloom_intensity_3;
            float totalGlow = glow1 + glow2 + glow3;

            float3 currentBloomValue = dot_color * totalGlow * amp_processed;
            bloomAccumulator = bloomAccumulator + currentBloomValue - bloomAccumulator * currentBloomValue; 
        }
    }
    
    effectColor += bloomAccumulator; 

    return AS_applyBlend(float4(effectColor, 1.0), originalColor, BlendMode, BlendAmount);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_VFX_CircularSpectrum <
    ui_label = "[AS] VFX: Circular Spectrum";
    ui_tooltip = "Displays a circular audio visualizer as dots of light using ListeningWay FreqBands and AS_Palette. Full AS-StageFX controls.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CircularSpectrumDots;
    }
}

#endif // __AS_VFX_CIRCULARSPECTRUMDOTS_1_FX