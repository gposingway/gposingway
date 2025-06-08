/**
 * AS_GFX_MultiLayerHalftone.1.fx - Flexible multi-layer halftone effect shader
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a highly customizable multi-layer halftone effect with support for up to four 
 * independent layers. Each layer can use different pattern types, isolation methods, 
 * colors, and thresholds.
 *
 * FEATURES:
 * - Four independently configurable halftone layers
 * - Multiple pattern types (dots, lines, crosshatch)
 * - Various isolation methods (brightness, RGB, hue, depth)
 * - Customizable colors, densities, scales, and angles
 * - Layer blending with transparency support
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Each layer isolates pixel regions based on brightness, RGB intensity, hue, or depth
 * 2. Procedural pattern generation creates dots, lines, or crosshatch effects
 * 3. Pattern colors are applied to the isolated regions
 * 4. Layers are blended sequentially based on their background transparency
 * 
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_MultiLayerHalftone_1_fx
#define __AS_GFX_MultiLayerHalftone_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// HELPER MACROS & CONSTANTS
// ============================================================================

#define PATTERN_DOT_ROUND  0
#define PATTERN_DOT_SQUARE 1
#define PATTERN_LINE       2
#define PATTERN_CROSSHATCH 3

#define ISOLATE_BRIGHTNESS 0
#define ISOLATE_RGB        1
#define ISOLATE_HUE        2
#define ISOLATE_DEPTH      3

// Number of halftone layers
#define HALFTONE_LAYER_COUNT 4

// ============================================================================
// LAYER UI MACRO
// ============================================================================

// Define a macro for the UI controls of each layer to avoid repetition
#define HALFTONE_LAYER_UI(index, defaultEnable, defaultIsolation, defaultMinThreshold, defaultMaxThreshold, defaultPattern, defaultScale, defaultDensity, defaultAngle, defaultPatternColor, defaultBgColor) \
uniform bool Layer##index##_Enable < ui_label = "Enable Layer " #index; ui_tooltip = "Toggle this entire halftone layer on or off."; ui_category = "Layer " #index " Settings"; ui_category_closed = index > 1; > = defaultEnable; \
uniform int Layer##index##_IsolationMethod < ui_type = "combo"; ui_label = "Isolation Method"; ui_tooltip = "Choose metric to isolate pixels (Brightness, RGB intensity, Hue, or Depth)."; ui_items = "Brightness\0Composite RGB\0Hue\0Depth\0"; ui_category = "Layer " #index " Settings"; > = defaultIsolation; \
uniform float Layer##index##_ThresholdMin < ui_type = "slider"; ui_min = AS_RANGE_ZERO_ONE_MIN * 100.0; ui_max = AS_RANGE_ZERO_ONE_MAX * 100.0; ui_step = 1.0; ui_label = "Range Min (1-100)"; ui_tooltip = "Start of selection range (1-100). Mapped to 0-1 or 0-360 based on Method. Swapped internally with Min if needed."; ui_category = "Layer " #index " Settings"; > = defaultMinThreshold; \
uniform float Layer##index##_ThresholdMax < ui_type = "slider"; ui_min = AS_RANGE_ZERO_ONE_MIN * 100.0; ui_max = AS_RANGE_ZERO_ONE_MAX * 100.0; ui_step = 1.0; ui_label = "Range Max (1-100)"; ui_tooltip = "End of selection range (1-100). Mapped to 0-1 or 0-360 based on Method. Swapped internally with Max if needed."; ui_category = "Layer " #index " Settings"; > = defaultMaxThreshold; \
uniform bool Layer##index##_InvertRange < ui_label = "Invert Selection Range"; ui_tooltip = "Check to apply pattern OUTSIDE the defined Min/Max range."; ui_category = "Layer " #index " Settings"; > = false; \
uniform int Layer##index##_PatternType < ui_type = "combo"; ui_label = "Pattern Type"; ui_tooltip = "Pattern geometry to apply."; ui_items = "Round Dots\0Square Dots\0Lines\0Crosshatch\0"; ui_category = "Layer " #index " Settings"; > = defaultPattern; \
uniform float Layer##index##_PatternScale < ui_type = "slider"; ui_min = AS_RANGE_SCALE_MIN * AS_RANGE_SCALE_MAX * 0.5; ui_max = AS_RANGE_SCALE_MAX * 2.0; ui_step = 0.1; ui_label = "Pattern Scale"; ui_tooltip = "Size of pattern elements. Smaller values = more elements."; ui_category = "Layer " #index " Settings"; > = defaultScale; \
uniform float Layer##index##_PatternDensity < ui_type = "slider"; ui_min = AS_RANGE_ZERO_ONE_MIN; ui_max = AS_RANGE_ZERO_ONE_MAX; ui_step = 0.01; ui_label = "Pattern Density"; ui_tooltip = "Thickness/density of pattern elements."; ui_category = "Layer " #index " Settings"; > = defaultDensity; \
uniform float Layer##index##_PatternAngle < ui_type = "slider"; ui_min = AS_RANGE_ZERO_ONE_MIN; ui_max = AS_PI * AS_RADIANS_TO_DEGREES; ui_step = 0.5; ui_label = "Pattern Angle"; ui_tooltip = "Rotation angle of pattern (most visible with lines)."; ui_category = "Layer " #index " Settings"; > = defaultAngle; \
uniform float4 Layer##index##_PatternColor < ui_type = "color"; ui_label = "Pattern Color"; ui_tooltip = "Color to use for the pattern itself."; ui_category = "Layer " #index " Settings"; > = defaultPatternColor; \
uniform float4 Layer##index##_BackgroundColor < ui_type = "color"; ui_label = "Background Color"; ui_tooltip = "Color to use for areas between pattern elements. Alpha controls transparency."; ui_category = "Layer " #index " Settings"; > = defaultBgColor;

// ============================================================================
// LAYER CONTROLS (Using the macro)
// ============================================================================

// Layer 1 controls
HALFTONE_LAYER_UI(1, true, ISOLATE_BRIGHTNESS, 1.0, 50.0, 
                 PATTERN_DOT_ROUND, 50.0, AS_RANGE_BLEND_DEFAULT, 45.0,
                 float4(AS_RANGE_ZERO_ONE_MIN, AS_RANGE_ZERO_ONE_MIN, AS_RANGE_ZERO_ONE_MIN, AS_OP_DEFAULT), 
                 float4(AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MIN))

// Layer 2 controls                 
HALFTONE_LAYER_UI(2, false, ISOLATE_BRIGHTNESS, 50.0, 75.0, 
                 PATTERN_LINE, 60.0, AS_RANGE_BLEND_DEFAULT, AS_HALF_PI * AS_RADIANS_TO_DEGREES,
                 float4(AS_RANGE_ZERO_ONE_MIN, AS_RANGE_ZERO_ONE_MIN, AS_RANGE_ZERO_ONE_MIN, AS_OP_DEFAULT), 
                 float4(AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MIN))

// Layer 3 controls
HALFTONE_LAYER_UI(3, false, ISOLATE_HUE, 10.0, 40.0, 
                 PATTERN_CROSSHATCH, 40.0, AS_RANGE_BLEND_DEFAULT, 30.0,
                 float4(AS_RANGE_ZERO_ONE_MIN, AS_RANGE_ZERO_ONE_MIN, AS_RANGE_ZERO_ONE_MIN, AS_OP_DEFAULT), 
                 float4(AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MIN))

// Layer 4 controls
HALFTONE_LAYER_UI(4, false, ISOLATE_BRIGHTNESS, 75.0, AS_RANGE_ZERO_ONE_MAX * 100.0, 
                 PATTERN_DOT_SQUARE, 30.0, AS_RANGE_BLEND_DEFAULT, 60.0,
                 float4(AS_RANGE_ZERO_ONE_MIN, AS_RANGE_ZERO_ONE_MIN, AS_RANGE_ZERO_ONE_MIN, AS_OP_DEFAULT), 
                 float4(AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MIN))

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_UI("Off\0Layers\0Metrics\0")

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get luminance/brightness of a color
float GetLuminance(float3 color) {
    return dot(color, float3(0.299, 0.587, 0.114));
}

// Get average RGB intensity
float GetRGBIntensity(float3 color) {
    return (color.r + color.g + color.b) * AS_THIRD;
}

// Convert RGB to Hue (0-360)
float RGBtoHue(float3 color) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(color.bg, K.wz), float4(color.gb, K.xy), step(color.b, color.g));
    float4 q = lerp(float4(p.xyw, color.r), float4(color.r, p.yzx), step(p.x, color.r));
      float d = q.x - min(q.w, q.y);
    float e = AS_EPSILON; // Small epsilon to prevent division by zero
    float h = abs(q.z + (q.w - q.y) / (6.0 * d + e));
    
    // Convert to 0-360 range and handle edge cases
    h = (d < e) ? 0.0 : (h * 360.0);
    return h;
}

// Apply rotation to coordinates
float2 RotatePoint(float2 p, float angle, float2 center) {
    // Translate to origin
    float2 translated = p - center;
      // Rotate
    float s = sin(angle * AS_DEGREES_TO_RADIANS);
    float c = cos(angle * AS_DEGREES_TO_RADIANS);
    float2 rotated = float2(
        translated.x * c - translated.y * s,
        translated.x * s + translated.y * c
    );
    
    // Translate back
    return rotated + center;
}

// Get the pixel metric based on isolation method
float GetPixelMetric(float4 color, float2 texcoord, int isolationMethod) {
    if (isolationMethod == ISOLATE_BRIGHTNESS) {
        return GetLuminance(color.rgb);
    } else if (isolationMethod == ISOLATE_RGB) {
        return GetRGBIntensity(color.rgb);
    } else if (isolationMethod == ISOLATE_HUE) {
        return RGBtoHue(color.rgb);
    } else if (isolationMethod == ISOLATE_DEPTH) {
        return ReShade::GetLinearizedDepth(texcoord);
    }
    
    // Default fallback
    return GetLuminance(color.rgb);
}

// Check if a pixel is in the specified range
bool IsInRange(float pixelMetric, float mappedMin, float mappedMax, int isolationMethod) {
    if (isolationMethod == ISOLATE_HUE) {
        // Special handling for hue which is circular (0-360)
        if (mappedMin <= mappedMax) {
            return (pixelMetric >= mappedMin && pixelMetric <= mappedMax);
        } else {
            // Handle wrap-around case (e.g., 330° to 30°)
            return (pixelMetric >= mappedMin || pixelMetric <= mappedMax);
        }
    } else {
        // Standard range check for brightness, RGB, and depth
        return (pixelMetric >= mappedMin && pixelMetric <= mappedMax);
    }
}

// Generate pattern value based on pattern type and parameters
float GeneratePattern(float2 uv, int patternType, float scale, float density, float angle) {    // Scale factor (larger number = smaller pattern)
    float scaleFactor = scale * 0.01;
    
    // Screen center in normalized coordinates
    float2 screenCenter = float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
    
    // Pattern value
    float pattern = AS_RANGE_ZERO_ONE_MIN;
    
    if (patternType == PATTERN_DOT_ROUND || patternType == PATTERN_DOT_SQUARE) {        // For dot patterns, we need a completely different approach to rotation
        // First convert angle to radians
        float angleRad = angle * AS_DEGREES_TO_RADIANS;
        
        // Create rotation matrix
        float2x2 rotMatrix = float2x2(
            cos(angleRad), -sin(angleRad),
            sin(angleRad), cos(angleRad)
        );
        
        // Scale coordinates by screen size to maintain aspect ratio
        float2 scaledCoord = uv * ReShade::ScreenSize * scaleFactor;
        
        // Rotate the grid coordinates (not the dots themselves)
        float2 rotatedCoord = mul(rotMatrix, scaledCoord);
          // Get cell position and local position within cell
        float2 cell = floor(rotatedCoord);
        float2 localPos = rotatedCoord - cell - AS_HALF; // Center within cell
        
        // Generate pattern based on type
        if (patternType == PATTERN_DOT_ROUND) {            // Use distance from center for round dots
            float dist = length(localPos);
            pattern = step(dist, AS_HALF * density);
        }
        else { // PATTERN_DOT_SQUARE
            // Use max component distance for square dots
            float dist = max(abs(localPos.x), abs(localPos.y));
            pattern = step(dist, AS_HALF * density);
        }
    }
    else if (patternType == PATTERN_LINE) {
        // For lines, rotation works well with UV rotation
        float2 rotatedUV = RotatePoint(uv, angle, screenCenter);
        float2 scaledUV = rotatedUV * ReShade::ScreenSize * scaleFactor;
          // Lines pattern
        float lineValue = frac(scaledUV.y);
        pattern = step(lineValue, density * AS_HALF);
    }
    else if (patternType == PATTERN_CROSSHATCH) {
        // For crosshatch, use two rotated line patterns
        // Primary lines
        float2 rotatedUV1 = RotatePoint(uv, angle, screenCenter);
        float2 scaledUV1 = rotatedUV1 * ReShade::ScreenSize * scaleFactor;
        float lineValue1 = frac(scaledUV1.y);
        float pattern1 = step(lineValue1, density * 0.5);
          // Secondary lines (90 degrees to primary)
        float2 rotatedUV2 = RotatePoint(uv, angle + AS_HALF_PI * AS_RADIANS_TO_DEGREES, screenCenter);        float2 scaledUV2 = rotatedUV2 * ReShade::ScreenSize * scaleFactor;
        float lineValue2 = frac(scaledUV2.y);
        float pattern2 = step(lineValue2, density * AS_HALF);
        
        // Combine patterns
        pattern = max(pattern1, pattern2);
    }
    
    return pattern;
}

// Structure to hold layer parameters for easier handling
struct HalftoneLayerParams {
    bool enable;
    int isolationMethod;
    float thresholdMin;
    float thresholdMax;
    bool invertRange;
    int patternType;
    float patternScale;
    float patternDensity;
    float patternAngle;
    float4 patternColor;
    float4 backgroundColor;
};

// Helper function to get layer parameters for a given layer index
HalftoneLayerParams GetLayerParams(int layerIndex) {
    HalftoneLayerParams params;
    
    if (layerIndex == 0) {
        params.enable = Layer1_Enable;
        params.isolationMethod = Layer1_IsolationMethod;
        params.thresholdMin = Layer1_ThresholdMin;
        params.thresholdMax = Layer1_ThresholdMax;
        params.invertRange = Layer1_InvertRange;
        params.patternType = Layer1_PatternType;
        params.patternScale = Layer1_PatternScale;
        params.patternDensity = Layer1_PatternDensity;
        params.patternAngle = Layer1_PatternAngle;
        params.patternColor = Layer1_PatternColor;
        params.backgroundColor = Layer1_BackgroundColor;
    }
    else if (layerIndex == 1) {
        params.enable = Layer2_Enable;
        params.isolationMethod = Layer2_IsolationMethod;
        params.thresholdMin = Layer2_ThresholdMin;
        params.thresholdMax = Layer2_ThresholdMax;
        params.invertRange = Layer2_InvertRange;
        params.patternType = Layer2_PatternType;
        params.patternScale = Layer2_PatternScale;
        params.patternDensity = Layer2_PatternDensity;
        params.patternAngle = Layer2_PatternAngle;
        params.patternColor = Layer2_PatternColor;
        params.backgroundColor = Layer2_BackgroundColor;
    }
    else if (layerIndex == 2) {
        params.enable = Layer3_Enable;
        params.isolationMethod = Layer3_IsolationMethod;
        params.thresholdMin = Layer3_ThresholdMin;
        params.thresholdMax = Layer3_ThresholdMax;
        params.invertRange = Layer3_InvertRange;
        params.patternType = Layer3_PatternType;
        params.patternScale = Layer3_PatternScale;
        params.patternDensity = Layer3_PatternDensity;
        params.patternAngle = Layer3_PatternAngle;
        params.patternColor = Layer3_PatternColor;
        params.backgroundColor = Layer3_BackgroundColor;
    }
    else { // layerIndex == 3
        params.enable = Layer4_Enable;
        params.isolationMethod = Layer4_IsolationMethod;
        params.thresholdMin = Layer4_ThresholdMin;
        params.thresholdMax = Layer4_ThresholdMax;
        params.invertRange = Layer4_InvertRange;
        params.patternType = Layer4_PatternType;
        params.patternScale = Layer4_PatternScale;
        params.patternDensity = Layer4_PatternDensity;
        params.patternAngle = Layer4_PatternAngle;
        params.patternColor = Layer4_PatternColor;
        params.backgroundColor = Layer4_BackgroundColor;
    }
    
    return params;
}

// Process a single halftone layer
float4 ProcessLayer(float4 currentColor, float2 texcoord, HalftoneLayerParams params) {
    // Return current color if layer is disabled
    if (!params.enable) return currentColor;
    
    // Ensure proper min/max order
    float actualMin = min(params.thresholdMin, params.thresholdMax);
    float actualMax = max(params.thresholdMin, params.thresholdMax);
      // Map thresholds based on isolation method
    float mappedMin, mappedMax;
    if (params.isolationMethod == ISOLATE_HUE) {
        // Map to 0-360 range for hue
        mappedMin = actualMin * 3.6; // 3.6 = 360.0/100.0
        mappedMax = actualMax * 3.6;
    } else {
        // Map to 0-1 range for brightness, RGB, and depth
        mappedMin = actualMin * 0.01; // 0.01 = AS_RANGE_ZERO_ONE_MAX/100.0
        mappedMax = actualMax * 0.01;
    }
    
    // Calculate pixel metric based on isolation method
    float pixelMetric = GetPixelMetric(currentColor, texcoord, params.isolationMethod);
    
    // Check if pixel is in range
    bool isInRange = IsInRange(pixelMetric, mappedMin, mappedMax, params.isolationMethod);
    
    // Apply inversion if requested
    bool applyPattern = (isInRange != params.invertRange);
    
    // If we should apply the pattern to this pixel
    if (applyPattern) {
        // Generate pattern value at this pixel
        float patternValue = GeneratePattern(texcoord, params.patternType, params.patternScale, 
                                            params.patternDensity, params.patternAngle);
          // Select color based on pattern value
        float4 layerColor = (patternValue > AS_HALF) ? params.patternColor : params.backgroundColor;
        
        // Blend with current color using the layer's alpha
        return float4(
            lerp(currentColor.rgb, layerColor.rgb, layerColor.a),
            currentColor.a
        );
    }
    
    // If pattern doesn't apply, return current color unchanged
    return currentColor;
}

// ============================================================================
// MAIN SHADER FUNCTIONS
// ============================================================================

float4 PS_MultiLayerHalftone(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Sample input texture
    float4 finalColor = tex2D(ReShade::BackBuffer, texcoord);
    
    // Process each layer sequentially, using their individual enable flags
    for (int i = 0; i < HALFTONE_LAYER_COUNT; i++) {
        // Get layer parameters
        HalftoneLayerParams params = GetLayerParams(i);
        
        // Process the layer (the enable check is inside ProcessLayer)
        finalColor = ProcessLayer(finalColor, texcoord, params);
    }
    
    return finalColor;
}

// Technique definition
technique AS_MultiLayerHalftone <
    ui_label = "[AS] GFX: Multi-Layer Halftone";
    ui_tooltip = "Apply up to four customizable halftone pattern layers with various isolation methods and pattern types.";
> {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_MultiLayerHalftone;
    }
}

#endif // __AS_GFX_MultiLayerHalftone_1_fx

