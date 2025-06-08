/**
 * AS_GFX_AspectRatio.1.fx - Aspect Ratio Framing Tool
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * A versatile aspect ratio framing tool designed to help position subjects for social media posts,
 * photography, and video composition. Creates customizable aspect ratio frames with optional guides.
 * Features comprehensive composition guides for professional photography and cinematography.
 *
 * FEATURES:
 * - Preset aspect ratios for common social media, photography, and video formats
 *   - Each aspect ratio available in both landscape and portrait orientations
 *   - Platform-specific tags (FB, IG, YT, etc.) for quick identification
 * - Custom aspect ratio input option
 * - Adjustable clipped area color and opacity
 * - Advanced composition guides:
 *   - Rule of Thirds, Golden Ratio, Center Lines
 *   - Diagonal Method (Baroque and Sinister diagonals)
 *   - Harmonic Armature / Dynamic Symmetry Grid
 *   - Phi Grid (Golden Grid)
 *   - Golden Spiral with four orientation options
 *   - Triangle composition guides
 *   - Customizable grid overlays
 *   - Safe zones for video production
 * - Adjustable guide intensity, width, and rotation
 * - Horizontal/vertical alignment controls
 * - Optimized for all screen resolutions
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. User selects a preset aspect ratio or defines a custom ratio
 * 2. Shader calculates the appropriate frame dimensions based on screen resolution
 * 3. Areas outside the selected aspect ratio are filled with customizable color/opacity
 * 4. Optional composition guides are drawn to assist with subject positioning
 * 5. Advanced pattern controls allow for rotation and customization of guide elements
 * 6. Result is blended with the original image for a non-destructive guide
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_GFX_AspectRatio_1_fx
#define __AS_GFX_AspectRatio_1_fx

// Core includes
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// CONSTANTS
// ============================================================================
// Shader-specific constants
#define AS_AR_GUIDE_INTENSITY_MIN 0.1
#define AS_AR_GRID_WIDTH_MAX 20.0
#define AS_AR_ACTION_SAFE_MARGIN 0.05
#define AS_AR_TITLE_SAFE_MARGIN 0.1
#define AS_AR_SPIRAL_SCALE_FACTOR 100.0
#define AS_AR_SPIRAL_MIN_THICKNESS 0.001
#define AS_AR_INTENSITY_STRONG 0.8
#define AS_AR_INTENSITY_MEDIUM 0.7
#define AS_AR_INTENSITY_WEAK 0.6

// Grid size constants
#define AS_AR_GRID_3X3 3
#define AS_AR_GRID_4X4 4
#define AS_AR_GRID_5X5 5
#define AS_AR_GRID_6X6 6

// ============================================================================
// UI DECLARATIONS
// ============================================================================

// Aspect Ratio Selection
// ============================= Aspect Ratio Configuration =============================
uniform int AspectRatioPreset < ui_type = "combo"; ui_label = "Aspect Ratio Preset"; ui_tooltip = "Select from common aspect ratios or choose 'Custom' to define your own"; ui_category = "Aspect Ratio"; ui_items = "Custom\0"
                "Eorzea Collection\0"
                "  [EC] Standard Image (3:5 Portrait)\0"
                "  [EC] Standard Image (5:3 Landscape)\0"
                "  [EC] Layout 2 - Main Image (104:57)\0"
                "  [EC] Layout 3 - Grid Image (103:56)\0"
                "  [EC] Layout 4 - Wide Image (123:50)\0"
                "  [EC] Layout 5 - Thumbnail (85:70)\0"
                "  [EC] Layout 6 - Center Image (115:95)\0"               
                "BlueSky\0"
                "  [BS] Post Image (Square 1:1)\0"
                "  [BS] Post Image (1.91:1 Landscape)\0"
                "  [BS] Post Image (4:5 Portrait)\0" 
                "  [BS] Post Image (5:4 Landscape)\0"
                "  [BS] Profile Picture (1:1)\0"
                "  [BS] Banner Image (3:1)\0"               
                "Instagram\0"
                "  [IG] Feed Post (Square 1:1)\0"
                "  [IG] Feed Post (4:5 Portrait)\0"
                "  [IG] Feed Post (5:4 Landscape)\0"
                "  [IG] Feed Post (1.91:1 Landscape)\0"
                "  [IG] Story / Reels (9:16 Portrait)\0"
                "  [IG] Story / Reels (16:9 Landscape)\0"              
                "Facebook\0"
                "  [FB] Feed Post (1.91:1 Landscape)\0"
                "  [FB] Feed Post (4:5 Portrait)\0"
                "  [FB] Feed Post (5:4 Landscape)\0"
                "  [FB] Story (9:16 Portrait)\0"
                "  [FB] Story (16:9 Landscape)\0"
                "  [FB] Cover Photo (2.63:1 Landscape)\0"               
                "Twitter (X)\0"
                "  [TW] Single Image (16:9 Landscape)\0"
                "  [TW] Single Image (9:16 Portrait)\0"
                "  [TW] Multi-Image 2 Images (7:8 Portrait)\0"
                "  [TW] Multi-Image 2 Images (8:7 Landscape)\0"
                "  [TW] Multi-Image 4 Images (2:1 Landscape)\0"               
                "LinkedIn\0"
                "  [LI] Feed Post (1.91:1 Landscape)\0"
                "  [LI] Story (9:16 Portrait)\0"
                "  [LI] Story (16:9 Landscape)\0"               
                "Pinterest\0"
                "  [PI] Pin (2:3 Portrait)\0"
                "  [PI] Pin (3:2 Landscape)\0"
                "  [PI] Max Length Pin (1:2.1 Portrait)\0"
                "  [PI] Max Length Pin (2.1:1 Landscape)\0"               
                "TikTok / Snapchat\0"
                "  [TS] Video / Story (9:16 Portrait)\0"
                "  [TS] Video / Story (16:9 Landscape)\0"
                "YouTube\0"
                "  [YT] Thumbnail (16:9 Landscape)\0"
                "  [YT] Shorts (9:16 Portrait)\0"
                "  [YT] Community Post (1:1)\0"
                "Photography\0"
                "  [PH] 3:2 (Classic)\0"
                "  [PH] 4:3 (Standard)\0"
                "  [PH] 5:4 (Medium Format)\0"
                "  [PH] 1:1 (Square)\0"
                "Cinema\0"
                "  [CM] 16:9 (HD/4K)\0"
                "  [CM] 21:9 (Ultrawide)\0"
                "  [CM] 2.39:1 (Anamorphic)\0";
> = 3;

uniform float2 CustomAspectRatio < ui_type = "drag"; ui_label = "Custom Aspect Ratio"; ui_tooltip = "Set your own aspect ratio (X:Y)"; ui_category = "Aspect Ratio"; ui_min = AS_RANGE_SCALE_MIN; ui_max = AS_RANGE_SCALE_MAX * 2.0; ui_step = 0.01; > = float2(16.0, 9.0);

// ============================= Appearance Controls =============================
uniform float4 ClippedAreaColor < ui_type = "color"; ui_label = "Masked Area Color"; ui_tooltip = "Color for areas outside the selected aspect ratio"; ui_category = "Appearance"; > = float4(AS_RANGE_ZERO_ONE_MIN, AS_RANGE_ZERO_ONE_MIN, AS_RANGE_ZERO_ONE_MIN, AS_OP_MAX);

uniform float4 GuideColor < ui_type = "color"; ui_label = "Guide Color"; ui_tooltip = "Color for the guide lines"; ui_category = "Appearance"; > = float4(AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_HALF);

uniform float GuideIntensity < ui_type = "drag"; ui_label = "Guide Intensity"; ui_tooltip = "Adjusts the opacity of composition guides"; ui_category = "Appearance"; ui_min = AS_AR_GUIDE_INTENSITY_MIN; ui_max = AS_OP_MAX; ui_step = 0.05; > = AS_OP_DEFAULT;

uniform float GridWidth < ui_type = "drag"; ui_label = "Grid Width"; ui_tooltip = "Width of grid lines and border (in pixels)"; ui_category = "Appearance"; ui_min = AS_RANGE_SCALE_DEFAULT; ui_max = AS_AR_GRID_WIDTH_MAX; ui_step = 1.0; > = AS_RANGE_SCALE_DEFAULT;

// ============================= Composition Guides =============================
uniform int GuideType < ui_type = "combo"; ui_label = "Composition Guide"; ui_tooltip = "Optional grid overlay to help with composition"; ui_category = "Composition Guides"; ui_items = "None\0"
               "Basic Guides\0"
               "  Rule of Thirds\0"
               "  Golden Ratio\0"
               "  Center Lines\0"
               "  Phi Grid (Golden Grid)\0"
               "Dynamic Guides\0"
               "  Diagonal Method - Both\0"
               "  Diagonal Method - Baroque\0"
               "  Diagonal Method - Sinister\0"
               "  Triangle - Up\0"
               "  Triangle - Down\0"
               "  Triangle - Diagonal\0"
               "  Golden Spiral - Lower Right\0"
               "  Golden Spiral - Upper Right\0"
               "  Golden Spiral - Upper Left\0"
               "  Golden Spiral - Lower Left\0"
               "  Harmonic Armature - Basic\0"
               "  Harmonic Armature - Reciprocal\0"
               "  Harmonic Armature - Complex\0"
               "Practical Guides\0"
               "  Grid 3×3\0"
               "  Grid 4×4\0"
               "  Grid 5×5\0"
               "  Grid 6×6\0"
               "  Safe Zones\0";
> = 0;

// ============================= Advanced Guide Options =============================
uniform bool PatternAdvanced < ui_label = "Advanced Pattern Controls"; ui_tooltip = "Enable additional pattern customization"; ui_category = "Advanced Guide Options"; > = false;

uniform float PatternRotation < ui_type = "drag"; ui_label = "Pattern Rotation"; ui_tooltip = "Rotate the pattern (in degrees)"; ui_category = "Advanced Guide Options"; ui_min = AS_RANGE_ZERO_ONE_MIN; ui_max = AS_TWO_PI * AS_RADIANS_TO_DEGREES; ui_step = 0.5; > = AS_RANGE_ZERO_ONE_MIN;

uniform float PatternComplexity < ui_type = "drag"; ui_label = "Pattern Complexity"; ui_tooltip = "Adjust the complexity of certain patterns"; ui_category = "Advanced Guide Options"; ui_category_closed = true; ui_min = AS_RANGE_SCALE_DEFAULT; ui_max = AS_RANGE_SCALE_MAX * 2.0; ui_step = 0.1; > = 3.0;

// ============================= Position Controls =============================
AS_POS_UI(EffectPosition) // Standard position control

// Guide type constants (hundreds place = main type, ones place = subtype)
#define GUIDE_NONE 0
#define GUIDE_RULE_THIRDS 100
#define GUIDE_GOLDEN_RATIO 200
#define GUIDE_CENTER_LINES 300
#define GUIDE_DIAGONAL_METHOD 400
#define GUIDE_PHI_GRID 500
#define GUIDE_TRIANGLE 600
#define GUIDE_GOLDEN_SPIRAL 700
#define GUIDE_HARMONIC_ARMATURE 800
#define GUIDE_GRID 900
#define GUIDE_SAFE_ZONES 1000

// Guide subtype constants (add to main type)
#define SUBTYPE_DEFAULT 0
#define SUBTYPE_BAROQUE 1
#define SUBTYPE_SINISTER 2

// Spiral orientation constants for clarity
#define SPIRAL_LOWER_RIGHT 0
#define SPIRAL_UPPER_RIGHT 1
#define SPIRAL_UPPER_LEFT  2
#define SPIRAL_LOWER_LEFT  3

// Old constants kept for backwards compatibility
#define SUBTYPE_UPPER_LEFT 2
#define SUBTYPE_UPPER_RIGHT 1
#define SUBTYPE_LOWER_LEFT 3
#define SUBTYPE_LOWER_RIGHT 0

#define SUBTYPE_UP 0
#define SUBTYPE_DOWN 1
#define SUBTYPE_DIAGONAL 2
#define SUBTYPE_RECIPROCAL 1
#define SUBTYPE_COMPLEX 2

// Helper functions to extract type and subtype from the encoded value
int GetGuideType(int guideValue) {
    return guideValue / 100;
}

int GetGuideSubType(int guideValue) {
    return guideValue % 100;
}

// Get the guide value directly from the UI index
int GetGuideValue() {
    // Map UI indices to guide values
    switch (GuideType) {
        case 0: return GUIDE_NONE;
        case 2: return GUIDE_RULE_THIRDS;
        case 3: return GUIDE_GOLDEN_RATIO;
        case 4: return GUIDE_CENTER_LINES;
        case 5: return GUIDE_PHI_GRID;
        case 7: return GUIDE_DIAGONAL_METHOD;
        case 8: return GUIDE_DIAGONAL_METHOD + SUBTYPE_BAROQUE;
        case 9: return GUIDE_DIAGONAL_METHOD + SUBTYPE_SINISTER;
        case 10: return GUIDE_TRIANGLE + SUBTYPE_UP;
        case 11: return GUIDE_TRIANGLE + SUBTYPE_DOWN;
        case 12: return GUIDE_TRIANGLE + SUBTYPE_DIAGONAL;
        case 13: return GUIDE_GOLDEN_SPIRAL + SUBTYPE_LOWER_RIGHT;
        case 14: return GUIDE_GOLDEN_SPIRAL + SUBTYPE_UPPER_RIGHT;
        case 15: return GUIDE_GOLDEN_SPIRAL + SUBTYPE_UPPER_LEFT;
        case 16: return GUIDE_GOLDEN_SPIRAL + SUBTYPE_LOWER_LEFT;
        case 17: return GUIDE_HARMONIC_ARMATURE;
        case 18: return GUIDE_HARMONIC_ARMATURE + SUBTYPE_RECIPROCAL;
        case 19: return GUIDE_HARMONIC_ARMATURE + SUBTYPE_COMPLEX;
        case 21: return GUIDE_GRID;
        case 22: return GUIDE_GRID + 1;
        case 23: return GUIDE_GRID + 2;
        case 24: return GUIDE_GRID + 3;
        case 25: return GUIDE_SAFE_ZONES;
        default: return GUIDE_NONE; // Headers or invalid indices
    }
}

// Constants moved to the CONSTANTS section

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Get the selected aspect ratio
float GetAspectRatio() {
    if (AspectRatioPreset == 0) {
        // Custom aspect ratio
        return CustomAspectRatio.x / CustomAspectRatio.y;
    }
    
    // Map preset indices directly to aspect ratios
    switch(AspectRatioPreset) {
        // Eorzea Collection
        case 2: return 57.0/34.0;      // Standard Image (3:5 Portrait)
        case 3: return 34.0/57.0;      // Standard Image (5:3 Landscape)
        case 4: return 104.0/57.0;     // Layout 2 - Main Image
        case 5: return 103.0/56.0;     // Layout 3 - Grid Image
        case 6: return 123.0/50.0;     // Layout 4 - Wide Image
        case 7: return 85.0/70.0;      // Layout 5 - Thumbnail
        case 8: return 115.0/95.0;     // Layout 6 - Center Image
        
        // BlueSky
        case 10: return 1.0;           // Post Image (Square 1:1)
        case 11: return 1.91;          // Post Image (1.91:1 Landscape)
        case 12: return 5.0/4.0;       // Post Image (4:5 Portrait)
        case 13: return 4.0/5.0;       // Post Image (5:4 Landscape)
        case 14: return 1.0;           // Profile Picture (1:1)
        case 15: return 3.0;           // Banner Image (3:1)
        
        // Instagram
        case 17: return 1.0;           // Feed Post Square (1:1)
        case 18: return 5.0/4.0;       // Feed Post (4:5 Portrait)
        case 19: return 4.0/5.0;       // Feed Post (5:4 Landscape)
        case 20: return 1.91;          // Feed Post (1.91:1 Landscape)
        case 21: return 16.0/9.0;      // Story / Reels (9:16 Portrait)
        case 22: return 9.0/16.0;      // Story / Reels (16:9 Landscape)
        
        // Facebook
        case 24: return 1.91;          // Feed Post (1.91:1 Landscape)
        case 25: return 5.0/4.0;       // Feed Post (4:5 Portrait)
        case 26: return 4.0/5.0;       // Feed Post (5:4 Landscape)
        case 27: return 16.0/9.0;      // Story (9:16 Portrait)
        case 28: return 9.0/16.0;      // Story (16:9 Landscape)
        case 29: return 2.63;          // Cover Photo (2.63:1 Landscape)
        
        // Twitter (X)
        case 31: return 9.0/16.0;      // Single Image (16:9 Landscape)
        case 32: return 16.0/9.0;      // Single Image (9:16 Portrait)
        case 33: return 8.0/7.0;       // Multi-Image 2 Images (7:8 Portrait)
        case 34: return 7.0/8.0;       // Multi-Image 2 Images (8:7 Landscape)
        case 35: return 2.0;           // Multi-Image 4 Images (2:1 Landscape)
        
        // LinkedIn
        case 37: return 1.91;          // Feed Post (1.91:1 Landscape)
        case 38: return 16.0/9.0;      // Story (9:16 Portrait)
        case 39: return 9.0/16.0;      // Story (16:9 Landscape)
        
        // Pinterest
        case 41: return 3.0/2.0;       // Pin (2:3 Portrait)
        case 42: return 2.0/3.0;       // Pin (3:2 Landscape)
        case 43: return 2.1;           // Max Length Pin (1:2.1 Portrait)
        case 44: return 1.0/2.1;       // Max Length Pin (2.1:1 Landscape)
        
        // TikTok/Snapchat
        case 46: return 16.0/9.0;      // Video / Story (9:16 Portrait)
        case 47: return 9.0/16.0;      // Video / Story (16:9 Landscape)
        
        // YouTube
        case 49: return 9.0/16.0;      // Thumbnail (16:9 Landscape)
        case 50: return 16.0/9.0;      // Shorts (9:16 Portrait)
        case 51: return 1.0;           // Community Post (1:1)
        
        // Photography
        case 53: return 3.0/2.0;       // Classic (3:2)
        case 54: return 4.0/3.0;       // Standard (4:3)
        case 55: return 5.0/4.0;       // Medium Format (5:4)
        case 56: return 1.0;           // Square (1:1)
        
        // Cinema
        case 58: return 9.0/16.0;      // HD/4K (16:9 Landscape)
        case 59: return 21.0/9.0;      // Ultrawide (21:9)
        case 60: return 2.39;          // Anamorphic (2.39:1)
        
        // For category headers, return default values
        case 1: return 57.0/34.0;      // Eorzea Collection header
        case 9: return 1.0;            // BlueSky header
        case 16: return 1.0;           // Instagram header
        case 23: return 1.91;          // Facebook header
        case 30: return 16.0/9.0;      // Twitter header
        case 36: return 1.91;          // LinkedIn header
        case 40: return 3.0/2.0;       // Pinterest header
        case 45: return 16.0/9.0;      // TikTok/Snapchat header
        case 48: return 16.0/9.0;      // YouTube header
        case 52: return 3.0/2.0;       // Photography header
        case 57: return 16.0/9.0;      // Cinema header
        
        // Fallback to 16:9 for any unhandled cases
        default: return 16.0/9.0;
    }
}

float2 RotatePoint(float2 pt, float2 center, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    
    // Translate point to origin
    pt -= center;
    
    // Rotate point
    float2 rotated = float2(
        pt.x * c - pt.y * s,
        pt.x * s + pt.y * c
    );
    
    // Translate back
    rotated += center;
    
    return rotated;
}

// Calculate normalized grid width for physical consistency across resolutions
float2 CalculateGridWidth(float gridWidthPixels, float2 pixelSize, float2 borderSize, float aspectRatio) {
    // Calculate normalized width values based on frame dimensions
    float frameWidth = 1.0;
    float frameHeight = 1.0;
    
    if (aspectRatio > ReShade::AspectRatio) {
        frameHeight = 1.0 - (borderSize.y * 2.0);
    } else {
        frameWidth = 1.0 - (borderSize.x * 2.0);
    }
    
    // Adjust grid widths based on normalization scaling
    return float2(
        (pixelSize.x * gridWidthPixels) / frameWidth,
        (pixelSize.y * gridWidthPixels) / frameHeight
    );
}

// Transform a screen coordinate to normalized frame coordinate
float2 ScreenToFrameCoord(float2 texcoord, float2 borderSize, float aspectRatio, float2 offset) {
    float2 frameCoord = texcoord;
    
    if (aspectRatio > ReShade::AspectRatio) {
        // Wider aspect ratio - normalize y coordinates first
        float topEdge = borderSize.y + offset.y;
        float frameHeight = AS_RANGE_ZERO_ONE_MAX - (borderSize.y * 2.0);
        
        // Normalize Y from [topEdge, topEdge + frameHeight] to [0, 1]
        frameCoord.y = (texcoord.y - topEdge) / frameHeight;
        
        // For X, just adjust for horizontal offset, centering in available width
        frameCoord.x = texcoord.x - offset.x;
    }
    else {
        // Taller aspect ratio - normalize x coordinates first
        float leftEdge = borderSize.x + offset.x;
        float frameWidth = AS_RANGE_ZERO_ONE_MAX - (borderSize.x * 2.0);
        
        // Normalize X from [leftEdge, leftEdge + frameWidth] to [0, 1]
        frameCoord.x = (texcoord.x - leftEdge) / frameWidth;
        
        // For Y, just adjust for vertical offset, centering in available height
        frameCoord.y = texcoord.y - offset.y;
    }
    
    return frameCoord;
}

// Check if a point is on a line with specified width
bool IsPointOnLine(float2 coord, float value, float width) {
    return abs(coord - value) < width;
}

// Helper function to draw guide line with rotation and intensity support
float3 DrawGuideLine(float3 originalColor, float3 guideColor, float guideAlpha, float2 frameCoord, 
                    float2 lineStart, float2 lineEnd, float2 pixelSize, float lineWidth) {
    // Apply rotation if needed
    if (PatternAdvanced && PatternRotation != AS_RANGE_ZERO_ONE_MIN) {
        float2 center = float2(AS_SCREEN_CENTER_X, AS_SCREEN_CENTER_Y);
        lineStart = RotatePoint(lineStart, center, PatternRotation * AS_DEGREES_TO_RADIANS);
        lineEnd = RotatePoint(lineEnd, center, PatternRotation * AS_DEGREES_TO_RADIANS);
    }
    
    // Calculate distance from point to line
    float2 lineDir = lineEnd - lineStart;
    float lineLength = length(lineDir);
    lineDir /= lineLength; // Normalize
    
    float2 toPoint = frameCoord - lineStart;
    float projLength = dot(toPoint, lineDir);
    
    // Check if projection falls within line segment
    if (projLength >= 0.0 && projLength <= lineLength) {
        float2 closestPoint = lineStart + lineDir * projLength;
        float dist = distance(frameCoord, closestPoint);
          // Adjust line width for consistent physical width regardless of aspect ratio
        float adjustedWidth = pixelSize.y * lineWidth;
        
        if (dist < adjustedWidth) {
            return lerp(originalColor, guideColor, guideAlpha * GuideIntensity);
        }
    }
    
    return originalColor;
}

// Draw Rule of Thirds guide
float3 DrawRuleOfThirds(float3 origColor, float3 guideColor, float2 frameCoord, float2 gridWidth) {
    // Vertical lines
    if (IsPointOnLine(frameCoord.x, AS_THIRD, gridWidth.x) || 
        IsPointOnLine(frameCoord.x, AS_TWO_THIRDS, gridWidth.x))
        return lerp(origColor, guideColor, GuideColor.a * GuideIntensity);
    
    // Horizontal lines
    if (IsPointOnLine(frameCoord.y, AS_THIRD, gridWidth.y) || 
        IsPointOnLine(frameCoord.y, AS_TWO_THIRDS, gridWidth.y))
        return lerp(origColor, guideColor, GuideColor.a * GuideIntensity);
    
    return origColor;
}

// Draw Golden Ratio guide
float3 DrawGoldenRatio(float3 origColor, float3 guideColor, float2 frameCoord, float2 gridWidth) {
    float goldenX = 1.0 / AS_GOLDEN_RATIO;
    float goldenY = 1.0 / AS_GOLDEN_RATIO;
    
    // Vertical lines
    if (IsPointOnLine(frameCoord.x, goldenX, gridWidth.x) || 
        IsPointOnLine(frameCoord.x, AS_RANGE_ZERO_ONE_MAX - goldenX, gridWidth.x))
        return lerp(origColor, guideColor, GuideColor.a * GuideIntensity);
    
    // Horizontal lines
    if (IsPointOnLine(frameCoord.y, goldenY, gridWidth.y) || 
        IsPointOnLine(frameCoord.y, AS_RANGE_ZERO_ONE_MAX - goldenY, gridWidth.y))
        return lerp(origColor, guideColor, GuideColor.a * GuideIntensity);
    
    return origColor;
}

// Draw Center Lines guide
float3 DrawCenterLines(float3 origColor, float3 guideColor, float2 frameCoord, float2 gridWidth) {
    // Vertical center line
    if (IsPointOnLine(frameCoord.x, AS_HALF, gridWidth.x))
        return lerp(origColor, guideColor, GuideColor.a * GuideIntensity);
    
    // Horizontal center line
    if (IsPointOnLine(frameCoord.y, AS_HALF, gridWidth.y))
        return lerp(origColor, guideColor, GuideColor.a * GuideIntensity);
    
    return origColor;
}

// Draw border around active area
float3 DrawBorder(float2 texcoord, float3 origColor, float3 guideColor, float2 borderSize, float aspectRatio) {
    if (GridWidth <= 0.0) 
        return origColor;
    
    float2 pixelSize = 1.0 / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float borderWidthPixels = GridWidth;
    
    // Normalize border width based on aspect ratio
    float frameWidth = 1.0;
    float frameHeight = 1.0;
    
    if (aspectRatio > ReShade::AspectRatio) {
        frameHeight = 1.0 - (borderSize.y * 2.0);
    } else {
        frameWidth = 1.0 - (borderSize.x * 2.0);
    }
    
    // Adjust border widths to ensure consistent physical size
    float borderWidthX = pixelSize.x * borderWidthPixels;
    float borderWidthY = pixelSize.y * borderWidthPixels;
    
    if (aspectRatio > ReShade::AspectRatio) {
        // Wider aspect ratio - draw horizontal borders
        float topEdge = borderSize.y + EffectPosition.y;
        float bottomEdge = 1.0 - borderSize.y + EffectPosition.y;
        
        // Draw the horizontal borders exactly at the crop edges
        if ((abs(texcoord.y - topEdge) < borderWidthY) || 
            (abs(texcoord.y - bottomEdge) < borderWidthY))
            return lerp(origColor, guideColor, GuideColor.a * GuideIntensity);
    }
    else {
        // Taller aspect ratio - draw vertical borders
        float leftEdge = borderSize.x + EffectPosition.x;
        float rightEdge = 1.0 - borderSize.x + EffectPosition.x;
        
        // Draw the vertical borders exactly at the crop edges
        if ((abs(texcoord.x - leftEdge) < borderWidthX) || 
            (abs(texcoord.x - rightEdge) < borderWidthX))
            return lerp(origColor, guideColor, GuideColor.a * GuideIntensity);
    }
    
    return origColor;
}

// Draws the composition guide overlay
float3 DrawGuides(float2 texcoord, float3 originalColor, float3 guideColor, float aspectRatio) {
    float2 borderSize = float2(0.0, 0.0);
    bool isInFrame = true;
    
    // Calculate active frame area based on aspect ratio
    if (aspectRatio > ReShade::AspectRatio) {
        // Wider aspect ratio than screen - black bars on top and bottom
        borderSize.y = (1.0 - (ReShade::AspectRatio / aspectRatio)) / 2.0;
        isInFrame = (texcoord.y >= borderSize.y + EffectPosition.y) && 
                   (texcoord.y <= 1.0 - borderSize.y + EffectPosition.y);
    }
    else {
        // Taller or equal aspect ratio - black bars on sides
        borderSize.x = (1.0 - (aspectRatio / ReShade::AspectRatio)) / 2.0;
        isInFrame = (texcoord.x >= borderSize.x + EffectPosition.x) && 
                   (texcoord.x <= 1.0 - borderSize.x + EffectPosition.x);
    }
    
    // Get the guide configuration from the UI selection
    int guideValue = GetGuideValue();
    int actualGuideType = GetGuideType(guideValue);
    int actualSubType = GetGuideSubType(guideValue);
    
    // If not in frame, return original color immediately
    if (!isInFrame && actualGuideType != 0) {
        return originalColor;
    }    // Draw guides
    if (actualGuideType != 0 && isInFrame) {
        // Transform screen coordinates to normalized frame coordinates
        float2 frameCoord = ScreenToFrameCoord(
            texcoord, 
            borderSize, 
            aspectRatio, 
            EffectPosition
        );
        
        // Calculate pixel-width based threshold for grid lines with consistent physical width
        float2 pixelSize = 1.0 / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
        float gridWidthPixels = GridWidth * 0.5; // Half width for each side
        
        // Use our helper function to calculate normalized grid widths
        float2 gridWidth = CalculateGridWidth(
            gridWidthPixels, 
            pixelSize, 
            borderSize, 
            aspectRatio
        );
        
        // Dispatch to the appropriate guide drawing function based on type
        switch(actualGuideType) {
            case 1: // Rule of thirds
                return DrawRuleOfThirds(originalColor, guideColor, frameCoord, gridWidth);
                
            case 2: // Golden ratio
                return DrawGoldenRatio(originalColor, guideColor, frameCoord, gridWidth);
                
            case 3: // Center lines
                return DrawCenterLines(originalColor, guideColor, frameCoord, gridWidth);
                
            case 4: { // Diagonal Method
                // Diagonal lines from opposite corners
                float diagonalWidth = sqrt(gridWidth.x * gridWidth.x + gridWidth.y * gridWidth.y);
                
                // Apply rotation if enabled
                float2 rotatedCoord = frameCoord;
                if (PatternAdvanced && PatternRotation != 0.0) {
                    rotatedCoord = RotatePoint(frameCoord, float2(0.5, 0.5), PatternRotation * AS_PI / 180.0);
                }
                
                if (actualSubType == 0 || actualSubType == 1) {
                    // Baroque diagonal: Lower-left to upper-right
                    float distToBaroque = abs(rotatedCoord.y - rotatedCoord.x);
                    if (distToBaroque < diagonalWidth)
                        return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
                }
                
                if (actualSubType == 0 || actualSubType == 2) {
                    // Sinister diagonal: Upper-left to lower-right
                    float distToSinister = abs(rotatedCoord.y - (1.0 - rotatedCoord.x));
                    if (distToSinister < diagonalWidth)
                        return lerp(originalColor, guideColor, GuideColor.a * GuideIntensity);
                }
                break;
            }
              case 5: { // Phi Grid (Golden Grid)
                // Phi proportions (golden ratio)
                float phi = 1.0 / AS_GOLDEN_RATIO;
                
                // Vertical lines at phi and 1-phi
                if (IsPointOnLine(frameCoord.x, phi, gridWidth.x) || 
                    IsPointOnLine(frameCoord.x, AS_RANGE_ZERO_ONE_MAX - phi, gridWidth.x))
                    return lerp(originalColor, guideColor, GuideColor.a);
                
                // Horizontal lines at phi and 1-phi
                if (IsPointOnLine(frameCoord.y, phi, gridWidth.y) || 
                    IsPointOnLine(frameCoord.y, AS_RANGE_ZERO_ONE_MAX - phi, gridWidth.y))
                    return lerp(originalColor, guideColor, GuideColor.a);
                break;
            }
              case 6: { // Triangle Composition
                float triHeight = 0.866; // Height of an equilateral triangle (sqrt(3)/2)
                
                if (actualSubType == 0) { // Centered triangle pointing up
                    // Triangle base at bottom
                    if (IsPointOnLine(frameCoord.y, AS_RANGE_ZERO_ONE_MAX, gridWidth.y) && 
                        frameCoord.x >= AS_QUARTER && frameCoord.x <= 0.75)
                        return lerp(originalColor, guideColor, GuideColor.a);
                    
                    // Left side
                    float leftSide = AS_HALF - 2.0 * (AS_HALF - frameCoord.y);
                    if (IsPointOnLine(frameCoord.x, leftSide, gridWidth.x) && 
                        frameCoord.y <= AS_RANGE_ZERO_ONE_MAX && frameCoord.y >= AS_RANGE_ZERO_ONE_MIN)
                        return lerp(originalColor, guideColor, GuideColor.a);
                    
                    // Right side
                    float rightSide = AS_HALF + 2.0 * (AS_HALF - frameCoord.y);
                    if (IsPointOnLine(frameCoord.x, rightSide, gridWidth.x) && 
                        frameCoord.y <= AS_RANGE_ZERO_ONE_MAX && frameCoord.y >= AS_RANGE_ZERO_ONE_MIN)
                        return lerp(originalColor, guideColor, GuideColor.a);
                }                else if (actualSubType == 1) { // Centered triangle pointing down
                    // Triangle base at top
                    if (IsPointOnLine(frameCoord.y, AS_RANGE_ZERO_ONE_MIN, gridWidth.y) && 
                        frameCoord.x >= AS_QUARTER && frameCoord.x <= 0.75)
                        return lerp(originalColor, guideColor, GuideColor.a);
                    
                    // Left side
                    float leftSide = AS_HALF - 2.0 * frameCoord.y;
                    if (IsPointOnLine(frameCoord.x, leftSide, gridWidth.x) && 
                        frameCoord.y <= AS_HALF && frameCoord.y >= AS_RANGE_ZERO_ONE_MIN)
                        return lerp(originalColor, guideColor, GuideColor.a);
                    
                    // Right side
                    float rightSide = AS_HALF + 2.0 * frameCoord.y;
                    if (IsPointOnLine(frameCoord.x, rightSide, gridWidth.x) && 
                        frameCoord.y <= AS_HALF && frameCoord.y >= AS_RANGE_ZERO_ONE_MIN)
                        return lerp(originalColor, guideColor, GuideColor.a);
                }
                else if (actualSubType == 2) { // Rule of triangles - diagonal from lower-left
                    float dist = abs(frameCoord.x + frameCoord.y - AS_RANGE_ZERO_ONE_MAX);
                    if (dist < gridWidth.x)
                        return lerp(originalColor, guideColor, GuideColor.a);
                }
                break;
            }
            
            case 7: { // Golden Spiral
                float2 spiralCenter;
                float angle, radius, phi = 1.618;
                
                // Change spiral orientation based on subtype
                if (actualSubType == SPIRAL_LOWER_RIGHT) {
                    spiralCenter = float2(1.0, 1.0);
                    angle = atan2(1.0 - frameCoord.y, 1.0 - frameCoord.x);
                } else if (actualSubType == SPIRAL_UPPER_RIGHT) {
                    spiralCenter = float2(1.0, 0.0);
                    angle = atan2(frameCoord.y, 1.0 - frameCoord.x);
                } else if (actualSubType == SPIRAL_UPPER_LEFT) {
                    spiralCenter = float2(0.0, 0.0);
                    angle = atan2(frameCoord.y, frameCoord.x);
                } else if (actualSubType == SPIRAL_LOWER_LEFT) {
                    spiralCenter = float2(0.0, 1.0);
                    angle = atan2(1.0 - frameCoord.y, frameCoord.x);
                }
                  // Normalize angle to [0, 2π)
                if (angle < AS_RANGE_ZERO_ONE_MIN) angle += AS_TWO_PI;
                
                // Calculate distance to spiral center
                float2 delta = abs(frameCoord - spiralCenter);
                float dist = length(delta);
                
                // Calculate the ideal radius for a golden spiral at this angle
                float b = log(phi) / (AS_PI * AS_HALF);
                float idealRadius = 0.25 * exp(b * angle);
                  // Calculate spiral thickness based on GridWidth
                float spiralThickness = (GridWidth * 0.01) * length(float2(1.0/BUFFER_WIDTH, 1.0/BUFFER_HEIGHT)) * AS_AR_SPIRAL_SCALE_FACTOR;
                spiralThickness = max(spiralThickness, AS_AR_SPIRAL_MIN_THICKNESS); // Minimum thickness
                
                if (abs(dist - idealRadius) < spiralThickness)
                    return lerp(originalColor, guideColor, GuideColor.a);
                
                // Draw the golden rectangles
                float phiInv = 1.0 / phi;
                
                if (actualSubType == SPIRAL_LOWER_RIGHT) {                if (IsPointOnLine(frameCoord.x, AS_RANGE_ZERO_ONE_MAX - phiInv, gridWidth.x) || 
                        IsPointOnLine(frameCoord.y, AS_RANGE_ZERO_ONE_MAX - phiInv, gridWidth.y))
                        return lerp(originalColor, guideColor, GuideColor.a * AS_AR_INTENSITY_MEDIUM);
                } else if (actualSubType == SPIRAL_UPPER_RIGHT) {
                    if (IsPointOnLine(frameCoord.x, 1.0 - phiInv, gridWidth.x) || 
                        IsPointOnLine(frameCoord.y, phiInv, gridWidth.y))
                        return lerp(originalColor, guideColor, GuideColor.a * 0.7);
                } else if (actualSubType == SPIRAL_UPPER_LEFT) {                if (IsPointOnLine(frameCoord.x, phiInv, gridWidth.x) || 
                        IsPointOnLine(frameCoord.y, phiInv, gridWidth.y))
                        return lerp(originalColor, guideColor, GuideColor.a * AS_AR_INTENSITY_MEDIUM);
                } else if (actualSubType == SPIRAL_LOWER_LEFT) {
                    if (IsPointOnLine(frameCoord.x, phiInv, gridWidth.x) || 
                        IsPointOnLine(frameCoord.y, 1.0 - phiInv, gridWidth.y))
                        return lerp(originalColor, guideColor, GuideColor.a * 0.7);
                }
                break;
            }
            
            case 8: { // Harmonic Armature / Dynamic Symmetry
                float diagonalWidth = sqrt(gridWidth.x * gridWidth.x + gridWidth.y * gridWidth.y);
                
                // Main diagonals
                float distToD1 = abs(frameCoord.x - frameCoord.y);
                float distToD2 = abs(frameCoord.x - (1.0 - frameCoord.y));
                
                if (distToD1 < diagonalWidth || distToD2 < diagonalWidth)
                    return lerp(originalColor, guideColor, GuideColor.a);
                
                // Reciprocal
                if (actualSubType > 0) {
                    // Vertical and horizontal center lines
                        if (IsPointOnLine(frameCoord.x, AS_HALF, gridWidth.x * AS_AR_INTENSITY_MEDIUM) || 
                        IsPointOnLine(frameCoord.y, AS_HALF, gridWidth.y * AS_AR_INTENSITY_MEDIUM))
                        return lerp(originalColor, guideColor, GuideColor.a * AS_AR_INTENSITY_MEDIUM);
                    
                    // Additional diagonals for more complex armature
                    if (actualSubType > 1) {
                        // Reciprocal diagonals from the center
                        float centerDistY1 = abs((frameCoord.x - 0.5) * 2.0 - (frameCoord.y - 0.5));
                        float centerDistY2 = abs((frameCoord.x - 0.5) * 2.0 + (frameCoord.y - 0.5));
                                  if (centerDistY1 < diagonalWidth * AS_AR_INTENSITY_MEDIUM || centerDistY2 < diagonalWidth * AS_AR_INTENSITY_MEDIUM)
                            return lerp(originalColor, guideColor, GuideColor.a * AS_AR_INTENSITY_WEAK);
                    }
                }
                break;
            }
              case 9: { // Grid
                // Determine grid size based on SubType
                int gridSize = AS_AR_GRID_3X3; // Default to 3x3
                if (actualSubType == 1) gridSize = AS_AR_GRID_4X4; // 4x4
                else if (actualSubType == 2) gridSize = AS_AR_GRID_5X5; // 5x5
                else if (actualSubType == 3) gridSize = AS_AR_GRID_6X6; // 6x6
                
                // Check if we're on a grid line
                for (int i = 1; i < gridSize; i++) {
                    float pos = float(i) / float(gridSize);
                    
                    // Vertical or horizontal lines
                    if (IsPointOnLine(frameCoord.x, pos, gridWidth.x) || 
                        IsPointOnLine(frameCoord.y, pos, gridWidth.y))
                        return lerp(originalColor, guideColor, GuideColor.a);
                }
                break;
            }
            
            case 10: { // Safe Zones                // Action Safe (90%)
                float actionSafe = AS_AR_ACTION_SAFE_MARGIN;
                
                // Title Safe (80%)
                float titleSafe = AS_AR_TITLE_SAFE_MARGIN;
                
                // Draw Action Safe zone
                if (IsPointOnLine(frameCoord.x, actionSafe, gridWidth.x) || 
                    IsPointOnLine(frameCoord.x, AS_RANGE_ZERO_ONE_MAX - actionSafe, gridWidth.x) ||
                    IsPointOnLine(frameCoord.y, actionSafe, gridWidth.y) || 
                    IsPointOnLine(frameCoord.y, AS_RANGE_ZERO_ONE_MAX - actionSafe, gridWidth.y))
                    return lerp(originalColor, guideColor, GuideColor.a);
                
                // Draw Title Safe zone
                if (IsPointOnLine(frameCoord.x, titleSafe, gridWidth.x) || 
                    IsPointOnLine(frameCoord.x, AS_RANGE_ZERO_ONE_MAX - titleSafe, gridWidth.x) ||
                    IsPointOnLine(frameCoord.y, titleSafe, gridWidth.y) || 
                    IsPointOnLine(frameCoord.y, AS_RANGE_ZERO_ONE_MAX - titleSafe, gridWidth.y))
                    return lerp(originalColor, float3(AS_RANGE_ZERO_ONE_MAX, AS_RANGE_ZERO_ONE_MAX, AS_HALF), GuideColor.a * AS_AR_INTENSITY_STRONG);
                break;
            }
        }    }
    
    // Draw border around active area if needed (only if guide type is not None)
    if (GridWidth > 0.0 && isInFrame && actualGuideType != 0) {
        return DrawBorder(texcoord, originalColor, guideColor, borderSize, aspectRatio);
    }
    
    return originalColor;
}

// ============================================================================
// PIXEL SHADER
// ============================================================================

float3 PS_AspectRatio(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float aspectRatio = GetAspectRatio();
    
    // Determine if the current pixel is inside the aspect ratio frame
    bool isInFrame = true;
    float2 borderSize = float2(0.0, 0.0);
    
    // Calculate border size based on whether the aspect ratio is wider or taller than the screen
    if (aspectRatio > ReShade::AspectRatio) {
        // Wider aspect ratio than screen - black bars on top and bottom
        borderSize.y = (1.0 - (ReShade::AspectRatio / aspectRatio)) / 2.0;
        float topEdge = borderSize.y + EffectPosition.y;
        float bottomEdge = 1.0 - borderSize.y + EffectPosition.y;
        isInFrame = (texcoord.y >= topEdge) && (texcoord.y <= bottomEdge);
    }
    else {
        // Taller or equal aspect ratio - black bars on sides
        borderSize.x = (1.0 - (aspectRatio / ReShade::AspectRatio)) / 2.0;
        float leftEdge = borderSize.x + EffectPosition.x;
        float rightEdge = 1.0 - borderSize.x + EffectPosition.x;
        isInFrame = (texcoord.x >= leftEdge) && (texcoord.x <= rightEdge);
    }    // Save the original color before applying effects
    float3 originalColor = color;
      // Draw composition guides (only if inside frame AND guide type is not None)
    int guideTypeValue = GetGuideType(GetGuideValue());
    if (isInFrame && guideTypeValue != 0) {
        color = DrawGuides(texcoord, color, GuideColor.rgb, aspectRatio);
    }
    
    // Apply the clipped area color if outside the frame (must be done after guides)
    if (!isInFrame) {
        color = lerp(originalColor, ClippedAreaColor.rgb, ClippedAreaColor.a);
    }
    
    return color;
}

// ============================================================================
// TECHNIQUE
// ============================================================================

technique AS_GFX_AspectRatio <
ui_label = "[AS] GFX: Aspect Ratio"; ui_tooltip = "Aspect ratio framing tool for precise subject positioning"; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_AspectRatio;
    }
}

#endif // __AS_GFX_AspectRatio_1_fx


