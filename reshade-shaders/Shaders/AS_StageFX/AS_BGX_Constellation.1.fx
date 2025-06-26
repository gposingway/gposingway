/**
 * AS_BGX_Constellation.1.fx - Dynamic Cosmic Constellation Pattern
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 *  * CREDITS:
 * Based on "old joseph" by jairoandre
 * Shadertoy: https://www.shadertoy.com/view/slfGzf
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates an animated stellar constellation pattern with twinkling stars and connecting lines.
 * Perfect for cosmic, night sky, or abstract network visualizations with a hand-drawn aesthetic.
 *
 * FEATURES:
 * - Dynamic constellation lines with customizable thickness and falloff
 * - Twinkling star points with adjustable sparkle properties
 * - Procedurally animated line connections
 * - Animated color palette with adjustable parameters
 * - Audio reactivity for zoom, gradient effects, line brightness, and sparkle magnitude
 * - Depth-aware rendering
 * - Standard blend options
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Generates a grid of animated star points that move in procedural patterns
 * 2. Creates line connections between these points based on proximity rules
 * 3. Applies twinkling effects to stars using sine-based animation
 * 4. Combines multiple layers at different scales for a parallax depth effect
 * 5. Processes color based on animated palette parameters
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_BGX_Constellation_1_fx
#define __AS_BGX_Constellation_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // For AS_getTime(), AS_getAudioSource(), UI macros, AS_PI etc.

namespace ASConstellation {

// ============================================================================
// CONSTANTS
// ============================================================================

// ============================================================================
// TUNABLE CONSTANTS (Defaults and Ranges)
// ============================================================================

// --- Constellation Lines ---
static const float LINE_CORE_THICKNESS_MIN = 0.001; 
static const float LINE_CORE_THICKNESS_MAX = 0.05;
static const float LINE_CORE_THICKNESS_DEFAULT = 0.01;

static const float LINE_FALLOFF_WIDTH_MIN = 0.001;
static const float LINE_FALLOFF_WIDTH_MAX = 0.1;
static const float LINE_FALLOFF_WIDTH_DEFAULT = 0.02;

static const float LINE_OVERALL_BRIGHTNESS_MIN = 0.0;
static const float LINE_OVERALL_BRIGHTNESS_MAX = 10.0;
static const float LINE_OVERALL_BRIGHTNESS_DEFAULT = 1.0;

static const float LINE_LENGTH_MOD_STRENGTH_MIN = 0.0;
static const float LINE_LENGTH_MOD_STRENGTH_MAX = 1.0;
static const float LINE_LENGTH_MOD_STRENGTH_DEFAULT = 1.0;

// --- Star Sparkles ---
static const float SPARKLE_SHARPNESS_MIN = 1.0;
static const float SPARKLE_SHARPNESS_MAX = 50.0;
static const float SPARKLE_SHARPNESS_DEFAULT = 10.0;

static const float SPARKLE_BASE_INTENSITY_MIN = 0.0;
static const float SPARKLE_BASE_INTENSITY_MAX = 5.0;
static const float SPARKLE_BASE_INTENSITY_DEFAULT = 1.0;

static const float SPARKLE_TWINKLE_SPEED_MIN = 0.0;
static const float SPARKLE_TWINKLE_SPEED_MAX = 50.0;
static const float SPARKLE_TWINKLE_SPEED_DEFAULT = 10.0;

static const float SPARKLE_TWINKLE_MAGNITUDE_MIN = 0.0;
static const float SPARKLE_TWINKLE_MAGNITUDE_MAX = 1.0;
static const float SPARKLE_TWINKLE_MAGNITUDE_DEFAULT = 1.0;

static const float SPARKLE_PHASE_VARIATION_MIN = 0.0;
static const float SPARKLE_PHASE_VARIATION_MAX = 50.0;
static const float SPARKLE_PHASE_VARIATION_DEFAULT = 10.0;

// --- Color Palette ---
static const float PALETTE_TIME_SCALE_MIN = 0.0;
static const float PALETTE_TIME_SCALE_MAX = 100.0;
static const float PALETTE_TIME_SCALE_DEFAULT = 20.0;

static const float PALETTE_COLOR_AMPLITUDE_MIN = 0.0;
static const float PALETTE_COLOR_AMPLITUDE_MAX = 1.0;
static const float PALETTE_COLOR_AMPLITUDE_DEFAULT = 0.25;

static const float PALETTE_COLOR_BIAS_MIN = 0.0;
static const float PALETTE_COLOR_BIAS_MAX = 1.0;
static const float PALETTE_COLOR_BIAS_DEFAULT = 0.75;

// --- Global Controls ---
static const float ZOOM_MIN = 0.1;
static const float ZOOM_MAX = 5.0;
static const float ZOOM_DEFAULT = 1.0;

// --- Audio Reactivity ---
static const float AUDIO_GAIN_ZOOM_MIN = 0.0;
static const float AUDIO_GAIN_ZOOM_MAX = 2.0;
static const float AUDIO_GAIN_ZOOM_DEFAULT = 0.0;
static const float AUDIO_GAIN_GRADIENT_MIN = 0.0;
static const float AUDIO_GAIN_GRADIENT_MAX = 5.0;
static const float AUDIO_GAIN_GRADIENT_DEFAULT = 1.0;

static const float AUDIO_GAIN_LINE_BRIGHTNESS_MIN = 0.0;
static const float AUDIO_GAIN_LINE_BRIGHTNESS_MAX = 2.0;
static const float AUDIO_GAIN_LINE_BRIGHTNESS_DEFAULT = 0.0;

static const float AUDIO_GAIN_LINE_FALLOFF_MIN = 0.0;
static const float AUDIO_GAIN_LINE_FALLOFF_MAX = 2.0;
static const float AUDIO_GAIN_LINE_FALLOFF_DEFAULT = 0.0;

static const float AUDIO_GAIN_SPARKLE_MAG_MIN = 0.0;
static const float AUDIO_GAIN_SPARKLE_MAG_MAX = 3.0;
static const float AUDIO_GAIN_SPARKLE_MAG_DEFAULT = 0.0;

// ============================================================================
// UI DECLARATIONS - Organized by category
// ============================================================================

//------------------------------------------------------------------------------------------------
// Animation & Time Controls
//------------------------------------------------------------------------------------------------

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'old joseph' by jairoandre\nLink: https://www.shadertoy.com/view/slfGzf\nLicence: CC Share-Alike Non-Commercial\n\n";>;

AS_ANIMATION_UI(TimeSpeed, TimeKeyframe, "Animation")

uniform float Zoom < ui_type = "drag"; ui_label = "Zoom"; ui_tooltip = "Adjust to zoom in or out of the pattern."; ui_min = ZOOM_MIN; ui_max = ZOOM_MAX; ui_step = 0.01; ui_category = "Animation"; > = ZOOM_DEFAULT;

//------------------------------------------------------------------------------------------------
// Audio Reactivity
//------------------------------------------------------------------------------------------------
AS_AUDIO_UI(MasterAudioSource, "Audio Source", AS_AUDIO_BASS, "Audio Reactivity")

uniform float AudioGain_GradientEffect < ui_type = "slider"; ui_label = "Gradient"; ui_tooltip = "How much audio affects the color gradient subtraction."; ui_min = AUDIO_GAIN_GRADIENT_MIN; ui_max = AUDIO_GAIN_GRADIENT_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_GRADIENT_DEFAULT;
uniform float AudioGain_LineBrightness < ui_type = "slider"; ui_label = "Line Brightness"; ui_tooltip = "How much audio affects overall line brightness."; ui_min = AUDIO_GAIN_LINE_BRIGHTNESS_MIN; ui_max = AUDIO_GAIN_LINE_BRIGHTNESS_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_LINE_BRIGHTNESS_DEFAULT;
uniform float AudioGain_LineFalloff < ui_type = "slider"; ui_label = "Line Softness"; ui_tooltip = "How much audio affects line falloff width (can make Lines appear thinner/softer)."; ui_min = AUDIO_GAIN_LINE_FALLOFF_MIN; ui_max = AUDIO_GAIN_LINE_FALLOFF_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_LINE_FALLOFF_DEFAULT;
uniform float AudioGain_SparkleMagnitude < ui_type = "slider"; ui_label = "Sparkle Amount"; ui_tooltip = "How much audio affects sparkle twinkle strength."; ui_min = AUDIO_GAIN_SPARKLE_MAG_MIN; ui_max = AUDIO_GAIN_SPARKLE_MAG_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_SPARKLE_MAG_DEFAULT;
uniform float AudioGain_Zoom < ui_type = "slider"; ui_label = "Zoom"; ui_tooltip = "How much audio affects the zoom level (pulse effect)."; ui_min = AUDIO_GAIN_ZOOM_MIN; ui_max = AUDIO_GAIN_ZOOM_MAX; ui_step = 0.01; ui_category = "Audio Reactivity"; > = AUDIO_GAIN_ZOOM_DEFAULT;

//------------------------------------------------------------------------------------------------
// Constellation Lines
//------------------------------------------------------------------------------------------------
uniform float LineCoreThickness < ui_type = "drag"; ui_label = "Core Thickness"; ui_min = LINE_CORE_THICKNESS_MIN; ui_max = LINE_CORE_THICKNESS_MAX; ui_step = 0.001; ui_category = "Lines"; > = LINE_CORE_THICKNESS_DEFAULT;
uniform float LineFalloffWidth < ui_type = "drag"; ui_label = "Edge Softness"; ui_min = LINE_FALLOFF_WIDTH_MIN; ui_max = LINE_FALLOFF_WIDTH_MAX; ui_step = 0.001; ui_category = "Lines"; > = LINE_FALLOFF_WIDTH_DEFAULT;
uniform float LineOverallBrightness < ui_type = "drag"; ui_label = "Overall Brightness"; ui_min = LINE_OVERALL_BRIGHTNESS_MIN; ui_max = LINE_OVERALL_BRIGHTNESS_MAX; ui_step = 0.1; ui_category = "Lines"; > = LINE_OVERALL_BRIGHTNESS_DEFAULT;
uniform float LineLengthModStrength < ui_type = "drag"; ui_label = "Length Affects Brightness"; ui_min = LINE_LENGTH_MOD_STRENGTH_MIN; ui_max = LINE_LENGTH_MOD_STRENGTH_MAX; ui_step = 0.01; ui_category = "Lines"; > = LINE_LENGTH_MOD_STRENGTH_DEFAULT;

//------------------------------------------------------------------------------------------------
// Star Sparkles
//------------------------------------------------------------------------------------------------
uniform float SparkleSharpness < ui_type = "drag"; ui_label = "Sharpness"; ui_min = SPARKLE_SHARPNESS_MIN; ui_max = SPARKLE_SHARPNESS_MAX; ui_step = 0.1; ui_category = "Stars"; > = SPARKLE_SHARPNESS_DEFAULT;
uniform float SparkleBaseIntensity < ui_type = "drag"; ui_label = "Base Intensity"; ui_min = SPARKLE_BASE_INTENSITY_MIN; ui_max = SPARKLE_BASE_INTENSITY_MAX; ui_step = 0.01; ui_category = "Stars"; > = SPARKLE_BASE_INTENSITY_DEFAULT;
uniform float SparkleTwinkleSpeed < ui_type = "drag"; ui_label = "Twinkle Speed"; ui_min = SPARKLE_TWINKLE_SPEED_MIN; ui_max = SPARKLE_TWINKLE_SPEED_MAX; ui_step = 0.1; ui_category = "Stars"; > = SPARKLE_TWINKLE_SPEED_DEFAULT;
uniform float SparkleTwinkleMagnitude < ui_type = "drag"; ui_label = "Twinkle Amount"; ui_min = SPARKLE_TWINKLE_MAGNITUDE_MIN; ui_max = SPARKLE_TWINKLE_MAGNITUDE_MAX; ui_step = 0.01; ui_category = "Stars"; > = SPARKLE_TWINKLE_MAGNITUDE_DEFAULT;
uniform float SparklePhaseVariation < ui_type = "drag"; ui_label = "Twinkle Variation"; ui_min = SPARKLE_PHASE_VARIATION_MIN; ui_max = SPARKLE_PHASE_VARIATION_MAX; ui_step = 0.1; ui_category = "Stars"; > = SPARKLE_PHASE_VARIATION_DEFAULT;

//------------------------------------------------------------------------------------------------
// Color Palette
//------------------------------------------------------------------------------------------------
uniform float PaletteTimeScale < ui_type = "drag"; ui_label = "Palette Animation Speed"; ui_min = PALETTE_TIME_SCALE_MIN; ui_max = PALETTE_TIME_SCALE_MAX; ui_step = 0.1; ui_category = "Color Palette"; > = PALETTE_TIME_SCALE_DEFAULT;
uniform float3 PaletteColorPhaseFactors < ui_type = "drag"; ui_label = "Palette Color Phase Factors (RGB)"; ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; ui_category = "Color Palette"; > = float3(0.345f, 0.543f, 0.682f);
uniform float PaletteColorAmplitude < ui_type = "drag"; ui_label = "Palette Color Amplitude"; ui_min = PALETTE_COLOR_AMPLITUDE_MIN; ui_max = PALETTE_COLOR_AMPLITUDE_MAX; ui_step = 0.01; ui_category = "Color Palette"; > = PALETTE_COLOR_AMPLITUDE_DEFAULT;
uniform float PaletteColorBias < ui_type = "drag"; ui_label = "Palette Color Bias (Brightness)"; ui_min = PALETTE_COLOR_BIAS_MIN; ui_max = PALETTE_COLOR_BIAS_MAX; ui_step = 0.01; ui_category = "Color Palette"; > = PALETTE_COLOR_BIAS_DEFAULT;

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
float calculateDistanceToLine(float2 refPoint, float2 Linestart, float2 lineEnd) {
    float2 pointToLinestart = refPoint - Linestart;
    float2 lineVector = lineEnd - Linestart;
    float t = saturate(dot(pointToLinestart, lineVector) / (dot(lineVector, lineVector) + AS_EPSILON)); 
    return length(pointToLinestart - lineVector * t);   
}

float hashRandom1D(float2 p) {
    p = frac(p * float2(233.24f, 851.73f));
    p += dot(p, p + 23.45f);
    return frac(p.x * p.y);
}

float2 hashRandom2D(float2 p) {
    float n = hashRandom1D(p);
    return float2(n, hashRandom1D(p + n)); 
}

float2 calculatePointPosition(float2 gridIndex, float2 offset, float currentTime) { 
    float2 noise = hashRandom2D(gridIndex + offset) * currentTime; 
    return offset + sin(noise) * 0.4f; 
}

float calculateLineIntensity(float2 refPoint, float2 Linestart, float2 lineEnd, float coreThickness, float falloffWidth) {
    float distanceToLine = calculateDistanceToLine(refPoint, Linestart, lineEnd);
    float fadeEndDistance = coreThickness + falloffWidth; // Use audio-modulated falloff
    float brightness = smoothstep(fadeEndDistance, coreThickness, distanceToLine); 
    float lineLength = length(Linestart - lineEnd); 
    float lengthModulation = smoothstep(1.6f, 0.5f, lineLength) * 0.5f + smoothstep(0.05f, 0.03f, abs(lineLength - 0.75f));
    brightness *= lerp(1.0f, saturate(lengthModulation), LineLengthModStrength); 
    return brightness;
}

float renderConstellationLayer(float2 uv, float currentTime, float coreThickness, float falloffWidth, float twinkleMagnitude) { 
    float totalBrightness = 0.0f;
    float2 gridLocalPosition = frac(uv) - 0.5f; 
    float2 gridCellIndex = floor(uv);      
    float2 starPositions[9]; 
    int positionIndex = 0; 
    for (float yOffset = -1.0f; yOffset <= 1.0f; yOffset += 1.0f) {
        for (float xOffset = -1.0f; xOffset <= 1.0f; xOffset += 1.0f) {
            if (positionIndex < 9) starPositions[positionIndex++] = calculatePointPosition(gridCellIndex, float2(xOffset, yOffset), currentTime);
        }
    }
    float sparkleAnimationTime = currentTime * SparkleTwinkleSpeed; 
    for (int k = 0; k < 9; k++) { 
        totalBrightness += calculateLineIntensity(gridLocalPosition, starPositions[4], starPositions[k], coreThickness, falloffWidth); 
        float2 sparkleVector = (starPositions[k] - gridLocalPosition) * SparkleSharpness; 
        float sparkleBaseIntensity = SparkleBaseIntensity / (dot(sparkleVector, sparkleVector) + AS_EPSILON); 
        float twinkleEffect = (sin(sparkleAnimationTime + frac(starPositions[k].x) * SparklePhaseVariation) * 0.5f + 0.5f);
        totalBrightness += sparkleBaseIntensity * twinkleEffect * twinkleMagnitude; // Use audio-modulated magnitude
    }
    totalBrightness += calculateLineIntensity(gridLocalPosition, starPositions[1], starPositions[3], coreThickness, falloffWidth); 
    totalBrightness += calculateLineIntensity(gridLocalPosition, starPositions[1], starPositions[5], coreThickness, falloffWidth); 
    totalBrightness += calculateLineIntensity(gridLocalPosition, starPositions[5], starPositions[7], coreThickness, falloffWidth); 
    totalBrightness += calculateLineIntensity(gridLocalPosition, starPositions[3], starPositions[7], coreThickness, falloffWidth);
    return totalBrightness;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================
float4 PS_Constellation(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float currentTime = AS_getAnimationTime(TimeSpeed, TimeKeyframe);
    float2 screenPosition = texcoord * ReShade::ScreenSize; 
    float2 normalizedUV = (screenPosition - 0.5f * ReShade::ScreenSize) / ReShade::ScreenSize.y;
    
    // Get master audio level once
    float masterAudioLevel = AS_getAudioSource(MasterAudioSource);
    
    // Calculate audio-reactive zoom effect (audio increases = zoom out)
    float audioBoostedZoom = Zoom * (1.0f + masterAudioLevel * AudioGain_Zoom);
    
    // Apply zoom factor with audio reactivity (smaller values = zoom in, larger values = zoom out)
    normalizedUV /= audioBoostedZoom;
    
    float verticalGradient = normalizedUV.y;
    float accumulatedBrightness = 0.0f; 
    float mainAnimationTime = currentTime * 0.1f; 
    float sinRotation = sin(mainAnimationTime * 2.0f);
    float cosRotation = cos(mainAnimationTime * 5.0f); 
    float2x2 rotationMatrix = float2x2(cosRotation, sinRotation, -sinRotation, cosRotation); 
    float2 rotatedUV = mul(normalizedUV, rotationMatrix);

    // Apply audio reactivity to parameters using master audio level and specific gains
    float audioBoostedBrightness = LineOverallBrightness * (1.0f + masterAudioLevel * AudioGain_LineBrightness);
    float audioBoostedTwinkleMagnitude = SparkleTwinkleMagnitude * (1.0f + masterAudioLevel * AudioGain_SparkleMagnitude);
    float audioBoostedFalloffWidth = LineFalloffWidth * (1.0f + masterAudioLevel * AudioGain_LineFalloff);
    audioBoostedFalloffWidth = max(0.001f, audioBoostedFalloffWidth);
    
    // Audio-modulated value for gradient effect
    float audioModulatedGradient = masterAudioLevel * AudioGain_GradientEffect;

    const float layerStep = 1.0f / 4.0f;
    for (float layerIndex = 0.0f; layerIndex < (1.0f - layerStep / 2.0f); layerIndex += layerStep) { 
        float zPhase = frac(layerIndex + mainAnimationTime);    
        float layerScale = lerp(10.0f, 0.5f, zPhase);  
        float layerOpacity = smoothstep(0.0f, 0.5f, zPhase) * smoothstep(1.0f, 0.8f, zPhase); 
        
        accumulatedBrightness += renderConstellationLayer(
            rotatedUV * layerScale + layerIndex * 20.0f, 
            currentTime, 
            LineCoreThickness,         // Base thickness
            audioBoostedFalloffWidth,  // Audio-modulated falloff
            audioBoostedTwinkleMagnitude  // Audio-modulated sparkle magnitude
        ) * layerOpacity;
    }
    
    float3 colorPalette = sin(mainAnimationTime * PaletteTimeScale * PaletteColorPhaseFactors) * PaletteColorAmplitude + PaletteColorBias;
    
    float3 finalColor = accumulatedBrightness * audioBoostedBrightness * colorPalette; // Use audio-modulated brightness
    
    float gradientEffect = verticalGradient * audioModulatedGradient * 2.0f; 
    finalColor -= gradientEffect * colorPalette; 
    
    // Apply depth masking
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float depthMask = depth >= EffectDepth;
    
    // Blend the final color with the original scene
    float3 blended = AS_applyBlend(saturate(finalColor), originalColor.rgb, BlendMode);
    return float4(lerp(originalColor.rgb, blended, BlendStrength * depthMask), 1.0f);
}

// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_BGX_Constellation <
    ui_label = "[AS] BGX: Constellation";
    ui_tooltip = "Dynamic cosmic constellation pattern with twinkling stars and connecting Lines.\n"
                 "Perfect for cosmic, night sky, or abstract network visualizations.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Constellation;
    }
}

} // namespace ASConstellation

#endif // __AS_BGX_Constellation_1_fx
