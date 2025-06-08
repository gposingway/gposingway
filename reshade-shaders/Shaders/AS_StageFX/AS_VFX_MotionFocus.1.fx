/**
 * AS_VFX_MotionFocus.1.fx - Automatic Motion-Based Camera Focus & Zoom
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on MotionFocus.fx originally made by Ganossa and ported by IDDQD.
 * This implementation has been extensively rewritten and enhanced for the AS StageFX framework.
 *
 * ===================================================================================
 * *
 * DESCRIPTION:
 * This shader analyzes inter-frame motion differences to dynamically adjust the viewport,
 * zooming towards and centering on areas of detected movement. It uses a multi-pass
 * approach to capture frames, detect motion, analyze motion distribution in quadrants,
 * and apply a corresponding camera transformation with motion-centered zoom.
 * * FEATURES:
 * - Multi-pass motion analysis for robust detection
 * - Half-resolution processing for performance optimization
 * - Temporal smoothing to prevent jittery camera movements
 * - Separate focus center smoothing for stable camera positioning
 * - Adaptive decay for responsive adjustments to changing motion patterns
 * - Quadrant-based motion aggregation to determine the center of activity
 * - Dynamic zoom and focus centered on detected motion areas
 * - Motion-weighted zoom center calculation for natural camera movement
 * - Generous zoom limits for dramatic effect possibilities
 * - Edge correction to prevent sampling outside screen bounds
 * - User-configurable strength for focus and zoom with advanced tunables
 * - Audio reactivity for focus and zoom strength parameters
 * - Debug mode to visualize motion data
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Pass 1 (PS_MotionFocusNorm): Captures the current frame at half resolution
 * 2. Pass 2 (PS_MotionFocusQuadFull): Calculates per-pixel motion intensity using frame
 *    differencing, exponential smoothing, and an adaptive decay system
 * 3. Pass 3 (PS_MotionFocus): Aggregates motion data into four screen quadrants
 * 4. Pass 4 (PS_MotionFocusDisplay): Calculates motion-weighted center and zoom level,
 *    then applies motion-centered zoom transformation to the current frame
 * 5. Pass 5 (PS_MotionFocusStorage): Stores processed frame and motion data for next frame
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================

#ifndef __AS_VFX_MotionFocus_1_fx
#define __AS_VFX_MotionFocus_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// CONSTANTS
// ============================================================================
#define SAMPLE_GRID_X_COUNT 72
#define SAMPLE_GRID_Y_COUNT 72
#define TOTAL_SAMPLES (SAMPLE_GRID_X_COUNT * SAMPLE_GRID_Y_COUNT)

// UI Parameter Constants
static const float FOCUS_STRENGTH_MIN = 0.0;
static const float FOCUS_STRENGTH_MAX = 5.0;
static const float FOCUS_STRENGTH_DEFAULT = 1.4;

static const float ZOOM_STRENGTH_MIN = 0.0;
static const float ZOOM_STRENGTH_MAX = 5.0;
static const float ZOOM_STRENGTH_DEFAULT = 1.4;

static const float MAX_ZOOM_LEVEL_MIN = 0.05;
static const float MAX_ZOOM_LEVEL_MAX = 0.85;
static const float MAX_ZOOM_LEVEL_DEFAULT = 0.3;

static const float ZOOM_INTENSITY_MIN = 0.1;
static const float ZOOM_INTENSITY_MAX = 5.0;
static const float ZOOM_INTENSITY_DEFAULT = 1.8;

static const float MOTION_SMOOTHNESS_MIN = 0.800;
static const float MOTION_SMOOTHNESS_MAX = 0.999;
static const float MOTION_SMOOTHNESS_DEFAULT = 0.9;

static const float MOTION_FADE_RATE_MIN = 0.800;
static const float MOTION_FADE_RATE_MAX = 0.999;
static const float MOTION_FADE_RATE_DEFAULT = 0.978;

static const float FADE_SENSITIVITY_MIN = 0.0;
static const float FADE_SENSITIVITY_MAX = 1.0;
static const float FADE_SENSITIVITY_DEFAULT = 0.8;

static const float CHANGE_SENSITIVITY_MIN = 1000.0;
static const float CHANGE_SENSITIVITY_MAX = 1000000.0;
static const float CHANGE_SENSITIVITY_DEFAULT = 100000.0;

static const float GLOBAL_MOTION_SENSITIVITY_MIN = 1.0;
static const float GLOBAL_MOTION_SENSITIVITY_MAX = 20.0;
static const float GLOBAL_MOTION_SENSITIVITY_DEFAULT = 12.0;

static const float FOCUS_PRECISION_MIN = 1.0;
static const float FOCUS_PRECISION_MAX = 5.0;
static const float FOCUS_PRECISION_DEFAULT = 5.0;

static const float FOCUS_SMOOTHNESS_MIN = 0.500;
static const float FOCUS_SMOOTHNESS_MAX = 0.998;
static const float FOCUS_SMOOTHNESS_DEFAULT = 0.55;

// Motion Detection Constants
static const float MOTION_DETECTION_DIVISOR = 3.0;
static const float DECAY_FACTOR_POWER = 2.0;
static const float GLOBAL_MOTION_POWER = 3.0;
static const float GLOBAL_MOTION_MIN_FACTOR = 1.0;
static const float GLOBAL_MOTION_MAX_FACTOR = 2.0;

// Quadrant Center Positions
static const float QUADRANT_TL_X = 0.25;
static const float QUADRANT_TL_Y = 0.25;
static const float QUADRANT_TR_X = 0.75;
static const float QUADRANT_TR_Y = 0.25;
static const float QUADRANT_BL_X = 0.25;
static const float QUADRANT_BL_Y = 0.75;
static const float QUADRANT_BR_X = 0.75;
static const float QUADRANT_BR_Y = 0.75;

// Texture Resolution Constants
static const int HALF_RESOLUTION_DIVISOR = 2;

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================

texture MotionFocus_NormTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = RGBA8; };
texture MotionFocus_PrevFrameTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = RGBA8; };

texture MotionFocus_QuadFullTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = R32F; }; // Store motion intensity (single channel)
texture MotionFocus_PrevMotionTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = R32F; };

texture MotionFocus_FocusTex { Width = 1; Height = 1; Format = RGBA32F; }; // Stores float4 quadrant motion intensity sums
texture MotionFocus_PrevFocusCenterTex { Width = 1; Height = 1; Format = RG32F; }; // Stores previous focus center (x,y)

sampler MotionFocus_NormSampler { Texture = MotionFocus_NormTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler MotionFocus_PrevFrameSampler { Texture = MotionFocus_PrevFrameTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler MotionFocus_QuadFullSampler { Texture = MotionFocus_QuadFullTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler MotionFocus_PrevMotionSampler { Texture = MotionFocus_PrevMotionTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler MotionFocus_FocusSampler { Texture = MotionFocus_FocusTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; }; // Point for 1x1
sampler MotionFocus_PrevFocusCenterSampler { Texture = MotionFocus_PrevFocusCenterTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; }; // Point for 1x1

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Tunable Constants ---
uniform float FocusStrength < ui_type = "slider"; ui_label = "Focus Strength"; ui_min = FOCUS_STRENGTH_MIN; ui_max = FOCUS_STRENGTH_MAX; ui_step = 0.01; ui_category = "Tunable Constants"; ui_tooltip = "Controls how aggressively the camera follows areas of motion."; > = FOCUS_STRENGTH_DEFAULT;
uniform float ZoomStrength < ui_type = "slider"; ui_label = "Zoom Strength"; ui_min = ZOOM_STRENGTH_MIN; ui_max = ZOOM_STRENGTH_MAX; ui_step = 0.01; ui_category = "Tunable Constants"; ui_tooltip = "Controls the overall intensity of zooming towards areas of motion."; > = ZOOM_STRENGTH_DEFAULT;
uniform float MaxZoomLevel < ui_type = "slider"; ui_label = "Max Zoom Level"; ui_min = MAX_ZOOM_LEVEL_MIN; ui_max = MAX_ZOOM_LEVEL_MAX; ui_step = 0.01; ui_category = "Tunable Constants"; ui_tooltip = "Limits how much the view can zoom in (e.g., 0.8 means 20% of original dimension)."; > = MAX_ZOOM_LEVEL_DEFAULT;
uniform float ZoomIntensity < ui_type = "slider"; ui_label = "Zoom Intensity"; ui_min = ZOOM_INTENSITY_MIN; ui_max = ZOOM_INTENSITY_MAX; ui_step = 0.05; ui_category = "Tunable Constants"; ui_tooltip = "Overall scaling factor for the calculated zoom amount."; > = ZOOM_INTENSITY_DEFAULT;

// --- Detection Controls ---
uniform float MotionSmoothness < ui_type = "slider"; ui_label = "Motion Smoothness"; ui_min = MOTION_SMOOTHNESS_MIN; ui_max = MOTION_SMOOTHNESS_MAX; ui_step = 0.001; ui_category = "Detection Controls"; ui_category_closed = true; ui_tooltip = "Controls temporal smoothing of motion. Higher = smoother, less responsive."; > = MOTION_SMOOTHNESS_DEFAULT;
uniform float MotionFadeRate < ui_type = "slider"; ui_label = "Motion Fade Rate"; ui_min = MOTION_FADE_RATE_MIN; ui_max = MOTION_FADE_RATE_MAX; ui_step = 0.001; ui_category = "Detection Controls"; ui_tooltip = "Base rate at which detected motion intensity fades over time."; > = MOTION_FADE_RATE_DEFAULT;
uniform float FadeSensitivity < ui_type = "slider"; ui_label = "Fade Sensitivity"; ui_min = FADE_SENSITIVITY_MIN; ui_max = FADE_SENSITIVITY_MAX; ui_step = 0.01; ui_category = "Detection Controls"; ui_tooltip = "How strongly motion changes affect the decay rate. Higher = more adaptive decay."; > = FADE_SENSITIVITY_DEFAULT;
uniform float ChangeSensitivity < ui_type = "slider"; ui_label = "Change Sensitivity"; ui_min = CHANGE_SENSITIVITY_MIN; ui_max = CHANGE_SENSITIVITY_MAX; ui_step = 1000.0; ui_category = "Detection Controls"; ui_tooltip = "Sensitivity to motion changes for adapting the decay rate."; > = CHANGE_SENSITIVITY_DEFAULT;
uniform float GlobalMotionSensitivity < ui_type = "slider"; ui_label = "Global Motion Sensitivity"; ui_min = GLOBAL_MOTION_SENSITIVITY_MIN; ui_max = GLOBAL_MOTION_SENSITIVITY_MAX; ui_step = 0.1; ui_category = "Detection Controls"; ui_tooltip = "Scales overall motion input for zoom dampening."; > = GLOBAL_MOTION_SENSITIVITY_DEFAULT;
uniform float FocusPrecision < ui_type = "slider"; ui_label = "Focus Precision"; ui_min = FOCUS_PRECISION_MIN; ui_max = FOCUS_PRECISION_MAX; ui_step = 0.1; ui_category = "Detection Controls"; ui_tooltip = "Exponent for focus distribution factor. Higher = more aggressive shifts."; > = FOCUS_PRECISION_DEFAULT;
uniform float FocusSmoothness < ui_type = "slider"; ui_label = "Focus Smoothness"; ui_min = FOCUS_SMOOTHNESS_MIN; ui_max = FOCUS_SMOOTHNESS_MAX; ui_step = 0.001; ui_category = "Detection Controls"; ui_tooltip = "Temporal smoothing for focus center position. Higher = smoother camera movement."; > = FOCUS_SMOOTHNESS_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_UI(FocusAudioSource, "Focus Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULT_UI(FocusAudioMult, "Focus Audio Multiplier", 1.0, 4.0, "Audio Reactivity")
AS_AUDIO_UI(ZoomAudioSource, "Zoom Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULT_UI(ZoomAudioMult, "Zoom Audio Multiplier", 1.0, 4.0, "Audio Reactivity")

// --- Debug Controls ---
AS_DEBUG_UI("Off\0Motion Intensity (Mid-Pass)\0Quadrant Motion Data (Final)\0")

// ============================================================================
// PASS 1: Frame Capture (Half Resolution)
// ============================================================================
float4 PS_MotionFocusNorm(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    return tex2D(ReShade::BackBuffer, texcoord);
}

// ============================================================================
// PASS 2: Motion Detection (Temporal Smoothing & Adaptive Decay)
// ============================================================================
float PS_MotionFocusQuadFull(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{    float3 currentFrame = tex2D(MotionFocus_NormSampler, texcoord).rgb;
    float3 prevFrame = tex2D(MotionFocus_PrevFrameSampler, texcoord).rgb;float frameDiff = (abs(currentFrame.r - prevFrame.r) +
                       abs(currentFrame.g - prevFrame.g) +
                       abs(currentFrame.b - prevFrame.b)) / MOTION_DETECTION_DIVISOR;

    float prevMotion = tex2D(MotionFocus_PrevMotionSampler, texcoord).r;    // Temporal Smoothing (Exponential Moving Average)
    float smoothedMotion = MotionSmoothness * prevMotion + (1.0 - MotionSmoothness) * frameDiff;

    // Adaptive Decay System
    float motionChange = abs(smoothedMotion - prevMotion);
    float decayFactor = MotionFadeRate - FadeSensitivity * max(1.0 - pow(1.0 - motionChange, DECAY_FACTOR_POWER) * ChangeSensitivity, 0.0);
    decayFactor = clamp(decayFactor, 0.0, 1.0); // Ensure decay factor is valid

    // Use smoothed motion in the adaptive decay calculation
    float finalMotion = decayFactor * smoothedMotion + (1.0 - decayFactor) * frameDiff;
    
    return finalMotion;
}

// ============================================================================
// PASS 3: Quadrant Analysis
// ============================================================================
#define SAMPLE_GRID_X_COUNT 72
#define SAMPLE_GRID_Y_COUNT 72
#define TOTAL_SAMPLES (SAMPLE_GRID_X_COUNT * SAMPLE_GRID_Y_COUNT)

float4 PS_MotionFocus(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target // Only runs for the first pixel (1x1 texture)
{    // quadrantMotionSums: x=top-left, y=top-right, z=bottom-left, w=bottom-right
    float4 quadrantMotionSums = 0; 

    float centerX = AS_SCREEN_CENTER_X;
    float centerY = AS_SCREEN_CENTER_Y;    float stepX = 1.0 / (float)SAMPLE_GRID_X_COUNT;
    float stepY = 1.0 / (float)SAMPLE_GRID_Y_COUNT;

    for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j)
    {        for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i)
        {
            float2 sampleUV = float2((i + AS_HALF) * stepX, (j + AS_HALF) * stepY);
            float motionIntensity = tex2Dlod(MotionFocus_QuadFullSampler, float4(sampleUV, 0, 0)).r;

            if (sampleUV.x < centerX && sampleUV.y < centerY)
                quadrantMotionSums.x += motionIntensity; // Top-left
            else if (sampleUV.x >= centerX && sampleUV.y < centerY)
                quadrantMotionSums.y += motionIntensity; // Top-right
            else if (sampleUV.x < centerX && sampleUV.y >= centerY)
                quadrantMotionSums.z += motionIntensity; // Bottom-left
            else
                quadrantMotionSums.w += motionIntensity; // Bottom-right
        }
    }

    quadrantMotionSums /= (float)TOTAL_SAMPLES; // Normalize by total samples

    return quadrantMotionSums;
}

// ============================================================================
// PASS 4: Focus Application & Display
// ============================================================================
float4 PS_MotionFocusDisplay(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 original_color = tex2D(ReShade::BackBuffer, texcoord);    // currentQuadrantMotion: .x=TL, .y=TR, .z=BL, .w=BR normalized motion intensity
    float4 currentQuadrantMotion = tex2D(MotionFocus_FocusSampler, float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y));
    
    // Get previous focus center for smoothing
    float2 prevFocusCenter = tex2D(MotionFocus_PrevFocusCenterSampler, float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y)).xy;
    
    if (DebugMode == 1) return tex2D(MotionFocus_QuadFullSampler, texcoord).xxxx; // Show full motion detection pass
    if (DebugMode == 2) return currentQuadrantMotion; // Show the RGBA values representing quadrant motions    // Apply audio reactivity to focus and zoom strength
    float focusStrength_reactive = AS_applyAudioReactivity(FocusStrength, FocusAudioSource, FocusAudioMult, true);
    float zoomStrength_reactive = AS_applyAudioReactivity(ZoomStrength, ZoomAudioSource, ZoomAudioMult, true);
    
    // Dominant Quadrant Intensity: The motion intensity of the most active quadrant.
    float dominantQuadrantIntensity = max(currentQuadrantMotion.x, max(currentQuadrantMotion.y, max(currentQuadrantMotion.z, currentQuadrantMotion.w)));
    
    // Focus Distribution Factor: How much the dominant quadrant stands out from the others. Higher if motion is concentrated.
    float focusDistributionFactor = 1.0;
    float sumAllQuadrantMotions = currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w;
    if (sumAllQuadrantMotions > AS_EPSILON) 
    {
        if (dominantQuadrantIntensity == currentQuadrantMotion.x) focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w) * AS_THIRD;
        else if (dominantQuadrantIntensity == currentQuadrantMotion.y) focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.z + currentQuadrantMotion.w) * AS_THIRD;
        else if (dominantQuadrantIntensity == currentQuadrantMotion.z) focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.w) * AS_THIRD;
        else focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z) * AS_THIRD;
        focusDistributionFactor = max(0.0, focusDistributionFactor); 
    }
      // Global Motion Influence: Factor that moderates zoom based on overall screen activity.
    float averageTotalMotion = sumAllQuadrantMotions * AS_QUARTER;
    float globalMotionInfluence = AS_HALF * max(GLOBAL_MOTION_MIN_FACTOR, min(GLOBAL_MOTION_MAX_FACTOR - pow(saturate(averageTotalMotion * GlobalMotionSensitivity), GLOBAL_MOTION_POWER), GLOBAL_MOTION_MAX_FACTOR));

    // Final Transformation Calculation - use audio-reactive zoom strength
    float2 finalZoomAmount = dominantQuadrantIntensity * focusDistributionFactor * globalMotionInfluence * zoomStrength_reactive * ZoomIntensity; 
    finalZoomAmount = min(finalZoomAmount, MaxZoomLevel);
      // Calculate weighted center of motion based on quadrant intensities
    float2 rawMotionCenter = float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y); // Default to screen center
    
    if (sumAllQuadrantMotions > AS_EPSILON) {
        // Quadrant centers: TL(0.25,0.25), TR(0.75,0.25), BL(0.25,0.75), BR(0.75,0.75)
        rawMotionCenter.x = (currentQuadrantMotion.x * QUADRANT_TL_X + currentQuadrantMotion.y * QUADRANT_TR_X + 
                            currentQuadrantMotion.z * QUADRANT_BL_X + currentQuadrantMotion.w * QUADRANT_BR_X) / sumAllQuadrantMotions;
        rawMotionCenter.y = (currentQuadrantMotion.x * QUADRANT_TL_Y + currentQuadrantMotion.y * QUADRANT_TR_Y + 
                            currentQuadrantMotion.z * QUADRANT_BL_Y + currentQuadrantMotion.w * QUADRANT_BR_Y) / sumAllQuadrantMotions;
    }
      // Apply temporal smoothing to focus center - inverted for intuitive behavior
    // Higher FocusSmoothness = more smoothing, Lower FocusSmoothness = more responsive
    float2 motionCenter = lerp(rawMotionCenter, prevFocusCenter, 1.0 - FocusSmoothness);
      // Blend motion center with screen center based on focus distribution - use audio-reactive focus strength
    // More concentrated motion = use motion center more, distributed motion = stay closer to screen center
    float centerBlendFactor = pow(focusDistributionFactor, FocusPrecision) * focusStrength_reactive;
    motionCenter = lerp(float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y), motionCenter, centerBlendFactor);
      float2 zoomScaleFactor = 1.0 - finalZoomAmount; 
    
    // Apply zoom transformation centered around the calculated motion center
    float2 transformedUv = (texcoord - motionCenter) * zoomScaleFactor + motionCenter;
    
    // Edge Correction - recalculated for motion-centered zoom
    float2 sourceUvAtScreenCorner00 = (float2(0.0, 0.0) - motionCenter) / zoomScaleFactor + motionCenter;
    float2 sourceUvAtScreenCorner11 = (float2(1.0, 1.0) - motionCenter) / zoomScaleFactor + motionCenter;

    float2 edgeCorrectionOffset = 0;
    if (sourceUvAtScreenCorner00.x < 0.0) edgeCorrectionOffset.x -= sourceUvAtScreenCorner00.x * zoomScaleFactor.x;
    if (sourceUvAtScreenCorner11.x > 1.0) edgeCorrectionOffset.x -= (sourceUvAtScreenCorner11.x - 1.0) * zoomScaleFactor.x;
    if (sourceUvAtScreenCorner00.y < 0.0) edgeCorrectionOffset.y -= sourceUvAtScreenCorner00.y * zoomScaleFactor.y;
    if (sourceUvAtScreenCorner11.y > 1.0) edgeCorrectionOffset.y -= (sourceUvAtScreenCorner11.y - 1.0) * zoomScaleFactor.y;
    
    transformedUv += edgeCorrectionOffset;
    transformedUv = clamp(transformedUv, AS_EPSILON, 1.0 - AS_EPSILON);

    return tex2D(ReShade::BackBuffer, transformedUv);
}

// ============================================================================
// PASS 5: Data Storage
// ============================================================================
float4 PS_MotionFocusStorageNorm(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    return tex2D(MotionFocus_NormSampler, texcoord);
}

float PS_MotionFocusStorageMotion(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    return tex2D(MotionFocus_QuadFullSampler, texcoord).r;
}

float2 PS_MotionFocusStorageFocusCenter(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    // Store the smoothed focus center for next frame's smoothing
    // This runs after PS_MotionFocusDisplay, so we need to recalculate the motion center AND apply smoothing
    float4 currentQuadrantMotion = tex2D(MotionFocus_FocusSampler, float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y));
    float2 prevFocusCenter = tex2D(MotionFocus_PrevFocusCenterSampler, float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y)).xy;
    float sumAllQuadrantMotions = currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w;
    
    float2 rawMotionCenter = float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
    if (sumAllQuadrantMotions > AS_EPSILON) {
        rawMotionCenter.x = (currentQuadrantMotion.x * QUADRANT_TL_X + currentQuadrantMotion.y * QUADRANT_TR_X + 
                            currentQuadrantMotion.z * QUADRANT_BL_X + currentQuadrantMotion.w * QUADRANT_BR_X) / sumAllQuadrantMotions;
        rawMotionCenter.y = (currentQuadrantMotion.x * QUADRANT_TL_Y + currentQuadrantMotion.y * QUADRANT_TR_Y + 
                            currentQuadrantMotion.z * QUADRANT_BL_Y + currentQuadrantMotion.w * QUADRANT_BR_Y) / sumAllQuadrantMotions;
    }
      // CRITICAL FIX: Apply the same temporal smoothing as in PS_MotionFocusDisplay
    // This ensures FocusSmoothness parameter actually affects the stored focus center
    // Inverted for intuitive behavior: Higher FocusSmoothness = more smoothing
    float2 smoothedMotionCenter = lerp(rawMotionCenter, prevFocusCenter, 1.0 - FocusSmoothness);
    
    return smoothedMotionCenter;
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_MotionFocus < 
    ui_label = "[AS] VFX: Motion Focus";
    ui_tooltip = "Automatically zooms towards detected motion with audio-reactive control."; 
>
{
    pass MotionFocusNormPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusNorm;
        RenderTarget = MotionFocus_NormTex;
    }
    pass MotionFocusQuadFullPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusQuadFull;
        RenderTarget = MotionFocus_QuadFullTex;
    }
    pass MotionFocusCalcPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocus;
        RenderTarget = MotionFocus_FocusTex;
    }
    pass MotionFocusDisplayPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusDisplay;
    }
    pass MotionFocusStorageNormPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageNorm;
        RenderTarget = MotionFocus_PrevFrameTex;
    }    pass MotionFocusStorageMotionPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageMotion;
        RenderTarget = MotionFocus_PrevMotionTex;
    }
    pass MotionFocusStorageFocusCenterPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageFocusCenter;
        RenderTarget = MotionFocus_PrevFocusCenterTex;
    }
}

#endif // __AS_VFX_MotionFocus_1_fx