/**
 * AS_Perspective.1.fxh - Standardized Perspective Controls for AS StageFX
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * Provides a standardized set of UI controls and helper functions for applying 
 * 3D perspective transformations to 2D coordinates. This allows for consistent
 * perspective effects across different shaders.
 *
 * FEATURES:
 * - UI macro for easy integration of perspective controls (Pitch, Yaw, Z Offset, Focal Length).
 * - Helper function to apply the perspective transformation.
 * - Designed for use within the AS StageFX framework.
 *
 * IMPLEMENTATION OVERVIEW:
 * 1. The AS_PERSPECTIVE_UI macro declares uniform variables for perspective parameters.
 * 2. The AS_applyPerspectiveTransform function takes UV coordinates and perspective
 *    parameters to compute transformed UVs. It uses a standard perspective projection
 *    matrix approach.
 *
 * ===================================================================================
 */

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_Perspective_1_fx
#define __AS_Perspective_1_fx

// ============================================================================
// INCLUDES
// ============================================================================
// #include "ReShade.fxh" // Included by the parent shader
// #include "AS_Utils.1.fxh" // Included by the parent shader

// ============================================================================
// UI DECLARATIONS (MACRO)
// ============================================================================

#ifndef AS_PERSPECTIVE_UI
#define AS_PERSPECTIVE_UI(RotationAngles, ZOffset, FocalLength, CategoryName) \
    uniform float2 RotationAngles < ui_type = "slider"; ui_label = "Perspective Pitch (X), Yaw (Y)"; ui_tooltip = "Controls the vertical (Pitch X) and horizontal (Yaw Y) tilt of the perspective. Both range from -90 to +90 degrees."; ui_min = -90.0; ui_max = 90.0; ui_step = 0.1; ui_category = CategoryName; > = float2(0.0, 0.0); \
    uniform float ZOffset < ui_type = "slider"; ui_label = "Perspective Z Offset"; ui_tooltip = "Controls the distance of the plane from the camera (zoom). Positive values move plane away, negative values move it closer."; ui_min = -2.0; ui_max = 2.0; ui_step = 0.01; ui_category = CategoryName; > = 0.0; \
    uniform float FocalLength < ui_type = "slider"; ui_label = "Perspective Focal Length"; ui_tooltip = "Controls the field of view. Higher values = narrower FOV (telephoto), lower values = wider FOV."; ui_min = 0.1; ui_max = 5.0; ui_step = 0.01; ui_category = CategoryName; > = 1.0;
#endif

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Applies a 3D perspective transformation to 2D UV coordinates.
 * texcoord: The input 2D texture coordinates (typically 0-1 range, centered, with x already scaled for aspect ratio).
 * rotation_angles_deg: A float2 containing Pitch (X) and Yaw (Y) rotation in degrees.
 * z_offset: Translation along the Z-axis. Positive values move the plane further away.
 * focal_length: The focal length of the virtual camera.
 * Returns the transformed 2D UV coordinates.
 */
float2 AS_applyPerspectiveTransform(float2 texcoord, float2 rotation_angles_deg, float z_offset, float focal_length)
{
    float pitch_deg = rotation_angles_deg.x;
    float yaw_deg = rotation_angles_deg.y;

    // Convert angles to radians
    float pitch_rad = radians(pitch_deg);
    float yaw_rad = radians(yaw_deg);

    // Create rotation matrices
    float cos_pitch = cos(pitch_rad);
    float sin_pitch = sin(pitch_rad);
    float cos_yaw = cos(yaw_rad);
    float sin_yaw = sin(yaw_rad);

    // 3D point (aspect corrected, centered UVs)
    // Input texcoord is assumed to be already centered around (0,0)
    // e.g., texcoord.x ranges from -0.5 * aspect_ratio to 0.5 * aspect_ratio
    // and texcoord.y ranges from -0.5 to 0.5
    float3 pnt = float3(texcoord.x, texcoord.y, 0.0);

    // Apply pitch (rotation around X-axis)
    pnt = float3(pnt.x, pnt.y * cos_pitch - pnt.z * sin_pitch, pnt.y * sin_pitch + pnt.z * cos_pitch);
    // Apply yaw (rotation around Y-axis)
    pnt = float3(pnt.x * cos_yaw + pnt.z * sin_yaw, pnt.y, -pnt.x * sin_yaw + pnt.z * cos_yaw);

    // Apply Z offset (translation along Z-axis)
    // The plane is initially at Z=0. We add z_offset to move it.
    // The camera is at Z = -focal_length.
    // So, the distance from camera to plane's new Z is focal_length + pnt.z + z_offset
    pnt.z += z_offset;

    // Perspective projection
    // The camera is at (0,0, -focal_length) looking towards positive Z.
    // The projection plane is at Z=0.
    // We project the pnt (pnt.x, pnt.y, pnt.z + focal_length) onto the Z=focal_length plane relative to camera.
    // Or, more simply, project (pnt.x, pnt.y, pnt.z) onto a plane at distance 'focal_length' from the pnt, towards the camera.
    
    // Perspective division:
    // projected_x = (pnt.x * focal_length) / (focal_length + pnt.z);
    // projected_y = (pnt.y * focal_length) / (focal_length + pnt.z);
    // The 'focal_length + pnt.z' term is the effective distance from the camera's Z position to the pnt's Z position.
    // If pnt.z is positive (moved away), effective distance increases, shrinking the projection.
    // If pnt.z is negative (moved closer), effective distance decreases, enlarging the projection.
    
    float perspective_divisor = (focal_length + pnt.z);
    if (abs(perspective_divisor) < 1e-5f) perspective_divisor = 1e-5f; // Avoid division by zero

    float2 projected_uv;
    projected_uv.x = (pnt.x * focal_length) / perspective_divisor;
    projected_uv.y = (pnt.y * focal_length) / perspective_divisor;

    // The result is still centered. The calling shader will need to uncenter it.
    // e.g., projected_uv + 0.5
    return projected_uv;
}

#endif // __AS_Perspective_1_fx


