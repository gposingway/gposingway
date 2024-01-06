uniform int red_x   < source = "random"; min = 0; max = 100; >;
uniform int red_y   < source = "random"; min = 0; max = 100; >;

uniform int green_x < source = "random"; min = 0; max = 100; >;
uniform int green_y < source = "random"; min = 0; max = 100; >;

uniform int blue_x  < source = "random"; min = 0; max = 100; >;
uniform int blue_y  < source = "random"; min = 0; max = 100; >;

TEXTURE_FULL_SRC (TexGrain, "SHADERDECK/Grain/Grain.png",   1024, 1024, RGBA8)
SAMPLER_UV       (TextureGrain,  TexGrain,  WRAP)

float3 GetGrainTexture(int index, float inv, float2 coord)
{
    float3 grain;
    float2 rpos, gpos, bpos, scale;

    // Randomize the texture position for the RGB channels (random value between 0.0 - 1.0)
    rpos       = float2(red_x,   red_y)   * 0.01 * inv;
    gpos       = float2(green_x, green_y) * 0.01 * inv;
    bpos       = float2(blue_x,  blue_y)  * 0.01 * inv;

    scale      = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 1024.0;

    switch(index)
    {
            case 0:
                // Pull the grain texture
                grain.r  = tex2D(TextureGrain, ((coord) + rpos) * scale).x;
                grain.g  = tex2D(TextureGrain, ((coord) + gpos) * scale).x;
                grain.b  = tex2D(TextureGrain, ((coord) + bpos) * scale).x;
            break;

            case 1:
                // Pull the grain texture
                grain.r  = tex2D(TextureGrain, ((coord) + rpos) * scale).y;
                grain.g  = tex2D(TextureGrain, ((coord) + gpos) * scale).y;
                grain.b  = tex2D(TextureGrain, ((coord) + bpos) * scale).y;
            break;

            case 2:
                // Pull the grain texture
                grain.r  = tex2D(TextureGrain, ((coord) + rpos) * scale).z;
                grain.g  = tex2D(TextureGrain, ((coord) + gpos) * scale).z;
                grain.b  = tex2D(TextureGrain, ((coord) + bpos) * scale).z;
            break;
    }

    return grain;
}

float3 FilmGrain(float3 color, int index, float mult, int intensity, float2 coord)
{
    float3 range, grain, hsl, shadows, midtones, highlights;
    float2 rpos, gpos, bpos, scale;
    float  luma;
    int    profile;

    profile = index;

    grain = GetGrainTexture(index, mult, coord);

    // Film grain saturation for shadows, midtones, and highlights
    float3 satcurve[3] =
    {
        // Super 16mm
        float3(0.55, 0.45, 0.25),

        // Super 35mm
        float3(0.5, 0.5, 0.4),

        // Full Frame 35mm
        float3(0.5, 0.4, 0.3)
    };

    // Grain amount in shadows, midtones, and highlights
    float3 lumacurve[3] =
    {
        // Super 16mm
        float3(1.0, 0.5, 0.75),

        // Super 35mm
        float3(0.25, 0.75, 1.0),

        // Full Frame 35mm
        float3(0.66, 0.33, 1.0)
    };

    // Per-channel grain in shadows
    float3 rgbshadows[3] =
    {
        // Super 16mm
        float3(1.0, 0.33, 0.75),

        // Super 35mm
        float3(0.33, 1.0, 0.5),

        // Full Frame 35mm
        float3(0.66, 0.15, 1.0)
    };

    // Per-channel grain in midtones
    float3 rgbmids[3] =
    {
        // Super 16mm
        float3(0.25, 1.0, 0.33),

        // Super 35mm
        float3(0.66, 0.25, 0.5),

        // Full Frame 35mm
        float3(1.0, 1.0, 1.0)
    };

    // Per-channel grain in highlights
    float3 rgbhighs[3] =
    {
        // Super 16mm
        float3(1.0, 0.33, 0.5),

        // Super 35mm
        float3(1.0, 0.15, 1.0),

        // Full Frame 35mm
        float3(1.0, 1.0, 1.0)
    };

    // Setup the luma ranges
    luma        = GetLuma(pow(abs(color), 0.75));
    range.x     = smoothstep(0.333, 0.0, luma);
    range.z     = smoothstep(0.333, 1.0, luma);
    range.y     = saturate(1 - range.x - range.z);

    // Setup the RGB balance for shadows, midtones, and highlights
    // Use B&W grain if a B&W negative is selected
    #ifdef __BW_CHECK
        if (__BW_CHECK)
        {
            shadows     = lerp(0.5, grain, rgbshadows[profile]);
            midtones    = lerp(0.5, grain, rgbmids[profile]);
            highlights  = lerp(0.5, grain, rgbhighs[profile]);
        }

        else
        {
            shadows     = grain.x;
            midtones    = grain.x;
            highlights  = grain.x;
        }
    #else
        shadows     = lerp(0.5, grain, rgbshadows[profile]);
        midtones    = lerp(0.5, grain, rgbmids[profile]);
        highlights  = lerp(0.5, grain, rgbhighs[profile]);
    #endif

    // Setup grain for shadows, midtones, and highlights
    shadows     = lerp(0.5, shadows,    lumacurve[profile].x);
    midtones    = lerp(0.5, midtones,   lumacurve[profile].y);
    highlights  = lerp(0.5, highlights, lumacurve[profile].z);

    // Apply the saturation curve to the grain
    #ifdef __BW_CHECK
        if (__BW_CHECK)
        {
            shadows     = lerp(GetLuma(shadows),    shadows,    satcurve[profile].x);
            midtones    = lerp(GetLuma(midtones),   midtones,   satcurve[profile].y);
            highlights  = lerp(GetLuma(highlights), highlights, satcurve[profile].z);
        }
    #else
        shadows     = lerp(GetLuma(shadows),    shadows,    satcurve[profile].x);
        midtones    = lerp(GetLuma(midtones),   midtones,   satcurve[profile].y);
        highlights  = lerp(GetLuma(highlights), highlights, satcurve[profile].z);
    #endif
    
    // Apply the luma curve to the grain
    grain       = 0.0;
    grain      += lerp(0.0, shadows,    range.x);
    grain      += lerp(0.0, midtones,   range.y);
    grain      += lerp(0.0, highlights, range.z);

    // Blend the grain
    color += (((grain - 0.5) * 2) * (intensity * 0.0125));

    return saturate(color);
}
