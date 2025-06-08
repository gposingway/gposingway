/**
 * AS_LFX_LaserShow.1.fx - Audio-Reactive Laser Show with Procedural Smoke
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Renders multiple colored laser beams emanating from a user-defined origin, illuminating a swirling, animated smoke field. The effect is fully audio-reactive via Listeningway, with fanning and blinking animations driven by music or sound.
 *
 * FEATURES:
 * - Up to 8 configurable, colored laser beams with analytical intensity
 * - Procedural FBM Simplex noise smoke with domain warping
 * - Audio-reactive fanning and blinking (Listeningway integration)
 * - Depth-based occlusion and user-tunable blending
 * - Highly configurable via ReShade UI
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Compute procedural smoke using FBM Simplex noise with domain warping
 * 2. For each pixel, sum intensity from all active beams based on angle/distance from origin
 * 3. Modulate laser intensity by smoke and depth occlusion
 * 4. Animate fanning and blinking using audio or time
 * 5. Blend with scene using standard AS blend modes
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_LFX_LaserShow_1_fx
#define __AS_LFX_LaserShow_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "AS_Noise.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
// --- Laser Appearance ---
// Origin doesn't have min/max constants since it's a float2 with different ranges
static const float LASER_ANGLE_MIN = -180.0;
static const float LASER_ANGLE_MAX = 180.0;
static const float LASER_ANGLE_DEFAULT = 0.0;

static const float LASER_WIDTH_MIN = 0.001;
static const float LASER_WIDTH_MAX = 0.1;
static const float LASER_WIDTH_DEFAULT = 0.02;

static const float LASER_INTENSITY_MIN = 0.0;
static const float LASER_INTENSITY_MAX = 5.0;
static const float LASER_INTENSITY_DEFAULT = 2.50;

static const float LASER_CORE_MIN = 0.0;
static const float LASER_CORE_MAX = 1.0;
static const float LASER_CORE_DEFAULT = 0.5;

static const int LASER_MIN_BEAMS = 1;
static const int LASER_MAX_BEAMS = 24;
static const int LASER_DEFAULT_BEAMS = 6;

static const float LASER_SPREAD_MIN = 5.0;
static const float LASER_SPREAD_MAX = 180.0;
static const float LASER_SPREAD_DEFAULT = 30.0;

// --- Animation ---
static const float FAN_MAG_MIN = 0.0;
static const float FAN_MAG_MAX = 1.0;
static const float FAN_MAG_DEFAULT = 0.5;

static const float FAN_SPEED_MIN = 0.0;
static const float FAN_SPEED_MAX = 5.0;
static const float FAN_SPEED_DEFAULT = 1.0;

static const float BLINK_SPEED_MIN = 0.0;
static const float BLINK_SPEED_MAX = 8.0;
static const float BLINK_SPEED_DEFAULT = 2.0;

static const float SWAY_SPEED_MIN = 0.0;
static const float SWAY_SPEED_MAX = 5.0;
static const float SWAY_SPEED_DEFAULT = 1.0;

static const float SWAY_ANGLE_MIN = 0.0;
static const float SWAY_ANGLE_MAX = 360.0;
static const float SWAY_ANGLE_DEFAULT = 60.0;

// --- Smoke ---
static const float NOISE_SCALE_MIN = 0.1;
static const float NOISE_SCALE_MAX = 4.0;
static const float NOISE_SCALE_DEFAULT = 1.0;

static const float NOISE_SPEED_MIN = 0.0;
static const float NOISE_SPEED_MAX = 2.0;
static const float NOISE_SPEED_DEFAULT = 0.5;

static const float SMOKE_DENSITY_MIN = 0.0;
static const float SMOKE_DENSITY_MAX = 2.0;
static const float SMOKE_DENSITY_DEFAULT = 1.0;

// --- Vortex Controls ---
static const float VORTEX_STRENGTH_MIN = 0.0;
static const float VORTEX_STRENGTH_MAX = 5.0;
static const float VORTEX_STRENGTH_DEFAULT = 1.0;

static const float VORTEX_SIZE_MIN = 0.1;
static const float VORTEX_SIZE_MAX = 5.0;
static const float VORTEX_SIZE_DEFAULT = 1.0;

static const float VORTEX_SPEED_MIN = 0.0;
static const float VORTEX_SPEED_MAX = 5.0;
static const float VORTEX_SPEED_DEFAULT = 1.0;

static const float VORTEX_TWIRL_MIN = 0.0;
static const float VORTEX_TWIRL_MAX = 10.0;
static const float VORTEX_TWIRL_DEFAULT = 2.0;

static const int VORTEX_COUNT_MIN = 1;
static const int VORTEX_COUNT_MAX = 5;
static const int VORTEX_COUNT_DEFAULT = 2;

// Vortex Direction doesn't have min/max constants since it's a float2

// --- Palette & Style ---
static const float COLOR_CYCLE_SPEED_MIN = -10.0;
static const float COLOR_CYCLE_SPEED_MAX = 10.0;
static const float COLOR_CYCLE_SPEED_DEFAULT = 0.0;

// ============================================================================
// PALETTE & STYLE
// ============================================================================
// Using standardized AS_Utils palette selection
AS_PALETTE_SELECTION_UI(PalettePreset, "Palette", AS_PALETTE_NEON, "Palette & Style")
AS_DECLARE_CUSTOM_PALETTE(LaserShow_, "Palette & Style")

uniform float ColorCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "Controls how fast the beam colors cycle. 0 = static, negative = counter-clockwise, positive = clockwise"; ui_min = COLOR_CYCLE_SPEED_MIN; ui_max = COLOR_CYCLE_SPEED_MAX; ui_step = 0.1; ui_category = "Palette & Style"; > = COLOR_CYCLE_SPEED_DEFAULT;

// ============================================================================
// EFFECT-SPECIFIC APPEARANCE
// ============================================================================
uniform float2 LaserOrigin < ui_type = "slider"; ui_label = "Laser Origin (X,Y)"; ui_min = -0.2; ui_max = 1.2; ui_category = "Laser Appearance"; ui_tooltip = "Position of the laser source. Values outside 0-1 range place the origin off-screen."; > = float2(0.5, 0.5);
uniform float Angle < ui_type = "slider"; ui_label = "Base Angle (deg)"; ui_min = LASER_ANGLE_MIN; ui_max = LASER_ANGLE_MAX; ui_step = 0.1; ui_category = "Laser Appearance"; > = LASER_ANGLE_DEFAULT;
uniform float LaserWidth < ui_type = "slider"; ui_label = "Laser Width"; ui_min = LASER_WIDTH_MIN; ui_max = LASER_WIDTH_MAX; ui_step = 0.001; ui_category = "Laser Appearance"; > = LASER_WIDTH_DEFAULT;
uniform float LaserIntensity < ui_type = "slider"; ui_label = "Laser Intensity"; ui_min = LASER_INTENSITY_MIN; ui_max = LASER_INTENSITY_MAX; ui_step = 0.01; ui_category = "Laser Appearance"; > = LASER_INTENSITY_DEFAULT;
uniform float LaserCore < ui_type = "slider"; ui_label = "Laser Core Intensity"; ui_tooltip = "Controls how much the center of the laser beam maintains its intensity over distance"; ui_min = LASER_CORE_MIN; ui_max = LASER_CORE_MAX; ui_step = 0.01; ui_category = "Laser Appearance"; > = LASER_CORE_DEFAULT;
uniform int NumBeams < ui_type = "slider"; ui_label = "Active Beams"; ui_min = LASER_MIN_BEAMS; ui_max = LASER_MAX_BEAMS; ui_category = "Laser Appearance"; > = LASER_DEFAULT_BEAMS;
uniform float BeamSpread < ui_type = "slider"; ui_label = "Base Spread Angle (deg)"; ui_min = LASER_SPREAD_MIN; ui_max = LASER_SPREAD_MAX; ui_step = 0.1; ui_category = "Laser Appearance"; > = LASER_SPREAD_DEFAULT;

// ============================================================================
// ANIMATION
// ============================================================================
uniform float FanMagnitude < ui_type = "slider"; ui_label = "Fanning Magnitude"; ui_min = FAN_MAG_MIN; ui_max = FAN_MAG_MAX; ui_step = 0.01; ui_category = "Animation"; > = FAN_MAG_DEFAULT;
uniform float FanSpeed < ui_type = "slider"; ui_label = "Fanning Speed"; ui_min = FAN_SPEED_MIN; ui_max = FAN_SPEED_MAX; ui_step = 0.01; ui_category = "Animation"; > = FAN_SPEED_DEFAULT;
uniform float BlinkSpeed < ui_type = "slider"; ui_label = "Blinking Speed"; ui_min = BLINK_SPEED_MIN; ui_max = BLINK_SPEED_MAX; ui_step = 0.01; ui_category = "Animation"; > = BLINK_SPEED_DEFAULT;
// Using standardized UI macros for sway parameters
AS_SWAYSPEED_UI(SwaySpeed, "Animation")
AS_SWAYANGLE_UI(SwayAngle, "Animation")

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================
AS_AUDIO_UI(FanAudioSource, "Fanning Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULT_UI(FanAudioMult, "Fanning Audio Multiplier", 1.0, 2.0, "Audio Reactivity")
AS_AUDIO_UI(BlinkAudioSource, "Blinking Audio Source", AS_AUDIO_VOLUME, "Audio Reactivity")
AS_AUDIO_MULT_UI(BlinkAudioMult, "Blinking Audio Multiplier", 1.0, 2.0, "Audio Reactivity")

// ============================================================================
// NOISE (SMOKE)
// ============================================================================
uniform float NoiseScale < ui_type = "slider"; ui_label = "Noise Scale"; ui_min = NOISE_SCALE_MIN; ui_max = NOISE_SCALE_MAX; ui_step = 0.01; ui_category = "Smoke"; > = NOISE_SCALE_DEFAULT;
uniform float NoiseSpeed < ui_type = "slider"; ui_label = "Noise Animation Speed"; ui_min = NOISE_SPEED_MIN; ui_max = NOISE_SPEED_MAX; ui_step = 0.01; ui_category = "Smoke"; > = NOISE_SPEED_DEFAULT;
uniform float SmokeDensity < ui_type = "slider"; ui_label = "Smoke Density Influence"; ui_min = SMOKE_DENSITY_MIN; ui_max = SMOKE_DENSITY_MAX; ui_step = 0.01; ui_category = "Smoke"; > = SMOKE_DENSITY_DEFAULT;

// ============================================================================
// VORTEX CONTROLS
// ============================================================================
uniform float VortexStrength < ui_type = "slider"; ui_label = "Vortex Strength"; ui_min = VORTEX_STRENGTH_MIN; ui_max = VORTEX_STRENGTH_MAX; ui_step = 0.01; ui_category = "Vortex Controls"; ui_tooltip = "Controls how strongly the vortices affect the smoke"; > = VORTEX_STRENGTH_DEFAULT;
uniform float VortexSize < ui_type = "slider"; ui_label = "Vortex Size"; ui_min = VORTEX_SIZE_MIN; ui_max = VORTEX_SIZE_MAX; ui_step = 0.01; ui_category = "Vortex Controls"; ui_tooltip = "Controls the size of the vortices"; > = VORTEX_SIZE_DEFAULT;
uniform float VortexSpeed < ui_type = "slider"; ui_label = "Vortex Animation Speed"; ui_min = VORTEX_SPEED_MIN; ui_max = VORTEX_SPEED_MAX; ui_step = 0.01; ui_category = "Vortex Controls"; ui_tooltip = "Controls how fast the vortices animate across the screen"; > = VORTEX_SPEED_DEFAULT;
uniform float VortexTwirl < ui_type = "slider"; ui_label = "Vortex Twirl"; ui_min = VORTEX_TWIRL_MIN; ui_max = VORTEX_TWIRL_MAX; ui_step = 0.01; ui_category = "Vortex Controls"; ui_tooltip = "Controls how much the vortices twist the smoke"; > = VORTEX_TWIRL_DEFAULT;
uniform int VortexCount < ui_type = "slider"; ui_label = "Number of Vortices"; ui_min = VORTEX_COUNT_MIN; ui_max = VORTEX_COUNT_MAX; ui_category = "Vortex Controls"; ui_tooltip = "Controls how many vortices appear in the scene"; > = VORTEX_COUNT_DEFAULT;
uniform float2 VortexDirection < ui_type = "slider"; ui_label = "Vortex Direction (X,Y)"; ui_min = -1.0; ui_max = 1.0; ui_category = "Vortex Controls"; ui_tooltip = "Controls the general direction of vortex movement"; > = float2(1.0, 0.0);

// Audio reactivity for vortices
AS_AUDIO_UI(VortexAudioSource, "Vortex Audio Source", AS_AUDIO_BASS, "Vortex Controls")
AS_AUDIO_MULT_UI(VortexAudioMult, "Vortex Audio Multiplier", 1.0, 5.0, "Vortex Controls")

// ============================================================================
// STAGE DISTANCE (DEPTH)
// ============================================================================
AS_STAGEDEPTH_UI(StageDepth)

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_UI("Off\0Smoke\0Audio\0Laser\0")

// ============================================================================
// SYSTEM UNIFORMS
// ============================================================================
// (frameCount is included via AS_Utils.1.fxh)

// ============================================================================
// NAMESPACE & HELPERS
// ============================================================================
namespace AS_LaserShow {

// Get color from the currently selected palette using standardized AS_Utils functions
float3 LaserShow_getPaletteColor(float t, float time) {
    // Apply time-based color cycling if enabled
    if (ColorCycleSpeed != 0.0) {
        // Calculate the cycle rate - positive is clockwise, negative is counter-clockwise
        // Scale by 0.1 to match the requirement (|10| = 10 cycles per second)
        float cycleRate = ColorCycleSpeed * 0.1;
        
        // Apply cycling offset to the palette index
        t = frac(t + cycleRate * time);
    }
    
    // Return the color from the selected palette
    if (PalettePreset == AS_PALETTE_CUSTOM) {
        return AS_GET_INTERPOLATED_CUSTOM_COLOR(LaserShow_, t);
    }
    return AS_getInterpolatedColor(PalettePreset, t);
}

// --- Simplex Noise Implementation (2D, optimized for FBM) ---
// Fallback: Use AS_hash21 for basic noise if no Simplex2D available
float Simplex2D(float2 v) {
    // Simple value noise using AS_hash21, range [-1,1]
    return AS_hash21(v).x * 2.0 - 1.0;
}

// Fractal Brownian Motion (FBM) with domain warping
float FBMNoise(float2 uv, float time, float scale, float speed) {
    float2 p = uv * scale;
    float n = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    float2 warp = float2(0.0, 0.0);
    for (int i = 0; i < 4; ++i) {
        float t = time * speed * freq;
        float2 domain = p + warp + float2(t, -t);
        float val = Simplex2D(domain);
        n += val * amp;
        warp += float2(val, -val) * 0.25 * amp;
        amp *= 0.5;
        freq *= 2.0;
    }
    return n * 0.5 + 0.5;
}

// Analytical beam intensity (angle/distance from origin)
float BeamIntensity(float2 uv, float2 origin, float angle, float width, float coreIntensity) {
    float2 dir = float2(cos(angle), sin(angle));
    float2 rel = uv - origin;
    float dist = length(rel);
    float beamAngle = atan2(rel.y, rel.x);
    float dAngle = abs(AS_mod(beamAngle - angle + AS_PI, AS_TWO_PI) - AS_PI);
    
    // Calculate the base intensity with Gaussian falloff based on angle deviation
    float intensity = exp(-0.5 * (dAngle * dAngle) / (width * width));
    
    // Create the core effect: a thinner, more intense center that fades less with distance
    float coreWidth = width * 0.25; // Core is 1/4 the width of the beam
    float coreIntensityFactor = exp(-0.5 * (dAngle * dAngle) / (coreWidth * coreWidth));
    
    // Standard distance falloff for the outer beam
    float distanceFalloff = exp(-dist * 2.0);
    
    // Reduced distance falloff for the core (controlled by coreIntensity)
    float coreDistanceFalloff = exp(-dist * (2.0 - 1.5 * coreIntensity));
    
    // Blend the core and outer beam based on the core intensity parameter
    return intensity * distanceFalloff * (1.0 - coreIntensity) + 
           coreIntensityFactor * coreDistanceFalloff * coreIntensity;
}

} // namespace

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float2 AS_aspectCorrectUV(float2 uv) {
    float aspect = ReShade::ScreenSize.x / ReShade::ScreenSize.y;
    return float2((uv.x - 0.5) * aspect + 0.5, uv.y);
}

float4 PS_LaserShow(float4 pos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float2 aspectUV = AS_aspectCorrectUV(texcoord);
    float2 origin = LaserOrigin;
    float2 aspectOrigin = AS_aspectCorrectUV(origin);

    // --- Depth cutoff (stage depth) ---
    float sceneDepth = ReShade::GetLinearizedDepth(texcoord);
    if (sceneDepth < StageDepth)
        return orig;

    // --- Noise (smoke) ---
    float time = AS_getTime();
    float noise = AS_LaserShow::FBMNoise(aspectUV, time, NoiseScale, NoiseSpeed);
    float smoke = pow(noise, SmokeDensity);

    // --- Fanning and Blinking Animation (audio-reactive) ---
    bool enableAudio = true; // Always enable audio reactivity since we removed the checkbox
    float fanAudio = AS_applyAudioReactivity(1.0, FanAudioSource, FanAudioMult, enableAudio);
    float blinkAudio = AS_applyAudioReactivity(1.0, BlinkAudioSource, BlinkAudioMult, enableAudio);

    float fanPhase = time * FanSpeed * fanAudio;
    float blinkPhase = time * BlinkSpeed * blinkAudio;
    float blink = 0.5 + 0.5 * sin(blinkPhase * AS_TWO_PI);

    // --- Laser Beams ---
    float baseAngle = radians(Angle);
    
    // Apply sway animation to the base angle using our centralized helper function
    float sway = AS_applySway(SwayAngle, SwaySpeed);
    baseAngle += sway;
    
    float baseSpread = radians(BeamSpread);
    float fan = FanMagnitude * sin(fanPhase);
    // Add fanning audio directly to the spread angle
    float fanAudioSpread = baseSpread + (fanAudio * FanAudioMult);
    float spread = fanAudioSpread * (1.0 + fan);
    
    // Track cumulative color contribution per pixel
    float3 cumulativeColor = float3(0.0, 0.0, 0.0);
    float cumulativeIntensity = 0.0;
    
    // Calculate each beam color and intensity
    for (int i = 0; i < LASER_MAX_BEAMS; ++i) {
        if (i >= NumBeams) break;
        
        // Calculate beam angle
        float frac = (NumBeams == 1) ? 0.0 : (float(i) / (NumBeams - 1) - 0.5);
        float angle = baseAngle + frac * spread;
        
        // Calculate beam intensity at this pixel
        float beamIntensity = AS_LaserShow::BeamIntensity(aspectUV, aspectOrigin, angle, LaserWidth, LaserCore);
        
        // Get the color for this specific beam from our palette
        float3 beamColor = AS_LaserShow::LaserShow_getPaletteColor(float(i) / float(LASER_MAX_BEAMS), time);
        
        // Add this beam's contribution to the cumulative color
        cumulativeColor += beamColor * beamIntensity;
        cumulativeIntensity += beamIntensity;
    }
    
    // Apply global intensity and blink effects
    cumulativeColor *= LaserIntensity * blink;
    cumulativeIntensity *= LaserIntensity * blink;

    // --- Smoke Modulation ---
    float3 laserSmoke = cumulativeColor * smoke;

    // --- Depth Occlusion ---
    float depthMask = (sceneDepth >= StageDepth) ? 1.0 : 0.0;
    float3 finalLaser = laserSmoke * depthMask;

    // --- Final Result ---
    float4 effect = float4(finalLaser, saturate(cumulativeIntensity * smoke * depthMask));

    // --- Debug Output ---
    float4 maskDbg = float4(smoke.xxx, 1.0);
    float4 audioDbg = float4(fanAudio, blinkAudio, 0, 1);
    float4 laserDbg = float4(finalLaser, 1.0);
    float4 outColor = AS_debugOutput(DebugMode, orig, maskDbg, audioDbg, laserDbg);
    if (DebugMode == 0) {
        // Use standard blend function from AS_Utils with blend amount
        float3 blended = AS_applyBlend(effect.rgb, orig.rgb, BlendMode);
        // Apply blend amount for final mix
        outColor = float4(lerp(orig.rgb, blended, BlendAmount), orig.a);
    }
    return outColor;
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_LaserShow < ui_label = "[AS] LFX: Laser Show"; ui_tooltip = "Audio-reactive laser beams through procedural smoke"; > {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_LaserShow;
    }
}

#endif // __AS_LFX_LaserShow_1_fx


