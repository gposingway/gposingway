/*******************************************************************************
    Author: Vortigern

    License: MIT, Copyright (c) 2023 Vortigern

    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
*******************************************************************************/

#pragma once

/*******************************************************************************
    Globals
*******************************************************************************/

#define PHI (1.6180339887498)
#define INV_PHI (0.6180339887498)
#define EPSILON (1e-7)
#define PI (3.1415927)
#define HALF_PI (1.5707963)
#define DOUBLE_PI (6.2831853)
#define FLOAT_MAX (65504.0)
#define FLOAT_MIN (-65504.0)
#define IS_SRGB (BUFFER_COLOR_SPACE == 1 || BUFFER_COLOR_SPACE == 0)
#define IS_SCRGB (BUFFER_COLOR_SPACE == 2)
#define IS_HDR_PQ (BUFFER_COLOR_SPACE == 3)
#define IS_HDR_HLG (BUFFER_COLOR_SPACE == 4)
#define IS_8BIT (BUFFER_COLOR_BIT_DEPTH == 8)
#define IS_DX9 (__RENDERER__ < 0xA000)
#define CAN_COMPUTE (__RENDERER__ >= 0xB000)

// safer versions of built-in functions
float RCP(float x)   { x = rcp(x == 0 ? EPSILON : x); return x; }
float2 RCP(float2 x) { x = rcp(x == 0 ? EPSILON : x); return x; }
float3 RCP(float3 x) { x = rcp(x == 0 ? EPSILON : x); return x; }
float4 RCP(float4 x) { x = rcp(x == 0 ? EPSILON : x); return x; }

#define CEIL_DIV(x, y) ((((x) - 1) / (y)) + 1)
#define POW(_b, _e) (pow(max(EPSILON, (_b)), (_e)))
#define RSQRT(_x) (RCP(sqrt(_x)))
#define NORMALIZE(_x) ((_x) * RSQRT(_x))
#define LOG(_x) (log(max(EPSILON, (_x))))
#define LOG2(_x) (log2(max(EPSILON, (_x))))
#define LOG10(_x) (log10(max(EPSILON, (_x))))
#define exp10(_x) (exp2(3.3219281 * (_x)))

#if !defined(__RESHADE__) || __RESHADE__ < 30000
    #error "ReShade 3.0+ is required to use this header file"
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
    #define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_REVERSED
    #define RESHADE_DEPTH_INPUT_IS_REVERSED 1
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
    #define RESHADE_DEPTH_INPUT_IS_LOGARITHMIC 0
#endif
#ifndef RESHADE_DEPTH_MULTIPLIER
    #define RESHADE_DEPTH_MULTIPLIER 1
#endif
#ifndef RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
    #define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0
#endif
// Above 1 expands coordinates, below 1 contracts and 1 is equal to no scaling on any axis
#ifndef RESHADE_DEPTH_INPUT_Y_SCALE
    #define RESHADE_DEPTH_INPUT_Y_SCALE 1
#endif
#ifndef RESHADE_DEPTH_INPUT_X_SCALE
    #define RESHADE_DEPTH_INPUT_X_SCALE 1
#endif
// An offset to add to the Y coordinate, (+) = move up, (-) = move down
#ifndef RESHADE_DEPTH_INPUT_Y_OFFSET
    #define RESHADE_DEPTH_INPUT_Y_OFFSET 0
#endif
#ifndef RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
    #define RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET 0
#endif
// An offset to add to the X coordinate, (+) = move right, (-) = move left
#ifndef RESHADE_DEPTH_INPUT_X_OFFSET
    #define RESHADE_DEPTH_INPUT_X_OFFSET 0
#endif
#ifndef RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
    #define RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET 0
#endif

#define BUFFER_PIXEL_SIZE float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define BUFFER_SCREEN_SIZE float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#define BUFFER_ASPECT_RATIO (BUFFER_WIDTH * BUFFER_RCP_HEIGHT)

#if defined(__RESHADE_FXC__)
    float GetAspectRatio() { return BUFFER_WIDTH * BUFFER_RCP_HEIGHT; }
    float2 GetPixelSize() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
    float2 GetScreenSize() { return float2(BUFFER_WIDTH, BUFFER_HEIGHT); }
    #define AspectRatio GetAspectRatio()
    #define PixelSize GetPixelSize()
    #define ScreenSize GetScreenSize()
#else
    // These are deprecated and will be removed eventually.
    static const float AspectRatio = BUFFER_WIDTH * BUFFER_RCP_HEIGHT;
    static const float2 PixelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
    static const float2 ScreenSize = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
#endif

uniform uint FRAME_COUNT < source = "framecount"; >;
uniform float FRAME_TIME < source = "frametime"; >;

// works since REST addon v1.2.1
#ifndef V_USE_HW_LIN
    #define V_USE_HW_LIN 0
#endif

#if !IS_SRGB
    #ifndef V_HDR_WHITE_LVL
        #define V_HDR_WHITE_LVL 203
    #endif
#endif

#define UI_FLOAT(_category, _name, _label, _descr, _min, _max, _default) \
    uniform float _name < \
        ui_category = _category; \
        ui_label = _label; \
        ui_min = _min; \
        ui_max = _max; \
        ui_tooltip = _descr; \
        ui_step = 0.001; \
        ui_type = "slider"; \
    > = _default;

#define UI_FLOAT2(_category, _name, _label, _descr, _min, _max, _default) \
    uniform float2 _name < \
        ui_category = _category; \
        ui_label = _label; \
        ui_min = _min; \
        ui_max = _max; \
        ui_tooltip = _descr; \
        ui_step = 0.001; \
        ui_type = "slider"; \
    > = _default;

#define UI_INT(_category, _name, _label, _descr, _min, _max, _default) \
    uniform int _name < \
        ui_category = _category; \
        ui_label = _label; \
        ui_min = _min; \
        ui_max = _max; \
        ui_tooltip = _descr; \
        ui_step = 1; \
        ui_type = "slider"; \
    > = _default;

#define UI_INT2(_category, _name, _label, _descr, _min, _max, _default) \
    uniform int2 _name < \
        ui_category = _category; \
        ui_label = _label; \
        ui_min = _min; \
        ui_max = _max; \
        ui_tooltip = _descr; \
        ui_step = 1; \
        ui_type = "slider"; \
    > = _default;

#define UI_BOOL(_category, _name, _label, _descr, _default) \
    uniform bool _name < \
        ui_category = _category; \
        ui_label = _label; \
        ui_tooltip = _descr; \
        ui_type = "radio"; \
    > = _default;

#define UI_LIST(_category, _name, _label, _descr, _items, _default) \
    uniform int _name < \
        ui_category = _category; \
        ui_label = _label; \
        ui_items = _items; \
        ui_tooltip = _descr; \
        ui_type = "combo"; \
    > = _default;

#define UI_COLOR(_category, _name, _label, _descr, _default) \
    uniform float3 _name < \
        ui_category = _category; \
        ui_label = _label; \
        ui_min = 0.0; \
        ui_max = 1.0; \
        ui_tooltip = _descr; \
        ui_step = 0.001; \
        ui_type = "color"; \
        ui_closed = true; \
    > = _default;

#define UI_HELP(_name, _descr) \
    uniform int _name < \
        ui_category = "Preprocessor Help"; \
        ui_label = " "; \
        ui_text = _descr; \
        ui_type = "radio"; \
    >;

#define TEX_SIZE(_bit) Width = BUFFER_WIDTH >> _bit; Height = BUFFER_HEIGHT >> _bit;
#define TEX_RGBA8 Format = RGBA8;
#define TEX_RGBA16 Format = RGBA16F;
#define TEX_RGBA32 Format = RGBA32F;
#define TEX_R8 Format = R8;
#define TEX_RG8 Format = RG8;
#define TEX_R16 Format = R16F;
#define TEX_R32 Format = R32F;
#define TEX_RG16 Format = RG16F;
#define TEX_RG32 Format = RG32F;

#define SAM_POINT  MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;
#define SAM_MIRROR AddressU = MIRROR; AddressV = MIRROR;
#define SAM_WRAP   AddressU = WRAP;   AddressV = WRAP;
#define SAM_REPEAT AddressU = REPEAT; AddressV = REPEAT;
#define SAM_BORDER AddressU = BORDER; AddressV = BORDER;

struct VSOUT { float4 vpos : SV_POSITION; float2 uv : TEXCOORD0; };
struct PSOUT2 { float4 t0 : SV_Target0, t1 : SV_Target1; };
struct CSIN {
    uint3 id : SV_DispatchThreadID;
    uint3 gtid : SV_GroupThreadID;
    uint3 gid : SV_GroupID;
    uint gIndex : SV_GroupIndex;
};

#define PS_ARGS1 in VSOUT i, out float  o : SV_Target0
#define PS_ARGS2 in VSOUT i, out float2 o : SV_Target0
#define PS_ARGS3 in VSOUT i, out float3 o : SV_Target0
#define PS_ARGS4 in VSOUT i, out float4 o : SV_Target0

#define CS_ARGS in CSIN i

#define VS_ARGS \
    in uint id : SV_VertexID, out float4 vpos : SV_Position, out float2 uv : TEXCOORD

#define VS_VPOS_FROM_UV \
    vpos = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);

#define VS_SMALL_TRIANGLE(_num) \
    float k = RCP(1 << _num); \
    uv.x = (id == 2) ? k * 2.0 : 0.0; \
    uv.y = (id == 1) ? 1.0 : (1 - k); \
    VS_VPOS_FROM_UV

#define SRGB_WRITE_ENABLE SRGBWriteEnable = IS_SRGB && IS_8BIT && V_USE_HW_LIN;

/*******************************************************************************
    Functions
*******************************************************************************/

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// to be used instead of tex2D and tex2Dlod
float4 Sample(sampler samp, float2 uv) { return tex2Dlod(samp, float4(uv, 0, 0)); }
float4 Sample(sampler samp, float2 uv, int mip) { return tex2Dlod(samp, float4(uv, 0, mip)); }
float4 Sample(sampler samp, float2 uv, int mip, int2 offs) { return tex2Dlod(samp, float4(uv, 0, mip), offs); }

float3 SRGBToLin(float3 c)
{
    return (c < 0.04045) ? c / 12.92 : POW((c + 0.055) / 1.055, 2.4);
}

float3 LinToSRGB(float3 c)
{
    return (c < 0.0031308) ? 12.92 * c : 1.055 * POW(c, 0.41666666) - 0.055;
}

float3 PQToLin(float3 c, float white_lvl)
{
    static const float c1 = 107.0 / 128.0;
    static const float c2 = 2413.0 / 128.0;
    static const float c3 = 2392.0 / 128.0;

    c = POW(c, 32.0 / 2523.0);
    c = max(c - c1, 0.0) * RCP(c2 - c3 * c);

    return POW(c, 8192.0 / 1305.0) * (1e4 / white_lvl);
}

float3 LinToPQ(float3 c, float white_lvl)
{
    static const float c1 = 107.0 / 128.0;
    static const float c2 = 2413.0 / 128.0;
    static const float c3 = 2392.0 / 128.0;

    c = POW(c, 1305.0 / 8192.0) * (white_lvl / 1e4);
    c = (c1 + c2 * c) * RCP(1 + c3 * c);

    return POW(c, 2523.0 / 32.0);
}

float3 HLGToLin(float3 c, float white_lvl)
{
    static const float c1 = 0.17883277;
    static const float c2 = 0.28466892;
    static const float c3 = 0.55991073;

    c = c < 0.5 ? ((c * c) / 3.0) : ((exp((c - c3) / c1) + c2) / 12.0);

    return c * (1e3 / white_lvl);
}

float3 LinToHLG(float3 c, float white_lvl)
{
    static const float c1 = 0.17883277;
    static const float c2 = 0.28466892;
    static const float c3 = 0.55991073;

    c = sqrt(c * (white_lvl / 1e3) * 3);

    return c < 0.5 ? c : (LOG(c * 12 - c2) * c1 + c3);
}

float3 ApplyLinearCurve(float3 c)
{
#if IS_SRGB && (!IS_8BIT || !V_USE_HW_LIN)
    c = SRGBToLin(c);
#elif IS_SCRGB
    c = c * (80.0 / V_HDR_WHITE_LVL);
#elif IS_HDR_PQ
    c = PQToLin(c, V_HDR_WHITE_LVL);
#elif IS_HDR_HLG
    c = HLGToLin(c, V_HDR_WHITE_LVL);
#endif

    return c;
}

float3 ApplyGammaCurve(float3 c)
{
#if IS_SRGB && (!IS_8BIT || !V_USE_HW_LIN)
    c = LinToSRGB(c);
#elif IS_SCRGB
    c = c * (V_HDR_WHITE_LVL / 80.0);
#elif IS_HDR_PQ
    c = LinToPQ(c, V_HDR_WHITE_LVL);
#elif IS_HDR_HLG
    c = LinToHLG(c, V_HDR_WHITE_LVL);
#endif

    return c;
}

float RGBToYCbCrLumi(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

float RGBToYCoCgLumi(float3 c)
{
    return dot(c, float3(0.25, 0.5, 0.25));
}

float3 RGBToYCoCg(float3 rgb)
{
    return float3(
        RGBToYCoCgLumi(rgb),
        dot(rgb, float3(0.5, 0.0, -0.5)),
        dot(rgb, float3(-0.25, 0.5, -0.25))
    );
}

float3 YCoCgToRGB(float3 ycc)
{
    return float3(
        dot(ycc, float3(1.0, 1.0, -1.0)),
        dot(ycc, float3(1.0, 0.0, 1.0)),
        dot(ycc, float3(1.0, -1.0, -1.0))
    );
}

float3 RGBToYCbCr(float3 rgb)
{
    float y = RGBToYCbCrLumi(rgb);

    return float3(y, (rgb.b - y) * 0.565, (rgb.r - y) * 0.713);
}

float3 YCbCrToRGB(float3 ycc)
{
    return float3(
        ycc.x + 1.403 * ycc.z,
        ycc.x - 0.344 * ycc.y - 0.714 * ycc.z,
        ycc.x + 1.770 * ycc.y
    );
}

float3 RGBToHSV(float3 c)
{
    static const float4 K = float4(0.0, (-1.0 / 3.0), (2.0 / 3.0), -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);

    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + EPSILON)), d / (q.x + EPSILON), q.x);
}

float3 HSVToRGB(float3 c)
{
    static const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);

    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float3 RGBToXYZ(float3 col)
{
    return float3(
        dot(float3(0.4124, 0.3576, 0.1805), col),
        dot(float3(0.4124, 0.3576, 0.1805), col),
        dot(float3(0.0193, 0.1192, 0.9505), col)
    );
}

float3 XYZToRGB(float3 col)
{
    return float3(
        dot(float3(3.2406, -1.5372, -0.4986), col),
        dot(float3(-0.9689, 1.8758, 0.0415), col),
        dot(float3(0.0557, -0.2040, 1.0570), col)
    );
}

float3 XYZToYXY(float3 col)
{
    float inv = 1.0 / dot(col, 1.0);

    return float3(col.y, col.x * inv, col.y * inv);
}

float3 YXYToXYZ(float3 col)
{
    return float3(
        col.x * col.y / col.z,
        col.x,
        col.x * (1.0 - col.y - col.z) / col.z
    );
}

float3 RGBToYXY(float3 col)
{
    return XYZToYXY(RGBToXYZ(col));
}

float3 YXYToRGB(float3 col)
{
    return XYZToRGB(YXYToXYZ(col));
}

float3 XYZToLAB(float3 c)
{
    float3 n = c / float3(0.95047, 1.0, 1.08883);
    float3 v = n > 0.008856 ? POW(n, 1.0 / 3.0) : (7.787 * n) + (16.0 / 116.0);
    float3 lab = float3((116.0 * v.y) - 16.0, 500.0 * (v.x - v.y), 200.0 * (v.y - v.z));

    return float3(lab.x / 100.0, 0.5 + 0.5 * (lab.y / 127.0), 0.5 + 0.5 * (lab.z / 127.0));
}

float3 LABToXYZ(float3 c)
{
    float3 lab = float3(100.0 * c.x, 2.0 * 127.0 * (c.y - 0.5), 2.0 * 127.0 * (c.z - 0.5));
    float3 v;

    v.y = (lab.x + 16.0) / 116.0;
    v.x = lab.y / 500.0 + v.y;
    v.z = v.y - lab.z / 200.0;

    return float3(0.95047, 1.0, 1.08883) * (v > 0.206897 ? v * (v * v) : (v - 16.0 / 116.0) / 7.787);
}

float3 RGBToLAB(float3 c)
{
    return XYZToLAB(RGBToXYZ(c));
}

float3 LABToRGB(float3 c)
{
    return XYZToRGB(LABToXYZ(c));
}

float Max3(float a, float b, float c) { return max(a, max(b, c)); }
float2 Max3(float2 a, float2 b, float2 c) { return max(a, max(b, c)); }
float3 Max3(float3 a, float3 b, float3 c) { return max(a, max(b, c)); }
float4 Max3(float4 a, float4 b, float4 c) { return max(a, max(b, c)); }

float Min3(float a, float b, float c) { return min(a, min(b, c)); }
float2 Min3(float2 a, float2 b, float2 c) { return min(a, min(b, c)); }
float3 Min3(float3 a, float3 b, float3 c) { return min(a, min(b, c)); }
float4 Min3(float4 a, float4 b, float4 c) { return min(a, min(b, c)); }

float GetNoise(float2 co)
{
    return frac(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
}
