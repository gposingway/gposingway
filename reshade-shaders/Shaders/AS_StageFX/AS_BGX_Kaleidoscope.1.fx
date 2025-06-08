/**
 * AS_BGX_Kaleidoscope.1.fx - Dynamic Fractal Kaleidoscope Pattern
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *  * CREDITS:
 * Based on "Kaleidoscope" by Kanduvisla
 * Shadertoy: https://www.shadertoy.com/view/ddsyDN
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a vibrant, ever-evolving fractal kaleidoscope pattern with animated tendrils.
 * Perfect for psychedelic, cosmic, or abstract backgrounds with a hypnotic quality.
 *
 * FEATURES:
 * - Adjustable kaleidoscope mirror count for symmetry control
 * - Fractal zoom and pattern rotation with animation controls
 * - Customizable wave parameters and color palette
 * - Audio reactivity for zoom, wave intensity, and pattern rotation
 * - Depth-aware rendering
 * - Standard blend options
 * * IMPLEMENTATION OVERVIEW:
 * 1. Applies mirrored transformations to create kaleidoscope symmetry
 * 2. Generates an iterative fractal pattern with customizable zoom
 * 3. Uses sine-wave distortion to create flowing tendrils
 * 4. Processes through a customizable color palette
 * 5. Applies audio reactivity to key animation parameters
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_Kaleidoscope_1_fx
#define __AS_BGX_Kaleidoscope_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime(), AS_getAudioSource(), UI macros, AS_PI etc.
#include "AS_Palette.1.fxh" // AS palette system

namespace ASKaleidoscope {

// ============================================================================
// CONSTANTS
// ============================================================================

static const float EPSILON = 0.00001f; // Local epsilon

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Kaleidoscope Sectors ---
static const int SECTORS_MIN = 1;
static const int SECTORS_MAX = 24;
static const int SECTORS_DEFAULT = 6;

// --- Fractal Pattern Animation ---
static const float FRACTAL_ZOOM_BASE_MIN = 1.01;
static const float FRACTAL_ZOOM_BASE_MAX = 3.0;
static const float FRACTAL_ZOOM_BASE_DEFAULT = 1.5;

static const float FRACTAL_ZOOM_PULSE_STRENGTH_MIN = 0.0;
static const float FRACTAL_ZOOM_PULSE_STRENGTH_MAX = 0.5;
static const float FRACTAL_ZOOM_PULSE_STRENGTH_DEFAULT = 0.0;

static const float FRACTAL_ZOOM_PULSE_SPEED_MIN = 0.0;
static const float FRACTAL_ZOOM_PULSE_SPEED_MAX = 2.0;
static const float FRACTAL_ZOOM_PULSE_SPEED_DEFAULT = 0.5;

// --- Wave Animation Parameters ---
static const float PALETTE_CYCLE_SPEED_MIN = 0.0;
static const float PALETTE_CYCLE_SPEED_MAX = 2.0;
static const float PALETTE_CYCLE_SPEED_DEFAULT = 0.4;

static const float WAVE_MOTION_SPEED_MIN = 0.0;
static const float WAVE_MOTION_SPEED_MAX = 2.0;
static const float WAVE_MOTION_SPEED_DEFAULT = 1.0;

static const float WAVE_FREQUENCY_MIN = 1.0;
static const float WAVE_FREQUENCY_MAX = 32.0;
static const float WAVE_FREQUENCY_DEFAULT = 8.0;

static const float WAVE_AMPLITUDE_DIVISOR_MIN = 1.0;
static const float WAVE_AMPLITUDE_DIVISOR_MAX = 32.0;
static const float WAVE_AMPLITUDE_DIVISOR_DEFAULT = 8.0;

// --- Base Pattern Motion ---
static const float PATTERN_ROTATION_SPEED_MIN = -10.0;
static const float PATTERN_ROTATION_SPEED_MAX = 10.0;
static const float PATTERN_ROTATION_SPEED_DEFAULT = 0.1;

static const float PATTERN_PULSING_ZOOM_STRENGTH_MIN = 0.0;
static const float PATTERN_PULSING_ZOOM_STRENGTH_MAX = 0.5;
static const float PATTERN_PULSING_ZOOM_STRENGTH_DEFAULT = 0.0;

static const float PATTERN_PULSING_ZOOM_SPEED_MIN = 0.0;
static const float PATTERN_PULSING_ZOOM_SPEED_MAX = 2.0;
static const float PATTERN_PULSING_ZOOM_SPEED_DEFAULT = 0.5;

// --- Audio Reactivity ---
static const float AUDIO_GAIN_FRACTAL_ZOOM_MIN = 0.0;
static const float AUDIO_GAIN_FRACTAL_ZOOM_MAX = 0.5;
static const float AUDIO_GAIN_FRACTAL_ZOOM_DEFAULT = 0.0;

static const float AUDIO_GAIN_WAVE_AMPLITUDE_MIN = 0.0;
static const float AUDIO_GAIN_WAVE_AMPLITUDE_MAX = 10.0;
static const float AUDIO_GAIN_WAVE_AMPLITUDE_DEFAULT = 0.0;

static const float AUDIO_GAIN_ROTATION_MIN = 0.0;
static const float AUDIO_GAIN_ROTATION_MAX = 2.0;
static const float AUDIO_GAIN_ROTATION_DEFAULT = 0.0;

// ============================================================================
// UI DECLARATIONS - Organized by category
// ============================================================================

//------------------------------------------------------------------------------------------------
// Animation & Time Controls
//------------------------------------------------------------------------------------------------
AS_ANIMATION_UI(TimeSpeed, TimeKeyframe, "Animation")

//------------------------------------------------------------------------------------------------
// Kaleidoscope Controls
//------------------------------------------------------------------------------------------------
uniform int Sectors < ui_type = "slider"; ui_label = "Mirrors"; ui_tooltip = "Number of kaleidoscope sectors. 1 means no effect. Even numbers often look best."; ui_min = SECTORS_MIN; ui_max = SECTORS_MAX; ui_step = 1; ui_category = "Kaleidoscope"; > = SECTORS_DEFAULT;

//------------------------------------------------------------------------------------------------
// Audio Reactivity
//------------------------------------------------------------------------------------------------
AS_AUDIO_UI(MasterAudioSource, "Audio Source", AS_AUDIO_BASS, "Audio Reactivity")

uniform float AudioGain_FractalZoom < ui_type = "slider"; ui_label = "Fractal Zoom"; ui_tooltip = "How much audio affects the fractal zoom. Higher = more pulsing with audio."; ui_min = AUDIO_GAIN_FRACTAL_ZOOM_MIN; ui_max = AUDIO_GAIN_FRACTAL_ZOOM_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_FRACTAL_ZOOM_DEFAULT;
uniform float AudioGain_WaveAmplitude < ui_type = "slider"; ui_label = "Wave Amplitude"; ui_tooltip = "How much audio affects the wave amplitude. Higher = more intense tendril motion with audio."; ui_min = AUDIO_GAIN_WAVE_AMPLITUDE_MIN; ui_max = AUDIO_GAIN_WAVE_AMPLITUDE_MAX; ui_step = 0.1; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_WAVE_AMPLITUDE_DEFAULT;
uniform float AudioGain_Rotation < ui_type = "slider"; ui_label = "Pattern Rotation"; ui_tooltip = "How much audio affects pattern rotation. Higher = more rotation with audio."; ui_min = AUDIO_GAIN_ROTATION_MIN; ui_max = AUDIO_GAIN_ROTATION_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_ROTATION_DEFAULT;

//------------------------------------------------------------------------------------------------
// Fractal Pattern Controls
//------------------------------------------------------------------------------------------------
uniform float FractalZoomBase < ui_type = "slider"; ui_label = "Base Zoom Factor"; ui_tooltip = "Base zoom for the fractal UV transformation."; ui_min = FRACTAL_ZOOM_BASE_MIN; ui_max = FRACTAL_ZOOM_BASE_MAX; ui_step = 0.01; ui_category = "Fractal Pattern"; > = FRACTAL_ZOOM_BASE_DEFAULT;
uniform float FractalZoomPulseStrength < ui_type = "slider"; ui_label = "Zoom Pulse Strength"; ui_tooltip = "Amount the fractal zoom pulses over time. Added to Base Zoom."; ui_min = FRACTAL_ZOOM_PULSE_STRENGTH_MIN; ui_max = FRACTAL_ZOOM_PULSE_STRENGTH_MAX; ui_step = 0.01; ui_category = "Fractal Pattern"; > = FRACTAL_ZOOM_PULSE_STRENGTH_DEFAULT;
uniform float FractalZoomPulseSpeed < ui_type = "slider"; ui_label = "Zoom Pulse Speed"; ui_tooltip = "Speed of the fractal zoom pulsation (relative to Master Animation Time)."; ui_min = FRACTAL_ZOOM_PULSE_SPEED_MIN; ui_max = FRACTAL_ZOOM_PULSE_SPEED_MAX; ui_step = 0.01; ui_category = "Fractal Pattern"; > = FRACTAL_ZOOM_PULSE_SPEED_DEFAULT;

//------------------------------------------------------------------------------------------------
// Wave Controls
//------------------------------------------------------------------------------------------------
uniform float WaveMotionSpeed < ui_type = "slider"; ui_label = "Wave Motion Speed"; ui_tooltip = "How fast the tendril waves move."; ui_min = WAVE_MOTION_SPEED_MIN; ui_max = WAVE_MOTION_SPEED_MAX; ui_step = 0.01; ui_category = "Wave Parameters"; > = WAVE_MOTION_SPEED_DEFAULT;
uniform float WaveFrequency < ui_type = "slider"; ui_label = "Wave Frequency"; ui_tooltip = "Frequency of the sine waves creating the tendrils."; ui_min = WAVE_FREQUENCY_MIN; ui_max = WAVE_FREQUENCY_MAX; ui_step = 0.1; ui_category = "Wave Parameters"; > = WAVE_FREQUENCY_DEFAULT;
uniform float WaveAmplitude < ui_type = "slider"; ui_label = "Wave Amplitude"; ui_tooltip = "Controls intensity of wave patterns. Higher = sharper, more defined tendrils."; ui_min = 1.0; ui_max = 32.0; ui_step = 0.1; ui_category = "Wave Parameters"; > = 8.0;

//------------------------------------------------------------------------------------------------
// Pattern Motion Controls
//------------------------------------------------------------------------------------------------
uniform float BasePatternRotationSpeed < ui_type = "slider"; ui_label = "Pattern Rotation Speed"; ui_tooltip = "Speed of rotation for the base pattern inside the kaleidoscope mirrors."; ui_min = PATTERN_ROTATION_SPEED_MIN; ui_max = PATTERN_ROTATION_SPEED_MAX; ui_step = 0.1; ui_category = "Pattern Motion"; > = PATTERN_ROTATION_SPEED_DEFAULT;
uniform float GlobalPulsingZoomStrength < ui_type = "slider"; ui_label = "Pattern Pulsing Zoom Strength"; ui_tooltip = "Strength of the pulsing zoom effect applied to the base pattern."; ui_min = PATTERN_PULSING_ZOOM_STRENGTH_MIN; ui_max = PATTERN_PULSING_ZOOM_STRENGTH_MAX; ui_step = 0.01; ui_category = "Pattern Motion"; > = PATTERN_PULSING_ZOOM_STRENGTH_DEFAULT;
uniform float GlobalPulsingZoomSpeed < ui_type = "slider"; ui_label = "Pattern Pulsing Zoom Speed"; ui_tooltip = "Speed of the pulsing zoom effect."; ui_min = PATTERN_PULSING_ZOOM_SPEED_MIN; ui_max = PATTERN_PULSING_ZOOM_SPEED_MAX; ui_step = 0.01; ui_category = "Pattern Motion"; > = PATTERN_PULSING_ZOOM_SPEED_DEFAULT;

//------------------------------------------------------------------------------------------------
// Color Palette Controls
//------------------------------------------------------------------------------------------------

AS_PALETTE_SELECTION_UI(PaletteSelect, "Color Palette", AS_PALETTE_CUSTOM, "Color Palette")

// Manually declare custom palette colors to set specific defaults for this shader
uniform float3 ASKaleidoscopeCustomPaletteColor0 < ui_type = "color"; ui_label = "Custom Color 1 (Offset)"; ui_category = "Color Palette"; > = float3(0.5, 0.5, 0.5);
uniform float3 ASKaleidoscopeCustomPaletteColor1 < ui_type = "color"; ui_label = "Custom Color 2 (Amplitude)"; ui_category = "Color Palette"; > = float3(0.5, 0.5, 0.5);
uniform float3 ASKaleidoscopeCustomPaletteColor2 < ui_type = "color"; ui_label = "Custom Color 3 (Frequency)"; ui_category = "Color Palette"; > = float3(1.0, 1.0, 1.0);
uniform float3 ASKaleidoscopeCustomPaletteColor3 < ui_type = "color"; ui_label = "Custom Color 4 (Phase)"; ui_category = "Color Palette"; > = float3(0.263, 0.416, 0.557);
uniform float3 ASKaleidoscopeCustomPaletteColor4 < ui_type = "color"; ui_label = "Custom Color 5 (Background)"; ui_category = "Color Palette"; > = float3(0.0, 0.0, 0.0); // Default Black for the 5th color

uniform float PaletteCycleSpeed < ui_type = "slider"; ui_label = "Color Cycle Speed"; ui_tooltip = "How fast colors cycle through the palette."; ui_min = PALETTE_CYCLE_SPEED_MIN; ui_max = PALETTE_CYCLE_SPEED_MAX; ui_step = 0.01; ui_category = "Color Palette"; > = PALETTE_CYCLE_SPEED_DEFAULT;

//------------------------------------------------------------------------------------------------
// Stage & Depth
//------------------------------------------------------------------------------------------------
AS_STAGEDEPTH_UI(EffectDepth)

//------------------------------------------------------------------------------------------------
// Final Mix
//------------------------------------------------------------------------------------------------
AS_BLENDMODE_UI(BlendMode)
AS_BLENDAMOUNT_UI(BlendStrength)

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
float2 kaleidoscope_transform(float2 uv, int sectors) {
    if (sectors <= 1) { 
        return uv;
    }
    float angle = atan2(uv.y, uv.x);
    float radius = length(uv);
    float num_sectors_float = (float)sectors;
    float slice_angle_rad = AS_PI / num_sectors_float; 
    
    angle = fmod(angle, 2.0 * slice_angle_rad);
    if (angle < 0.0) {
        angle += 2.0 * slice_angle_rad;
    }
    angle = abs(angle - slice_angle_rad);
    return float2(radius * cos(angle), radius * sin(angle));
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_Kaleidoscope(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
    // Get original color for blending
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    
    // Get animation time from the standardized utils
    float animationTime = AS_getAnimationTime(TimeSpeed, TimeKeyframe);
    
    // Get audio level for reactivity
    float masterAudioLevel = AS_getAudioSource(MasterAudioSource);
    
    // Convert texcoord to centered coordinates
    float2 screenPosition = texcoord * ReShade::ScreenSize; 
    float2 normalizedUV = (screenPosition - 0.5 * ReShade::ScreenSize) / ReShade::ScreenSize.y;

    // 1. Apply Kaleidoscope transformation
    if (Sectors > 1) {
        normalizedUV = kaleidoscope_transform(normalizedUV, Sectors);
    }
    
    // 2. Apply base pattern rotation with audio reactivity
    float audioModulatedRotation = BasePatternRotationSpeed * (1.0 + masterAudioLevel * AudioGain_Rotation);
    if (abs(audioModulatedRotation) > EPSILON) {
        float baseRotAngle = animationTime * audioModulatedRotation;
        float sRot = sin(baseRotAngle);
        float cRot = cos(baseRotAngle);
        float2x2 baseRotMatrix = float2x2(cRot, sRot, -sRot, cRot); 
        normalizedUV = mul(normalizedUV, baseRotMatrix);
    }

    // 3. Apply pattern pulsing zoom
    if (abs(GlobalPulsingZoomStrength) > EPSILON) {
        float zoomFactor = 1.0 + sin(animationTime * GlobalPulsingZoomSpeed) * GlobalPulsingZoomStrength;
        normalizedUV *= zoomFactor;
    }
    
    // Store original UV for fractal calculation
    float2 baseUV = normalizedUV; 
    
    // Initialize finalColor with the 5th palette color (background)
    float3 backgroundColor;
    if (PaletteSelect == AS_PALETTE_CUSTOM) {
        backgroundColor = AS_GET_CUSTOM_PALETTE_COLOR(ASKaleidoscope, 4);
    } else {
        backgroundColor = AS_getPaletteColor(PaletteSelect, 4);
    }
    float3 finalColor = backgroundColor;
    
    // Calculate fractal zoom with audio reactivity
    float audioModulatedZoom = FractalZoomBase;
    
    // Add zoom pulsing from animation
    if (abs(FractalZoomPulseStrength) > EPSILON) {
        audioModulatedZoom += sin(animationTime * FractalZoomPulseSpeed) * FractalZoomPulseStrength;
    }
    
    // Add zoom influence from audio
    audioModulatedZoom += masterAudioLevel * AudioGain_FractalZoom;
    
    // Ensure zoom is always at least slightly above 1.0 to avoid division issues
    audioModulatedZoom = max(1.01, audioModulatedZoom);
    
    // Calculate audio-modulated wave amplitude
    float audioModulatedWaveAmplitude = WaveAmplitude + masterAudioLevel * AudioGain_WaveAmplitude;
    audioModulatedWaveAmplitude = max(1.0, audioModulatedWaveAmplitude);
    
    // Current UV for the fractal iterations
    float2 currentUV = normalizedUV;
    
    // Apply 4 fractal iterations
    for (int i = 0; i < 4; i++) {
        // Fractal transform
        currentUV = frac(currentUV * audioModulatedZoom) - 0.5; 
        
        // Calculate distance, modified by the base UV
        float distance = length(currentUV) * exp(-length(baseUV)); 
        
        // Calculate palette time based on position, iteration, and animation
        float paletteTime = length(baseUV) + (float)i * 0.4 + animationTime * PaletteCycleSpeed; 
        
        // Get A, B, C, D components from the selected palette
        float3 palA, palB, palC, palD;
        if (PaletteSelect == AS_PALETTE_CUSTOM) {
            palA = AS_GET_CUSTOM_PALETTE_COLOR(ASKaleidoscope, 0);
            palB = AS_GET_CUSTOM_PALETTE_COLOR(ASKaleidoscope, 1);
            palC = AS_GET_CUSTOM_PALETTE_COLOR(ASKaleidoscope, 2);
            palD = AS_GET_CUSTOM_PALETTE_COLOR(ASKaleidoscope, 3);
        } else {
            palA = AS_getPaletteColor(PaletteSelect, 0);
            palB = AS_getPaletteColor(PaletteSelect, 1);
            palC = AS_getPaletteColor(PaletteSelect, 2);
            palD = AS_getPaletteColor(PaletteSelect, 3);
        }
        
        // Calculate color using the A, B, C, D components from the palette
        float3 color = palA + palB * cos(AS_TWO_PI * (palC * paletteTime + palD));
        
        // Apply sine wave distortion with audio reactivity
        float waveEffect = sin(distance * WaveFrequency + animationTime * WaveMotionSpeed);
        waveEffect /= max(EPSILON, audioModulatedWaveAmplitude);
        waveEffect = abs(waveEffect);
        
        // Apply power function to create "tendril" effect
        float intensity = pow(0.01 / (waveEffect + EPSILON), 1.2);
        
        // Add to final color
        finalColor += color * intensity;
    }
    
    // Apply depth masking
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = depth >= EffectDepth;
    
    // Blend the final color with the original scene
    float3 blended = AS_applyBlend(saturate(finalColor), originalColor.rgb, BlendMode);
    
    return float4(lerp(originalColor.rgb, blended, BlendStrength * depthMask), 1.0);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_Kaleidoscope <
    ui_label = "[AS] BGX: Kaleidoscope";
    ui_tooltip = "Dynamic fractal kaleidoscope with animated tendrils.\n"
                 "Perfect for psychedelic or abstract backgrounds.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Kaleidoscope;
    }
}

} // namespace ASKaleidoscope

#endif // __AS_BGX_Kaleidoscope_1_fx


