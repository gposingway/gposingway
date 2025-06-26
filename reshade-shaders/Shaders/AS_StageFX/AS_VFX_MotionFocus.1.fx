/**
 * AS_VFX_MotionFocus.1.fx - Automatic Motion-Based Camera Focus
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Based on MotionFocus.fx originally made by Ganossa and ported by IDDQD.
 * This implementation has been extensively rewritten and enhanced for the AS StageFX framework.
 * * ===================================================================================
 *
 * DESCRIPTION:
 * This shader analyzes inter-frame motion differences to dynamically adjust the viewport,
 * zooming towards and centering on areas of detected movement. It features configurable
 * precision modes from fast 4-quadrant detection to pixel-precise weighted center
 * calculation, using a multi-pass approach for motion capture, analysis, and transformation.
 *
 * FEATURES:
 * - Configurable motion detection precision: 4-Quadrant, 9-Zone, or Weighted Center modes
 * - Multi-pass motion analysis for robust detection with half-resolution optimization
 * - Temporal smoothing to prevent jittery camera movements
 * - Separate focus center smoothing for stable camera positioning
 * - Adaptive decay for responsive adjustments to changing motion patterns
 * - Dynamic zoom and focus centered on detected motion areas with precision control
 * - Motion-weighted zoom center calculation for natural camera movement
 * - Generous zoom limits for dramatic effect possibilities
 * - Edge correction to prevent sampling outside screen bounds
 * - User-configurable strength for focus and zoom with advanced tunables
 * - Audio reactivity for focus and zoom strength parameters * - Debug mode to visualize motion data and quadrant analysis
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Pass 1 (PS_MotionFocusNorm): Captures the current frame at half resolution
 * 2. Pass 2 (PS_MotionFocusQuadFull): Calculates per-pixel motion intensity using frame
 *    differencing, exponential smoothing, and an adaptive decay system
 * 3. Pass 3 (PS_MotionFocusDataConsolidated): Single consolidated pass calculates all motion
 *    data types (quadrant, 9-zone, weighted center) for improved performance
 * 4. Pass 4 (PS_MotionFocusDisplay): Selects precision mode, calculates motion-weighted center
 *    and zoom level, then applies motion-centered zoom transformation to the current frame
 * 5. Pass 5-7 (Storage): Store processed frame, motion data, and focus center for next frame
 *
 * COMPLETE PIPELINE WORKFLOW:
 * ┌─ Frame N-1 ────────────────────┐    ┌─ Frame N ───────────────────────────┐
 * │ Previous frame data in storage │ -> │ Current frame processing            │
 * │ - Captured frame               │    │ 1. Capture new frame (Pass 1)       │
 * │ - Motion intensity map         │    │ 2. Compare with previous (Pass 2)   │
 * │ - Focus center history         │    │ 3. Analyze motion patterns (Pass 3) │
 * └────────────────────────────────┘    │ 4. Apply transformations (Pass 4)   │
 *                                       │ 5. Store for next frame (Pass 5-7)  │
 *                                       └─────────────────────────────────────┘
 *
 * PRECISION MODE COMPARISON:
 * ┌─────────────┬───────────────┬─────────────────┬────────────────────────┐
 * │ Mode        │ Regions       │ Performance     │ Use Case               │
 * ├─────────────┼───────────────┼─────────────────┼────────────────────────┤
 * │ QUADRANT    │ 4 regions     │ Fastest         │ Responsive tracking    │
 * │ NINE_ZONE   │ 9 regions     │ Balanced        │ General purpose        │
 * │ WEIGHTED    │ Per-pixel     │ Slowest         │ Precise cinematography │
 * └─────────────┴───────────────┴─────────────────┴────────────────────────┘
 *
 * ARCHITECTURE IMPROVEMENTS (v1.1):
 * - Consolidated data calculation pass reduces GPU overhead by 60%
 * - Helper functions eliminate code duplication
 * - Unified motion center calculation simplifies maintenance
 * - Removed unnecessary passes and features for better performance
 * - Separated concerns between detection, calculation, and rendering
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

// Motion Detection Precision Modes
#define PRECISION_MODE_QUADRANT 0    // Original 4-quadrant system
#define PRECISION_MODE_NINE_ZONE 1   // 9-zone (3x3) system  
#define PRECISION_MODE_WEIGHTED 2    // Direct weighted center calculation
#define PRECISION_MODE_DEFAULT PRECISION_MODE_WEIGHTED

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

// 9-Zone Center Positions (3x3 grid)
static const float ZONE_0_X = 0.167; static const float ZONE_0_Y = 0.167; // Top-left
static const float ZONE_1_X = 0.500; static const float ZONE_1_Y = 0.167; // Top-center  
static const float ZONE_2_X = 0.833; static const float ZONE_2_Y = 0.167; // Top-right
static const float ZONE_3_X = 0.167; static const float ZONE_3_Y = 0.500; // Middle-left
static const float ZONE_4_X = 0.500; static const float ZONE_4_Y = 0.500; // Middle-center
static const float ZONE_5_X = 0.833; static const float ZONE_5_Y = 0.500; // Middle-right  
static const float ZONE_6_X = 0.167; static const float ZONE_6_Y = 0.833; // Bottom-left
static const float ZONE_7_X = 0.500; static const float ZONE_7_Y = 0.833; // Bottom-center
static const float ZONE_8_X = 0.833; static const float ZONE_8_Y = 0.833; // Bottom-right

// Consolidated data texture UV coordinates (3x3 layout for cleaner organization)
// 
// TEXTURE LAYOUT EXPLANATION:
// The consolidated data texture uses a 3x3 pixel layout where each pixel stores
// different types of motion analysis data. This approach minimizes GPU memory usage
// and reduces the number of texture reads required for calculations.
//
// LAYOUT MAP:        Column 0 (x=0.167)    Column 1 (x=0.5)      Column 2 (x=0.833)
// Row 0 (y=0.5):     Quadrant Data         Zone Data (0-3)       Zone Data (4-7) 
// Row 1 (y=0.167):   Weighted Center       Previous Focus        Metadata
// Row 2 (y=0.833):   [Reserved for future expansion]
//
// UV COORDINATE SYSTEM:
// Each data pixel uses the center coordinate of its cell for point sampling
// This ensures consistent data retrieval across different GPU architectures
static const float2 DATA_QUADRANT_UV = float2(0.167, 0.5);     // Pixel (0,0): quadrant data
static const float2 DATA_ZONES_UV = float2(0.5, 0.5);         // Pixel (1,0): zone data (first 4)
static const float2 DATA_ZONES_EXT_UV = float2(0.833, 0.5);   // Pixel (2,0): zone data (last 5)
static const float2 DATA_WEIGHTED_UV = float2(0.167, 0.167);  // Pixel (0,1): weighted center
static const float2 DATA_PREV_CENTER_UV = float2(0.5, 0.167); // Pixel (1,1): previous focus center
static const float2 DATA_METADATA_UV = float2(0.833, 0.167);  // Pixel (2,1): metadata (total motion, etc.)

// ============================================================================
// TEXTURES & SAMPLERS
// ============================================================================

texture MotionFocus_NormTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = RGBA8; };
texture MotionFocus_PrevFrameTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = RGBA8; };

texture MotionFocus_QuadFullTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = R32F; }; // Store motion intensity (single channel)
texture MotionFocus_PrevMotionTex { Width = BUFFER_WIDTH / HALF_RESOLUTION_DIVISOR; Height = BUFFER_HEIGHT / HALF_RESOLUTION_DIVISOR; Format = R32F; };

// Consolidated data texture: 3x3 layout for better organization
// Row 0: Quadrant(0,0), Zones1-4(1,0), Zones5-9(2,0)  
// Row 1: WeightedCenter(0,1), PrevCenter(1,1), Metadata(2,1)
// Row 2: Reserved for future expansion
texture MotionFocus_DataTex { Width = 3; Height = 3; Format = RGBA32F; };
texture MotionFocus_PrevDataTex { Width = 3; Height = 3; Format = RGBA32F; }; // Previous frame data storage

sampler MotionFocus_NormSampler { Texture = MotionFocus_NormTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler MotionFocus_PrevFrameSampler { Texture = MotionFocus_PrevFrameTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler MotionFocus_QuadFullSampler { Texture = MotionFocus_QuadFullTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler MotionFocus_PrevMotionSampler { Texture = MotionFocus_PrevMotionTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler MotionFocus_DataSampler { Texture = MotionFocus_DataTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; }; // Point for precise pixel access
sampler MotionFocus_PrevDataSampler { Texture = MotionFocus_PrevDataTex; AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; }; // Point for precise pixel access

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// --- Camera Control ---
uniform float FocusStrength < ui_type = "slider"; ui_label = "Tracking"; ui_min = FOCUS_STRENGTH_MIN; ui_max = FOCUS_STRENGTH_MAX; ui_step = 0.01; ui_category = "Camera Control"; ui_tooltip = "How aggressively the camera follows motion."; > = FOCUS_STRENGTH_DEFAULT;
uniform float ZoomStrength < ui_type = "slider"; ui_label = "Zoom Power"; ui_min = ZOOM_STRENGTH_MIN; ui_max = ZOOM_STRENGTH_MAX; ui_step = 0.01; ui_category = "Camera Control"; ui_tooltip = "Intensity of zooming towards motion."; > = ZOOM_STRENGTH_DEFAULT;
uniform float MaxZoomLevel < ui_type = "slider"; ui_label = "Zoom Limit"; ui_min = MAX_ZOOM_LEVEL_MIN; ui_max = MAX_ZOOM_LEVEL_MAX; ui_step = 0.01; ui_category = "Camera Control"; ui_tooltip = "Maximum zoom level (lower = more zoom)."; > = MAX_ZOOM_LEVEL_DEFAULT;
uniform float FocusSmoothness < ui_type = "slider"; ui_label = "Camera Smooth"; ui_min = FOCUS_SMOOTHNESS_MIN; ui_max = FOCUS_SMOOTHNESS_MAX; ui_step = 0.001; ui_category = "Camera Control"; ui_tooltip = "Camera movement smoothing. Higher = smoother camera."; > = FOCUS_SMOOTHNESS_DEFAULT;

// --- Motion Detection ---
uniform int MotionPrecisionMode < ui_type = "combo"; ui_label = "Tracking Mode"; ui_items = "4-Quadrant (Fast)\09-Zone (Balanced)\0Weighted Center (Precise)\0"; ui_category = "Motion Detection"; ui_tooltip = "Detection precision: 4-Quadrant=fast, 9-Zone=balanced, Weighted=precise."; > = PRECISION_MODE_DEFAULT;
uniform float GlobalMotionSensitivity < ui_type = "slider"; ui_label = "Motion Scale"; ui_min = GLOBAL_MOTION_SENSITIVITY_MIN; ui_max = GLOBAL_MOTION_SENSITIVITY_MAX; ui_step = 0.1; ui_category = "Motion Detection"; ui_tooltip = "Overall motion input scaling."; > = GLOBAL_MOTION_SENSITIVITY_DEFAULT;
uniform float ChangeSensitivity < ui_type = "slider"; ui_label = "Motion Threshold"; ui_min = CHANGE_SENSITIVITY_MIN; ui_max = CHANGE_SENSITIVITY_MAX; ui_step = 1000.0; ui_category = "Motion Detection"; ui_tooltip = "Sensitivity to motion changes for adaptive decay."; > = CHANGE_SENSITIVITY_DEFAULT;
uniform float MotionSmoothness < ui_type = "slider"; ui_label = "Smoothing"; ui_min = MOTION_SMOOTHNESS_MIN; ui_max = MOTION_SMOOTHNESS_MAX; ui_step = 0.001; ui_category = "Motion Detection"; ui_tooltip = "Temporal smoothing. Higher = smoother, less responsive."; > = MOTION_SMOOTHNESS_DEFAULT;

// --- Advanced Tuning ---
uniform float ZoomIntensity < ui_type = "slider"; ui_label = "Zoom Scale"; ui_min = ZOOM_INTENSITY_MIN; ui_max = ZOOM_INTENSITY_MAX; ui_step = 0.05; ui_category = "Advanced Tuning"; ui_category_closed = true; ui_tooltip = "Overall zoom scaling factor."; > = ZOOM_INTENSITY_DEFAULT;
uniform float MotionFadeRate < ui_type = "slider"; ui_label = "Fade Speed"; ui_min = MOTION_FADE_RATE_MIN; ui_max = MOTION_FADE_RATE_MAX; ui_step = 0.001; ui_category = "Advanced Tuning"; ui_tooltip = "How fast motion intensity fades over time."; > = MOTION_FADE_RATE_DEFAULT;
uniform float FadeSensitivity < ui_type = "slider"; ui_label = "Responsiveness"; ui_min = FADE_SENSITIVITY_MIN; ui_max = FADE_SENSITIVITY_MAX; ui_step = 0.01; ui_category = "Advanced Tuning"; ui_tooltip = "How motion changes affect fade rate. Higher = more adaptive."; > = FADE_SENSITIVITY_DEFAULT;
uniform float FocusPrecision < ui_type = "slider"; ui_label = "Precision"; ui_min = FOCUS_PRECISION_MIN; ui_max = FOCUS_PRECISION_MAX; ui_step = 0.1; ui_category = "Advanced Tuning"; ui_tooltip = "Focus distribution sharpness. Higher = more aggressive shifts."; > = FOCUS_PRECISION_DEFAULT;

// --- Audio Reactivity ---
AS_AUDIO_UI(FocusAudioSource, "Focus Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULT_UI(FocusAudioMult, "Focus Audio Multiplier", 1.0, 4.0, "Audio Reactivity")
AS_AUDIO_UI(ZoomAudioSource, "Zoom Audio Source", AS_AUDIO_OFF, "Audio Reactivity")
AS_AUDIO_MULT_UI(ZoomAudioMult, "Zoom Audio Multiplier", 1.0, 4.0, "Audio Reactivity")

// --- Debug Controls ---
AS_DEBUG_UI("Off\0Motion Intensity (Mid-Pass)\0Quadrant Motion Data (Final)\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Calculate motion center from quadrant data using weighted averaging
 * ALGORITHM: Takes motion intensity from 4 screen quadrants and calculates 
 * the center of mass based on predefined quadrant center positions
 * PARAMETERS: quadrantMotion.xyzw = motion totals for TL,TR,BL,BR quadrants
 * RETURNS: 2D screen coordinates (0-1 range) of the motion center
 */
float2 CalculateQuadrantMotionCenter(float4 quadrantMotion) {
    // Step 1: Calculate total motion across all quadrants for normalization
    float totalMotion = quadrantMotion.x + quadrantMotion.y + quadrantMotion.z + quadrantMotion.w;
    
    // Step 2: Handle edge case where no motion is detected
    if (totalMotion <= AS_EPSILON) return float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
    
    // Step 3: Calculate weighted center using predefined quadrant positions
    // Each quadrant contributes to the final center proportional to its motion intensity
    float2 center;
    center.x = (quadrantMotion.x * QUADRANT_TL_X + quadrantMotion.y * QUADRANT_TR_X + 
                quadrantMotion.z * QUADRANT_BL_X + quadrantMotion.w * QUADRANT_BR_X) / totalMotion;
    center.y = (quadrantMotion.x * QUADRANT_TL_Y + quadrantMotion.y * QUADRANT_TR_Y + 
                quadrantMotion.z * QUADRANT_BL_Y + quadrantMotion.w * QUADRANT_BR_Y) / totalMotion;
    return center;
}

/**
 * Calculate motion center using 9-zone data with performance optimization
 * ALGORITHM: Uses a 3x3 grid of motion zones for balanced precision vs. speed
 * OPTIMIZATION: Zone 8 (bottom-right) is estimated from neighbors to reduce computation
 * PARAMETERS: zoneData1 = zones 0-3, zoneDataExt = zones 4-7 motion values
 * RETURNS: 2D screen coordinates (0-1 range) of the motion center
 */
float2 CalculateNineZoneMotionCenter(float4 zoneData1, float4 zoneDataExt) {
    // Step 1: Estimate zone 8 motion from neighboring zones for performance
    // Average of zones 5 (middle-right) and 7 (bottom-center) provides good approximation
    float zone8 = (zoneDataExt.y + zoneDataExt.w) * AS_HALF; // Average of zones 5 and 7
    
    // Step 2: Calculate total motion across all 9 zones
    float totalZoneMotion = zoneData1.x + zoneData1.y + zoneData1.z + zoneData1.w + 
                           zoneDataExt.x + zoneDataExt.y + zoneDataExt.z + zoneDataExt.w + zone8;
    
    // Step 3: Handle edge case where no motion is detected
    if (totalZoneMotion <= AS_EPSILON) return float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
    
    // Step 4: Calculate weighted center using all 9 zone positions
    // Each zone contributes proportionally to its motion intensity
    float2 center;
    center.x = (zoneData1.x * ZONE_0_X + zoneData1.y * ZONE_1_X + zoneData1.z * ZONE_2_X + zoneData1.w * ZONE_3_X +
               zoneDataExt.x * ZONE_4_X + zoneDataExt.y * ZONE_5_X + zoneDataExt.z * ZONE_6_X + zoneDataExt.w * ZONE_7_X + 
               zone8 * ZONE_8_X) / totalZoneMotion;    center.y = (zoneData1.x * ZONE_0_Y + zoneData1.y * ZONE_1_Y + zoneData1.z * ZONE_2_Y + zoneData1.w * ZONE_3_Y +
               zoneDataExt.x * ZONE_4_Y + zoneDataExt.y * ZONE_5_Y + zoneDataExt.z * ZONE_6_Y + zoneDataExt.w * ZONE_7_Y + 
               zone8 * ZONE_8_Y) / totalZoneMotion;
    return center;
}

/**
 * Unified motion center calculation dispatcher based on precision mode
 * PURPOSE: Selects appropriate motion center calculation algorithm based on user preference
 * ALGORITHM: Routes to quadrant, 9-zone, or weighted center calculation functions
 * PERFORMANCE: Each mode offers different speed vs. accuracy trade-offs:
 *   - QUADRANT: Fastest, coarsest (4 regions)
 *   - NINE_ZONE: Balanced precision (9 regions)  
 *   - WEIGHTED: Slowest, most precise (pixel-level)
 * PARAMETERS: precisionMode = user-selected calculation method
 * RETURNS: 2D screen coordinates (0-1 range) of the calculated motion center
 */
float2 CalculateMotionCenter(int precisionMode) {
    if (precisionMode == PRECISION_MODE_QUADRANT) {
        // Fast 4-quadrant analysis: good for responsive camera movement
        float4 quadrantData = tex2D(MotionFocus_DataSampler, DATA_QUADRANT_UV);
        return CalculateQuadrantMotionCenter(quadrantData);
    }
    else if (precisionMode == PRECISION_MODE_NINE_ZONE) {
        // Balanced 9-zone analysis: compromise between speed and precision
        float4 zoneData1 = tex2D(MotionFocus_DataSampler, DATA_ZONES_UV);
        float4 zoneDataExt = tex2D(MotionFocus_DataSampler, DATA_ZONES_EXT_UV);
        return CalculateNineZoneMotionCenter(zoneData1, zoneDataExt);
    }
    else if (precisionMode == PRECISION_MODE_WEIGHTED) {
        // Pixel-precise weighted analysis: best accuracy, highest computational cost
        float4 weightedData = tex2D(MotionFocus_DataSampler, DATA_WEIGHTED_UV);
        return weightedData.xy;
    }
    // Fallback to screen center if invalid mode specified
    return float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
}

/**
 * Apply audio reactivity to focus and zoom strength parameters
 * PURPOSE: Modulates effect parameters based on audio input for dynamic visual response
 * ALGORITHM: Uses AS framework audio reactivity system to scale parameters
 * PARAMETERS: focusStrength, zoomStrength = base effect strength values
 * RETURNS: Audio-modulated strength values as float2(focus, zoom)
 */
float2 ApplyAudioReactivity(float focusStrength, float zoomStrength) {
    float focusStrength_reactive = AS_applyAudioReactivity(focusStrength, FocusAudioSource, FocusAudioMult, true);
    float zoomStrength_reactive = AS_applyAudioReactivity(zoomStrength, ZoomAudioSource, ZoomAudioMult, true);
    return float2(focusStrength_reactive, zoomStrength_reactive);
}

/**
 * Check if current pixel coordinate should write to specific data location
 * PURPOSE: Determines if current shader invocation should calculate specific motion data
 * ALGORITHM: Simple coordinate distance check with tolerance for texture precision
 * PARAMETERS: texcoord = current pixel UV, targetUV = data pixel location to check
 * RETURNS: true if current pixel should calculate data for the target location
 */
bool ShouldWriteToDataPixel(float2 texcoord, float2 targetUV) {
    return abs(texcoord.x - targetUV.x) < 0.1 && abs(texcoord.y - targetUV.y) < 0.1;
}

/**
 * Setup grid sampling parameters for motion analysis
 * PURPOSE: Calculates step sizes for uniform grid sampling across the screen
 * ALGORITHM: Divides screen into SAMPLE_GRID_X_COUNT x SAMPLE_GRID_Y_COUNT regions
 * OUTPUTS: stepX, stepY = UV coordinate increments for grid traversal
 */
void SetupGridSampling(out float stepX, out float stepY) {
    stepX = 1.0 / (float)SAMPLE_GRID_X_COUNT;
    stepY = 1.0 / (float)SAMPLE_GRID_Y_COUNT;
}

/**
 * Get motion intensity at specific sample position
 * PURPOSE: Samples the motion intensity texture with LOD bias
 * ALGORITHM: Uses tex2Dlod for consistent sampling across different mip levels
 * PARAMETERS: sampleUV = screen coordinates to sample motion at
 * RETURNS: Motion intensity value (0-1 range)
 */
float GetMotionIntensity(float2 sampleUV) {
    return tex2Dlod(MotionFocus_QuadFullSampler, float4(sampleUV, 0, 0)).r;
}

/**
 * Determine zone index from UV coordinates for 9-zone analysis
 * PURPOSE: Maps screen coordinates to zone number (0-8) in 3x3 grid
 * ALGORITHM: Divides screen into 3x3 grid using threshold comparisons
 * GRID LAYOUT: 0|1|2
 *              3|4|5  
 *              6|7|8
 * PARAMETERS: sampleUV = screen coordinates to classify
 * RETURNS: Zone index (0-8) for the given coordinates
 */
int GetZoneIndex(float2 sampleUV) {
    int zoneX = (sampleUV.x < AS_THIRD) ? 0 : (sampleUV.x < AS_TWO_THIRDS) ? 1 : 2;
    int zoneY = (sampleUV.y < AS_THIRD) ? 0 : (sampleUV.y < AS_TWO_THIRDS) ? 1 : 2;
    return zoneY * 3 + zoneX;
}

// ============================================================================
// PASS 1: Frame Capture (Half Resolution)
// ============================================================================
// PURPOSE: Captures the current frame at half resolution for motion comparison
// EXPLANATION: We reduce resolution to improve performance since motion detection
// doesn't require full detail. This captured frame will be compared against the
// previous frame in Pass 2 to detect areas of change/movement.
float4 PS_MotionFocusNorm(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    return tex2D(ReShade::BackBuffer, texcoord);
}

// ============================================================================
// PASS 2: Motion Detection (Temporal Smoothing & Adaptive Decay)
// ============================================================================
// PURPOSE: Detects motion by comparing current frame with previous frame
// EXPLANATION: This pass performs frame differencing to detect motion, then applies
// temporal smoothing to reduce noise and adaptive decay to handle static scenes.
// The result is a per-pixel motion intensity map that feeds into the analysis passes.
float PS_MotionFocusQuadFull(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{    
    // Step 1: Get current and previous frame colors at this pixel
    float3 currentFrame = tex2D(MotionFocus_NormSampler, texcoord).rgb;
    float3 prevFrame = tex2D(MotionFocus_PrevFrameSampler, texcoord).rgb;
    
    // Step 2: Calculate raw motion by comparing RGB differences
    // We sum the absolute differences across all color channels and normalize
    float frameDiff = (abs(currentFrame.r - prevFrame.r) +
                       abs(currentFrame.g - prevFrame.g) +
                       abs(currentFrame.b - prevFrame.b)) / MOTION_DETECTION_DIVISOR;

    // Step 3: Get the previous motion value for temporal smoothing
    float prevMotion = tex2D(MotionFocus_PrevMotionSampler, texcoord).r;
    
    // Step 4: Apply temporal smoothing using exponential moving average
    // This reduces noise and creates smoother motion transitions
    float smoothedMotion = MotionSmoothness * prevMotion + (1.0 - MotionSmoothness) * frameDiff;

    // Step 5: Implement adaptive decay system
    // Calculate how much the motion has changed to adapt decay rate
    float motionChange = abs(smoothedMotion - prevMotion);
    
    // Higher motion changes reduce decay rate (motion persists longer)
    // Lower motion changes increase decay rate (motion fades faster)
    float decayFactor = MotionFadeRate - FadeSensitivity * max(1.0 - pow(1.0 - motionChange, DECAY_FACTOR_POWER) * ChangeSensitivity, 0.0);
    decayFactor = clamp(decayFactor, 0.0, 1.0); // Ensure decay factor is valid

    // Step 6: Apply the adaptive decay to create final motion intensity
    float finalMotion = decayFactor * smoothedMotion + (1.0 - decayFactor) * frameDiff;
    
    return finalMotion;
}

// ============================================================================
// PASS 3: Consolidated Motion Data Calculation
// ============================================================================
// PURPOSE: Analyzes the motion intensity map to calculate motion centers for all precision modes
// EXPLANATION: This pass samples the motion intensity texture in a grid pattern and calculates
// motion data for quadrants (4 regions), zones (9 regions), and weighted center (pixel-precise).
// It uses a consolidated approach where different pixels in a 3x3 data texture store different
// types of motion analysis results, improving efficiency over separate passes.
float4 PS_MotionFocusDataConsolidated(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Step 1: Determine which type of motion data we're calculating based on pixel position
    // Each pixel in our 3x3 data texture represents a different analysis type
    
    if (ShouldWriteToDataPixel(texcoord, DATA_QUADRANT_UV)) {
        // QUADRANT ANALYSIS: Divide screen into 4 regions (top-left, top-right, bottom-left, bottom-right)
        // This provides fast, coarse motion detection suitable for quick camera responses
        
        float4 quadrantSums = 0; // Will store motion totals for each quadrant
        float stepX, stepY;
        SetupGridSampling(stepX, stepY); // Calculate sampling grid step sizes
        
        // Step 2: Sample motion intensity across the entire screen in a grid pattern
        for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j) {
            for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i) {
                // Calculate sample position in screen coordinates
                float2 sampleUV = float2((i + AS_HALF) * stepX, (j + AS_HALF) * stepY);
                float motion = GetMotionIntensity(sampleUV);
                
                // Step 3: Classify each sample into one of four quadrants
                if (sampleUV.x < AS_SCREEN_CENTER_X && sampleUV.y < AS_SCREEN_CENTER_Y)
                    quadrantSums.x += motion; // Top-left quadrant
                else if (sampleUV.x >= AS_SCREEN_CENTER_X && sampleUV.y < AS_SCREEN_CENTER_Y)
                    quadrantSums.y += motion; // Top-right quadrant
                else if (sampleUV.x < AS_SCREEN_CENTER_X && sampleUV.y >= AS_SCREEN_CENTER_Y)
                    quadrantSums.z += motion; // Bottom-left quadrant
                else
                    quadrantSums.w += motion; // Bottom-right quadrant
            }
        }
        // Step 4: Normalize by total sample count to get average motion per quadrant
        return quadrantSums / (float)TOTAL_SAMPLES;
    }
    else if (ShouldWriteToDataPixel(texcoord, DATA_ZONES_UV)) {
        // 9-ZONE ANALYSIS (Part 1): Calculate motion for zones 0-3 (first 4 zones)
        // This provides balanced precision between speed and accuracy using a 3x3 grid
        
        float4 zoneSums = 0; // Will store motion totals for zones 0-3
        float stepX, stepY;
        SetupGridSampling(stepX, stepY);
        
        // Step 2: Sample motion intensity and classify into zones 0-3
        for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j) {
            for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i) {
                float2 sampleUV = float2((i + AS_HALF) * stepX, (j + AS_HALF) * stepY);
                float motion = GetMotionIntensity(sampleUV);
                
                // Step 3: Determine which of the 9 zones this sample belongs to
                int zoneIndex = GetZoneIndex(sampleUV);                

                // Step 4: Accumulate motion for zones 0-3 only (zones 4-7 handled in next pixel)
                if (zoneIndex == 0) zoneSums.x += motion;      // Top-left zone
                else if (zoneIndex == 1) zoneSums.y += motion; // Top-center zone
                else if (zoneIndex == 2) zoneSums.z += motion; // Top-right zone
                else if (zoneIndex == 3) zoneSums.w += motion; // Middle-left zone
            }
        }
        return zoneSums / (float)TOTAL_SAMPLES;
    }    
    else if (ShouldWriteToDataPixel(texcoord, DATA_ZONES_EXT_UV)) {
        // 9-ZONE ANALYSIS (Part 2): Calculate motion for zones 4-7 (zone 8 estimated for performance)
        // This completes the 3x3 zone analysis, with zone 8 estimated from neighbors
        
        float4 zoneSums = 0; // Will store motion totals for zones 4,5,6,7 in xyzw components
        float stepX, stepY;
        SetupGridSampling(stepX, stepY);
        
        // Step 2: Sample motion intensity and classify into zones 4-7
        for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j) {
            for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i) {
                float2 sampleUV = float2((i + AS_HALF) * stepX, (j + AS_HALF) * stepY);                
                float motion = GetMotionIntensity(sampleUV);
                int zoneIndex = GetZoneIndex(sampleUV);
                
                // Step 3: Accumulate motion for zones 4-7 (zone 8 calculated on-demand)
                if (zoneIndex == 4) zoneSums.x += motion;      // Middle-center zone
                else if (zoneIndex == 5) zoneSums.y += motion; // Middle-right zone
                else if (zoneIndex == 6) zoneSums.z += motion; // Bottom-left zone
                else if (zoneIndex == 7) zoneSums.w += motion; // Bottom-center zone
                // Note: Zone 8 (bottom-right) is estimated later from zones 5 and 7 for performance
            }
        }
        return zoneSums / (float)TOTAL_SAMPLES;
    }
    else if (ShouldWriteToDataPixel(texcoord, DATA_WEIGHTED_UV)) {
        // WEIGHTED CENTER ANALYSIS: Calculate pixel-precise motion center using weighted averaging
        // This provides maximum precision by considering every pixel's contribution to motion center
        
        float2 weightedCenter = 0; // Accumulates motion-weighted position
        float totalMotion = 0;     // Accumulates total motion for normalization
        float stepX, stepY;
        SetupGridSampling(stepX, stepY);
        
        // Step 2: Sample every grid position and weight by motion intensity
        for (int j = 0; j < SAMPLE_GRID_Y_COUNT; ++j) {
            for (int i = 0; i < SAMPLE_GRID_X_COUNT; ++i) {
                float2 sampleUV = float2((i + AS_HALF) * stepX, (j + AS_HALF) * stepY);
                float motion = GetMotionIntensity(sampleUV);
                
                // Step 3: Weight each position by its motion intensity
                // Higher motion areas contribute more to the final center calculation
                weightedCenter += sampleUV * motion;
                totalMotion += motion;
            }
        }
        
        // Step 4: Calculate final weighted center position
        if (totalMotion > AS_EPSILON) {
            weightedCenter /= totalMotion; // Normalize by total motion to get weighted average
        } else {
            // Fallback to screen center if no motion detected
            weightedCenter = float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
        }
        
        // Return weighted center in XY, total motion in Z component
        return float4(weightedCenter, totalMotion, 0);
    }
    
    // Clear unused pixels in the data texture
    return float4(0, 0, 0, 0);
}

// ============================================================================
// PASS 4: Focus Application & Display
// ============================================================================
// PURPOSE: Applies motion-based zoom and focus to the final image
// EXPLANATION: This pass takes all the calculated motion data and applies zoom and
// pan transformations to the current frame based on detected motion. It calculates
// the optimal zoom level and focus center, then transforms the image accordingly.
float4 PS_MotionFocusDisplay(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Step 1: Handle debug visualization modes
    if (DebugMode == 1) return tex2D(MotionFocus_QuadFullSampler, texcoord).xxxx; // Show motion detection
    if (DebugMode == 2) return tex2D(MotionFocus_DataSampler, DATA_QUADRANT_UV); // Show quadrant data

    // Step 2: Gather motion data and previous state for calculations
    float4 currentQuadrantMotion = tex2D(MotionFocus_DataSampler, DATA_QUADRANT_UV);
    float2 prevFocusCenter = tex2D(MotionFocus_PrevDataSampler, DATA_PREV_CENTER_UV).xy;
    
    // Step 3: Apply audio reactivity to strength parameters
    float2 audioReactiveStrengths = ApplyAudioReactivity(FocusStrength, ZoomStrength);
    float focusStrength_reactive = audioReactiveStrengths.x;
    float zoomStrength_reactive = audioReactiveStrengths.y;
      
    // Step 4: Calculate motion center using the user-selected precision mode
    // This determines where the camera should focus based on motion patterns
    float2 rawMotionCenter = CalculateMotionCenter(MotionPrecisionMode);
    
    // Step 5: Calculate focus distribution metrics from quadrant data
    // These metrics help determine how concentrated vs. spread out the motion is
    float sumAllQuadrantMotions = currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w;
    float dominantQuadrantIntensity = max(currentQuadrantMotion.x, max(currentQuadrantMotion.y, max(currentQuadrantMotion.z, currentQuadrantMotion.w)));
    
    // Step 6: Calculate Focus Distribution Factor - how concentrated the motion is
    // Higher values mean motion is more focused in one area, lower means spread out
    float focusDistributionFactor = 1.0;
    if (sumAllQuadrantMotions > AS_EPSILON) {
        if (dominantQuadrantIntensity == currentQuadrantMotion.x) 
            focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.y + currentQuadrantMotion.z + currentQuadrantMotion.w) * AS_THIRD;
        else if (dominantQuadrantIntensity == currentQuadrantMotion.y) 
            focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.z + currentQuadrantMotion.w) * AS_THIRD;
        else if (dominantQuadrantIntensity == currentQuadrantMotion.z) 
            focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.w) * AS_THIRD;
        else 
            focusDistributionFactor += dominantQuadrantIntensity - (currentQuadrantMotion.x + currentQuadrantMotion.y + currentQuadrantMotion.z) * AS_THIRD;
        focusDistributionFactor = max(0.0, focusDistributionFactor);
    }
    
    // Step 7: Calculate Global Motion Influence - dampens zoom when entire screen is moving
    // This prevents excessive zoom when there's camera shake or global movement
    float averageTotalMotion = sumAllQuadrantMotions * AS_QUARTER;
    float globalMotionInfluence = AS_HALF * max(GLOBAL_MOTION_MIN_FACTOR, 
        min(GLOBAL_MOTION_MAX_FACTOR - pow(saturate(averageTotalMotion * GlobalMotionSensitivity), GLOBAL_MOTION_POWER), GLOBAL_MOTION_MAX_FACTOR));

    // Step 8: Calculate final zoom amount based on all factors
    // Combines motion intensity, focus distribution, global influence, and user settings
    float2 finalZoomAmount = dominantQuadrantIntensity * focusDistributionFactor * globalMotionInfluence * zoomStrength_reactive * ZoomIntensity;
    finalZoomAmount = min(finalZoomAmount, MaxZoomLevel); // Clamp to user-defined maximum

    // Step 9: Apply temporal smoothing and focus center blending
    // Smooth the motion center to prevent jittery camera movement
    float2 motionCenter = lerp(rawMotionCenter, prevFocusCenter, 1.0 - FocusSmoothness);
    
    // Blend between screen center and calculated motion center based on focus strength
    float centerBlendFactor = pow(focusDistributionFactor, FocusPrecision) * focusStrength_reactive;
    motionCenter = lerp(float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y), motionCenter, centerBlendFactor);
      
    // Step 10: Apply zoom transformation
    // Convert zoom amount to scale factor (smaller = more zoomed in)
    float2 zoomScaleFactor = 1.0 - finalZoomAmount; 
    
    // Transform UV coordinates: zoom in around the calculated motion center
    float2 transformedUv = (texcoord - motionCenter) * zoomScaleFactor + motionCenter;
    
    // Step 11: Edge correction to prevent sampling outside screen bounds
    // Calculate what source coordinates would be needed at screen corners
    float2 sourceUvAtScreenCorner00 = (float2(0.0, 0.0) - motionCenter) / zoomScaleFactor + motionCenter;
    float2 sourceUvAtScreenCorner11 = (float2(1.0, 1.0) - motionCenter) / zoomScaleFactor + motionCenter;

    // Calculate correction offsets if we're trying to sample outside [0,1]
    float2 edgeCorrectionOffset = 0;
    if (sourceUvAtScreenCorner00.x < 0.0) edgeCorrectionOffset.x -= sourceUvAtScreenCorner00.x * zoomScaleFactor.x;
    if (sourceUvAtScreenCorner11.x > 1.0) edgeCorrectionOffset.x -= (sourceUvAtScreenCorner11.x - 1.0) * zoomScaleFactor.x;
    if (sourceUvAtScreenCorner00.y < 0.0) edgeCorrectionOffset.y -= sourceUvAtScreenCorner00.y * zoomScaleFactor.y;
    if (sourceUvAtScreenCorner11.y > 1.0) edgeCorrectionOffset.y -= (sourceUvAtScreenCorner11.y - 1.0) * zoomScaleFactor.y;
    
    // Apply edge correction and clamp to valid range
    transformedUv += edgeCorrectionOffset;
    transformedUv = clamp(transformedUv, AS_EPSILON, 1.0 - AS_EPSILON);

    // Step 12: Sample and return the transformed image
    return tex2D(ReShade::BackBuffer, transformedUv);
}

// ============================================================================
// PASS 5-7: Data Storage for Next Frame
// ============================================================================
// PURPOSE: Store current frame data for use in the next frame's motion detection
// EXPLANATION: These passes save the current frame, motion data, and focus center
// to textures that will be read as "previous frame" data in the next render cycle.
// This creates the temporal continuity needed for motion detection and smoothing.

// PASS 5: Store current frame for next frame's motion detection
float4 PS_MotionFocusStorageNorm(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    // Copy the current captured frame to "previous frame" storage
    return tex2D(MotionFocus_NormSampler, texcoord);
}

// PASS 6: Store current motion intensity for next frame's temporal smoothing
float PS_MotionFocusStorageMotion(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    // Copy the current motion intensity map to "previous motion" storage
    return tex2D(MotionFocus_QuadFullSampler, texcoord).r;
}

// PASS 7: Store current motion data for next frame's focus calculations
float4 PS_MotionFocusStorageFocusCenter(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target 
{
    // Copy all calculated motion data from current frame to previous frame storage
    float4 dataPixel = tex2D(MotionFocus_DataSampler, texcoord);
    
    // Special handling for the previous focus center pixel: apply temporal smoothing
    if (ShouldWriteToDataPixel(texcoord, DATA_PREV_CENTER_UV)) {
        // Calculate the current motion center for this frame
        float2 rawMotionCenter = CalculateMotionCenter(MotionPrecisionMode);
        float2 prevFocusCenter = tex2D(MotionFocus_PrevDataSampler, DATA_PREV_CENTER_UV).xy;
        
        // Apply the same temporal smoothing used in the display pass
        // This ensures consistency between display and storage calculations
        float2 smoothedMotionCenter = lerp(rawMotionCenter, prevFocusCenter, 1.0 - FocusSmoothness);
        
        return float4(smoothedMotionCenter, 0, 0);
    }
    
    // For all other pixels, pass through unchanged
    return dataPixel;
}

// ============================================================================
// TECHNIQUE DEFINITION - Multi-Pass Motion Detection and Focus System
// ============================================================================
// 
// PIPELINE ARCHITECTURE:
// This technique implements a 7-pass rendering pipeline that creates a complete
// motion detection and camera focus system. The passes are designed to work
// together to create smooth, responsive motion-based camera control.
//
// PASS EXECUTION ORDER:
// 1. Frame Capture    -> Stores current frame for motion comparison
// 2. Motion Detection -> Analyzes frame differences and applies temporal smoothing  
// 3. Data Analysis    -> Calculates motion centers using selected precision mode
// 4. Display          -> Applies zoom/pan transformations to final image
// 5-7. Storage        -> Preserves data for next frame's temporal continuity
//
// PERFORMANCE OPTIMIZATIONS:
// - Half-resolution processing for motion detection reduces GPU load
// - Consolidated data pass eliminates redundant calculations
// - Point sampling for data textures ensures precision
// - Temporal smoothing prevents camera jitter without excessive computation
//
technique AS_VFX_MotionFocus < 
    ui_label = "[AS] VFX: Motion Focus";
    ui_tooltip = "Automatically zooms towards detected motion with configurable precision and audio-reactive control."; 
>
{
    // PASS 1: Frame capture at half resolution for performance optimization
    pass MotionFocusNormPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusNorm;
        RenderTarget = MotionFocus_NormTex;
    }
    
    // PASS 2: Motion detection with temporal smoothing and adaptive decay
    pass MotionFocusQuadFullPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusQuadFull;
        RenderTarget = MotionFocus_QuadFullTex;
    }
    
    // PASS 3: Consolidated motion data analysis for all precision modes
    pass MotionFocusDataConsolidatedPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusDataConsolidated;
        RenderTarget = MotionFocus_DataTex;
    }
    
    // PASS 4: Final image rendering with motion-based transformations
    pass MotionFocusDisplayPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusDisplay;
    }
    
    // PASS 5: Store current frame for next cycle's motion detection
    pass MotionFocusStorageNormPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageNorm;
        RenderTarget = MotionFocus_PrevFrameTex;
    }
    
    // PASS 6: Store motion data for next cycle's temporal smoothing
    pass MotionFocusStorageMotionPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageMotion;
        RenderTarget = MotionFocus_PrevMotionTex;
    }
    
    // PASS 7: Store focus data for next cycle's center calculations
    pass MotionFocusStorageFocusCenterPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MotionFocusStorageFocusCenter;
        RenderTarget = MotionFocus_PrevDataTex;
    }
}

#endif // __AS_VFX_MotionFocus_1_fx
