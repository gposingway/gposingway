/**
 * AS_LFX_StageSpotlights.1.fx - Directional Stage Lighting Effect
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * This shader simulates a vibrant rock concert stage lighting system with directional
 * spotlights, glow effects, and audio reactivity. Perfect for creating dramatic
 * lighting for screenshots and videos.
 *
 * FEATURES:
 * - Up to 4 independently controllable spotlights with customizable properties
 * - Audio-reactive light intensity, automated sway, and pulsing via AS_Utils integration
 * - Adjustable position, size, color, angle, and direction for each spotlight
 * - Beautiful bokeh glow effects that inherit spotlight colors
 * - Depth-based masking for scene integration
 * - Multiple blend modes for different lighting scenarios
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The shader creates cone-shaped directional light beams from defined source points
 * 2. Each spotlight's intensity and movement can be modulated by audio input
 * 3. Atmospheric bokeh effects are scattered across the scene based on spotlight colors
 * 4. All elements are composited with depth-aware blending for natural scene integration
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_LFX_StageSpotlights_1_fx
#define __AS_LFX_StageSpotlights_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "AS_Noise.1.fxh"

// ============================================================================
// HELPER MACROS & CONSTANTS
// ============================================================================

// --- Tunable Constants ---
static const int SPOTLIGHT_COUNT = 4;
static const float SPOT_RADIUS_MIN = 0.05;
static const float SPOT_RADIUS_MAX = 1.5;
static const float SPOT_RADIUS_DEFAULT = 0.5;
static const float SPOT_INTENSITY_MIN = 0.0;
static const float SPOT_INTENSITY_MAX = 2.0;
static const float SPOT_INTENSITY_DEFAULT = 0.5;
static const float SPOT_ANGLE_MIN = 10.0;
static const float SPOT_ANGLE_MAX = 160.0;
static const float SPOT_ANGLE_DEFAULT = 35.0;
static const float SPOT_DIRECTION_MIN = -190.0;
static const float SPOT_DIRECTION_MAX = 180.0;
static const float SPOT_DIRECTION_DEFAULT = 0.0;
static const float SPOT_AUDIOMULT_MIN = 0.5;
static const float SPOT_AUDIOMULT_MAX = 5.0;
static const float SPOT_AUDIOMULT_DEFAULT = 1.00;
static const float SPOT_SWAYSPEED_MIN = 0.0;
static const float SPOT_SWAYSPEED_MAX = 5.0;
static const float SPOT_SWAYSPEED_DEFAULT = 0.5;
static const float SPOT_SWAYANGLE_MIN = 0.0;
static const float SPOT_SWAYANGLE_MAX = 180.0;
static const float SPOT_SWAYANGLE_DEFAULT = 15.0;

static const float BOKEH_DENSITY_MIN = 0.0;
static const float BOKEH_DENSITY_MAX = 1.0;
static const float BOKEH_DENSITY_DEFAULT = 0.25;
static const float BOKEH_SIZE_MIN = 0.01;
static const float BOKEH_SIZE_MAX = 0.2;
static const float BOKEH_SIZE_DEFAULT = 0.08;
static const float BOKEH_STRENGTH_MIN = 0.0;
static const float BOKEH_STRENGTH_MAX = 2.0;
static const float BOKEH_STRENGTH_DEFAULT = 0.7;

// ============================================================================
// SPOTLIGHT UI MACRO
// ============================================================================

// Define a macro for the UI controls of each spotlight to avoid repetition
#define SPOTLIGHT_UI(index, defaultEnable, defaultColor, defaultPosition, \
                    defaultRadius, defaultIntensity, defaultAngle, defaultDirection, \
                    defaultSwaySpeed, defaultSwayAngle, defaultAudioSource, defaultAudioMult) \
uniform bool Spot##index##_Enable < ui_label = "Enable Spotlight " #index; ui_tooltip = "Toggle this spotlight on or off."; ui_category = "Spotlight " #index; ui_category_closed = index > 1; > = defaultEnable; \
uniform float3 Spot##index##_Color < ui_type = "color"; ui_label = "Color"; ui_category = "Spotlight " #index; > = defaultColor; \
uniform float2 Spot##index##_Position < ui_type = "slider"; ui_label = "Position (X, Y)"; ui_tooltip = "Screen position for the spotlight source. (0,0) is center, [-1, 1] covers the central square."; ui_min = -1.5; ui_max = 1.5; ui_step = 0.01; ui_category = "Spotlight " #index; > = defaultPosition; /* Updated range and tooltip */ \
uniform float Spot##index##_Radius < ui_type = "slider"; ui_label = "Size"; ui_tooltip = "Radius of the spotlight cone relative to screen height."; ui_min = SPOT_RADIUS_MIN; ui_max = SPOT_RADIUS_MAX; ui_category = "Spotlight " #index; > = defaultRadius; /* Updated tooltip */ \
uniform float Spot##index##_Intensity < ui_type = "slider"; ui_label = "Intensity"; ui_min = SPOT_INTENSITY_MIN; ui_max = SPOT_INTENSITY_MAX; ui_category = "Spotlight " #index; > = defaultIntensity; \
uniform float Spot##index##_Angle < ui_type = "slider"; ui_label = "Opening"; ui_min = SPOT_ANGLE_MIN; ui_max = SPOT_ANGLE_MAX; ui_category = "Spotlight " #index; > = defaultAngle; \
uniform float Spot##index##_Direction < ui_type = "slider"; ui_label = "Direction"; ui_tooltip = "Base direction angle in degrees (0=down, 90=right, -90=left)."; ui_min = SPOT_DIRECTION_MIN; ui_max = SPOT_DIRECTION_MAX; ui_category = "Spotlight " #index; > = defaultDirection; /* Updated tooltip */ \
uniform float Spot##index##_SwaySpeed < ui_type = "slider"; ui_label = "Speed"; ui_min = SPOT_SWAYSPEED_MIN; ui_max = SPOT_SWAYSPEED_MAX; ui_category = "Spotlight " #index; > = defaultSwaySpeed; \
uniform float Spot##index##_SwayAngle < ui_type = "slider"; ui_label = "Sway"; ui_min = SPOT_SWAYANGLE_MIN; ui_max = SPOT_SWAYANGLE_MAX; ui_category = "Spotlight " #index; > = defaultSwayAngle; \
uniform int Spot##index##_AudioSource < ui_type = "combo"; ui_label = "Source"; ui_items = "Volume\0Beat\0Bass\0Mid\0Treble\0"; ui_category = "Spotlight " #index; > = defaultAudioSource; \
uniform float Spot##index##_AudioMult < ui_type = "slider"; ui_label = "Source Intensity"; ui_tooltip = "Multiplier for the spotlight intensity"; ui_min = SPOT_AUDIOMULT_MIN; ui_max = SPOT_AUDIOMULT_MAX; ui_category = "Spotlight " #index; > = defaultAudioMult;

// ============================================================================
// SPOTLIGHT CONTROLS (Using the macro)
// ============================================================================

// Spotlight A controls - Centered top
SPOTLIGHT_UI(1, true, float3(0.30196, 0.60000, 1.00000), float2(0.0, -1.0), 
            1.359, 0.496, 87.225, 11.451, 
            0.500, 15.000, 1, 1.000)

// Spotlight B controls - Left side
SPOTLIGHT_UI(2, true, float3(1.00000, 0.50196, 0.20000), float2(-1.0, 0.0),
            0.931, 0.259, 75.280, -59.574, 
            0.500, 15.000, 1, 1.000)

// Spotlight C controls - Right side
SPOTLIGHT_UI(3, false, float3(0.8, 0.3, 1.0), float2(1.0, 0.0),
            SPOT_RADIUS_DEFAULT, SPOT_INTENSITY_DEFAULT, SPOT_ANGLE_DEFAULT, -90.0, /* Pointing left */
            SPOT_SWAYSPEED_DEFAULT, SPOT_SWAYANGLE_DEFAULT, 1, SPOT_AUDIOMULT_DEFAULT)

// Spotlight D controls - Bottom center
SPOTLIGHT_UI(4, false, float3(0.2, 1.0, 0.5), float2(0.0, 1.0),
            SPOT_RADIUS_DEFAULT, SPOT_INTENSITY_DEFAULT, SPOT_ANGLE_DEFAULT, 180.0, /* Pointing up */
            SPOT_SWAYSPEED_DEFAULT, SPOT_SWAYANGLE_DEFAULT, 1, SPOT_AUDIOMULT_DEFAULT)

// --- Bokeh Settings ---
uniform float BokehDensity < ui_type = "slider"; ui_label = "Density"; ui_min = BOKEH_DENSITY_MIN; ui_max = BOKEH_DENSITY_MAX; ui_category = "Stage Effects"; > = BOKEH_DENSITY_DEFAULT;
uniform float BokehSize < ui_type = "slider"; ui_label = "Size"; ui_min = BOKEH_SIZE_MIN; ui_max = BOKEH_SIZE_MAX; ui_category = "Stage Effects"; > = BOKEH_SIZE_DEFAULT;
uniform float BokehStrength < ui_type = "slider"; ui_label = "Strength"; ui_min = BOKEH_STRENGTH_MIN; ui_max = BOKEH_STRENGTH_MAX; ui_category = "Stage Effects"; > = BOKEH_STRENGTH_DEFAULT;

// --- Stage Settings ---
AS_STAGEDEPTH_UI(StageDepth) // Renamed category
AS_ROTATION_UI(GlobalSnapRotation, GlobalFineRotation) // Added global rotation

// --- Blend Settings ---
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendAmount)

// --- Debug Settings ---
AS_DEBUG_UI("Off\0Spotlights\0Bokeh\0")

// ============================================================================
// HELPER FUNCTIONS & STRUCTURES
// ============================================================================

// Structure to hold spotlight parameters for easier handling
struct SpotlightParams {
    bool enable;
    float3 color;
    float2 position;
    float radius;
    float intensity;
    float angle;
    float direction;
    float swaySpeed;
    float swayAngle;
    int audioSource;
    float audioMult;
};

// Helper function to get spotlight parameters for a given index
SpotlightParams GetSpotlightParams(int spotIndex) {
    SpotlightParams params;
    
    if (spotIndex == 0) {
        params.enable = Spot1_Enable;
        params.color = Spot1_Color;
        params.position = Spot1_Position;
        params.radius = Spot1_Radius;
        params.intensity = Spot1_Intensity;
        params.angle = Spot1_Angle;
        params.direction = Spot1_Direction;
        params.swaySpeed = Spot1_SwaySpeed;
        params.swayAngle = Spot1_SwayAngle;
        params.audioSource = Spot1_AudioSource;
        params.audioMult = Spot1_AudioMult;
    }
    else if (spotIndex == 1) {
        params.enable = Spot2_Enable;
        params.color = Spot2_Color;
        params.position = Spot2_Position;
        params.radius = Spot2_Radius;
        params.intensity = Spot2_Intensity;
        params.angle = Spot2_Angle;
        params.direction = Spot2_Direction;
        params.swaySpeed = Spot2_SwaySpeed;
        params.swayAngle = Spot2_SwayAngle;
        params.audioSource = Spot2_AudioSource;
        params.audioMult = Spot2_AudioMult;
    }
    else if (spotIndex == 2) {
        params.enable = Spot3_Enable;
        params.color = Spot3_Color;
        params.position = Spot3_Position;
        params.radius = Spot3_Radius;
        params.intensity = Spot3_Intensity;
        params.angle = Spot3_Angle;
        params.direction = Spot3_Direction;
        params.swaySpeed = Spot3_SwaySpeed;
        params.swayAngle = Spot3_SwayAngle;
        params.audioSource = Spot3_AudioSource;
        params.audioMult = Spot3_AudioMult;
    }
    else { // spotIndex == 3
        params.enable = Spot4_Enable;
        params.color = Spot4_Color;
        params.position = Spot4_Position;
        params.radius = Spot4_Radius;
        params.intensity = Spot4_Intensity;
        params.angle = Spot4_Angle;
        params.direction = Spot4_Direction;
        params.swaySpeed = Spot4_SwaySpeed;
        params.swayAngle = Spot4_SwayAngle;
        params.audioSource = Spot4_AudioSource;
        params.audioMult = Spot4_AudioMult;
    }
    
    return params;
}

// Process a single spotlight in the normalized central square space
float3 ProcessSpotlight(float2 diff, SpotlightParams params, out float maskValue) { 
    // Skip processing if spotlight is disabled
    maskValue = 0.0;
    if (!params.enable) return float3(0, 0, 0);
    
    // --- Initial setup ---
    float time = AS_getTime();
    float dist = length(diff);
    
    // Skip early if we're far beyond the maximum radius (optimization)
    if (dist > params.radius * 1.2) return float3(0, 0, 0);
    
    // Calculate sway
    float sway = 0.0;
    if (params.swaySpeed > 0.0 && params.swayAngle > 0.0) {
        sway = AS_applySway(params.swayAngle, params.swaySpeed);
    }
    
    // Final direction angle including sway
    float dirAngle = AS_radians(params.direction) + sway;
    float2 spotDir = float2(sin(dirAngle), -cos(dirAngle)); // Y negated for downwards convention
    
    // --- Audio Reactivity ---
    // Map UI audio source value to the correct AS_AUDIO constants
    int mappedAudioSource;
    switch(params.audioSource) {
        case 0: mappedAudioSource = AS_AUDIO_VOLUME; break;
        case 1: mappedAudioSource = AS_AUDIO_BEAT; break;
        case 2: mappedAudioSource = AS_AUDIO_BASS; break;
        case 3: mappedAudioSource = AS_AUDIO_MID; break;
        case 4: mappedAudioSource = AS_AUDIO_TREBLE; break;
        default: mappedAudioSource = AS_AUDIO_SOLID; break;
    }
    
    // Get audio value and calculate intensity
    float audioVal = AS_getAudioSource(mappedAudioSource);
    float sourceIntensity = params.audioMult * audioVal;
    float intensity = params.intensity + sourceIntensity;
    
    // --- Core Light Beam Calculation ---
    // 1. Calculate angle to light direction
    float dirDot = 0.0;
    if (dist > 1e-5) {
        // For normal pixels: calculate projection onto light direction
        dirDot = dot(normalize(-diff), spotDir);
    } else {
        // For pixels at origin: use full intensity
        dirDot = 1.0;
    }
    
    // 2. Calculate cone angle parameters
    float halfAngleRad = AS_radians(clamp(params.angle, SPOT_ANGLE_MIN, SPOT_ANGLE_MAX)) * 0.5;
    float coneCos = cos(halfAngleRad);
    float tanHalfAngle = tan(halfAngleRad);
    
    // 3. Calculate angular mask with smooth falloff at cone edges
    float edgeSoftness = 0.1;
    float angleFactor = smoothstep(coneCos - edgeSoftness, coneCos + edgeSoftness * 0.5, dirDot);
    
    // Early exit if outside the cone angle
    if (angleFactor <= 0.001) {
        maskValue = 0.0;
        return float3(0, 0, 0);
    }
    
    // 4. Calculate beam shape parameters
    float projectedDist = dist * dirDot; // Distance along beam axis
    float perpDist = dist * sqrt(1.0 - dirDot * dirDot); // Distance perpendicular to beam axis
    
    // 5. Calculate the expected beam width at this distance
    float beamWidthAtDist = max(projectedDist * tanHalfAngle, 0.001);
    
    // 6. Calculate normalized position within the cone
    float normalizedPerpDist = perpDist / beamWidthAtDist;
    
    // 7. Apply radial falloff from center beam axis with:
    //    - Smoother gradient near center
    //    - Stronger falloff near edges
    float radialFalloff = 1.0 - smoothstep(0.0, 0.9, pow(normalizedPerpDist, 0.8));
    
    // 8. Apply length-based falloff with multiple components
    
    // Primary falloff: stronger at the far end of beam
    float primaryFalloff = 1.0 - smoothstep(0.0, params.radius, projectedDist);
    
    // Secondary falloff: to create more natural long-distance attenuation
    float secondaryFalloff = 1.0 - smoothstep(0.0, params.radius * 0.7, projectedDist);
    secondaryFalloff = pow(secondaryFalloff, 0.7); // Power < 1 creates gentler gradient
    
    // Distance falloff: prevents the spear artifact by ensuring smooth transition at beam end
    float distanceFalloff = lerp(secondaryFalloff, primaryFalloff, 0.7);
    
    // 9. Apply special treatment for the beam tip to eliminate "spear" artifact
    // Calculate how close we are to the beam's maximum extent
    float beamEndFactor = smoothstep(params.radius * 0.6, params.radius, projectedDist);
    
    // Apply extra radial falloff near the beam end to soften the tip
    radialFalloff *= 1.0 - (beamEndFactor * normalizedPerpDist * 0.7);
    
    // 10. Combine all factors for final mask
    float beamIntensity = radialFalloff * angleFactor * distanceFalloff * intensity;
    
    // Apply extra dampening at the very tip of the beam
    beamIntensity *= 1.0 - (beamEndFactor * beamEndFactor * 0.5);
    
    maskValue = saturate(beamIntensity);
    return params.color * maskValue;
}

// ============================================================================
// MAIN SHADER FUNCTIONS
// ============================================================================

// Updated renderSpotlights to use the centered 1:1 aspect ratio central square space
float3 renderSpotlights(float2 texcoord, float audioPulse, out float3 spotSum, out float3 spotMask) {
    float3 color = 0;
    float3 mask = 0;
    float3 sum = 0;
    float aspectRatio = ReShade::AspectRatio;
    
    // Step 1: Convert texcoord [0,1] to normalized central square space [-1,1]
    // This creates the uniform coordinate space where the central square is exactly [-1,1]²
    float2 uv_norm;
    if (aspectRatio >= 1.0) { // Wider or square
        uv_norm.x = (texcoord.x - 0.5) * 2.0 * aspectRatio;
        uv_norm.y = (texcoord.y - 0.5) * 2.0;
    } else { // Taller
        uv_norm.x = (texcoord.x - 0.5) * 2.0;
        uv_norm.y = (texcoord.y - 0.5) * 2.0 / aspectRatio;
    }
    // uv_norm is now in a system where the central square is exactly [-1,1]² regardless of aspect ratio
    
    // Step 2: Apply inverse global rotation
    float globalRotation = AS_getRotationRadians(GlobalSnapRotation, GlobalFineRotation);
    float sinRot = sin(-globalRotation);
    float cosRot = cos(-globalRotation);
    float2 rotated_uv;
    rotated_uv.x = uv_norm.x * cosRot - uv_norm.y * sinRot;
    rotated_uv.y = uv_norm.x * sinRot + uv_norm.y * cosRot;
    
    // Process each spotlight
    for (int i = 0; i < SPOTLIGHT_COUNT; i++) {
        SpotlightParams params = GetSpotlightParams(i);
        if (!params.enable) continue; // Skip disabled
        
        // Spotlight positions are already in [-1.5, 1.5] range where [-1,1] is the central square
        // Note: No need to scale position by 0.5 since we're using a [-1,1] system, not [-0.5,0.5]
        float2 effect_pos = params.position;
        
        // Calculate difference in the rotated uniform space
        float2 diff = rotated_uv - effect_pos;
        
        // Process spotlight in uniform space
        float maskValue;
        float3 spotColor = ProcessSpotlight(diff, params, maskValue);
        
        // Accumulate results
        color += spotColor;
        mask += maskValue;
        sum += params.color * maskValue;
    }
    
    spotSum = sum;
    spotMask = mask;
    return color;
}

float3 renderBokeh(float2 uv, float3 spotSum) { 
    float3 bokeh = 0;
    float2 uv_screen = uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 seed = uv_screen * 0.1 + AS_getTime() * 10.0;
    
    const int BOKEH_SAMPLES = 8;
    for (int i = 0; i < BOKEH_SAMPLES; ++i) {
        float2 rnd = AS_hash21(seed + i * 12.9898);
        
        // Place bokeh relative to screen center
        float screenMinDim = min(BUFFER_WIDTH, BUFFER_HEIGHT);
        float2 pos_offset = (rnd * 2.0 - 1.0) * screenMinDim * 0.5;
        float2 pos = float2(BUFFER_WIDTH, BUFFER_HEIGHT) * 0.5 + pos_offset;
        
        float size = BokehSize * (0.7 + rnd.x * 0.6) * screenMinDim * 0.1;
        float dist_sq = dot(uv_screen - pos, uv_screen - pos);
        float fade = exp(-dist_sq / max(size * size, 1e-5));
        
        bokeh += spotSum * fade;
    }
    return bokeh * BokehStrength * BokehDensity / BOKEH_SAMPLES;
}

float4 PS_Spotlights(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get original image first
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    
    // Get scene depth
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    
    // Skip effect if pixel is closer than stage depth
    if (sceneDepth < StageDepth - 0.0005)
        return orig;
    
    // Calculate spotlight and bokeh effects
    // Note: The coordinate transformation now happens inside renderSpotlights
    float3 spotSum, spotMask;
    float3 spotlights = renderSpotlights(texcoord, 0.0, spotSum, spotMask);
    float3 bokeh = renderBokeh(texcoord, spotSum);
    
    // Handle debug modes
    if (DebugMode == 1) return float4(spotlights, 1.0);
    if (DebugMode == 2) return float4(bokeh, 1.0);
    
    // Combine lighting effects
    float3 fx = spotlights + bokeh;
    fx = saturate(fx);
    
    // Apply appropriate blend mode
    float3 blended = AS_applyBlend(fx, orig.rgb, BlendMode);
    float3 result = lerp(orig.rgb, blended, BlendAmount);
    
    return float4(result, orig.a);
}

technique AS_StageSpotlights < ui_label = "[AS] LFX: Stage Spotlights"; ui_tooltip = "Configurable stage spotlights with audio reactivity."; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Spotlights;
    }
}

#endif // __AS_LFX_StageSpotlights_1_fx
