/**
 * AS_GFX_CinematicDiffusion.1.fx - High-Quality Cinematic Diffusion Filter
 * Author: Leon Aquitaine
 * License: CC BY 4.0
 *
 * ===================================================================================
 *
 * DESCRIPTION:
 * A flexible, high-quality shader that digitally replicates beloved diffusion
 * filters from cinematography. Provides built-in presets for instant filmic
 * effects and a fully customizable mode for tailored artistic expression. This
 * version uses a multi-pass bloom for superior quality, ideal for virtual
 * photography where performance is secondary to visual fidelity.
 *
 * FEATURES:
 * - 8 Presets mimicking classic filters (Pro-Mist, Hollywood Black Magic, etc.).
 * - Fully customizable mode for granular control over the effect.
 * - Multi-pass, downsampling bloom implementation for smooth, natural glows.
 * - Controls for highlight threshold, bloom intensity, radius, color, and halation.
 * - Anamorphic shaping to stretch the diffusion glow horizontally or vertically.
 *
 * ===================================================================================
 */

#ifndef __AS_GFX_CinematicDiffusion_1_fx
#define __AS_GFX_CinematicDiffusion_1_fx

#include "ReShade.fxh"
#include "AS_Utils.1.fxh"

// ============================================================================
// Render Targets for Multi-Pass Bloom
// ============================================================================
texture CinematicDiffusion_TexHighlight { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
texture CinematicDiffusion_TexBlur1 { Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA16F; };
texture CinematicDiffusion_TexBlur2 { Width = BUFFER_WIDTH / 4; Height = BUFFER_HEIGHT / 4; Format = RGBA16F; };
texture CinematicDiffusion_TexBlur3 { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RGBA16F; };
texture CinematicDiffusion_TexBlur4 { Width = BUFFER_WIDTH / 16; Height = BUFFER_HEIGHT / 16; Format = RGBA16F; };

sampler CinematicDiffusion_SampHighlight { Texture = CinematicDiffusion_TexHighlight; AddressU = CLAMP; AddressV = CLAMP; };
sampler CinematicDiffusion_SampBlur1 { Texture = CinematicDiffusion_TexBlur1; AddressU = CLAMP; AddressV = CLAMP; };
sampler CinematicDiffusion_SampBlur2 { Texture = CinematicDiffusion_TexBlur2; AddressU = CLAMP; AddressV = CLAMP; };
sampler CinematicDiffusion_SampBlur3 { Texture = CinematicDiffusion_TexBlur3; AddressU = CLAMP; AddressV = CLAMP; };
sampler CinematicDiffusion_SampBlur4 { Texture = CinematicDiffusion_TexBlur4; AddressU = CLAMP; AddressV = CLAMP; };


// ============================================================================
// UI: UNIFORMS
// ============================================================================
uniform int Preset < ui_type = "combo"; ui_label = "Filter Preset"; ui_items = "Custom\0Pro-Mist\0Black Pro-Mist\0Hollywood Black Magic\0Classic Soft\0Tiffen Satin\0Black Supermist\0Radiant Soft\0Pearlescent\0"; ui_category = "Preset"; > = 0;
uniform float HighlightThreshold <
 ui_text = "The following controls are only active when Filter Preset is set to 'Custom'. Preset selection will override these values.";
 ui_type = "slider"; ui_min = 0.0; ui_max = 1.0; ui_label = "Highlight Threshold"; ui_tooltip = "Luminance level above which diffusion occurs."; ui_category = "Custom Settings"; > = 0.7;
uniform float HighlightKnee < ui_type = "slider"; ui_min = 0.01; ui_max = 1.0; ui_label = "Highlight Soft Knee"; ui_tooltip = "Smoothness of the transition into the diffused area."; ui_category = "Custom Settings"; > = 0.2;
uniform float BloomIntensity < ui_type = "slider"; ui_min = 0.0; ui_max = 5.0; ui_label = "Bloom Intensity"; ui_tooltip = "Overall strength of the diffusion glow."; ui_category = "Custom Settings"; > = 1.0;
uniform float BloomRadius < ui_type = "slider"; ui_min = 0.0; ui_max = 1.0; ui_label = "Bloom Radius"; ui_tooltip = "The spread/size of the glow."; ui_category = "Custom Settings"; > = 1.0;
uniform float AnamorphicRatio < ui_type = "slider"; ui_min = -1.0; ui_max = 1.0; ui_label = "Anamorphic Ratio"; ui_tooltip = "Stretches the glow. Negative=Vertical, Positive=Horizontal."; ui_category = "Custom Settings"; > = 0.0;
uniform float3 BloomTint < ui_type = "color"; ui_label = "Bloom Color Tint"; ui_category = "Custom Settings"; > = float3(1.0, 1.0, 1.0);
uniform float HalationIntensity < ui_type = "slider"; ui_min = 0.0; ui_max = 1.0; ui_label = "Halation (Color Fringing)"; ui_tooltip = "Adds subtle chromatic aberration to the glow."; ui_category = "Custom Settings"; > = 0.0;
uniform float Contrast < ui_type = "slider"; ui_min = 0.5; ui_max = 1.5; ui_label = "Contrast Compensation"; ui_tooltip = "Recovers contrast lost from the diffusion."; ui_category = "Custom Settings"; > = 1.0;
AS_BLENDMODE_UI_DEFAULT(BlendMode, AS_BLEND_LIGHTEN)
AS_BLENDAMOUNT_UI(BlendAmount)

// ============================================================================
// SHADER LOGIC
// ============================================================================

void SetPresetParams(out float threshold, out float knee, out float intensity, out float radius, out float contrast, out float3 tint)
{
    // Default to custom slider values
    threshold = HighlightThreshold;
    knee = HighlightKnee;
    intensity = BloomIntensity;
    radius = BloomRadius;
    contrast = Contrast;
    tint = BloomTint;

    // Override with preset values
    switch (Preset)
    {
        case 1: // Pro-Mist
            threshold = 0.60; knee = 0.5; intensity = 1.2; radius = 1.0; contrast = 0.95; tint = float3(1.0, 0.98, 0.95); break;
        case 2: // Black Pro-Mist
            threshold = 0.65; knee = 0.4; intensity = 0.9; radius = 0.9; contrast = 1.05; tint = float3(1.0, 1.0, 1.0); break;
        case 3: // Hollywood Black Magic
            threshold = 0.70; knee = 0.5; intensity = 0.8; radius = 0.8; contrast = 1.0; tint = float3(1.0, 0.97, 0.96); break;
        case 4: // Classic Soft
            threshold = 0.75; knee = 0.3; intensity = 0.6; radius = 0.7; contrast = 1.0; tint = float3(1.0, 1.0, 1.0); break;
        case 5: // Tiffen Satin
            threshold = 0.80; knee = 0.2; intensity = 0.4; radius = 0.6; contrast = 1.02; tint = float3(1.0, 1.0, 1.0); break;
        case 6: // Black Supermist
            threshold = 0.65; knee = 0.3; intensity = 0.9; radius = 0.9; contrast = 1.1; tint = float3(0.98, 0.98, 1.0); break;
        case 7: // Radiant Soft
            threshold = 0.65; knee = 0.6; intensity = 1.5; radius = 1.0; contrast = 0.98; tint = float3(1.0, 0.96, 0.94); break;
        case 8: // Pearlescent
            threshold = 0.70; knee = 0.5; intensity = 0.8; radius = 0.9; contrast = 1.0; tint = float3(1.0, 0.95, 1.0); break;
    }
}

// Pass 1: Isolate bright areas
void PS_IsolateHighlights(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target)
{
    float threshold, knee, intensity, radius, contrast;
    float3 tint;
    SetPresetParams(threshold, knee, intensity, radius, contrast, tint);

    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float luma = dot(color, float3(0.299, 0.587, 0.114));
    float mask = smoothstep(threshold - knee, threshold + knee, luma);
    outColor = float4(color * mask, 1.0);
}

// Pass 2: Downsample and blur
void PS_Downsample(float4 pos : SV_Position, float2 texcoord : TEXCOORD, sampler samp, out float4 outColor : SV_Target)
{
    float2 pixel_size = 1.0 / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float2 aspect_ratio_mult = float2(1.0 + max(0, AnamorphicRatio), 1.0 + max(0, -AnamorphicRatio));

    // 13-tap tent filter for high quality downsampling blur
    float4 sum = 0;
    sum += tex2D(samp, texcoord - 3.0 * pixel_size * aspect_ratio_mult) * 0.0625;
    sum += tex2D(samp, texcoord - 2.0 * pixel_size * aspect_ratio_mult) * 0.125;
    sum += tex2D(samp, texcoord - 1.0 * pixel_size * aspect_ratio_mult) * 0.25;
    sum += tex2D(samp, texcoord) * 0.125;
    sum += tex2D(samp, texcoord + 1.0 * pixel_size * aspect_ratio_mult) * 0.25;
    sum += tex2D(samp, texcoord + 2.0 * pixel_size * aspect_ratio_mult) * 0.125;
    sum += tex2D(samp, texcoord + 3.0 * pixel_size * aspect_ratio_mult) * 0.0625;
    
    outColor = sum;
}

// Pass 2-5: Downsample and blur (wrapper entry points for each sampler)
void PS_Downsample_Highlight(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target) {
    PS_Downsample(pos, texcoord, CinematicDiffusion_SampHighlight, outColor);
}
void PS_Downsample_Blur1(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target) {
    PS_Downsample(pos, texcoord, CinematicDiffusion_SampBlur1, outColor);
}
void PS_Downsample_Blur2(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target) {
    PS_Downsample(pos, texcoord, CinematicDiffusion_SampBlur2, outColor);
}
void PS_Downsample_Blur3(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target) {
    PS_Downsample(pos, texcoord, CinematicDiffusion_SampBlur3, outColor);
}

// Final Pass: Combine blurred layers and blend with original
void PS_Combine(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 outColor : SV_Target)
{
    float threshold, knee, intensity, radius, contrast;
    float3 tint;
    SetPresetParams(threshold, knee, intensity, radius, contrast, tint);

    float3 originalColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

    float3 blur1 = tex2D(CinematicDiffusion_SampBlur1, texcoord).rgb;
    float3 blur2 = tex2D(CinematicDiffusion_SampBlur2, texcoord).rgb;
    float3 blur3 = tex2D(CinematicDiffusion_SampBlur3, texcoord).rgb;
    float3 blur4 = tex2D(CinematicDiffusion_SampBlur4, texcoord).rgb;
    
    // Combine blurred layers with radius control
    float3 bloom = (blur1 + blur2 + blur3 + blur4) * radius;

    // Add Halation (Chromatic Aberration) to the bloom
    if (HalationIntensity > 0)
    {
        float2 shift = 0.001 * HalationIntensity;
        bloom.r += tex2D(CinematicDiffusion_SampBlur2, texcoord + shift).r;
        bloom.b += tex2D(CinematicDiffusion_SampBlur2, texcoord - shift).b;
    }
    
    // Apply final tint and intensity
    bloom *= tint * intensity;

    // Blend back with original and apply contrast
    float3 finalImage = AS_applyBlend(float4(bloom, 1.0), float4(originalColor, 1.0), BlendMode, BlendAmount).rgb;
    finalImage = pow(finalImage, contrast);

    outColor = float4(finalImage, 1.0);
}


// ============================================================================
// TECHNIQUE
// ============================================================================
technique AS_GFX_CinematicDiffusion <
    ui_label = "[AS] GFX: Cinematic Diffusion";
    ui_tooltip = "High-quality diffusion filter with presets for classic cinematic looks.";
>
{
    pass p1 { VertexShader = PostProcessVS; PixelShader = PS_IsolateHighlights; RenderTarget = CinematicDiffusion_TexHighlight; }
    pass p2 { VertexShader = PostProcessVS; PixelShader = PS_Downsample_Highlight; RenderTarget = CinematicDiffusion_TexBlur1; }
    pass p3 { VertexShader = PostProcessVS; PixelShader = PS_Downsample_Blur1; RenderTarget = CinematicDiffusion_TexBlur2; }
    pass p4 { VertexShader = PostProcessVS; PixelShader = PS_Downsample_Blur2; RenderTarget = CinematicDiffusion_TexBlur3; }
    pass p5 { VertexShader = PostProcessVS; PixelShader = PS_Downsample_Blur3; RenderTarget = CinematicDiffusion_TexBlur4; }
    pass p6 { VertexShader = PostProcessVS; PixelShader = PS_Combine; }
}

#endif // __AS_GFX_CinematicDiffusion_1_fx