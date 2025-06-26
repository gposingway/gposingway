/**
 * AS_VFX_TiltedGrid.1.fx - Rotatable grid effect with borders
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Inspired by: "Godot 4: Tilted Grid Effect Tutorial" by FencerDevLog
 * Tutorial URL: https://www.youtube.com/watch?v=Tfj6RDqXEHM
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Creates a rotatable grid that pixelates the image and adds adjustable borders
 * between grid cells. Corner chamfers are overlaid independently. Each cell captures the color
 * from its center position.
 *
 * FEATURES:
 * - Adjustable grid size for pixelation effect
 * - Customizable border color and thickness (as percentage of cell size)
 * - Customizable corner chamfer size (as percentage of cell size) - Additive overlay
 * - Rotation controls for diagonal/tilted effects
 * - Depth masking for selective application
 * - Audio reactivity options for dynamic adjustments
 * - Resolution-independent rendering
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. Transforms coordinates to rotated grid space
 * 2. Samples pixel color from cell centers for pixelation effect
 * 3. Calculates square border mask and additive chamfer corner mask independently
 * 4. Combines cell color and final border mask with adjustable blend options
 *
 * ===================================================================================
 */

#ifndef __AS_VFX_TiltedGrid_1_fx
#define __AS_VFX_TiltedGrid_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh" // Includes ReShadeUI.fxh, provides UI macros, helpers

// ============================================================================
// TUNABLE CONSTANTS
// ============================================================================
static const float GRID_SIZE_MIN = 0.001; // 0.1% of screen height
static const float GRID_SIZE_MAX = 0.2;   // 20% of screen height
static const float GRID_SIZE_DEFAULT = 0.02; // 2% of screen height

static const float BORDER_THICKNESS_MIN = 0.0;
static const float BORDER_THICKNESS_MAX = 0.5; // Max 50% of cell size
static const float BORDER_THICKNESS_DEFAULT = 0.1; // 10% of cell size

static const float CHAMFER_SIZE_MIN = 0.0;
static const float CHAMFER_SIZE_MAX = 0.5; // Max 50% of cell size (relative to cell dimensions)
static const float CHAMFER_SIZE_DEFAULT = 0.2; // 20% of cell size

// ============================================================================
// EFFECT-SPECIFIC PARAMETERS
// ============================================================================

uniform int as_shader_descriptor  <ui_type = "radio"; ui_label = " "; ui_text = "\nBased on 'Godot 4: Tilted Grid Effect Tutorial' by FencerDevLog\nLink: https://www.youtube.com/watch?v=Tfj6RDqXEHM\nLicence: Creative Commons Attribution 4.0 International\n\n";>;

uniform float GridSize < ui_type = "slider"; ui_label = "Cell Size"; ui_tooltip = "Size of grid cells as percentage of screen height (0.1% to 20%)."; ui_min = GRID_SIZE_MIN; ui_max = GRID_SIZE_MAX; ui_step = 0.001; ui_category = "Grid Pattern"; > = GRID_SIZE_DEFAULT;

uniform float BorderThickness < ui_type = "slider"; ui_label = "Border Thickness"; ui_tooltip = "Thickness of the grid borders as a percentage of cell size."; ui_min = BORDER_THICKNESS_MIN; ui_max = BORDER_THICKNESS_MAX; ui_step = 0.01; ui_category = "Grid Pattern"; > = BORDER_THICKNESS_DEFAULT;

uniform float ChamferSize < ui_type = "slider"; ui_label = "Chamfer Size"; ui_tooltip = "Size of additive corner chamfers as a percentage of cell size (0=square borders)."; ui_min = CHAMFER_SIZE_MIN; ui_max = CHAMFER_SIZE_MAX; ui_step = 0.01; ui_category = "Grid Pattern"; > = CHAMFER_SIZE_DEFAULT;

uniform float3 BorderColor < ui_type = "color"; ui_label = "Border Color"; ui_tooltip = "Color of the borders between cells."; ui_category = "Grid Pattern"; > = float3(0.0, 0.0, 0.0);

// ============================================================================
// AUDIO REACTIVITY
// ============================================================================
AS_AUDIO_UI(Grid_AudioSource, "Audio Source", AS_AUDIO_BEAT, "Audio Reactivity")
AS_AUDIO_MULT_UI(Grid_AudioMultiplier, "Intensity", 0.1, 4.0, "Audio Reactivity")

uniform int AudioTarget < ui_type = "combo"; ui_label = "Audio Target Parameter"; ui_tooltip = "Select which parameter will be affected by audio reactivity"; ui_items = "None\0Cell Size\0Border Thickness\0Chamfer Size\0Border + Chamfer\0"; ui_category = "Audio Reactivity"; > = 1;

// ============================================================================
// STAGE DISTANCE
// ============================================================================
AS_STAGEDEPTH_UI(EffectDepth)
AS_ROTATION_UI(GlobalSnapRotation, GlobalFineRotation)

// ============================================================================
// FINAL MIX
// ============================================================================
AS_BLENDMODE_UI_DEFAULT(BlendMode, 0)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// DEBUG
// ============================================================================
AS_DEBUG_UI("Normal\0Grid Cell Index\0Final Border Mask\0Cell Center Sample Points\0Square Border Mask\0Chamfer Mask\0") // Added more debug views

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================
namespace AS_TiltedGrid {
    // Rotate a coordinate around the origin
    float2 RotatePoint(float2 p, float angle) {
        float sinVal = sin(angle);
        float cosVal = cos(angle);
        return float2(
            p.x * cosVal - p.y * sinVal,
            p.x * sinVal + p.y * cosVal
        );
    }

    // Get grid cell index for a pixel
    float2 GetGridCell(float2 uv, float gridSizePercent, float angle) {
        // Calculate actual grid size in pixels (percentage of screen height)
        float gridSize = gridSizePercent * ReShade::ScreenSize.y;
        if (gridSize <= 0.0) return float2(0.0, 0.0); // Avoid division by zero

        // Scale to pixel space
        float2 pixel = uv * ReShade::ScreenSize;

        // Apply rotation around center
        float2 center = ReShade::ScreenSize * 0.5;
        float2 centered = pixel - center;
        float2 rotated = RotatePoint(centered, angle);

        // Calculate grid cell (centered at screen center)
        return floor(rotated / gridSize);
    }

    // Get the color for a grid cell by sampling its center
    float3 GetCellColor(float2 cell, float gridSizePercent, float angle) {
        // Calculate actual grid size in pixels (percentage of screen height)
        float gridSize = gridSizePercent * ReShade::ScreenSize.y;
        if (gridSize <= 0.0) return float3(0.0, 0.0, 0.0); // Return black if grid size invalid

        // Get center of cell in rotated space (centered grid system)
        float2 center = ReShade::ScreenSize * 0.5;
        float2 cellCenterRotated = (cell + 0.5) * gridSize; // Cell center in rotated space

        // Apply inverse rotation to get back to screen space
        float2 unrotated = RotatePoint(cellCenterRotated, -angle);
        float2 pixelPos = unrotated + center;

        // Convert back to UV and sample
        float2 uv = pixelPos / ReShade::ScreenSize;
        return tex2D(ReShade::BackBuffer, saturate(uv)).rgb;
    }

    // Calculate border mask (1.0 for border, 0.0 for interior) - Additive Chamfer Approach
    // Returns mask components: x = square border, y = chamfer overlay
    float2 GetBorderMaskComponents(float2 uv, float gridSizePercent, float borderThickness, float chamferSize, float angle) {
        // --- Calculate pixel position in rotated, normalized cell space ---
        float gridSize = gridSizePercent * ReShade::ScreenSize.y;
        // Prevent division by zero or negative values
        if (gridSize <= 0.0) return float2(0.0, 0.0);

        float2 center = ReShade::ScreenSize * 0.5;
        float2 pixel = uv * ReShade::ScreenSize;
        float2 centered = pixel - center;
        float2 rotated = RotatePoint(centered, angle);
        float2 cellPos = rotated / gridSize;
        float2 cellFrac = frac(cellPos); // Position within the current cell [0, 1)

        // --- Calculate Base Square Border ---
        float halfBorderWidth = borderThickness * 0.5;
        // Calculate anti-aliasing width based on pixel size relative to cell size
        float aa = (1.0 / gridSize) * 1.0; // Adjust multiplier for more/less AA

        float squareBorderMask = 0.0;
        if (halfBorderWidth > 0.0) // Only calculate if border exists
        {
             // Distance from cell edges [0, 0.5]
            float2 distToEdge = min(cellFrac, 1.0 - cellFrac);
            // Check distance to horizontal edges
            float borderX = smoothstep(halfBorderWidth + aa, halfBorderWidth - aa, distToEdge.x);
            // Check distance to vertical edges
            float borderY = smoothstep(halfBorderWidth + aa, halfBorderWidth - aa, distToEdge.y);
            // Combine - pixel is on border if close to EITHER horizontal OR vertical edge
            squareBorderMask = max(borderX, borderY);

            // Sharp version:
            // squareBorderMask = (min(distToEdge.x, distToEdge.y) < halfBorderWidth) ? 1.0 : 0.0;
        }

        // --- Calculate Additive Chamfer Corner Mask ---
        float chamferMask = 0.0;
        // Ensure chamferSize is valid [0, 0.5] and non-negative
        float effectiveChamferSize = clamp(chamferSize, 0.0, 0.5);

        if (effectiveChamferSize > 0.0)
        {
            // Identify the nearest corner vertex (0,0), (1,0), (0,1), or (1,1) in cellFrac space
            float2 cornerPos;
            cornerPos.x = cellFrac.x < 0.5 ? 0.0 : 1.0;
            cornerPos.y = cellFrac.y < 0.5 ? 0.0 : 1.0;

            // Calculate Manhattan distance from this corner vertex
            float distFromCorner = abs(cellFrac.x - cornerPos.x) + abs(cellFrac.y - cornerPos.y);

            // Check if the pixel is INSIDE the chamfer triangle area defined by the chamfer size.
            // The mask is 1.0 inside this triangle.
            float chamferSDF = effectiveChamferSize - distFromCorner; // Positive inside the chamfer triangle/diamond
            chamferMask = smoothstep(-aa, aa, chamferSDF); // Smooth transition around the edge == chamferSize

            // Sharp version:
            // chamferMask = step(0.0, chamferSDF); // 1.0 if inside or on edge (distFromCorner <= effectiveChamferSize)
        }

        // Return both masks for debugging or potential different blending later
        return float2(squareBorderMask, chamferMask);
    }

} // End namespace AS_TiltedGrid

// ============================================================================
// MAIN PIXEL SHADER
// ============================================================================
float4 PS_TiltedGrid(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // --- Initial Setup & Depth Test ---
    float4 orig = tex2D(ReShade::BackBuffer, texcoord);
    float depth = ReShade::GetLinearizedDepth(texcoord);
    if (depth < EffectDepth - 0.0005)
        return orig;

    // --- Constants & Inputs ---
    float aspectRatio = ReShade::AspectRatio;
    float rotation = AS_getRotationRadians(GlobalSnapRotation, GlobalFineRotation);

    // --- Audio Reactivity ---
    float gridSizeFinal = GridSize;
    float borderThicknessFinal = BorderThickness;
    float chamferSizeFinal = ChamferSize;

    if (AudioTarget > 0) {
        float audioValue = AS_applyAudioReactivity(1.0, Grid_AudioSource, Grid_AudioMultiplier, true);
        
        if (AudioTarget == 1) { // Cell Size
            gridSizeFinal = GridSize * audioValue;
            gridSizeFinal = max(gridSizeFinal, GRID_SIZE_MIN);
        } 
        else if (AudioTarget == 2) { // Border Thickness
            borderThicknessFinal = BorderThickness * audioValue;
            borderThicknessFinal = clamp(borderThicknessFinal, BORDER_THICKNESS_MIN, BORDER_THICKNESS_MAX);
        }
        else if (AudioTarget == 3) { // Chamfer Size
            chamferSizeFinal = ChamferSize * audioValue;
            chamferSizeFinal = clamp(chamferSizeFinal, CHAMFER_SIZE_MIN, CHAMFER_SIZE_MAX);
        }
        else if (AudioTarget == 4) { // Border + Chamfer Size
            // Apply audio reactivity to both border and chamfer together
            borderThicknessFinal = BorderThickness * audioValue;
            borderThicknessFinal = clamp(borderThicknessFinal, BORDER_THICKNESS_MIN, BORDER_THICKNESS_MAX);
            
            chamferSizeFinal = ChamferSize * audioValue;
            chamferSizeFinal = clamp(chamferSizeFinal, CHAMFER_SIZE_MIN, CHAMFER_SIZE_MAX);
        }
    }

    // --- Grid Calculation ---
    // Get the grid cell containing this pixel
    float2 cell = AS_TiltedGrid::GetGridCell(texcoord, gridSizeFinal, rotation);

    // Get the color for this cell from its center
    float3 cellColor = AS_TiltedGrid::GetCellColor(cell, gridSizeFinal, rotation);

    // --- Border Calculation (Additive Chamfer) ---
    // Get both mask components separately
    float2 borderComponents = AS_TiltedGrid::GetBorderMaskComponents(texcoord, gridSizeFinal, borderThicknessFinal, chamferSizeFinal, rotation);
    float squareBorderMask = borderComponents.x;
    float chamferMask = borderComponents.y;

    // Combine masks: take the maximum intensity from either mask
    float finalBorderMask = max(squareBorderMask, chamferMask);

    // Mix cell color with border color
    float3 finalColor = lerp(cellColor, BorderColor, finalBorderMask);

    // --- Debug Modes ---
    if (DebugMode == 1) { // Grid Cell Index
        return float4(frac(cell / 16.0), 0.0, 1.0); // Visualize cell index pattern
    }
    else if (DebugMode == 2) { // Final Border Mask
        return float4(finalBorderMask.xxx, 1.0);
    }
    else if (DebugMode == 3) { // Cell Center Sample Points Viz
        float gridSizeF = gridSizeFinal * ReShade::ScreenSize.y;
        if (gridSizeF <= 0.0) return float4(1.0,0.0,1.0,1.0); // Error color

        float2 centerP = ReShade::ScreenSize * 0.5;
        float2 cellCenterRotated = (cell + 0.5) * gridSizeF;
        float2 cellCenterUnrotated = AS_TiltedGrid::RotatePoint(cellCenterRotated, -rotation);
        float2 cellCenterPixel = cellCenterUnrotated + centerP;
        float2 sampleUV = saturate(cellCenterPixel / ReShade::ScreenSize);
        float dist = length(texcoord - sampleUV);
        float threshold = 1.5 * ReShade::PixelSize.y;
        float is_center_flag = (dist < threshold) ? 1.0 : 0.0;
        float3 debug_color = lerp(cellColor * 0.7, float3(0.0, 1.0, 0.0), is_center_flag); // Green if close, dimmed cellColor otherwise
        return float4(debug_color, 1.0);
    }
     else if (DebugMode == 4) { // Square Border Mask Only
        return float4(squareBorderMask.xxx, 1.0);
    }
     else if (DebugMode == 5) { // Chamfer Mask Only
        return float4(chamferMask.xxx, 1.0);
    }

    // --- Final Blending ---
    float3 blendedColor = AS_applyBlend(finalColor, orig.rgb, BlendMode);
    return float4(lerp(orig.rgb, blendedColor, BlendAmount), orig.a);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_TiltedGrid < ui_label = "[AS] VFX: Tilted Grid"; ui_tooltip = "Pixelates the image into a rotatable grid with customizable borders and corner chamfers."; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_TiltedGrid;
    }
}

#endif // __AS_VFX_TiltedGrid_1_fx
