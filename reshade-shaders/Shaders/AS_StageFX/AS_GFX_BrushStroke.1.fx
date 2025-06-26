/**
 * AS_GFX_BrushStroke.1.fx - Stylized Brush Stroke Band Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a stylized brush stroke band effect with highly textured, irregular edges.
 * Features procedural noise-based edge generation, optional drop shadows, and full customization
 * of stroke appearance including texture shading, color blending, and invert functionality.
 *
 * FEATURES:
 * - Procedurally generated highly irregular edges using thresholded FBM noise
 * - Anisotropic noise scaling for directional/fibrous ink texture appearance
 * - Full positioning, scaling, and rotation controls with aspect ratio independence
 * - Dynamic thresholding system for stroke density variation from center to edge
 * - Optional drop shadow with configurable color, angle, distance, and opacity
 * - Invert mode for negative space effects and creative masking
 * - Advanced texture shading with highlights and shadows based on noise density
 * - Audio reactivity support for dynamic parameter control
 * - Standard AS StageFX blending and depth testing capabilities
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Transforms texture coordinates using AS standard positioning system with aspect correction
 * 2. Applies rotation and scaling in aspect-corrected coordinate space
 * 3. Generates FBM noise with anisotropic scaling for realistic brush texture
 * 4. Uses dynamic thresholding to create solid center with irregular edges
 * 5. Calculates drop shadow using offset sampling with proper invert logic
 * 6. Applies texture-based shading using contrasted noise values
 * 7. Supports invert mode where stroke areas become transparent
 * 8. Integrates with AS blending system for advanced compositing
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD
// ============================================================================
#ifndef __AS_GFX_BRUSHSTROKE_1_FX
#define __AS_GFX_BRUSHSTROKE_1_FX

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Noise.1.fxh" // For AS_Fbm2D

// ============================================================================
// CONSTANTS
// ============================================================================

// Stroke Height Constants
static const float BRUSHSTROKE_HEIGHT_MIN = 0.01f;
static const float BRUSHSTROKE_HEIGHT_MAX = 1.0f;
static const float BRUSHSTROKE_HEIGHT_DEFAULT = 0.30f;

// Stroke Shape Constants
static const float BRUSHSTROKE_SHAPE_X_MIN = 0.1f;
static const float BRUSHSTROKE_SHAPE_X_MAX = 50.0f;
static const float BRUSHSTROKE_SHAPE_X_DEFAULT = 5.1f;
static const float BRUSHSTROKE_SHAPE_Y_MIN = 1.0f;
static const float BRUSHSTROKE_SHAPE_Y_MAX = 100.0f;
static const float BRUSHSTROKE_SHAPE_Y_DEFAULT = 63.9f;

// Edge and Texture Constants
static const float BRUSHSTROKE_FEATHER_MIN = 0.0001f;
static const float BRUSHSTROKE_FEATHER_MAX = 0.2f; 
static const float BRUSHSTROKE_FEATHER_DEFAULT = 0.0195f;
static const float BRUSHSTROKE_CONTRAST_MIN = 0.5f;
static const float BRUSHSTROKE_CONTRAST_MAX = 5.0f;
static const float BRUSHSTROKE_CONTRAST_DEFAULT = 1.2f;
static const float BRUSHSTROKE_THRESH_EDGE_MIN = 0.0f;
static const float BRUSHSTROKE_THRESH_EDGE_MAX = 1.0f;
static const float BRUSHSTROKE_THRESH_EDGE_DEFAULT = 0.66f;
static const float BRUSHSTROKE_THRESH_CENTER_MIN = 0.0f;
static const float BRUSHSTROKE_THRESH_CENTER_MAX = 1.0f;
static const float BRUSHSTROKE_THRESH_CENTER_DEFAULT = 0.07f;
static const float BRUSHSTROKE_EXTEND_MIN = 0.0f;
static const float BRUSHSTROKE_EXTEND_MAX = 0.5f;
static const float BRUSHSTROKE_EXTEND_DEFAULT = 0.22f;

// Texture Shading Constants
static const float BRUSHSTROKE_SHADOW_INT_MIN = 0.0f;
static const float BRUSHSTROKE_SHADOW_INT_MAX = 1.0f;
static const float BRUSHSTROKE_SHADOW_INT_DEFAULT = 0.3f;
static const float BRUSHSTROKE_HIGHLIGHT_INT_MIN = 0.0f;
static const float BRUSHSTROKE_HIGHLIGHT_INT_MAX = 1.0f;
static const float BRUSHSTROKE_HIGHLIGHT_INT_DEFAULT = 0.2f;

// Drop Shadow Constants
static const float BRUSHSTROKE_SHADOW_OPACITY_MIN = 0.0f;
static const float BRUSHSTROKE_SHADOW_OPACITY_MAX = 1.0f;
static const float BRUSHSTROKE_SHADOW_OPACITY_DEFAULT = 1.00f;
static const float BRUSHSTROKE_SHADOW_ANGLE_MIN = -180.0f;
static const float BRUSHSTROKE_SHADOW_ANGLE_MAX = 180.0f;
static const float BRUSHSTROKE_SHADOW_ANGLE_DEFAULT = 30.6f;
static const float BRUSHSTROKE_SHADOW_DIST_MIN = 0.0f;
static const float BRUSHSTROKE_SHADOW_DIST_MAX = 0.05f; 
static const float BRUSHSTROKE_SHADOW_DIST_DEFAULT = 0.0136f;

// ============================================================================
// UI CONTROLS
// ============================================================================

// --- Category: Tunable Constants ---
uniform float BandHeight < ui_type = "slider"; ui_label = "Stroke Height"; ui_tooltip = "Controls the nominal height/thickness of the brush stroke."; ui_min = BRUSHSTROKE_HEIGHT_MIN; ui_max = BRUSHSTROKE_HEIGHT_MAX; ui_step = 0.01f; ui_category = "Tunable Constants"; > = BRUSHSTROKE_HEIGHT_DEFAULT;

// --- Category: Stroke Appearance ---
uniform float StrokeShapeX < ui_type = "slider"; ui_label = "Ink Pattern Scale X (Along Stroke)"; ui_tooltip = "FBM noise scale along stroke. Smaller values = longer, more stretched ink features. Larger = more condensed features."; ui_min = BRUSHSTROKE_SHAPE_X_MIN; ui_max = BRUSHSTROKE_SHAPE_X_MAX; ui_step = 0.1f; ui_category = "Stroke Appearance"; > = BRUSHSTROKE_SHAPE_X_DEFAULT;

uniform float StrokeShapeY < ui_type = "slider"; ui_label = "Ink Pattern Scale Y (Across Stroke)"; ui_tooltip = "FBM noise scale across stroke. Larger values = finer, denser ink details/fibers. This, with Scale X, controls anisotropy."; ui_min = BRUSHSTROKE_SHAPE_Y_MIN; ui_max = BRUSHSTROKE_SHAPE_Y_MAX; ui_step = 0.1f; ui_category = "Stroke Appearance"; > = BRUSHSTROKE_SHAPE_Y_DEFAULT;

uniform float StrokeFeather < ui_type = "slider"; ui_label = "Ink Edge Feathering"; ui_tooltip = "Softness of the ink edges defined by thresholding FBM noise."; ui_min = BRUSHSTROKE_FEATHER_MIN; ui_max = BRUSHSTROKE_FEATHER_MAX; ui_step = 0.0001f; ui_category = "Stroke Appearance"; > = BRUSHSTROKE_FEATHER_DEFAULT;

uniform float InkContrast < ui_type = "slider"; ui_label = "Ink Noise Contrast"; ui_tooltip = "Sharpens the FBM noise (power function exponent). Higher values create more defined, less blurry ink patterns."; ui_min = BRUSHSTROKE_CONTRAST_MIN; ui_max = BRUSHSTROKE_CONTRAST_MAX; ui_step = 0.1f; ui_category = "Stroke Appearance"; > = BRUSHSTROKE_CONTRAST_DEFAULT;

uniform float MinInkThresholdAtEdge < ui_type = "slider"; ui_label = "Min Ink Threshold (Edge)"; ui_tooltip = "FBM noise must exceed this value to appear as ink near the stroke's nominal edge. Higher = more broken up edge."; ui_min = BRUSHSTROKE_THRESH_EDGE_MIN; ui_max = BRUSHSTROKE_THRESH_EDGE_MAX; ui_step = 0.01f; ui_category = "Stroke Appearance"; > = BRUSHSTROKE_THRESH_EDGE_DEFAULT;

uniform float MinInkThresholdAtCenter < ui_type = "slider"; ui_label = "Min Ink Threshold (Center)"; ui_tooltip = "FBM noise must exceed this value to appear as ink at the stroke's center. Should be <= Edge threshold for solid core."; ui_min = BRUSHSTROKE_THRESH_CENTER_MIN; ui_max = BRUSHSTROKE_THRESH_CENTER_MAX; ui_step = 0.01f; ui_category = "Stroke Appearance"; > = BRUSHSTROKE_THRESH_CENTER_DEFAULT;

uniform float EdgeExtendFactor < ui_type = "slider"; ui_label = "Edge Extend Factor"; ui_tooltip = "How far (relative to half stroke height) ink can 'bleed' or 'splatter' beyond the nominal stroke height."; ui_min = BRUSHSTROKE_EXTEND_MIN; ui_max = BRUSHSTROKE_EXTEND_MAX; ui_step = 0.01f; ui_category = "Stroke Appearance"; > = BRUSHSTROKE_EXTEND_DEFAULT;

// --- Category: Colors ---
uniform float3 StrokeColor < ui_type = "color"; ui_label = "Stroke Color"; ui_category = "Colors"; > = float3(0.1f, 0.1f, 0.1f); 

uniform bool InvertStroke < ui_type = "input"; ui_label = "Invert Stroke"; ui_tooltip = "When enabled, stroke areas become transparent and non-stroke areas are filled with stroke color."; ui_category = "Colors"; > = false;

uniform float StrokeTextureShadowIntensity < ui_type = "slider"; ui_label = "Ink Texture Shadow Intensity"; ui_tooltip = "Darkens parts of the ink based on FBM noise values, adding texture to the main stroke."; ui_min = BRUSHSTROKE_SHADOW_INT_MIN; ui_max = BRUSHSTROKE_SHADOW_INT_MAX; ui_step = 0.01f; ui_category = "Colors"; > = BRUSHSTROKE_SHADOW_INT_DEFAULT;

uniform float StrokeTextureHighlightIntensity < ui_type = "slider"; ui_label = "Ink Texture Highlight Intensity"; ui_tooltip = "Brightens parts of the ink based on FBM noise values, adding texture to the main stroke."; ui_min = BRUSHSTROKE_HIGHLIGHT_INT_MIN; ui_max = BRUSHSTROKE_HIGHLIGHT_INT_MAX; ui_step = 0.01f; ui_category = "Colors"; > = BRUSHSTROKE_HIGHLIGHT_INT_DEFAULT;

// --- Category: Shadow Settings ---
uniform float ShadowOpacity < ui_type = "slider"; ui_label = "Shadow Opacity"; ui_tooltip = "Opacity of the drop shadow. 0.0 disables the shadow."; ui_min = BRUSHSTROKE_SHADOW_OPACITY_MIN; ui_max = BRUSHSTROKE_SHADOW_OPACITY_MAX; ui_step = 0.01f; ui_category = "Shadow Settings"; ui_category_closed = true; > = BRUSHSTROKE_SHADOW_OPACITY_DEFAULT;

uniform float3 ShadowColor < ui_type = "color"; ui_label = "Shadow Color"; ui_category = "Shadow Settings"; > = float3(0.0f, 0.0f, 0.0f);

uniform float ShadowAngle < ui_type = "slider"; ui_label = "Shadow Angle"; ui_tooltip = "Direction of the shadow offset in degrees (0 is right, 90 is down)."; ui_min = BRUSHSTROKE_SHADOW_ANGLE_MIN; ui_max = BRUSHSTROKE_SHADOW_ANGLE_MAX; ui_step = 0.1f; ui_category = "Shadow Settings"; > = BRUSHSTROKE_SHADOW_ANGLE_DEFAULT;

uniform float ShadowDistance < ui_type = "slider"; ui_label = "Shadow Distance"; ui_tooltip = "Screen-relative offset distance of the shadow (fraction of screen height)."; ui_min = BRUSHSTROKE_SHADOW_DIST_MIN; ui_max = BRUSHSTROKE_SHADOW_DIST_MAX; ui_step = 0.0005f; ui_category = "Shadow Settings"; > = BRUSHSTROKE_SHADOW_DIST_DEFAULT;

uniform bool EnableCountershadow < ui_label = "Enable Countershadow"; ui_tooltip = "Adds a second shadow cast in the opposite direction for enhanced depth."; ui_category = "Shadow Settings"; > = false;

uniform float3 CounterShadowColor < ui_type = "color"; ui_label = "Countershadow Color"; ui_category = "Shadow Settings"; > = float3(0.0f, 0.0f, 0.0f);

// --- Category: Audio Reactivity ---
AS_AUDIO_UI(AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(AudioMultiplier, "Audio Intensity", 1.0, 2.0, "Audio Reactivity")
uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target"; ui_items = "None\0Stroke Height\0Ink Contrast\0Shadow Opacity\0"; ui_category = "Audio Reactivity"; ui_category_closed = true; > = 0;

// --- Category: Stage/Position Controls ---
AS_POSITION_SCALE_UI(StrokeCenter, StrokeScale)
AS_STAGEDEPTH_UI(StrokeDepth)
AS_ROTATION_UI(StrokeRotationSnap, StrokeRotationFine)

// --- Category: Final Mix (Blend) ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_NORMAL)
AS_BLENDAMOUNT_UI(BlendStrength)

// ============================================================================
// HELPER FUNCTION to calculate stroke alpha at given texcoord
// ============================================================================
float GetStrokeAlpha(
    float2 current_texcoord, 
    float2 current_stroke_center, float current_stroke_scale,
    float current_rotation_radians, float current_band_height,
    float current_stroke_shape_x, float current_stroke_shape_y,
    float current_ink_contrast, 
    float current_min_ink_thresh_center, float current_min_ink_thresh_edge,
    float current_stroke_feather, float current_edge_extend_factor,
    out float out_fbm_noise_contrasted // Pass out the fbm noise for shading
    )
{    float current_band_half_height = current_band_height * 0.5f;
    if (current_band_half_height < 0.0001f) current_band_half_height = 0.0001f; 

    // Apply aspect ratio correction to texture coordinates and scale
    float2 centered_tc = current_texcoord - current_stroke_center;
    centered_tc.x *= ReShade::AspectRatio; // Correct for aspect ratio
    centered_tc /= current_stroke_scale; // Apply scale
    
    // Apply rotation in the aspect-corrected space
    float2 local_uv = centered_tc;
    if (abs(current_rotation_radians) > 0.001f) {
        float s_rot = sin(current_rotation_radians);
        float c_rot = cos(current_rotation_radians);
        local_uv.x = centered_tc.x * c_rot - centered_tc.y * s_rot;
        local_uv.y = centered_tc.x * s_rot + centered_tc.y * c_rot;
    }

    int fbm_octaves = 4;
    float fbm_lacunarity = 2.0f;
    float fbm_gain = 0.5f;       
    float fbm_amplitude_norm_factor = 1.0f + fbm_gain + pow(fbm_gain, 2) + pow(fbm_gain, 3);    float2 fbm_sample_coord = float2(local_uv.x * current_stroke_shape_x, local_uv.y * current_stroke_shape_y);
    float fbm_val = AS_Fbm2D(fbm_sample_coord, fbm_octaves, fbm_lacunarity, fbm_gain); 
    
    fbm_val = saturate((fbm_val / fbm_amplitude_norm_factor + 1.0f) * 0.5f);
    out_fbm_noise_contrasted = pow(fbm_val, current_ink_contrast); // Store for shading

    float dist_y_norm = abs(local_uv.y) / current_band_half_height;
    float dynamic_threshold = lerp(current_min_ink_thresh_center, current_min_ink_thresh_edge, saturate(dist_y_norm));

    float calculated_alpha = smoothstep(dynamic_threshold - current_stroke_feather * 0.5f, 
                                      dynamic_threshold + current_stroke_feather * 0.5f, 
                                      out_fbm_noise_contrasted);    float band_max_extent = current_band_half_height * (1.0f + current_edge_extend_factor);
    float falloff_start = max(current_band_half_height * 0.99f, current_band_half_height - current_stroke_feather); 
    float band_falloff_mask = 1.0f - smoothstep(falloff_start, band_max_extent, abs(local_uv.y));
    
    return saturate(calculated_alpha * band_falloff_mask);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_BrushStroke(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 original_color = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
      // Depth test - render behind scene objects
    if (depth < StrokeDepth) {
        return original_color;
    }
      // Get rotation in radians
    float rotation = AS_getRotationRadians(StrokeRotationSnap, StrokeRotationFine);
    
    // Transform coordinates using AS standard coordinate system
    // Convert AS UI coordinates (-1.5 to 1.5, default 0,0) to screen coordinates (0.5 = center)
    float2 stroke_screen_position = float2(0.5, 0.5) + (StrokeCenter * 0.5);
      // --- Audio Reactivity ---
    float current_band_height = BandHeight;
    float current_ink_contrast = InkContrast;
    float current_shadow_opacity = ShadowOpacity;
    
    if (AudioTarget > 0) {
        float audioReactivity = AS_applyAudioReactivity(1.0, AudioSource, AudioMultiplier, true);
        
        if (AudioTarget == 1) { // Stroke Height
            current_band_height = BandHeight * audioReactivity;
            current_band_height = clamp(current_band_height, BRUSHSTROKE_HEIGHT_MIN, BRUSHSTROKE_HEIGHT_MAX);
        }
        else if (AudioTarget == 2) { // Ink Contrast
            current_ink_contrast = InkContrast * audioReactivity;
            current_ink_contrast = clamp(current_ink_contrast, BRUSHSTROKE_CONTRAST_MIN, BRUSHSTROKE_CONTRAST_MAX);
        }
        else if (AudioTarget == 3) { // Shadow Opacity
            current_shadow_opacity = ShadowOpacity * audioReactivity;
            current_shadow_opacity = clamp(current_shadow_opacity, BRUSHSTROKE_SHADOW_OPACITY_MIN, BRUSHSTROKE_SHADOW_OPACITY_MAX);
        }
    }
    
    float main_stroke_fbm_noise; // Will be filled by GetStrokeAlpha    // --- Shadow Pass ---
    float3 background_with_shadow = original_color.rgb;
    if (current_shadow_opacity > 0.001f)
    {
        // Shadow angle is relative to stroke rotation
        float shadow_angle_rad = AS_radians(ShadowAngle + rotation);
        float2 shadow_offset_vector;
        // ShadowDistance is fraction of screen height. Correct X offset for aspect ratio.
        shadow_offset_vector.x = cos(shadow_angle_rad) * ShadowDistance / ReShade::AspectRatio; 
        shadow_offset_vector.y = sin(shadow_angle_rad) * ShadowDistance;
          float2 shadow_sample_texcoord = texcoord - shadow_offset_vector; // Sample from where caster would be

        float shadow_fbm_noise_value; // Dummy for shadow alpha calculation, not used for its shading
        float shadow_casting_alpha = GetStrokeAlpha(
            shadow_sample_texcoord,
            stroke_screen_position, StrokeScale, rotation, current_band_height,
            StrokeShapeX, StrokeShapeY, current_ink_contrast,
            MinInkThresholdAtCenter, MinInkThresholdAtEdge,
            StrokeFeather, EdgeExtendFactor,
            shadow_fbm_noise_value // out param
        );
        
        // Apply invert logic to shadow as well
        float final_shadow_alpha = InvertStroke ? (1.0 - shadow_casting_alpha) : shadow_casting_alpha;
          if (final_shadow_alpha > 0.001f)
        {
            background_with_shadow = lerp(background_with_shadow, ShadowColor, final_shadow_alpha * current_shadow_opacity);        
        }
    }

    // --- Countershadow Pass ---
    if (EnableCountershadow && current_shadow_opacity > 0.001f)
    {
        // Countershadow angle is opposite to main shadow (180 degrees offset)
        float countershadow_angle_rad = AS_radians(ShadowAngle + 180.0 + rotation);
        float2 countershadow_offset_vector;
        // Use same distance as main shadow, corrected for aspect ratio
        countershadow_offset_vector.x = cos(countershadow_angle_rad) * ShadowDistance / ReShade::AspectRatio; 
        countershadow_offset_vector.y = sin(countershadow_angle_rad) * ShadowDistance;
          
        float2 countershadow_sample_texcoord = texcoord - countershadow_offset_vector; // Sample from where caster would be

        float countershadow_fbm_noise_value; // Dummy for countershadow alpha calculation, not used for its shading
        float countershadow_casting_alpha = GetStrokeAlpha(
            countershadow_sample_texcoord,
            stroke_screen_position, StrokeScale, rotation, current_band_height,
            StrokeShapeX, StrokeShapeY, current_ink_contrast,
            MinInkThresholdAtCenter, MinInkThresholdAtEdge,
            StrokeFeather, EdgeExtendFactor,
            countershadow_fbm_noise_value // out param
        );
        
        // Apply invert logic to countershadow as well
        float final_countershadow_alpha = InvertStroke ? (1.0 - countershadow_casting_alpha) : countershadow_casting_alpha;
        
        if (final_countershadow_alpha > 0.001f)
        {
            background_with_shadow = lerp(background_with_shadow, CounterShadowColor, final_countershadow_alpha * current_shadow_opacity);        
        }
    }

    // --- Main Stroke Pass ---
    float stroke_alpha = GetStrokeAlpha(
        texcoord,
        stroke_screen_position, StrokeScale, rotation, current_band_height,
        StrokeShapeX, StrokeShapeY, current_ink_contrast,
        MinInkThresholdAtCenter, MinInkThresholdAtEdge,
        StrokeFeather, EdgeExtendFactor,
        main_stroke_fbm_noise // out param, used for shading stroke
    );
      // --- Shading the Main Stroke ---
    float3 modified_stroke_color = StrokeColor; 
    if (stroke_alpha > 0.01f) { 
        // Use main_stroke_fbm_noise (which is already contrasted) for texture
        modified_stroke_color = lerp(modified_stroke_color, StrokeColor * (1.0f + StrokeTextureHighlightIntensity * 0.4f), saturate(main_stroke_fbm_noise * 1.5f - 0.5f) );
        modified_stroke_color = lerp(modified_stroke_color, StrokeColor * (1.0f - StrokeTextureShadowIntensity * 0.4f), saturate(0.5f - main_stroke_fbm_noise * 1.5f) );
        modified_stroke_color = saturate(modified_stroke_color);
    }      // Apply invert logic if enabled
    float final_alpha = InvertStroke ? (1.0 - stroke_alpha) : stroke_alpha;
    float3 final_stroke_color = InvertStroke ? modified_stroke_color : modified_stroke_color;
    float3 final_background = InvertStroke ? background_with_shadow : background_with_shadow;    // Apply blending
    float3 effect_color = lerp(final_background, final_stroke_color, final_alpha);
    float3 blended_color = AS_applyBlend(effect_color, original_color.rgb, BlendMode);
    float4 final_color = lerp(original_color, float4(blended_color, 1.0), BlendStrength);

    return final_color;
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_GFX_BrushStroke < ui_label = "[AS] GFX: Brush Stroke"; ui_tooltip = "Renders a configurable brush stroke band with highly textured, irregular edges, optional drop shadow, audio reactivity, and invert functionality for creative effects."; >
{
    pass BrushStrokePass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BrushStroke;
    }
}

#endif // __AS_GFX_BRUSHSTROKE_1_FX
