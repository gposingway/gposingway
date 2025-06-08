/**
 * AS_VFX_RadiantFire.1.fx - Reactive fire simulation that radiates from subject edges
 * Author: Leon Aquitaine
 * License: Creative Commons Attribution 4.0 International
 * You are free to use, share, and adapt this shader for any purpose, including commercially, as long as you provide attribution.
 * 
 * CREDITS:
 * Original: "301's Fire Shader - Remix 3" by mu6k (2016-07-27)
 * Source: https://www.shadertoy.com/view/4ttGWM
 * Adapted for ReShade with enhanced controls and AS StageFX framework integration.
 * 
 * ===================================================================================
 *
 * DESCRIPTION:
 * A fire simulation that generates flames radiating from subject edges.
 * Rotation now affects the direction of internal physics forces.
 */

// ============================================================================
// INCLUDES
// ============================================================================
#include "ReShade.fxh"
#include "AS_Utils.1.fxh"
#include "AS_Palette.1.fxh"

// ============================================================================
// TECHNIQUE GUARD - Prevents duplicate loading of the same shader
// ============================================================================
#ifndef __AS_VFX_RadiantFire_1_fx_v2_9 // Updated guard
#define __AS_VFX_RadiantFire_1_fx_v2_9

// ============================================================================
// TEXTURES & SAMPLERS for Flame Buffer (Ping-Pong Style)
// ============================================================================
// TODO: Convert to AS_CREATE_TEX_SAMPLER once the macro supports UI attributes
// for texture elements. Currently kept as separate declarations due to UI requirements.

texture FlameStateBuffer_A < ui_label = "Flame State Buffer A (Persistent)"; >
{
    Width = BUFFER_WIDTH; 
    Height = BUFFER_HEIGHT; 
    Format = RGBA16F;
};
sampler SamplerFlameState_A
{
    Texture = FlameStateBuffer_A;
    AddressU = CLAMP; 
    AddressV = CLAMP;
    MinFilter = LINEAR; 
    MagFilter = LINEAR; 
    MipFilter = NONE;
};

texture FlameStateBuffer_B < ui_label = "Flame State Buffer B (Temporary)"; >
{
    Width = BUFFER_WIDTH; 
    Height = BUFFER_HEIGHT; 
    Format = RGBA16F;
};
sampler SamplerFlameState_B
{
    Texture = FlameStateBuffer_B;
    AddressU = CLAMP; 
    AddressV = CLAMP;
    MinFilter = LINEAR; 
    MagFilter = LINEAR; 
    MipFilter = NONE;
};

// ============================================================================
// NAMESPACE
// ============================================================================
namespace ASRadiantFire {

// ============================================================================
// CONSTANTS 
// ============================================================================
static const float TURBULENCE_START_FREQ = 11.0f;
static const float TURBULENCE_MAX_FREQ = 50.0f;
static const float TURBULENCE_FREQ_MULTIPLIER = 1.2f;
static const float TURBULENCE_VEC_INCREMENT_X = 1.07f;
static const float TURBULENCE_VEC_INCREMENT_Y = 0.83f;
static const float TURBULENCE_WAVE_AMPLITUDE = 0.4f;
static const float TURBULENCE_TIME_SCALE = 6.0f;
static const float TURBULENCE_DISTORTION_THRESHOLD = 0.001f;
static const float TURBULENCE_DISTORTION_AMOUNT = 0.5f;
static const float TURBULENCE_START_Y_COMPONENT = 7.0f;
static const float ADVECTION_PIXEL_SCALE = 20.0f;
static const float MIN_LENGTH_FOR_NORMALIZATION = 0.0001f;
static const float KERNEL_SIZE = 9.0f; // 3x3 kernel
static const float DIFFUSION_BLEND_FACTOR = 0.5f;
static const float INJECTION_THRESHOLD = 0.1f;
static const float INJECTION_VELOCITY_SCALE = 0.1f;
static const float EDGE_THRESHOLD_BASE = 0.5f;
static const float TEMP_THRESHOLD = 0.01f;
static const float NORMALIZATION_TERM = 0.001f; 
static const float DEBUG_VECTOR_SCALE = 5.0f;
static const float DEBUG_VECTOR_OFFSET = 0.5f;
static const float MS_TO_SEC_CONVERSION = 0.001f;
static const float TIME_SCALE_NORMAL = 1.0f;
static const float DEFAULT_SUBJECT_DEPTH_CUTOFF = 0.1f;
static const float DEFAULT_EDGE_DETECTION_SENSITIVITY = 50.0f;
static const float DEFAULT_EDGE_SOFTNESS = 0.02f;
static const bool DEFAULT_OVERLAY_SUBJECT = true;
static const float2 DEFAULT_FIRE_REPULSION_CENTER_POS = float2(0.5f, 1.0f);
static const float DEFAULT_SOURCE_INJECTION_STRENGTH = 0.5f;
static const float DEFAULT_ADVECTION_STRENGTH = 1.0f;
static const float DEFAULT_REPULSION_STRENGTH = 0.002f;
static const float DEFAULT_GENERAL_BUOYANCY = 0.0005f;
static const float DEFAULT_DRAFT_SPEED = 0.0f;
static const float DEFAULT_DIFFUSION = 0.0005f;
static const float DEFAULT_DISSIPATION = 0.01f;
static const float DEFAULT_VELOCITY_DAMPING = 0.02f;
static const float DEFAULT_GLSL_TURBULENCE_ADVECTION_INFLUENCE = 0.005f;
static const float DEFAULT_FLAME_INTENSITY = 1.5f;
static const float DEFAULT_FLAME_COLOR_THRESHOLD_CORE = 1.0f;
static const float DEFAULT_FLAME_COLOR_THRESHOLD_MID = 0.5f;

// ============================================================================
// UNIFORMS
// ============================================================================

// --- Flame Physics ---
uniform float AdvectionStrength < ui_type = "slider"; ui_label = "Velocity Influence"; ui_tooltip = "How strongly flames follow their existing velocity (advection)."; ui_min = 0.0; ui_max = 5.0; ui_step = 0.01; ui_category = "Flame Physics"; > = DEFAULT_ADVECTION_STRENGTH;
uniform float RepulsionStrength < ui_type = "slider"; ui_label = "Repulsion Strength"; ui_tooltip = "How strongly flames are pushed from the Repulsion Center. Affected by Rotation."; ui_min = 0.0; ui_max = 0.01; ui_step = 0.0001; ui_category = "Flame Physics"; > = DEFAULT_REPULSION_STRENGTH;
uniform float GeneralBuoyancy < ui_type = "slider"; ui_label = "Buoyancy"; ui_tooltip = "Constant 'upwards' drift for all flames. Affected by Rotation."; ui_min = 0.0; ui_max = 0.005; ui_step = 0.00001; ui_category = "Flame Physics"; > = DEFAULT_GENERAL_BUOYANCY;
uniform float DraftSpeed < ui_type = "slider"; ui_label = "Draft Speed"; ui_tooltip = "Constant directional draft. Positive = 'up', Negative = 'down'. Affected by Rotation."; ui_min = -0.005; ui_max = 0.005; ui_step = 0.00001; ui_category = "Flame Physics"; > = DEFAULT_DRAFT_SPEED;
uniform float Diffusion < ui_type = "slider"; ui_label = "Diffusion (Spread)"; ui_tooltip = "How much the flame spreads/blurs out over time."; ui_min = 0.0; ui_max = 0.005; ui_step = 0.0001; ui_category = "Flame Physics"; > = DEFAULT_DIFFUSION;
uniform float Dissipation < ui_type = "slider"; ui_label = "Dissipation (Fade)"; ui_tooltip = "Rate at which flame intensity fades (cools down)."; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_category = "Flame Physics"; > = DEFAULT_DISSIPATION;
uniform float VelocityDamping < ui_type = "slider"; ui_label = "Velocity Damping"; ui_tooltip = "How quickly flame velocity fades over time."; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_category = "Flame Physics"; > = DEFAULT_VELOCITY_DAMPING;
uniform float GLSLTurbulenceAdvectionInfluence < ui_type = "slider"; ui_label = "Advection Influence"; ui_tooltip = "How much the GLSL turbulence pattern displaces advecting flames. Affected by Rotation."; ui_min = 0.0; ui_max = 0.1; ui_step = 0.001; ui_category = "Flame Physics"; > = DEFAULT_GLSL_TURBULENCE_ADVECTION_INFLUENCE;

// --- Flame Appearance ---
AS_PALETTE_SELECTION_UI(FlamePalette, "Color: Palette", AS_PALETTE_FIRE, "Flame Appearance") 
AS_DECLARE_CUSTOM_PALETTE(Flame, "Flame Appearance") // Label for custom palette colors set by AS_Utils
uniform float FlameIntensity < ui_type = "slider"; ui_label = "Overall Intensity"; ui_tooltip = "Master brightness multiplier for the rendered flame."; ui_min = 0.0; ui_max = 10.0; ui_step = 0.01; ui_category = "Flame Appearance"; > = DEFAULT_FLAME_INTENSITY;
uniform float FlameColorThresholdCore < ui_type = "slider"; ui_label = "Core Temperature"; ui_tooltip = "Temperature threshold for the flame's core color."; ui_min = 0.5; ui_max = 2.0; ui_step = 0.01; ui_category = "Flame Appearance"; > = DEFAULT_FLAME_COLOR_THRESHOLD_CORE;
uniform float FlameColorThresholdMid < ui_type = "slider"; ui_label = "Mid Temperature"; ui_tooltip = "Temperature threshold for the flame's mid color."; ui_min = 0.1; ui_max = 1.0; ui_step = 0.01; ui_category = "Flame Appearance"; > = DEFAULT_FLAME_COLOR_THRESHOLD_MID;

// --- Global Controls ---
uniform float AnimationSpeed < ui_type = "slider"; ui_label = "Animation Speed"; ui_tooltip = "Controls the overall speed of the fire animation."; ui_min = 0.1f; ui_max = 3.0f; ui_step = 0.05f; ui_category = "Animation"; > = TIME_SCALE_NORMAL;
uniform float2 FireRepulsionCenterPos < ui_type = "drag"; ui_label = "Repulsion Center (XY)"; ui_tooltip = "Normalized screen position (0-1) the fire radiates AWAY from."; ui_min = 0.0; ui_max = 1.0; ui_speed = 0.01; ui_category = "Animation"; > = DEFAULT_FIRE_REPULSION_CENTER_POS;

// --- Subject & Edges ---

AS_STAGEDEPTH_UI(SubjectDepthCutoff)
uniform float EdgeDetectionSensitivity < ui_type = "slider"; ui_label = "Depth Sensitivity"; ui_tooltip = "Sensitivity of edge detection based on depth changes."; ui_min = 1.0; ui_max = 200.0; ui_step = 1.0; ui_category = "Stage"; > = DEFAULT_EDGE_DETECTION_SENSITIVITY;
uniform float EdgeSoftness < ui_type = "slider"; ui_label = "Depth Edge"; ui_tooltip = "Softness of the detected subject edges for fire generation."; ui_min = 0.001; ui_max = 0.5; ui_step = 0.001; ui_category = "Stage"; > = DEFAULT_EDGE_SOFTNESS;
uniform float SourceInjectionStrength < ui_type = "slider"; ui_label = "Edge Fire Strength"; ui_tooltip = "Amount of 'heat' injected at subject edges to start flames."; ui_min = 0.0; ui_max = 1.0; ui_step = 0.01; ui_category = "Stage"; > = DEFAULT_SOURCE_INJECTION_STRENGTH;
uniform bool OverlaySubject < ui_type = "bool"; ui_label = "Subject: Overlay on Fire"; ui_tooltip = "If checked, the original subject is drawn on top of the fire."; ui_category = "Stage"; > = DEFAULT_OVERLAY_SUBJECT;

AS_ROTATION_UI(EffectSnapRotation, EffectFineRotation)

// --- Output & Blending ---
AS_BLENDMODE_UI_DEFAULT(OutputBlendMode, AS_BLEND_LIGHTEN) // Uses ui_category "Final Mix" from AS_Utils
AS_BLENDAMOUNT_UI(OutputBlendAmount) // Uses ui_category "Final Mix" from AS_Utils

// --- Debug ---
AS_DEBUG_UI("Off\0Subject Mask\0Edge Factor\0Flame Buffer Temp (R)\0Flame Buffer Vel (GB)\0Turbulence Displacement (Rotated RG)\0Rotated Buoyancy Dir\0") // Corrected separator

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

float GetTimeWithSpeed() {
    return AS_getTime() * AnimationSpeed; 
}

float2 RotateVector(float2 vec, float angle_rad) {
    float s = sin(angle_rad);
    float c = cos(angle_rad);
    return float2(
        vec.x * c - vec.y * s,
        vec.x * s + vec.y * c
    );
}

float2 GetGLSLTurbulenceDisplacement(float2 screen_uv, float time_sec)
{
    float2 r_screensize = ReShade::ScreenSize.xy;
    float2 p_centered_ndc = screen_uv * 2.0f - 1.0f; 
    p_centered_ndc.y *= -1.0f; 
    float2 p_initial = p_centered_ndc * float2(r_screensize.x / r_screensize.y, 1.0f); 
    float2 p_distorted = p_initial;
    if (abs(p_initial.y) > TURBULENCE_DISTORTION_THRESHOLD) {
         p_distorted *= 1.0f - TURBULENCE_DISTORTION_AMOUNT / float2(1.0f / p_initial.y, 1.0f + dot(p_initial, p_initial)); 
    }
    
    float2 p_scrolled = p_distorted;
    p_scrolled.y -= time_sec; 

    float2 p_loop = p_scrolled;
    float f_freq = TURBULENCE_START_FREQ;
    float2 r_vec = float2(f_freq, TURBULENCE_START_Y_COMPONENT); 

    [loop]
    for ( ; f_freq < TURBULENCE_MAX_FREQ; f_freq *= TURBULENCE_FREQ_MULTIPLIER )
    {
        r_vec.x += TURBULENCE_VEC_INCREMENT_X; 
        r_vec.y += TURBULENCE_VEC_INCREMENT_Y;
        float2 sin_r = sin(r_vec);
        float2 cos_r = cos(r_vec);
        p_loop += TURBULENCE_WAVE_AMPLITUDE * sin(f_freq * dot(p_loop, sin_r) + TURBULENCE_TIME_SCALE * time_sec) * cos_r / f_freq;
    }
    
    float2 displacement_in_p_space = p_loop - p_scrolled;
    float2 displacement_uv = displacement_in_p_space;
    displacement_uv.x /= (r_screensize.x / r_screensize.y); 
    displacement_uv.y *= -1.0f; 

    return displacement_uv;
}

// ============================================================================
// PIXEL SHADERS
// ============================================================================

float4 UpdateFlameStatePS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float4 prevState = tex2D(SamplerFlameState_A, texcoord);
    float prevTemp = prevState.r; 
    float2 prevVel = prevState.gb;   

    float newTemp = prevTemp;
    float2 newVel = prevVel;

    float2 pixelSize = ReShade::PixelSize;
    float time_sec = GetTimeWithSpeed();

    float rotationAngle = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);

    float2 base_turbulent_uv_offset = GetGLSLTurbulenceDisplacement(texcoord, time_sec);
    float2 rotated_turbulent_uv_offset = RotateVector(base_turbulent_uv_offset, rotationAngle);
    
    float2 baseAdvectLookup = texcoord - prevVel * AdvectionStrength * pixelSize * ADVECTION_PIXEL_SCALE; 
    float2 finalAdvectLookup = baseAdvectLookup + rotated_turbulent_uv_offset * GLSLTurbulenceAdvectionInfluence;
    
    float4 advectedState = tex2D(SamplerFlameState_A, finalAdvectLookup);
    newTemp = advectedState.r;
    newVel  = advectedState.gb;

    float2 unrotatedRepulsionDir = float2(0.0f, 0.0f);
    if (length(texcoord - FireRepulsionCenterPos) > MIN_LENGTH_FOR_NORMALIZATION) {
        unrotatedRepulsionDir = normalize(texcoord - FireRepulsionCenterPos); 
    }
    float2 rotatedRepulsionDir = RotateVector(unrotatedRepulsionDir, rotationAngle);
    newVel += rotatedRepulsionDir * RepulsionStrength;

    float2 baseUpVector_screenspace = float2(0.0f, -1.0f); 
    float2 rotatedUpVector = RotateVector(baseUpVector_screenspace, rotationAngle);

    newVel += rotatedUpVector * GeneralBuoyancy; 
    newVel += rotatedUpVector * DraftSpeed;     

    if (Diffusion > AS_EPSILON) 
    {
        float tempSum = 0.0f;
        [loop] for (int y = -1; y <= 1; ++y) {
            [loop] for (int x = -1; x <= 1; ++x) {
                tempSum += tex2D(SamplerFlameState_A, texcoord + float2(x, y) * Diffusion).r;
            }
        }
        newTemp = lerp(newTemp, tempSum / KERNEL_SIZE, DIFFUSION_BLEND_FACTOR); 
    }

    newTemp *= (1.0f - Dissipation);
    newVel  *= (1.0f - VelocityDamping);
    newTemp = max(0.0f, newTemp); 

    float linearDepth = ReShade::GetLinearizedDepth(texcoord);
    float subjectMask = (linearDepth < SubjectDepthCutoff) ? 1.0f : 0.0f;
    float depth_l = ReShade::GetLinearizedDepth(texcoord - float2(pixelSize.x, 0.0f));
    float depth_r = ReShade::GetLinearizedDepth(texcoord + float2(pixelSize.x, 0.0f));
    float depth_u = ReShade::GetLinearizedDepth(texcoord - float2(0.0f, pixelSize.y));
    float depth_d = ReShade::GetLinearizedDepth(texcoord + float2(0.0f, pixelSize.y));
    float sobel_x = -depth_l + depth_r;
    float sobel_y = -depth_u + depth_d; 
    float edgeFactorRaw = length(float2(sobel_x, sobel_y)) * EdgeDetectionSensitivity;
    float edgeFactor = smoothstep(EDGE_THRESHOLD_BASE - EdgeSoftness, EDGE_THRESHOLD_BASE + EdgeSoftness, edgeFactorRaw) * subjectMask;

    if (edgeFactor > INJECTION_THRESHOLD) {
        newTemp += SourceInjectionStrength * edgeFactor; 
        float2 initialVelDir = rotatedRepulsionDir; 
        if (length(initialVelDir) < MIN_LENGTH_FOR_NORMALIZATION) { 
            initialVelDir = rotatedUpVector; 
        }
        newVel += initialVelDir * SourceInjectionStrength * edgeFactor * INJECTION_VELOCITY_SCALE; 
    }
    
    newTemp = saturate(newTemp); 

    return float4(newTemp, newVel, 1.0f); 
}

float4 CopyStatePS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    return tex2D(SamplerFlameState_B, texcoord); 
}

float4 RenderFlamePS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    float3 baseSceneColor = tex2D(ReShade::BackBuffer, texcoord).rgb; 
    float4 flameState = tex2D(SamplerFlameState_A, texcoord); 

    float temp = flameState.r; 
    float3 flameVisualColor = float3(0.0f, 0.0f, 0.0f);

    float3 actualFlameColorOuter, actualFlameColorMid, actualFlameColorCore;
    if (FlamePalette == AS_PALETTE_CUSTOM) {
        actualFlameColorOuter = AS_GET_CUSTOM_PALETTE_COLOR(Flame, 0);
        actualFlameColorMid   = AS_GET_CUSTOM_PALETTE_COLOR(Flame, 2);
        actualFlameColorCore  = AS_GET_CUSTOM_PALETTE_COLOR(Flame, 4);
    } else {
        actualFlameColorOuter = AS_getPaletteColor(FlamePalette, 0);
        actualFlameColorMid   = AS_getPaletteColor(FlamePalette, 2);
        actualFlameColorCore  = AS_getPaletteColor(FlamePalette, 4);
    }

    if (temp > TEMP_THRESHOLD) {
        float midThresholdHalf = FlameColorThresholdMid * 0.5f;
        float3 colorLerp1 = lerp(actualFlameColorOuter, actualFlameColorMid,
                                  saturate((temp - midThresholdHalf) / (midThresholdHalf + NORMALIZATION_TERM)));
        flameVisualColor = lerp(colorLerp1, actualFlameColorCore,
                                  saturate((temp - FlameColorThresholdMid) / (FlameColorThresholdCore - FlameColorThresholdMid + NORMALIZATION_TERM)));
    }
    
    float flameAlpha = saturate(temp * FlameIntensity); 
    float3 premultipliedFlame = flameVisualColor * flameAlpha; 
    float3 colorWithFlame = premultipliedFlame + baseSceneColor * (1.0f - flameAlpha); 
    
    float linearDepth = ReShade::GetLinearizedDepth(texcoord); 
    float subjectMask = (linearDepth < SubjectDepthCutoff) ? 1.0f : 0.0f;
    float3 finalOutputColor = colorWithFlame;
    if (OverlaySubject) {
        finalOutputColor = lerp(colorWithFlame, baseSceneColor, subjectMask);
    }
    
    float2 pixelSize_dbg = ReShade::PixelSize; 
    float depth_l_dbg = ReShade::GetLinearizedDepth(texcoord - float2(pixelSize_dbg.x, 0.0f)); 
    float depth_r_dbg = ReShade::GetLinearizedDepth(texcoord + float2(pixelSize_dbg.x, 0.0f));
    float depth_u_dbg = ReShade::GetLinearizedDepth(texcoord - float2(0.0f, pixelSize_dbg.y));
    float depth_d_dbg = ReShade::GetLinearizedDepth(texcoord + float2(0.0f, pixelSize_dbg.y));
    float sobel_x_dbg = -depth_l_dbg + depth_r_dbg;
    float sobel_y_dbg = -depth_u_dbg + depth_d_dbg; 
    float edgeFactorRaw_dbg = length(float2(sobel_x_dbg, sobel_y_dbg)) * EdgeDetectionSensitivity; 

    if (DebugMode > 0) {
        if (DebugMode == 1) return float4(subjectMask.xxx, 1.0f);       
        if (DebugMode == 2) return float4(saturate(edgeFactorRaw_dbg).xxx, 1.0f); 
        if (DebugMode == 3) return float4(temp.xxx, 1.0f); 
        if (DebugMode == 4) return float4(flameState.g * DEBUG_VECTOR_OFFSET + DEBUG_VECTOR_OFFSET, 
                                          flameState.b * DEBUG_VECTOR_OFFSET + DEBUG_VECTOR_OFFSET, 0.0f, 1.0f); 
        if (DebugMode == 5) { 
            float rotAngle = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
            float2 base_turb_disp = GetGLSLTurbulenceDisplacement(texcoord, GetTimeWithSpeed());
            float2 rotated_turb_disp = RotateVector(base_turb_disp, rotAngle);
            return float4(rotated_turb_disp.x * DEBUG_VECTOR_SCALE + DEBUG_VECTOR_OFFSET, 
                          rotated_turb_disp.y * DEBUG_VECTOR_SCALE + DEBUG_VECTOR_OFFSET, 0.0f, 1.0f);
        }
        if (DebugMode == 6) { 
            float rotAngle = AS_getRotationRadians(EffectSnapRotation, EffectFineRotation);
            float2 baseUp = float2(0.0f, -1.0f); 
            float2 rotatedDir = RotateVector(baseUp, rotAngle);
            return float4(rotatedDir.x * 0.5f + 0.5f, rotatedDir.y * 0.5f + 0.5f, 0.0f, 1.0f);
        }
    } 
    
    float4 finalColorWithAlpha = float4(finalOutputColor, 1.0f);
    float4 baseSceneColorWithAlpha = float4(baseSceneColor, 1.0f); 
    return AS_applyBlend(finalColorWithAlpha, baseSceneColorWithAlpha, OutputBlendMode, OutputBlendAmount);
}

// ============================================================================
// TECHNIQUE DEFINITION
// ============================================================================
technique AS_VFX_RadiantFire < 
    ui_label = "[AS] VFX: Radiant Fire"; 
    ui_tooltip = "Edge-based fire simulation with fluid dynamics that radiates from subject contours.";
>
{
    pass UpdateStatePass 
    {
        VertexShader = PostProcessVS;
        PixelShader = UpdateFlameStatePS;
        RenderTarget = FlameStateBuffer_B; 
        ClearRenderTargets = true; 
    }
    pass CopyStateToPersistentPass 
    {
        VertexShader = PostProcessVS;
        PixelShader = CopyStatePS;
        RenderTarget = FlameStateBuffer_A; 
        ClearRenderTargets = false; 
    }
    pass RenderFlameToScreenPass 
    {
        VertexShader = PostProcessVS;
        PixelShader = RenderFlamePS;
    }
}

} // namespace ASRadiantFire

#endif // __AS_VFX_RadiantFire_1_fx_v2_9 // Updated guard


