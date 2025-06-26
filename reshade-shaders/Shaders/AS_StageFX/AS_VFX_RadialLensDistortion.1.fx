/**
 * AS_VFX_RadialLensDistortion.1.fx - Emulates Radial and Lens-Specific Distortions
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially,
 * as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader simulates various lens distortions including tangential (rotational) blur,
 * chromatic aberration (tangential or horizontal), and geometric barrel/pincushion distortion.
 * Effects are strongest at the edges and diminish towards a configurable center point.
 * Includes presets for emulating specific lens characteristics, plus global strength
 * and focus falloff controls. This version ensures consistent effect visibility
 * regardless of source alpha by controlling alpha during blending.
 *
 * FEATURES:
 * - Adjustable effect center point.
 * - Independent control over blur strength and chromatic aberration amount for custom settings.
 * - Global strength multiplier for overall effect intensity.
 * - Effect focus exponent to control the intensity falloff curve from center to edge.
 * - Variable sample count for quality/performance tuning.
 * - Aspect ratio correction for truly circular distortion patterns and strength falloff.
 * - Internal presets for common and iconic lens emulations, including geometric distortion.
 * - Chromatic aberration types: tangential (for rotational smear) or horizontal (for anamorphic).
 * - Standard AS-StageFX blending options.
 * - Modified alpha handling for consistent effect visibility across varying source alpha.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Determines base blur, aberration, and geometric distortion strengths from UI or presets.
 * 2. Applies a global strength multiplier to the base blur/aberration strengths.
 * 3. Applies geometric lens distortion to the base texture coordinates.
 * 4. Calculates an aspect-ratio-corrected distance from center. This distance is then modified by a focus exponent.
 * 5. Final blur/CA magnitudes are determined using the globally-scaled strengths and the focus-modified distance.
 * 6. For a set number of samples, it steps along the calculated tangential (or horizontal for anamorphic CA) direction.
 * 7. At each step, it samples color channels (using tex2Dlod) with slight offsets (chromatic aberration).
 * 8. The final color is an average of all samples. Its RGB components are blended with the original sample
 * (post-geometric distortion) as if the effect color is opaque. The original sample's alpha is preserved.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_VFX_RadialLensDistortion_1_fx
#define __AS_VFX_RadialLensDistortion_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================

static const int LENS_PRESET_CUSTOM = 0;
static const int LENS_PRESET_VINTAGE_SOFT = 1;
static const int LENS_PRESET_CHROMATIC_EDGE = 2;
static const int LENS_PRESET_DREAMY_HAZE = 3;
static const int LENS_PRESET_ANAMORPHIC_CINE = 4;
static const int LENS_PRESET_HELIOS_VINTAGE = 5;
static const int LENS_PRESET_WIDE_ANGLE = 6;

static const float2 EFFECT_CENTER_UV_DEFAULT = float2(0.5f, 0.5f);
static const float BLUR_STRENGTH_MIN = 0.0f;
static const float BLUR_STRENGTH_MAX = 50.0f; 
static const float BLUR_STRENGTH_DEFAULT = 40.0f;
static const float BLUR_STRENGTH_STEP = 0.1f;
static const float ABERRATION_AMOUNT_MIN = 0.0f;
static const float ABERRATION_AMOUNT_MAX = 50.0f;
static const float ABERRATION_AMOUNT_DEFAULT = 38.0f;
static const float ABERRATION_AMOUNT_STEP = 0.1f;
static const int SAMPLE_COUNT_MIN = 3;
static const int SAMPLE_COUNT_MAX = 25;
static const int SAMPLE_COUNT_DEFAULT = 15;

static const float GLOBAL_STRENGTH_MIN = 0.0f;
static const float GLOBAL_STRENGTH_MAX = 10.0f;
static const float GLOBAL_STRENGTH_DEFAULT = 2.3f;
static const float GLOBAL_STRENGTH_STEP = 0.05f;

static const float EFFECT_FOCUS_EXP_MIN = 0.1f;
static const float EFFECT_FOCUS_EXP_MAX = 5.0f;
static const float EFFECT_FOCUS_EXP_DEFAULT = 2.2f;
static const float EFFECT_FOCUS_EXP_STEP = 0.05f;

static const float3 PRESET_VS_PARAMS = float3(10.0f, 3.0f, 0.0f);
static const float3 PRESET_CE_PARAMS = float3(2.0f, 15.0f, 0.0f);
static const float3 PRESET_DH_PARAMS = float3(20.0f, 8.0f, 0.0f);
static const float3 PRESET_AC_PARAMS = float3(4.0f, 20.0f, 0.05f);
static const float3 PRESET_HV_PARAMS = float3(15.0f, 25.0f, -0.15f);
static const float3 PRESET_WA_PARAMS = float3(8.0f, 18.0f, -0.2f);

// Calculation constants
static const float CALCULATION_HALF = 0.5f;
static const float UNITY_VALUE = 1.0f;
static const float ZERO_LOD = 0.0f;
static const int MIN_SAMPLE_COUNT = 1;
static const float ANAMORPHIC_HORIZONTAL_X = 1.0f;
static const float ANAMORPHIC_HORIZONTAL_Y = 0.0f;

// ============================================================================
// UI UNIFORMS
// ============================================================================

uniform int LensModelPreset < ui_type = "combo"; ui_label = "Lens Model";
    ui_items =
        "Custom (Manual Settings)\0"
        "Vintage Soft Focus (Classic Portrait)\0"
        "Chromatic Edge (Cheap Optics - Tangential)\0"
        "Dreamy Haze (Soft Diffusion - Tangential)\0"
        "Anamorphic Cine Lens (Horizontal CA)\0"
        "Helios Vintage Lens (Swirly Blur/CA)\0"
        "Wide-Angle Lens (Barrel + Tangential CA)\0";
    ui_tooltip =
        "Select a lens emulation preset. 'Custom' enables manual settings.\n\n"
        "- Vintage Soft Focus: Subtle tangential blur, minimal tangential aberration for gentle portraits.\n"
        "- Chromatic Edge: Significant tangential chromatic aberration, mimicking inexpensive optics.\n"
        "- Dreamy Haze: Strong tangential blur, moderate tangential aberration for dreamlike aesthetics.\n"
        "- Anamorphic Cine: Mild pincushion distortion, prominent horizontal chromatic aberration.\n"
        "- Helios Vintage: Strong tangential (swirly) blur, pronounced tangential CA, strong barrel distortion.\n"
        "- Wide-Angle: Intense barrel distortion, pronounced tangential CA typical of wide-angle lenses.";
    ui_category = "Lens Model"; > = LENS_PRESET_CUSTOM;

uniform float2 EffectCenterUV < ui_type="drag"; ui_min=0.0f; ui_max=1.0f; ui_label = "Effect Center (UV Coords)";
    ui_tooltip = "Center point of the lens distortion effect (0,0 is top-left; 0.5,0.5 is screen center).";
    ui_category = "Effect Settings"; > = EFFECT_CENTER_UV_DEFAULT;

uniform float GlobalEffectStrength < ui_type = "slider"; ui_label = "Global Effect Strength";
    ui_min = GLOBAL_STRENGTH_MIN; ui_max = GLOBAL_STRENGTH_MAX; ui_step = GLOBAL_STRENGTH_STEP;
    ui_tooltip = "Master multiplier for the overall intensity of the calculated blur and chromatic aberration.";
    ui_category = "Effect Settings"; > = GLOBAL_STRENGTH_DEFAULT;

uniform float EffectFocusExponent < ui_type = "slider"; ui_label = "Effect Focus Exponent";
    ui_min = EFFECT_FOCUS_EXP_MIN; ui_max = EFFECT_FOCUS_EXP_MAX; ui_step = EFFECT_FOCUS_EXP_STEP;
    ui_tooltip = "Controls the falloff curve of effect intensity from center to edge.\n1.0 = linear.\n<1.0 = effect concentrated near center.\n>1.0 = effect pushed towards edges.";
    ui_category = "Effect Settings"; > = EFFECT_FOCUS_EXP_DEFAULT;
    
uniform float BlurStrength < ui_type = "slider"; ui_label = "Base Blur Strength (Pixels)";
    ui_min = BLUR_STRENGTH_MIN; ui_max = BLUR_STRENGTH_MAX; ui_step = BLUR_STRENGTH_STEP;
    ui_tooltip = "Base strength for tangential (rotational) blur, in approximate visual pixels at max distance (before Global Strength/Focus). Active if 'Lens Model' is 'Custom'.";
    ui_category = "Effect Settings"; > = BLUR_STRENGTH_DEFAULT;

uniform float AberrationAmount < ui_type = "slider"; ui_label = "Base Chromatic Aberration (Pixels)";
    ui_min = ABERRATION_AMOUNT_MIN; ui_max = ABERRATION_AMOUNT_MAX; ui_step = ABERRATION_AMOUNT_STEP;
    ui_tooltip = "Base strength for color channel separation (tangential or horizontal), in approximate visual pixels at max distance (before Global Strength/Focus). Active if 'Lens Model' is 'Custom'.";
    ui_category = "Effect Settings"; > = ABERRATION_AMOUNT_DEFAULT;

uniform int SampleCount < ui_type = "slider"; ui_label = "Sample Count (Quality)";
    ui_min = SAMPLE_COUNT_MIN; ui_max = SAMPLE_COUNT_MAX;
    ui_tooltip = "Number of samples taken for the effect. Higher values improve quality but reduce performance.";
    ui_category = "Effect Settings"; > = SAMPLE_COUNT_DEFAULT;

AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_NORMAL)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_RadialLensDistortion(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Effect strength calculation
    float base_active_blur_strength_pixels, base_active_aberration_pixels;
    float current_overall_blur_strength, current_overall_aberration_strength;
    float lensDistortionStrength = ZERO_LOD;
    
    // Coordinate processing
    float2 texcoord_for_effect = texcoord;
    float2 effect_center_uv, diff_uv, diff_corrected_for_dist_calc;
    float2 screen_space_equivalent_diff;
    float2 screen_space_radial_dir = float2(ZERO_LOD, ZERO_LOD);
    float2 screen_space_tangential_dir = float2(ZERO_LOD, ZERO_LOD);
    
    // Distance and focus calculation
    float dist_corrected, focused_dist;
    float final_blur_offset_pixels, final_aberration_offset_pixels;
    
    // Sampling iteration
    int current_sample_count;
    float r_accum = ZERO_LOD, g_accum = ZERO_LOD, b_accum = ZERO_LOD, a_accum = ZERO_LOD;
    float2 r_ca_offset_uv, b_ca_offset_uv;
    
    // Color processing
    float4 original_color_sample;
    float4 calculated_effect_rgb;

    base_active_blur_strength_pixels = BlurStrength;
    base_active_aberration_pixels = AberrationAmount;

    if (LensModelPreset == LENS_PRESET_VINTAGE_SOFT) {
        base_active_blur_strength_pixels = PRESET_VS_PARAMS.x; base_active_aberration_pixels = PRESET_VS_PARAMS.y; lensDistortionStrength = PRESET_VS_PARAMS.z;
    } else if (LensModelPreset == LENS_PRESET_CHROMATIC_EDGE) {
        base_active_blur_strength_pixels = PRESET_CE_PARAMS.x; base_active_aberration_pixels = PRESET_CE_PARAMS.y; lensDistortionStrength = PRESET_CE_PARAMS.z;
    } else if (LensModelPreset == LENS_PRESET_DREAMY_HAZE) {
        base_active_blur_strength_pixels = PRESET_DH_PARAMS.x; base_active_aberration_pixels = PRESET_DH_PARAMS.y; lensDistortionStrength = PRESET_DH_PARAMS.z;
    } else if (LensModelPreset == LENS_PRESET_ANAMORPHIC_CINE) {
        base_active_blur_strength_pixels = PRESET_AC_PARAMS.x; base_active_aberration_pixels = PRESET_AC_PARAMS.y; lensDistortionStrength = PRESET_AC_PARAMS.z;
    } else if (LensModelPreset == LENS_PRESET_HELIOS_VINTAGE) {
        base_active_blur_strength_pixels = PRESET_HV_PARAMS.x; base_active_aberration_pixels = PRESET_HV_PARAMS.y; lensDistortionStrength = PRESET_HV_PARAMS.z;
    } else if (LensModelPreset == LENS_PRESET_WIDE_ANGLE) {
        base_active_blur_strength_pixels = PRESET_WA_PARAMS.x; base_active_aberration_pixels = PRESET_WA_PARAMS.y; lensDistortionStrength = PRESET_WA_PARAMS.z;
    }
    
    current_overall_blur_strength = base_active_blur_strength_pixels * GlobalEffectStrength;
    current_overall_aberration_strength = base_active_aberration_pixels * GlobalEffectStrength;
    
    effect_center_uv = EffectCenterUV;
    
    if (abs(lensDistortionStrength) > AS_EPSILON) {
        float2 vec_from_center = texcoord - effect_center_uv;
        float2 vec_from_center_aspect_corrected = vec_from_center;
        if (ReShade::AspectRatio > UNITY_VALUE) vec_from_center_aspect_corrected.x /= ReShade::AspectRatio;
        else vec_from_center_aspect_corrected.y *= ReShade::AspectRatio;
        float r_aspect_corrected = length(vec_from_center_aspect_corrected);
        vec_from_center *= (UNITY_VALUE + lensDistortionStrength * r_aspect_corrected);
        texcoord_for_effect = effect_center_uv + vec_from_center;
        texcoord_for_effect = saturate(texcoord_for_effect);
    }
    
    original_color_sample = tex2Dlod(ReShade::BackBuffer, float4(texcoord_for_effect, ZERO_LOD, ZERO_LOD));

    diff_uv = texcoord_for_effect - effect_center_uv;
    
    if (abs(diff_uv.x) < AS_EPSILON && abs(diff_uv.y) < AS_EPSILON) {
        if (abs(lensDistortionStrength) < AS_EPSILON && abs(GlobalEffectStrength) < AS_EPSILON) 
             return tex2Dlod(ReShade::BackBuffer, float4(texcoord, ZERO_LOD, ZERO_LOD));
        return original_color_sample;
    }
    
    diff_corrected_for_dist_calc = diff_uv;
    
    if (ReShade::AspectRatio > UNITY_VALUE) diff_corrected_for_dist_calc.x /= ReShade::AspectRatio;
    else diff_corrected_for_dist_calc.y *= ReShade::AspectRatio;

    dist_corrected = length(diff_corrected_for_dist_calc);
    focused_dist = pow(saturate(dist_corrected), EffectFocusExponent);

    if (ReShade::AspectRatio >= UNITY_VALUE) {
        screen_space_equivalent_diff.x = diff_uv.x * ReShade::AspectRatio;
        screen_space_equivalent_diff.y = diff_uv.y;
    } else {
        screen_space_equivalent_diff.x = diff_uv.x;
        screen_space_equivalent_diff.y = diff_uv.y / ReShade::AspectRatio;
    }

    if (length(screen_space_equivalent_diff) > AS_EPSILON) {
        screen_space_radial_dir = normalize(screen_space_equivalent_diff);
    }

    screen_space_tangential_dir = float2(-screen_space_radial_dir.y, screen_space_radial_dir.x);    
    
    final_blur_offset_pixels = current_overall_blur_strength * focused_dist;
    final_aberration_offset_pixels = current_overall_aberration_strength * focused_dist;
    
    if (abs(final_blur_offset_pixels) < AS_EPSILON && abs(final_aberration_offset_pixels) < AS_EPSILON) {
        return original_color_sample;
    }    
    
    current_sample_count = max(MIN_SAMPLE_COUNT, SampleCount);
      [loop]
    for (int i = 0; i < current_sample_count; ++i)
    {
        // Calculate normalized sample position within the blur range
        float sample_t_norm = (current_sample_count > MIN_SAMPLE_COUNT) ? 
            (float(i) - (current_sample_count - 1) * 0.5f) / ((current_sample_count - 1) * 0.5f) : 
            0.0f;

        float2 blur_offset_vector_screen_units = screen_space_tangential_dir * sample_t_norm * final_blur_offset_pixels;
        float2 current_blur_offset_vector_uv = blur_offset_vector_screen_units * ReShade::PixelSize;
        float2 base_sample_uv = texcoord_for_effect + current_blur_offset_vector_uv;
        
        // Apply chromatic aberration direction
        float2 ca_effect_direction_screen_units; 
        if (LensModelPreset == LENS_PRESET_ANAMORPHIC_CINE) {
            ca_effect_direction_screen_units = float2(ANAMORPHIC_HORIZONTAL_X, ANAMORPHIC_HORIZONTAL_Y); 
        } else {
            ca_effect_direction_screen_units = screen_space_tangential_dir;        
        }
        
        r_ca_offset_uv = (ca_effect_direction_screen_units * final_aberration_offset_pixels) * ReShade::PixelSize;
        b_ca_offset_uv = (-ca_effect_direction_screen_units * final_aberration_offset_pixels) * ReShade::PixelSize;
        
        float2 r_sample_uv = saturate(base_sample_uv + r_ca_offset_uv);
        float2 g_sample_uv = saturate(base_sample_uv);
        float2 b_sample_uv = saturate(base_sample_uv + b_ca_offset_uv);
          // Sample color channels with chromatic aberration
        float4 r_sample = tex2Dlod(ReShade::BackBuffer, float4(r_sample_uv, ZERO_LOD, ZERO_LOD));
        float4 g_sample = tex2Dlod(ReShade::BackBuffer, float4(g_sample_uv, ZERO_LOD, ZERO_LOD));
        float4 b_sample = tex2Dlod(ReShade::BackBuffer, float4(b_sample_uv, ZERO_LOD, ZERO_LOD));
        
        r_accum += r_sample.r;
        g_accum += g_sample.g;
        b_accum += b_sample.b;
        a_accum += g_sample.a;
    }

    // Calculate final effect color by averaging all samples
    calculated_effect_rgb.r = r_accum / current_sample_count;    calculated_effect_rgb.g = g_accum / current_sample_count;
    calculated_effect_rgb.b = b_accum / current_sample_count;

    // Apply RGB effect with full opacity, preserve original alpha
    float4 blended_rgb = AS_applyBlend(float4(calculated_effect_rgb.rgb, UNITY_VALUE), original_color_sample, BlendMode, BlendAmount);
    
    return float4(blended_rgb.rgb, original_color_sample.a);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_RadialLensDistortion < 
    ui_label = "[AS] VFX: Radial Lens Distortion";
    ui_tooltip = "Simulates various lens distortions like tangential (rotational) blur, chromatic aberration, and geometric warping (barrel/pincushion).\nIncludes presets for specific lens characteristics. Effect is strongest at edges."; 
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_RadialLensDistortion;
    }
}

#endif // __AS_VFX_RadialLensDistortion_1_fx
