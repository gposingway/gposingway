/**
 * AS_GFX_VignettePlus.1.fx - Enhanced vignette effects with customizable patterns
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * The hexagonal grid implementation is inspired by/adapted from the hexagonal wipe shader on Shadertoy:
 * https://www.shadertoy.com/view/XfjyWG created by blandprix (2024-08-06)
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * A vignette shader that provides multiple visual styles and customizable pattern options. 
 * This shader creates directional, controllable vignette effects for stage compositions 
 * and scene framing. Perfect for adding mood, focus, or stylistic elements.
 *
 * FEATURES:
 * - Four distinct visual styles:
 *   • Smooth Gradient: Classic vignette with smooth falloff
 *   • Duotone Circles: Hexagonal grid-based pattern with circular elements
 *   • Directional Lines: Both perpendicular and parallel line patterns
 * - Multiple mirroring options (none, edge-based, center-based)
 * - Precise control over effect coverage with start/end falloff points
 * - Adjustable pattern density, size, and coverage boosting
 * - Standard StageFX rotation, depth masking and blend mode controls
 * - Comprehensive debug visualization modes for fine-tuning
 * - Optimized for performance across various resolutions
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Calculates composition factor based on screen position and rotation angle
 * 2. Determines vignette alpha using configured falloff points
 * 3. Applies selected pattern (gradient, circles, or lines) with anti-aliasing
 * 4. Implements standard AS StageFX depth masking and blend modes
 * ===================================================================================
 */

#ifndef __AS_GFX_VignettePlus_1_fx
#define __AS_GFX_VignettePlus_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// NAMESPACE
// ============================================================================
namespace ASVignettePlus {

// ============================================================================
// CONSTANTS
// ============================================================================

// --- Threshold Constants ---
static const float ALPHA_EPSILON = 0.00001f; // Minimum alpha threshold for processing
static const float CENTER_COORD = 0.5f; // Screen center coordinate
static const float PERCENT_TO_NORMAL = 0.01f; // Conversion from percentage to 0-1 range
static const float FULL_OPACITY = 1.0f; // Full opacity value
static const float3 BLACK_COLOR = float3(0.0, 0.0, 0.0); // Pure black color for debug views

// --- Default Values ---
static const float DEFAULT_FALLOFF_START = 70.0; // Default falloff start (%)
static const float DEFAULT_FALLOFF_END = 90.0; // Default falloff end (%)
static const float DEFAULT_PATTERN_SIZE = 0.008; // Default pattern element size
static const float DEFAULT_COVERAGE_BOOST = 1.05; // Default pattern coverage boost factor

// --- UI Range Constants ---
static const float MIN_FALLOFF = 0.0f; // Minimum falloff percentage
static const float MAX_FALLOFF = 100.0f; // Maximum falloff percentage
static const float MIN_PATTERN_SIZE = 0.001f; // Minimum pattern element size
static const float MAX_PATTERN_SIZE = 0.1f; // Maximum pattern element size
static const float MIN_COVERAGE_BOOST = 1.0f; // Minimum pattern coverage boost
static const float MAX_COVERAGE_BOOST = 1.2f; // Maximum pattern coverage boost

// --- Visual Style Constants ---
static const int STYLE_SMOOTH_GRADIENT = 0;
static const int STYLE_DUOTONE_CIRCLES = 1;
static const int STYLE_LINES_PERPENDICULAR = 2;
static const int STYLE_LINES_PARALLEL = 3;

// --- Mirror Style Constants ---
static const int MIRROR_STYLE_NONE = 0;
static const int MIRROR_STYLE_EDGE = 1; // Effect emanates from edges inwards
static const int MIRROR_STYLE_CENTER = 2; // Effect emanates from center outwards

// --- Debug Mode Constants ---
static const int DEBUG_OFF = 0;
static const int DEBUG_MASK = 1;
static const int DEBUG_FALLOFF = 2;
static const int DEBUG_PATTERN = 3;
static const int DEBUG_PATTERN_ONLY = 4;

//------------------------------------------------------------------------------------------------
// Uniforms (UI Elements)
//------------------------------------------------------------------------------------------------

// --- Group I: Main Effect Style & Appearance ---
uniform int EffectStyle < ui_type = "combo"; ui_label = "Visual Style"; ui_items = "Smooth Gradient\0Duotone: Circles\0Lines - Perpendicular\0Lines - Parallel\0"; ui_tooltip = "Selects the overall visual appearance of the effect."; ui_category = "Style"; > = STYLE_DUOTONE_CIRCLES;
uniform float3 EffectColor < ui_type = "color"; ui_label = "Effect Color"; ui_tooltip = "The primary color used for the gradient or duotone patterns."; ui_category = "Style"; > = float3(0.0, 0.0, 0.0);
uniform int MirrorStyle < ui_type = "combo"; ui_label = "Mirroring Style"; ui_items = "None\0Edge Mirrored (From Edges)\0Center Mirrored (From Center)\0"; ui_tooltip = "Selects how the directional effect is mirrored.\nNone: Standard directional effect.\nEdge Mirrored: Effect starts at outer edges and moves inwards.\nCenter Mirrored: Effect starts at the central axis and moves outwards."; ui_category = "Style"; > = MIRROR_STYLE_EDGE;
uniform bool InvertAlpha < ui_type = "checkbox"; ui_label = "Invert Transparency"; ui_tooltip = "Flips the effect's opacity: solid areas become transparent, and vice-versa."; ui_category = "Style"; > = false;

// --- Group II: Falloff Controls ---
uniform float FalloffStart < ui_type = "slider"; ui_label = "Falloff Start (%)"; ui_min = MIN_FALLOFF; ui_max = MAX_FALLOFF; ui_step = 0.1; ui_tooltip = "Defines where the effect begins to transition from solid. Order of Start/End doesn't matter."; ui_category = "Falloff"; > = DEFAULT_FALLOFF_START;
uniform float FalloffEnd < ui_type = "slider"; ui_label = "Falloff End (%)"; ui_min = MIN_FALLOFF; ui_max = MAX_FALLOFF; ui_step = 0.1; ui_tooltip = "Defines where the effect becomes fully transparent after transitioning. Order of Start/End doesn't matter."; ui_category = "Falloff"; > = DEFAULT_FALLOFF_END;

// --- Group III: Pattern Specifics (for Duotone/Lines) ---
uniform float PatternElementSize < ui_type = "slider"; ui_label = "Pattern Element Size / Spacing"; ui_tooltip = "For Duotone/Lines: Controls the base size of circles, or spacing of lines."; ui_min = MIN_PATTERN_SIZE; ui_max = MAX_PATTERN_SIZE; ui_step = 0.001; ui_category = "Pattern"; > = DEFAULT_PATTERN_SIZE;
uniform float PatternCoverageBoost < ui_type = "slider"; ui_label = "Pattern Coverage Boost"; ui_tooltip = "For Duotone/Lines: Slightly enlarges elements in solid areas to ensure full coverage. 1.0 = no boost."; ui_min = MIN_COVERAGE_BOOST; ui_max = MAX_COVERAGE_BOOST; ui_step = 0.005; ui_category = "Pattern"; > = DEFAULT_COVERAGE_BOOST;

// --- Group IV: Direction & Orientation ---
// --- Stage Depth Control ---
AS_STAGEDEPTH_UI(EffectDepth)

// Standard rotation controls for AS StageFX
AS_ROTATION_UI(SnapRotation, FineRotation)

// --- Final Mix Controls ---
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug ---
AS_DEBUG_UI("Off\0Mask\0Falloff\0Pattern\0Pattern Only\0")

//------------------------------------------------------------------------------------------------
// Helper Functions
//------------------------------------------------------------------------------------------------

// --- Hexagonal Grid Helper Functions (for Duotone Circles) ---
float fmod_positive(float a, float b) { 
    return a - b * floor(a / b); 
}

// Rounds a fractional axial coordinate to the nearest hexagonal grid point
float2 HexGridRoundAxial(float2 fractionalAxial) { 
    float q = fractionalAxial.x;
    float r = fractionalAxial.y;
    float s = -q - r; // Third coordinate in axial system (q + r + s = 0)
    
    float qRound = round(q);
    float rRound = round(r);
    float sRound = round(s);
    
    // Calculate differences to determine which coordinate to adjust
    float qDiff = abs(qRound - q);
    float rDiff = abs(rRound - r);
    float sDiff = abs(sRound - s);
    
    // Adjust the coordinate with the largest difference to maintain constraint q + r + s = 0
    if (qDiff > rDiff && qDiff > sDiff) {
        qRound = -rRound - sRound;
    }
    else if (rDiff > sDiff) {
        rRound = -qRound - sRound;
    }
    
    return float2(qRound, rRound);
}

// Converts axial hex coordinates to cartesian (screen space) coordinates
float2 HexGridAxialToCartesian(float2 axialCoord, float gridDensity) { 
    // Constants derived from hexagon geometry
    float xFactor = sqrt(3.0f);
    float yFactor = 1.5f;
    
    // Convert using standard hexagonal grid transformation
    return float2(
        (xFactor * axialCoord.x + xFactor/2.0f * axialCoord.y) / gridDensity,
        (yFactor * axialCoord.y) / gridDensity
    );
}

// Converts cartesian (screen space) coordinates to fractional axial hex coordinates
float2 HexGridCartesianToFractionalAxial(float2 cartesianCoord, float gridDensity) { 
    // Constants derived from hexagon geometry
    float qFactor = sqrt(3.0f)/3.0f;
    float rFactorX = -1.0f/3.0f;
    float rFactorY = 2.0f/3.0f;
    
    // Apply inverse transformation
    return float2(
        (qFactor * cartesianCoord.x + rFactorX * cartesianCoord.y) * gridDensity,
        (rFactorY * cartesianCoord.y) * gridDensity
    );
}

// Converts cartesian coordinates directly to nearest hex grid cell (whole axial coordinates)
float2 HexGridCartesianToNearestCell(float2 cartesianCoord, float gridDensity) { 
    return HexGridRoundAxial(HexGridCartesianToFractionalAxial(cartesianCoord, gridDensity));
}

// --- Composition Logic ---
float GetCompositionFactor(float2 texcoord, float rotation_radians, int mirrorStyle) {
    // Center coordinates
    float2 centered_coord = texcoord - CENTER_COORD;
    float cos_angle = cos(rotation_radians);
    float sin_angle = sin(rotation_radians);

    // Calculate projected value in pixel space to maintain correct aspect ratio at any angle
    float projected_value_pixel_scaled = 
        (centered_coord.x * ReShade::ScreenSize.x) * cos_angle + 
        (centered_coord.y * ReShade::ScreenSize.y) * sin_angle;

    // Calculate maximum extent in pixel space
    float max_extent_pixel_scaled = 
        CENTER_COORD * (ReShade::ScreenSize.x * abs(cos_angle) + 
                       ReShade::ScreenSize.y * abs(sin_angle));
    
    // Normalize to [0,1] range for directional factor
    float base_directional_factor = (projected_value_pixel_scaled / (max_extent_pixel_scaled + ALPHA_EPSILON)) * CENTER_COORD + CENTER_COORD;
    base_directional_factor = saturate(base_directional_factor); // Ensure it's 0-1 before mirroring logic

    // Apply mirroring based on selected style
    float final_factor;
    if (mirrorStyle == MIRROR_STYLE_EDGE) {
        // Edge Mirrored: factor is 0.0 at edges, 1.0 at center line
        final_factor = (base_directional_factor < CENTER_COORD) ? 
                       (base_directional_factor / CENTER_COORD) : 
                       ((1.0f - base_directional_factor) / CENTER_COORD);
    } 
    else if (mirrorStyle == MIRROR_STYLE_CENTER) {
        // Center Mirrored: factor is 0.0 at center line, 1.0 at edges
        final_factor = abs(base_directional_factor - CENTER_COORD) * 2.0f;
    } 
    else { // MIRROR_STYLE_NONE or any other case
        final_factor = base_directional_factor;
    }
    
    return saturate(final_factor);
}

// --- Vignette Alpha Calculation ---
float CalculateVignetteAlpha(float position, float normalizedStartInput, float normalizedEndInput) {
    // Determine the actual start and end of the transition range
    // to handle cases where user might set FalloffStart > FalloffEnd
    float first_threshold = min(normalizedStartInput, normalizedEndInput);
    float second_threshold = max(normalizedStartInput, normalizedEndInput);
    
    // Handle edge case of identical thresholds
    if (first_threshold >= second_threshold) { 
        return position <= first_threshold ? 1.0f : 0.0f;
    }
    
    // Standard transition logic
    if (position <= first_threshold) {
        // Position is before or at the start of the falloff: full effect
        return 1.0f;
    }
    else if (position >= second_threshold) {
        // Position is after or at the end of the falloff: no effect
        return 0.0f;
    }
    else {
        // Position is within the transition zone.
        float t = (position - first_threshold) / (second_threshold - first_threshold);
        // Apply smoothstep for natural falloff (inverted as we want 1→0)
        return 1.0f - smoothstep(0.0f, 1.0f, t); 
    }
}

//------------------------------------------------------------------------------------------------
// Pattern Functions
//------------------------------------------------------------------------------------------------

float4 ApplySmoothGradientPS(float raw_alpha_param, float3 color) {
    return float4(color, raw_alpha_param);
}

float4 ApplyDuotoneCirclesPS(float2 texcoord, float raw_alpha_param, float3 color,
                            float circle_cell_radius_base, float coverage_boost_uniform) {
    if (raw_alpha_param <= ALPHA_EPSILON) 
        return float4(color, 0.0f);
    
    // Prepare UV coordinates with aspect ratio correction
    float2 uv_dither = texcoord; 
    uv_dither.y /= ReShade::AspectRatio;
    
    // Calculate grid density from cell radius
    float current_grid_density = 1.0f / circle_cell_radius_base;
    
    // Get the nearest hex grid cell center for current position
    float2 nearestCell = HexGridCartesianToNearestCell(uv_dither, current_grid_density); 
    float2 cellCenter = HexGridAxialToCartesian(nearestCell, current_grid_density);
    
    // Calculate distance from current position to cell center
    float dist = distance(cellCenter, uv_dither);
    
    // Apply coverage boost based on alpha value
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float radius = circle_cell_radius_base * raw_alpha_param * boost;
    
    // Calculate anti-aliasing width using derivatives
    float aa_w = fwidth(dist);
    
    // Apply anti-aliasing with smoothstep
    return float4(color, smoothstep(radius + aa_w * 0.5f, radius - aa_w * 0.5f, dist));
}

// Shared logic for both line pattern functions to reduce code duplication
float4 ApplyDuotoneLinesSharedLogic(float2 texcoord, float raw_alpha_param, float3 color,
                                   float line_cycle_width_uv, float effect_rotation_rad, 
                                   float coverage_boost_uniform, bool use_u_component_for_banding) {
    if (raw_alpha_param <= ALPHA_EPSILON) 
        return float4(color, 0.0f);
    
    // Center coordinates for rotation
    float2 ctd_coord = texcoord - CENTER_COORD; 
    float W = ReShade::ScreenSize.x; 
    float H = ReShade::ScreenSize.y;
    
    // Compute trig functions once
    float cos_a = cos(effect_rotation_rad);
    float sin_a = sin(effect_rotation_rad);
    
    // Calculate components based on whether perpendicular or parallel lines
    float comp_pixels;
    float max_extent_pixels;
    
    if (use_u_component_for_banding) {
        // For perpendicular lines (parallel to gradient direction)
        comp_pixels = (ctd_coord.x * W) * cos_a + (ctd_coord.y * H) * sin_a;
        max_extent_pixels = CENTER_COORD * (W * abs(cos_a) + H * abs(sin_a));
    } 
    else {
        // For parallel lines (perpendicular to gradient direction)
        comp_pixels = -(ctd_coord.x * W) * sin_a + (ctd_coord.y * H) * cos_a;
        max_extent_pixels = CENTER_COORD * (W * abs(sin_a) + H * abs(cos_a));
    }
    
    // Normalize position to [0,1] range and calculate cycle position
    float norm_pos_banding = (comp_pixels / (max_extent_pixels + ALPHA_EPSILON)) * CENTER_COORD + CENTER_COORD;
    float cycle_in_raw = saturate(norm_pos_banding) / line_cycle_width_uv;
    float coord_cycle = frac(cycle_in_raw);
    
    // Calculate line thickness with boosting for solid areas
    float base_half_thick = raw_alpha_param * CENTER_COORD;
    float boost = lerp(1.0f, coverage_boost_uniform, raw_alpha_param);
    float boosted_half_thick = base_half_thick * boost;
    
    // Calculate distance from nearest line center
    float val_to_test = abs(coord_cycle - CENTER_COORD);
    float edge_thresh = boosted_half_thick;
    
    // Calculate anti-aliasing width for smooth transitions
    float aa_w_cycle = fwidth(cycle_in_raw);
    
    // Apply anti-aliasing with smoothstep
    return float4(color, smoothstep(edge_thresh + aa_w_cycle * 0.5f, edge_thresh - aa_w_cycle * 0.5f, val_to_test));
}

// Pattern-specific wrapper functions for parallel and perpendicular lines
float4 ApplyDuotoneLinesParallelPS(float2 texcoord, float raw_alpha, float3 color, 
                                  float line_cycle_width, float effect_rotation, float coverage_boost) {
    return ApplyDuotoneLinesSharedLogic(texcoord, raw_alpha, color, line_cycle_width, 
                                      effect_rotation, coverage_boost, false);
}

float4 ApplyDuotoneLinesPerpendicularPS(float2 texcoord, float raw_alpha, float3 color, 
                                       float line_cycle_width, float effect_rotation, float coverage_boost) {
    return ApplyDuotoneLinesSharedLogic(texcoord, raw_alpha, color, line_cycle_width, 
                                      effect_rotation, coverage_boost, true);
}

//------------------------------------------------------------------------------------------------
// Pixel Shader
//------------------------------------------------------------------------------------------------
float4 VignettePlusPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    // Get depth and handle depth-based masking
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth) {
        return tex2D(ReShade::BackBuffer, texcoord);
    }
    
    // Get original pixel color
    float3 original_color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    
    // Calculate rotation using standard AS helpers
    float rotation_radians = AS_getRotationRadians(SnapRotation, FineRotation); 
    
    // Calculate composition factor based on mirror style
    float composition_f = GetCompositionFactor(texcoord, rotation_radians, MirrorStyle);
    
    // Normalize falloff values from percentage to 0-1 range
    float tA_norm = FalloffStart * PERCENT_TO_NORMAL;
    float tB_norm = FalloffEnd * PERCENT_TO_NORMAL;
    
    // Calculate vignette alpha
    float raw_vignette_alpha = CalculateVignetteAlpha(composition_f, tA_norm, tB_norm);
    
    // Initialize the effect output
    float4 vignette_effect_color_alpha = float4(EffectColor, 0.0f);
    
    // Apply the selected pattern
    if (EffectStyle == STYLE_SMOOTH_GRADIENT) {
        vignette_effect_color_alpha = ApplySmoothGradientPS(raw_vignette_alpha, EffectColor);
    } 
    else if (EffectStyle == STYLE_DUOTONE_CIRCLES) {
        vignette_effect_color_alpha = ApplyDuotoneCirclesPS(texcoord, raw_vignette_alpha, EffectColor, 
                                                          PatternElementSize, PatternCoverageBoost);
    } 
    else if (EffectStyle == STYLE_LINES_PERPENDICULAR) {
        vignette_effect_color_alpha = ApplyDuotoneLinesPerpendicularPS(texcoord, raw_vignette_alpha, EffectColor, 
                                                                     PatternElementSize, rotation_radians, PatternCoverageBoost);
    } 
    else if (EffectStyle == STYLE_LINES_PARALLEL) {
        vignette_effect_color_alpha = ApplyDuotoneLinesParallelPS(texcoord, raw_vignette_alpha, EffectColor, 
                                                                PatternElementSize, rotation_radians, PatternCoverageBoost);
    }
    
    // Apply alpha inversion if enabled
    float final_effect_alpha = vignette_effect_color_alpha.a;
    if (InvertAlpha) {
        final_effect_alpha = 1.0f - final_effect_alpha;
    }
    
    // Blend with original scene color
    float3 blended_color = lerp(original_color, vignette_effect_color_alpha.rgb, final_effect_alpha);
    
    // Create a float4 with the effect result for blending and potential debug display
    float4 effect_result = float4(blended_color, FULL_OPACITY);
    float4 final_color = effect_result;
    
    // Apply blend mode if amount is less than full
    if (BlendAmount < FULL_OPACITY) {
        float4 background = float4(original_color, FULL_OPACITY);
        final_color = AS_applyBlend(effect_result, background, BlendMode, BlendAmount);
    }
    
    // Handle debug modes
    if (DebugMode == DEBUG_MASK) { 
        return float4(final_effect_alpha.xxx, FULL_OPACITY);
    }
    else if (DebugMode == DEBUG_FALLOFF) { 
        return float4(raw_vignette_alpha.xxx, FULL_OPACITY);
    }
    else if (DebugMode == DEBUG_PATTERN) { 
        return float4(vignette_effect_color_alpha.a.xxx, FULL_OPACITY);
    }
    else if (DebugMode == DEBUG_PATTERN_ONLY) {
        float3 pattern_only = lerp(BLACK_COLOR, EffectColor, vignette_effect_color_alpha.a);
        return float4(pattern_only, FULL_OPACITY);
    }
    
    return final_color;
}

//------------------------------------------------------------------------------------------------
// Technique Definition
//------------------------------------------------------------------------------------------------
technique AS_GFX_VignettePlus < ui_label = "[AS] GFX: Vignette Plus"; ui_tooltip = "Advanced vignette effects with customizable styles, falloff, and patterns."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = ASVignettePlus::VignettePlusPS;
    }
}

} // namespace ASVignettePlus

#endif // __AS_GFX_VignettePlus_1_fx

