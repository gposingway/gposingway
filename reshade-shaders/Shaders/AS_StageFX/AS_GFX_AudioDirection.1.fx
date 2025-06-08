/**
 * AS_GFX_AudioDirection.1.fx - Audio Direction Visualization
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * * ===================================================================================
 * * DESCRIPTION:
 * Renders a visual arc segment that points toward the direction of audio panning,
 * helping users identify where sound is coming from during gameplay. The arc appears
 * around the center of the screen with its orientation based on audio pan (center pan = up).
 * Colors are driven by the AS StageFX palette system with optional audio-reactive color selection.
 *
 * FEATURES:
 * - Real-time audio direction visualization using stereo panning data
 * - Audio-reactive arc length, thickness, and opacity (additive modifiers)
 * - Integrated AS StageFX palette system with custom palette support
 * - Audio-driven color selection along the palette spectrum
 * - Multiple blend modes for different visual integration needs
 * - Usability-focused design for gameplay assistance (e.g., similar to Fortnite's visual sound effects)
 * * IMPLEMENTATION OVERVIEW:
 * 1. Uses AS_getAudioDirectionRadians() to determine audio direction.
 * 2. Converts screen coordinates to polar coordinates centered on screen.
 * 3. Renders arc segment based on calculated audio direction and parameters.
 * 4. Applies audio reactivity to visual properties for dynamic feedback.
 * 5. Uses AS StageFX palette system for color selection with optional audio-driven interpolation.
 * 6. Correctly handles aspect ratio for distance and angle calculations.
 * 7. Implements robust arc drawing with soft edges.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_AudioDirection_1_fx
#define __AS_GFX_AudioDirection_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// CONSTANTS
// ============================================================================
static const float ARC_RADIUS_MIN = 0.05; 
static const float ARC_RADIUS_MAX = 0.5;  
static const float ARC_RADIUS_DEFAULT = 0.25;

static const float ARC_LENGTH_MIN = 5.0; // Arc span in degrees
static const float ARC_LENGTH_MAX = 180.0; // Max possible span after audio reactivity
static const float ARC_LENGTH_BASE_DEFAULT = 45.0; // Base span

static const float ARC_THICKNESS_MIN = 0.001; // Min possible thickness
static const float ARC_THICKNESS_MAX = 0.1; 
static const float ARC_THICKNESS_BASE_DEFAULT = 0.01;

static const float ARC_INTENSITY_MIN = 0.0; 
static const float ARC_INTENSITY_MAX = 1.0; 
static const float ARC_INTENSITY_BASE_DEFAULT = 0.0; // Base opacity can be 0 for additive

static const float EDGE_SOFTNESS_MIN = 0.001;
static const float EDGE_SOFTNESS_MAX = 0.02;
static const float EDGE_SOFTNESS_DEFAULT = 0.005;
static const float ANGULAR_FALLOFF_FACTOR = 0.1; 

// Constants for Additive Multiplier Ranges
static const float LENGTH_AUDIO_MULT_MIN = -45.0; // Degrees to add/subtract
static const float LENGTH_AUDIO_MULT_MAX = 90.0;
static const float LENGTH_AUDIO_MULT_DEFAULT = 20.0;

static const float THICKNESS_AUDIO_MULT_MIN = -0.01; // Normalized units to add/subtract
static const float THICKNESS_AUDIO_MULT_MAX = 1.0;
static const float THICKNESS_AUDIO_MULT_DEFAULT = 0.005;

static const float INTENSITY_AUDIO_MULT_MIN = 0.0; // Opacity multiplier (0 to 1 for full effect)
static const float INTENSITY_AUDIO_MULT_MAX = 5.0;
static const float INTENSITY_AUDIO_MULT_DEFAULT = 0.8;


// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Arc Positioning ---
uniform float ArcRadius < ui_type = "slider"; ui_label = "Distance from Center"; ui_tooltip = "How far from the center of the screen the arc appears"; ui_min = ARC_RADIUS_MIN; ui_max = ARC_RADIUS_MAX; ui_step = 0.005; ui_category = "Arc Position"; > = ARC_RADIUS_DEFAULT;

// --- Arc Style ---
uniform float BaseArcLengthDegrees < ui_type = "slider"; ui_label = "Arc Length"; ui_tooltip = "Base length of the arc in degrees"; ui_min = ARC_LENGTH_MIN; ui_max = ARC_LENGTH_MAX; ui_step = 1.0; ui_category = "Arc Style"; > = ARC_LENGTH_BASE_DEFAULT;
uniform float BaseThickness < ui_type = "slider"; ui_label = "Arc Thickness"; ui_tooltip = "Base thickness of the arc line"; ui_min = ARC_THICKNESS_MIN; ui_max = ARC_THICKNESS_MAX; ui_step = 0.001; ui_category = "Arc Style"; > = ARC_THICKNESS_BASE_DEFAULT;
uniform float BaseIntensity < ui_type = "slider"; ui_label = "Base Opacity"; ui_tooltip = "Base visibility of the arc"; ui_min = ARC_INTENSITY_MIN; ui_max = ARC_INTENSITY_MAX; ui_step = 0.01; ui_category = "Arc Style"; > = ARC_INTENSITY_BASE_DEFAULT;
uniform float EdgeSoftness < ui_type = "slider"; ui_label = "Edge Softness"; ui_tooltip = "How soft the edges of the arc appear"; ui_min = EDGE_SOFTNESS_MIN; ui_max = EDGE_SOFTNESS_MAX; ui_step = 0.001; ui_category = "Arc Style"; > = EDGE_SOFTNESS_DEFAULT;

// --- Palette & Colors ---
AS_PALETTE_SELECTION_UI(PaletteIndex, "Color Palette", 1, "Palette & Colors")
AS_DECLARE_CUSTOM_PALETTE(Arc, "Palette & Colors")
uniform float ColorInterpolation < ui_type = "slider"; ui_label = "Color Position"; ui_tooltip = "Position along the palette to sample colors from (0=first color, 1=last color)"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Palette & Colors"; > = 0.5;
AS_AUDIO_UI(ColorAudioSource, "Color Audio Source", AS_AUDIO_VOLUME, "Palette & Colors")
uniform float ColorAudioMult < ui_type = "slider"; ui_label = "Color Audio Multiplier"; ui_tooltip = "How much audio affects color position along the palette"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Palette & Colors"; > = 1.0;

// --- Audio Reactivity ---
AS_AUDIO_UI(LengthAudioSource, "Length Audio Source", AS_AUDIO_VOLUME, "Audio Reactivity")
uniform float LengthAudioMult < ui_type = "slider"; ui_label = "Length Boost"; ui_tooltip = "How much audio extends the arc length"; ui_min = LENGTH_AUDIO_MULT_MIN; ui_max = LENGTH_AUDIO_MULT_MAX; ui_step = 1.0; ui_category = "Audio Reactivity"; > = LENGTH_AUDIO_MULT_DEFAULT;

AS_AUDIO_UI(ThicknessAudioSource, "Thickness Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
uniform float ThicknessAudioMult < ui_type = "slider"; ui_label = "Thickness Boost"; ui_tooltip = "How much audio thickens the arc"; ui_min = THICKNESS_AUDIO_MULT_MIN; ui_max = THICKNESS_AUDIO_MULT_MAX; ui_step = 0.001; ui_category = "Audio Reactivity"; > = THICKNESS_AUDIO_MULT_DEFAULT;

AS_AUDIO_UI(IntensityAudioSource, "Opacity Audio Source", AS_AUDIO_SOLID, "Audio Reactivity")
uniform float IntensityAudioMult < ui_type = "slider"; ui_label = "Opacity Boost"; ui_tooltip = "How much audio brightens the arc"; ui_min = INTENSITY_AUDIO_MULT_MIN; ui_max = INTENSITY_AUDIO_MULT_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = INTENSITY_AUDIO_MULT_DEFAULT;

// --- Final Mix Category ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0) 
AS_BLENDAMOUNT_UI(BlendStrength)

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Gets the arc color based on palette selection and interpolation settings
 */
float3 getArcColor(float audioIntensity) {
    float colorPosition = ColorInterpolation;
    
    // Use audio intensity to drive color position if audio source is enabled
    if (ColorAudioSource != AS_AUDIO_OFF) {
        colorPosition = saturate(audioIntensity * ColorAudioMult);
    }
    
    // Handle custom palette (index 0)
    if (PaletteIndex == AS_PALETTE_CUSTOM) {
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(Arc, colorPosition);
    }
    
    // Use built-in palette
    return AS_getInterpolatedColor(PaletteIndex, colorPosition);
}

/**
 * Calculates the arc mask for the audio direction visualization
 * texcoord: Current pixel's screen coordinates (0-1)
 * target_direction_rad: The direction the arc should point (0 rad = UP in this function's convention)
 * arc_span_deg: The angular length of the arc in degrees
 * arc_radius_norm: Radius from center, normalized (e.g., 0.5 = screen edge if square)
 * arc_thickness_norm: Thickness, normalized
 * edge_softness_units: Softness for edges, in same units as radius/thickness
 */
float calculateArcVisualMask(float2 texcoord, float target_direction_rad, float arc_span_deg, float arc_radius_norm, float arc_thickness_norm, float edge_softness_units) {
    float2 centered_uv = texcoord - 0.5; 

    float pixel_angle_rad = atan2(centered_uv.x, -centered_uv.y); 
    
    float angle_diff_rad = pixel_angle_rad - target_direction_rad;
    angle_diff_rad = AS_mod(angle_diff_rad + AS_PI, AS_TWO_PI) - AS_PI;
    
    float half_arc_span_rad = AS_radians(arc_span_deg) * 0.5;
    
    float angular_falloff_rad = max(AS_radians(1.0), half_arc_span_rad * ANGULAR_FALLOFF_FACTOR); 
    float angleMask = smoothstep(half_arc_span_rad + angular_falloff_rad, half_arc_span_rad - angular_falloff_rad, abs(angle_diff_rad));

    float2 aspect_corrected_centered_uv = centered_uv;
    aspect_corrected_centered_uv.x *= ReShade::AspectRatio; 
    float dist_from_center_norm = length(aspect_corrected_centered_uv); 

    float r_inner = arc_radius_norm - arc_thickness_norm * 0.5;
    float r_outer = arc_radius_norm + arc_thickness_norm * 0.5;

    if (r_inner >= r_outer) return 0.0f; 

    float radial_falloff = edge_softness_units * 0.5; 

    float smooth_inner = smoothstep(r_inner - radial_falloff, r_inner + radial_falloff, dist_from_center_norm);
    float smooth_outer = 1.0 - smoothstep(r_outer - radial_falloff, r_outer + radial_falloff, dist_from_center_norm);
    float radiusMask = smooth_inner * smooth_outer;
    
    return saturate(angleMask * radiusMask);
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 AudioDirectionPS(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float4 backdrop_color = tex2D(ReShade::BackBuffer, texcoord);
    
    float audio_pan_direction_rad = AS_getAudioDirectionRadians(); 
    
    // Apply audio reactivity to parameters (additive mode = 1)
    float current_arc_span_deg = AS_applyAudioReactivityEx(BaseArcLengthDegrees, LengthAudioSource, LengthAudioMult, true, 1);
    current_arc_span_deg = clamp(current_arc_span_deg, ARC_LENGTH_MIN, ARC_LENGTH_MAX);

    float current_thickness = AS_applyAudioReactivityEx(BaseThickness, ThicknessAudioSource, ThicknessAudioMult, true, 1);
    current_thickness = clamp(current_thickness, ARC_THICKNESS_MIN, ARC_THICKNESS_MAX);    float current_intensity = AS_applyAudioReactivityEx(BaseIntensity, IntensityAudioSource, IntensityAudioMult, true, 1);
    current_intensity = saturate(current_intensity);

    // Get audio intensity for color calculation
    float audio_for_color = AS_getAudioSource(ColorAudioSource);
    
    // Calculate arc color using palette system
    float3 arc_color = getArcColor(audio_for_color);
    
    float arc_mask_value = calculateArcVisualMask(texcoord, audio_pan_direction_rad, current_arc_span_deg, ArcRadius, current_thickness, EdgeSoftness);
    
    float4 arc_primitive_color = float4(arc_color, saturate(arc_mask_value * current_intensity));
    
    float4 result = AS_applyBlend(arc_primitive_color, backdrop_color, BlendMode, BlendStrength);
    
    return result;
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_GFX_AudioDirection < 
    ui_label = "[AS] GFX: Audio Direction";
    ui_tooltip = "Renders a visual arc that points toward the direction of audio panning for gameplay assistance."; 
>
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = AudioDirectionPS;
    }
}

#endif // __AS_GFX_AudioDirection_1_fx