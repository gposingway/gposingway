/**
 * AS_Palette.1.fxh - Color palette system for AstrayFX shaders
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_Palettes_1_fxh
#define __AS_Palettes_1_fxh

/**
 * AS_Palette.1.fxh - Palette Definitions for AS StageFX Shader Collection
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 */

// --- Palette Constants ---
// Standard palette size
#define AS_PALETTE_COLORS 5

// Include the palette style definitions first so AS_PALETTE_COUNT is available
#include "AS_Palette_Styles.1.fxh"

// AS_PALETTE_CUSTOM is now defined as 0 in AS_Palette_Styles.1.fxh for backward compatibility

// Default custom palette colors (will be overridden by AS_CUSTOM_PALETTE_UI macro when used)
// These defaults ensure the variables exist even if the macro isn't used
static const float3 CustomPaletteColor0 = float3(1.0, 0.0, 0.0); // Red
static const float3 CustomPaletteColor1 = float3(1.0, 1.0, 0.0); // Yellow
static const float3 CustomPaletteColor2 = float3(0.0, 1.0, 0.0); // Green
static const float3 CustomPaletteColor3 = float3(0.0, 0.0, 1.0); // Blue
static const float3 CustomPaletteColor4 = float3(1.0, 0.0, 1.0); // Magenta

// Get palette color by index from the array
float3 AS_getPaletteColor(int paletteIdx, int colorIdx) {
    // Clamp palette and color indices to valid ranges
    paletteIdx = clamp(paletteIdx, 0, AS_PALETTE_COUNT - 1);
    colorIdx = clamp(colorIdx, 0, AS_PALETTE_COLORS - 1);
    
    // Handle custom palette as index 0
    if (paletteIdx == AS_PALETTE_CUSTOM) {
        if (colorIdx == 0) return CustomPaletteColor0;
        if (colorIdx == 1) return CustomPaletteColor1;
        if (colorIdx == 2) return CustomPaletteColor2;
        if (colorIdx == 3) return CustomPaletteColor3;
        return CustomPaletteColor4;
    }
    
    // For built-in palettes (indices 1 and above), adjust index to account for custom being at index 0
    int adjustedPaletteIdx = paletteIdx - 1; // Subtract 1 to skip the custom palette slot
    int idx = adjustedPaletteIdx * AS_PALETTE_COLORS + colorIdx;
    return AS_PALETTES[idx];
}

// Interpolate color between palette colors
float3 AS_getInterpolatedColor(int paletteIdx, float t) {
    // Clamp the parameter to [0, 1]
    t = saturate(t);
    
    // Normalize to [0, number of segments]
    float segments = AS_PALETTE_COLORS - 1;
    float scaledT = t * segments;
    
    // Find indices for the two colors to interpolate between
    int colorIdx1 = floor(scaledT);
    int colorIdx2 = min(colorIdx1 + 1, AS_PALETTE_COLORS - 1);
    
    // Get the fractional part for interpolation
    float mix = frac(scaledT);
    
    // Get the two colors and interpolate
    float3 color1 = AS_getPaletteColor(paletteIdx, colorIdx1);
    float3 color2 = AS_getPaletteColor(paletteIdx, colorIdx2);
    
    return lerp(color1, color2, mix);
}

// Standard palette selection UI
#define AS_PALETTE_SELECTION_UI(name, label, defaultPalette, category) \
uniform int name < ui_type = "combo"; ui_label = label; ui_items = AS_PALETTE_ITEMS; ui_category = category; > = defaultPalette; // AS_PALETTE_ITEMS is now from AS_Palette_Styles.1.fxh

// Macro to declare custom palette uniforms with a unique prefix
#define AS_DECLARE_CUSTOM_PALETTE(prefix, category) \
uniform float3 prefix##CustomPaletteColor0 < ui_type = "color"; ui_label = "Custom Color 1"; ui_category = category; > = float3(1.0, 0.0, 0.0); \
uniform float3 prefix##CustomPaletteColor1 < ui_type = "color"; ui_label = "Custom Color 2"; ui_category = category; > = float3(1.0, 1.0, 0.0); \
uniform float3 prefix##CustomPaletteColor2 < ui_type = "color"; ui_label = "Custom Color 3"; ui_category = category; > = float3(0.0, 1.0, 0.0); \
uniform float3 prefix##CustomPaletteColor3 < ui_type = "color"; ui_label = "Custom Color 4"; ui_category = category; > = float3(0.0, 0.0, 1.0); \
uniform float3 prefix##CustomPaletteColor4 < ui_type = "color"; ui_label = "Custom Color 5"; ui_category = category; > = float3(1.0, 0.0, 1.0);

// Macro to fetch a custom palette color by prefix and index
#define AS_GET_CUSTOM_PALETTE_COLOR(prefix, idx) \
    ((idx) == 0 ? prefix##CustomPaletteColor0 : \
    (idx) == 1 ? prefix##CustomPaletteColor1 : \
    (idx) == 2 ? prefix##CustomPaletteColor2 : \
    (idx) == 3 ? prefix##CustomPaletteColor3 : prefix##CustomPaletteColor4)

// Interpolate color between custom palette colors (by prefix)
#define AS_GET_INTERPOLATED_CUSTOM_COLOR(prefix, t) \
    lerp( \
        AS_GET_CUSTOM_PALETTE_COLOR(prefix, (int)floor(saturate(t)*(AS_PALETTE_COLORS-1))), \
        AS_GET_CUSTOM_PALETTE_COLOR(prefix, min((int)floor(saturate(t)*(AS_PALETTE_COLORS-1))+1, AS_PALETTE_COLORS-1)), \
        frac(saturate(t)*(AS_PALETTE_COLORS-1)) \
    )

#endif // __AS_Palettes_1_fxh


