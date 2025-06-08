/**
 * AS_Palette_Styles.1.fxh - Color palette style definitions for AstrayFX shaders
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_Palette_Styles_1_fxh
#define __AS_Palette_Styles_1_fxh

// This file assumes AS_PALETTE_COLORS is defined in the including file (e.g., AS_Palette.1.fxh)
// before this file is included.

// --- Palette Style Constants ---
// Define palette modes for all shaders
#define AS_PALETTE_CUSTOM       0  // Custom palette should be index 0 to avoid breaking presets when adding new palettes
#define AS_PALETTE_CLASSIC_VU   1
#define AS_PALETTE_BLUE         2
#define AS_PALETTE_SUNSET       3
#define AS_PALETTE_NEON         4
#define AS_PALETTE_RETRO        5
#define AS_PALETTE_BLUEWAVE     6
#define AS_PALETTE_BRIGHT_LIGHTS 7
#define AS_PALETTE_DISCO        8
#define AS_PALETTE_ELECTRONICA  9
#define AS_PALETTE_INDUSTRIAL  10
#define AS_PALETTE_METAL       11
#define AS_PALETTE_MONOTONE    12
#define AS_PALETTE_PASTEL_POP  13
#define AS_PALETTE_REDLINE     14
#define AS_PALETTE_RAINBOW     15
#define AS_PALETTE_FIRE        16
#define AS_PALETTE_AQUA        17
#define AS_PALETTE_VIRIDIS     18
#define AS_PALETTE_DEEP_PURPLE 19
#define AS_PALETTE_GROOVY      20
#define AS_PALETTE_VAPORWAVE   21
#define AS_PALETTE_AURORA      22
#define AS_PALETTE_ELECTRIC    23
#define AS_PALETTE_MYSTIC_NIGHT 24
// Note: AS_PALETTE_CUSTOM is defined in AS_Palette.1.fxh

// Total number of built-in palettes (including custom)
#define AS_PALETTE_COUNT 25

// --- Standard Palette Arrays ---
// All palettes standardized to 5 colors (AS_PALETTE_COLORS) for consistent interface
// HLSL doesn't support true multidimensional arrays, so we use a flattened array
// Custom palette is not in this array - it's handled separately in AS_getPaletteColor
static const float3 AS_PALETTES[(AS_PALETTE_COUNT-1) * AS_PALETTE_COLORS] = {
    // Classic VU (green -> yellow -> red)
    float3(0.0, 1.0, 0.0), float3(0.7, 1.0, 0.0), float3(1.0, 1.0, 0.0), float3(1.0, 0.5, 0.0), float3(1.0, 0.0, 0.0),
    // Blue
    float3(0.2, 0.6, 1.0), float3(0.3, 0.8, 1.0), float3(0.5, 1.0, 1.0), float3(0.7, 0.9, 1.0), float3(1.0, 1.0, 1.0),
    // Sunset
    float3(1.0, 0.4, 0.0), float3(1.0, 0.7, 0.0), float3(1.0, 1.0, 0.0), float3(1.0, 0.0, 0.5), float3(0.5, 0.0, 1.0),
    // Neon
    float3(0.0, 1.0, 1.0), float3(0.0, 0.5, 1.0), float3(0.5, 0.0, 1.0), float3(1.0, 0.0, 1.0), float3(1.0, 0.0, 0.5),
    // Retro
    float3(1.0, 0.0, 0.5), float3(1.0, 0.5, 0.0), float3(1.0, 1.0, 0.0), float3(0.0, 1.0, 0.5), float3(0.0, 0.5, 1.0),
    // Bluewave
    float3(0.2, 0.6, 1.0), float3(0.4, 0.8, 1.0), float3(0.6, 0.9, 1.0), float3(0.8, 1.0, 1.0), float3(0.0, 0.4, 1.0),
    // Bright Lights
    float3(1.0, 1.0, 0.6), float3(0.6, 1.0, 1.0), float3(1.0, 0.6, 1.0), float3(1.0, 0.8, 0.6), float3(0.6, 0.8, 1.0),
    // Disco
    float3(1.0, 0.2, 0.6), float3(1.0, 0.8, 0.2), float3(0.2, 1.0, 0.8), float3(0.8, 0.2, 1.0), float3(0.2, 0.8, 1.0),
    // Electronica
    float3(0.0, 1.0, 0.7), float3(0.2, 0.6, 1.0), float3(0.7, 0.0, 1.0), float3(1.0, 0.2, 0.6), float3(0.0, 1.0, 0.3),
    // Industrial
    float3(0.8, 0.8, 0.7), float3(0.5, 0.5, 0.5), float3(1.0, 0.6, 0.1), float3(0.2, 0.2, 0.2), float3(0.9, 0.7, 0.2),
    // Metal
    float3(0.7, 0.7, 0.7), float3(0.2, 0.2, 0.2), float3(1.0, 0.2, 0.2), float3(0.7, 0.5, 0.2), float3(0.3, 0.3, 0.3),
    // Monotone
    float3(0.9, 0.9, 0.9), float3(0.7, 0.7, 0.7), float3(0.5, 0.5, 0.5), float3(0.3, 0.3, 0.3), float3(0.1, 0.1, 0.1),
    // Pastel Pop
    float3(0.98, 0.80, 0.89), float3(0.80, 0.93, 0.98), float3(0.98, 0.96, 0.80), float3(0.80, 0.98, 0.87), float3(0.93, 0.80, 0.98),
    // Redline
    float3(1.0, 0.2, 0.2), float3(1.0, 0.4, 0.4), float3(1.0, 0.6, 0.6), float3(1.0, 0.8, 0.8), float3(1.0, 0.0, 0.0),
    // Rainbow
    float3(0.2, 0.4, 1.0), float3(0.0, 1.0, 0.4), float3(1.0, 1.0, 0.0), float3(1.0, 0.6, 0.0), float3(1.0, 0.0, 0.0),
    // Fire
    float3(0.2, 0.0, 0.0), float3(0.8, 0.2, 0.0), float3(1.0, 0.6, 0.0), float3(1.0, 1.0, 0.2), float3(1.0, 1.0, 1.0),
    // Aqua
    float3(0.0, 0.2, 0.4), float3(0.0, 0.8, 1.0), float3(0.2, 1.0, 0.8), float3(0.6, 1.0, 1.0), float3(1.0, 1.0, 1.0),
    // Viridis
    float3(0.2, 0.2, 0.4), float3(0.1, 0.4, 0.4), float3(0.2, 0.8, 0.4), float3(0.6, 0.9, 0.2), float3(0.9, 0.9, 0.2),
    // Deep Purple
    float3(0.10, 0.02, 0.25), float3(0.18, 0.04, 0.45), float3(0.25, 0.05, 0.65), float3(0.45, 0.05, 0.85), float3(0.85, 0.12, 0.95),
    // Groovy
    float3(0.98, 0.62, 0.11), float3(0.98, 0.11, 0.36), float3(0.36, 0.11, 0.98), float3(0.11, 0.98, 0.62), float3(0.98, 0.89, 0.11),
    // Vaporwave
    float3(0.58, 0.36, 0.98), float3(0.98, 0.36, 0.82), float3(0.36, 0.98, 0.98), float3(0.98, 0.82, 0.36), float3(0.36, 0.58, 0.98),
    // Aurora
    float3(0.11, 0.98, 0.62), float3(0.11, 0.62, 0.98), float3(0.36, 0.98, 0.36), float3(0.62, 0.11, 0.98), float3(0.11, 0.98, 0.98),
    // Electric
    float3(0.98, 0.98, 0.36), float3(0.36, 0.98, 0.98), float3(0.36, 0.36, 0.98), float3(0.98, 0.36, 0.98), float3(0.98, 0.36, 0.36),
    // Mystic Night
    float3(0.11, 0.11, 0.36), float3(0.36, 0.11, 0.36), float3(0.11, 0.36, 0.36), float3(0.36, 0.36, 0.11), float3(0.11, 0.11, 0.11)
};

// Standard palette UI strings for combo boxes
#define AS_PALETTE_ITEMS "Custom\0Classic VU\0Blue\0Sunset\0Neon\0Retro\0Bluewave\0Bright Lights\0Disco\0Electronica\0Industrial\0Metal\0Monotone\0Pastel Pop\0Redline\0Rainbow\0Fire\0Aqua\0Viridis\0Deep Purple\0Groovy\0Vaporwave\0Aurora\0Electric\0Mystic Night\0"

#endif // __AS_Palette_Styles_1_fxh

