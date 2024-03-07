/*******************************************************************************
    Author: Vortigern

    License:
    https://github.com/ampas/aces-dev

    Academy Color Encoding System (ACES) software and tools are provided by the
    Academy under the following terms and conditions: A worldwide, royalty-free,
    non-exclusive right to copy, modify, create derivatives, and use, in source and
    binary forms, is hereby granted, subject to acceptance of this license.

    Copyright 2015 Academy of Motion Picture Arts and Sciences (A.M.P.A.S.).
    Portions contributed by others as indicated. All rights reserved.

    Performance of any of the aforementioned acts indicates acceptance to be bound
    by the following terms and conditions:

    * Copies of source code, in whole or in part, must retain the above copyright
    notice, this list of conditions and the Disclaimer of Warranty.

    * Use in binary form must retain the above copyright notice, this list of
    conditions and the Disclaimer of Warranty in the documentation and/or other
    materials provided with the distribution.

    * Nothing in this license shall be deemed to grant any rights to trademarks,
    copyrights, patents, trade secrets or any other intellectual property of
    A.M.P.A.S. or any contributors, except as expressly stated herein.

    * Neither the name "A.M.P.A.S." nor the name of any other contributors to this
    software may be used to endorse or promote products derivative of or based on
    this software without express prior written permission of A.M.P.A.S. or the
    contributors, as appropriate.

    This license shall be construed pursuant to the laws of the State of
    California, and any disputes related thereto shall be subject to the
    jurisdiction of the courts therein.

    Disclaimer of Warranty: THIS SOFTWARE IS PROVIDED BY A.M.P.A.S. AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
    THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
    NON-INFRINGEMENT ARE DISCLAIMED. IN NO EVENT SHALL A.M.P.A.S., OR ANY
    CONTRIBUTORS OR DISTRIBUTORS, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, RESITUTIONARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
    OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
    ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    WITHOUT LIMITING THE GENERALITY OF THE FOREGOING, THE ACADEMY SPECIFICALLY
    DISCLAIMS ANY REPRESENTATIONS OR WARRANTIES WHATSOEVER RELATED TO PATENT OR
    OTHER INTELLECTUAL PROPERTY RIGHTS IN THE ACADEMY COLOR ENCODING SYSTEM, OR
    APPLICATIONS THEREOF, HELD BY PARTIES OTHER THAN A.M.P.A.S.,WHETHER DISCLOSED OR
    UNDISCLOSED.
*******************************************************************************

#pragma once
#include "Includes/vort_Defs.fxh"

/*******************************************************************************
    Globals
*******************************************************************************/

// Mid gray for both ACEScc and ACEScct
#define ACES_LOG_MID_GRAY 0.4135884

/*******************************************************************************
    Functions
*******************************************************************************/

float RGBToCenteredHue(float3 c)
{
    // hue is undefined when color channels are the same value
    float hue = (c.r == c.g && c.g == c.b) ? 0 : (57.2957795 * atan2(1.7320508 * (c.g - c.b), 2 * c.r - c.g - c.b));

    if(hue < 0) hue += 360.0;

    if(hue < -180.0)
        hue += 360.0;
    else if(hue > 180.0)
        hue -= 360.0;

    return hue;
}

float RGBToSaturation(float3 c)
{
    float max_chan = Max3(c.r, c.g, c.b);
    float min_chan = Min3(c.r, c.g, c.b);

    return (max(max_chan, EPSILON) - max(min_chan, EPSILON)) / max(max_chan, 1e-2);
}

float RGBToYC(float3 c)
{
    float chroma = sqrt(c.r * (c.r - c.b) + c.g * (c.g - c.r) + c.b * (c.b - c.g));

    return (c.r + c.g + c.b + 1.75 * chroma) / 3.0;
}

float SigmoidShaper(float x)
{
    float t = max(0.0, 1.0 - abs(x * 0.5));

    return 0.5 + 0.5 * sign(x) * (1.0 - t * t);
}

float GlowFwd(float yc, float glow_gain_in)
{
    if(yc <= (0.16 / 3.0))
        return glow_gain_in;
    else if(yc >= 0.16)
        return 0;
    else
        return glow_gain_in * (0.08 / yc - 0.5);
}

float GlowRev(float yc, float glow_gain_in)
{
    if(yc <= ((1 + glow_gain_in) * 0.16 / 3.0))
        return glow_gain_in * RCP(glow_gain_in + 1);
    else if(yc >= 0.16)
        return 0;
    else
        return glow_gain_in * (0.08 / yc - 0.5) * RCP(glow_gain_in * 0.5 - 1.0);
}

#if 0 // disable ACESFull
float SegmentedSplineC5Fwd(float x)
{
    static const float3x3 M = float3x3(0.5, -1.0, 0.5, -1.0, 1.0, 0.5, 0.5, 0.0, 0.0);
    static const float C5_COEFS_LOW[6] = { -4.0, -4.0, -3.1573766, -0.485245, 1.8477325, 1.8477325 };
    static const float C5_COEFS_HIGH[6] = { -0.7185482, 2.0810307, 3.6681241, 4.0, 4.0, 4.0 };
    static const float2 C5_MIN_POINT_L10 = float2(-5.2601774, -4);
    static const float2 C5_MID_POINT_L10 = float2(-0.7447275, 0.6812412);
    static const float2 C5_MAX_POINT_L10 = float2(4.6738124, 4);
    static const float C5_KNOT_INC_LOW = 1.5049699;
    static const float C5_KNOT_INC_HIGH = 1.80618;

    float logx = LOG10(x);
    float logy = 0;

    if (logx <= C5_MIN_POINT_L10.x)
    {
        logy = C5_MIN_POINT_L10.y;
    }
    else if(logx > C5_MIN_POINT_L10.x && logx < C5_MID_POINT_L10.x)
    {
        float knot_coord = (logx - C5_MIN_POINT_L10.x) / C5_KNOT_INC_LOW;
        int j = knot_coord;
        float t = knot_coord - j;
        float3 cf = float3(C5_COEFS_LOW[j], C5_COEFS_LOW[j + 1], C5_COEFS_LOW[j + 2]);

        logy = dot(float3(t * t, t, 1.0), mul(M, cf));
    }
    else if (logx >= C5_MID_POINT_L10.x && logx < C5_MAX_POINT_L10.x)
    {
        float knot_coord = (logx - C5_MID_POINT_L10.x) / C5_KNOT_INC_HIGH;
        int j = knot_coord;
        float t = knot_coord - j;
        float3 cf = float3(C5_COEFS_HIGH[j], C5_COEFS_HIGH[j + 1], C5_COEFS_HIGH[j + 2]);

        logy = dot(float3(t * t, t, 1.0), mul(M, cf));
    }
    else
    {
        logy = C5_MAX_POINT_L10.y;
    }

    return exp10(logy);
}

float SegmentedSplineC5Rev(float y)
{
    static const float3x3 M = float3x3(0.5, -1.0, 0.5, -1.0, 1.0, 0.5, 0.5, 0.0, 0.0);
    static const float C5_COEFS_LOW[6] = { -4.0, -4.0, -3.1573766, -0.485245, 1.8477325, 1.8477325 };
    static const float C5_COEFS_HIGH[6] = { -0.7185482, 2.0810307, 3.6681241, 4.0, 4.0, 4.0 };
    static const float2 C5_MIN_POINT_L10 = float2(-5.2601774, -4);
    static const float2 C5_MID_POINT_L10 = float2(-0.7447275, 0.6812412);
    static const float2 C5_MAX_POINT_L10 = float2(4.6738124, 4);
    static const float C5_KNOT_INC_LOW = 1.5049699;
    static const float C5_KNOT_INC_HIGH = 1.80618;
    static const float C5_KNOT_Y_LOW[4] = { -4.0, -3.5786883, -1.8213108, 0.6812412 };
    static const float C5_KNOT_Y_HIGH[4] = { 0.6812412, 2.8745774, 3.83406205, 4.0 };

    float logy = LOG10(y);
    float logx = 0;

    if(logy <= C5_MIN_POINT_L10.y)
    {
        logx = C5_MIN_POINT_L10.x;
    }
    else if(logy > C5_MIN_POINT_L10.y && logy <= C5_MID_POINT_L10.y)
    {
        int j = 3;
        float3 cf = 0;

        [loop]while(j-- > 0)
        {
            if(logy > C5_KNOT_Y_LOW[j] && logy <= C5_KNOT_Y_LOW[j + 1])
            {
                cf = float3(C5_COEFS_LOW[j], C5_COEFS_LOW[j + 1], C5_COEFS_LOW[j + 2]);
                break;
            }
        }

        float3 abc = mul(M, cf); abc.z = abc.z - logy;
        float t = (-2.0 * abc.z) * RCP(abc.y + sqrt(abc.y * abc.y - 4.0 * abc.x * abc.z));

        logx = C5_MIN_POINT_L10.x + (t + j) * C5_KNOT_INC_LOW;
    }
    else if(logy > C5_MID_POINT_L10.y && logy < C5_MAX_POINT_L10.y)
    {
        int j = 3;
        float3 cf = 0;

        [loop]while(j-- > 0)
        {
            if(logy > C5_KNOT_Y_HIGH[j] && logy <= C5_KNOT_Y_HIGH[j + 1])
            {
                cf = float3(C5_COEFS_HIGH[j], C5_COEFS_HIGH[j + 1], C5_COEFS_HIGH[j + 2]);
                break;
            }
        }

        float3 abc = mul(M, cf); abc.z = abc.z - logy;
        float t = (-2.0 * abc.z) * RCP(abc.y + sqrt(abc.y * abc.y - 4.0 * abc.x * abc.z));

        logx = C5_MID_POINT_L10.x + (t + j) * C5_KNOT_INC_HIGH;
    }
    else
    {
        logx = C5_MAX_POINT_L10.x;
    }

    return exp10(logx);
}

float SegmentedSplineC9Fwd(float x)
{
    static const float3x3 M = float3x3(0.5, -1.0, 0.5, -1.0, 1.0, 0.5, 0.5, 0.0, 0.0);
    static const float C9_COEFS_LOW[10] = { -1.69897, -1.69897, -1.4779, -1.2291, -0.8648, -0.448, 0.00518, 0.451108, 0.9113744, 0.9113744 };
    static const float C9_COEFS_HIGH[10] = { 0.5154386, 0.8470437, 1.1358, 1.3802, 1.5197, 1.5985, 1.6467, 1.6746091, 1.6878733, 1.6878733 };
    static const float2 C9_MIN_POINT_L10 = float2(-2.5402006, -1.69897);
    static const float2 C9_MID_POINT_L10 = float2(0.6812412, 0.6812412);
    static const float2 C9_MAX_POINT_L10 = float2(3.002479, 1.6812412);
    /* static const float2 C9_MIN_POINT_L10 = float2(LOG10(SegmentedSplineC5Fwd(0.18 * exp2(-6.5))), -1.69897); */
    /* static const float2 C9_MID_POINT_L10 = float2(LOG10(SegmentedSplineC5Fwd(0.18)), 0.6812412); */
    /* static const float2 C9_MAX_POINT_L10 = float2(LOG10(SegmentedSplineC5Fwd(0.18 * exp2(6.5))), 1.6812412); */
    static const float C9_KNOT_INC_LOW = 0.460206;
    static const float C9_KNOT_INC_HIGH = 0.3316054;

    float logx = LOG10(x);
    float logy = 0;

    if (logx <= C9_MIN_POINT_L10.x)
    {
        logy = C9_MIN_POINT_L10.y;
    }
    else if(logx > C9_MIN_POINT_L10.x && logx < C9_MID_POINT_L10.x)
    {
        float knot_coord = (logx - C9_MIN_POINT_L10.x) / C9_KNOT_INC_LOW;
        int j = knot_coord;
        float t = knot_coord - j;
        float3 cf = float3(C9_COEFS_LOW[j], C9_COEFS_LOW[j + 1], C9_COEFS_LOW[j + 2]);

        logy = dot(float3(t * t, t, 1.0), mul(M, cf));
    }
    else if (logx >= C9_MID_POINT_L10.x && logx < C9_MAX_POINT_L10.x)
    {
        float knot_coord = (logx - C9_MID_POINT_L10.x) / C9_KNOT_INC_HIGH;
        int j = knot_coord;
        float t = knot_coord - j;
        float3 cf = float3(C9_COEFS_HIGH[j], C9_COEFS_HIGH[j + 1], C9_COEFS_HIGH[j + 2]);

        logy = dot(float3(t * t, t, 1.0), mul(M, cf));
    }
    else
    {
        logy = (logx * 0.04) + C9_MAX_POINT_L10.y - (0.04 * C9_MAX_POINT_L10.x);
    }

    return exp10(logy);
}

float SegmentedSplineC9Rev(float y)
{
    static const float3x3 M = float3x3(0.5, -1.0, 0.5, -1.0, 1.0, 0.5, 0.5, 0.0, 0.0);
    static const float C9_COEFS_LOW[10] = { -1.69897, -1.69897, -1.4779, -1.2291, -0.8648, -0.448, 0.00518, 0.451108, 0.9113744, 0.9113744 };
    static const float C9_COEFS_HIGH[10] = { 0.5154386, 0.8470437, 1.1358, 1.3802, 1.5197, 1.5985, 1.6467, 1.6746091, 1.6878733, 1.6878733 };
    static const float2 C9_MIN_POINT_L10 = float2(-2.5402006, -1.69897);
    static const float2 C9_MID_POINT_L10 = float2(0.6812412, 0.6812412);
    static const float2 C9_MAX_POINT_L10 = float2(3.002479, 1.6812412);
    /* static const float2 C9_MIN_POINT_L10 = float2(LOG10(SegmentedSplineC5Fwd(0.18 * exp2(-6.5))), -1.69897); */
    /* static const float2 C9_MID_POINT_L10 = float2(LOG10(SegmentedSplineC5Fwd(0.18)), 0.6812412); */
    /* static const float2 C9_MAX_POINT_L10 = float2(LOG10(SegmentedSplineC5Fwd(0.18 * exp2(6.5))), 1.6812412); */
    static const float C9_KNOT_INC_LOW = 0.460206;
    static const float C9_KNOT_INC_HIGH = 0.3316054;
    static const float C9_KNOT_Y_LOW[8] = { -1.69897, -1.588435, -1.3535, -1.04695, -0.6564, -0.22141, 0.228144, 0.6812412 };
    static const float C9_KNOT_Y_HIGH[8] = { 0.6812412, 0.9914218, 1.258, 1.44995, 1.5591, 1.6226, 1.6606546, 1.6812412 };

    float logy = LOG10(y);
    float logx = 0;

    if(logy <= C9_MIN_POINT_L10.y)
    {
        logx = C9_MIN_POINT_L10.x;
    }
    else if(logy > C9_MIN_POINT_L10.y && logy <= C9_MID_POINT_L10.y)
    {
        int j = 7;
        float3 cf = 0;

        [loop]while(j-- > 0)
        {
            if(logy > C9_KNOT_Y_LOW[j] && logy <= C9_KNOT_Y_LOW[j + 1])
            {
                cf = float3(C9_COEFS_LOW[j], C9_COEFS_LOW[j + 1], C9_COEFS_LOW[j + 2]);
                break;
            }
        }

        float3 abc = mul(M, cf); abc.z = abc.z - logy;
        float t = (-2.0 * abc.z) * RCP(abc.y + sqrt(abc.y * abc.y - 4.0 * abc.x * abc.z));

        logx = C9_MIN_POINT_L10.x + (t + j) * C9_KNOT_INC_LOW;
    }
    else if(logy > C9_MID_POINT_L10.y && logy < C9_MAX_POINT_L10.y)
    {
        int j = 7;
        float3 cf = 0;

        [loop]while(j-- > 0)
        {
            if(logy > C9_KNOT_Y_HIGH[j] && logy <= C9_KNOT_Y_HIGH[j + 1])
            {
                cf = float3(C9_COEFS_HIGH[j], C9_COEFS_HIGH[j + 1], C9_COEFS_HIGH[j + 2]);
                break;
            }
        }

        float3 abc = mul(M, cf); abc.z = abc.z - logy;
        float t = (-2.0 * abc.z) * RCP(abc.y + sqrt(abc.y * abc.y - 4.0 * abc.x * abc.z));

        logx = C9_MID_POINT_L10.x + (t + j) * C9_KNOT_INC_HIGH;
    }
    else
    {
        logx = C9_MAX_POINT_L10.x;
    }

    return exp10(logx);
}

float3 InverseACESFull(float3 c)
{
    static const float3x3 RGB_2_D65XYZ_2_D60XYZ = float3x3(0.420004, 0.360291, 0.158883, 0.22071, 0.715493, 0.0599601, 0.0177995, 0.123548, 0.877884);
    c = mul(RGB_2_D65XYZ_2_D60XYZ, c);

    // XYZ dim to dark surrounding
    c.y = POW(c.y, 1.0192641);

    static const float3x3 XYZ_2_AP1_2_INV_ODT_SAT = float3x3(1.74242, -0.404036, -0.258584, -0.73346, 1.68778, 0.0141041, -0.00771874, -0.0592309, 1.05878);
    c = mul(XYZ_2_AP1_2_INV_ODT_SAT, c);

    // scale linear code value to luminance
    c = c * 47.98 + 0.02;

    // apply SegmentedSplineC9Rev
    c.r = SegmentedSplineC9Rev(c.r);
    c.g = SegmentedSplineC9Rev(c.g);
    c.b = SegmentedSplineC9Rev(c.b);

    // end of ODT and beginning of RRT

    // apply SegmentedSplineC5Rev
    c.r = SegmentedSplineC5Rev(c.r);
    c.g = SegmentedSplineC5Rev(c.g);
    c.b = SegmentedSplineC5Rev(c.b);

    static const float3x3 INV_RRT_SAT_2_AP1_2_AP0 = float3x3(0.715293, 0.12079, 0.163914, 0.0375268, 0.869741, 0.0927325, -0.0148903, -0.0215572, 1.03645);
    c = mul(INV_RRT_SAT_2_AP1_2_AP0, c);
    c = max(0.0, c);

    // red modifier
    float centered_hue = RGBToCenteredHue(c);
    float hue_weight = smoothstep(0.0, 1.0, 1.0 - abs(centered_hue / 67.5)); hue_weight *= hue_weight;
    float min_chan = centered_hue < 0 ? c.g : c.b;
    float3 abc = float3(
        hue_weight * 0.18 - 1.0,
        c.r - hue_weight * (0.03 + min_chan) * 0.18,
        hue_weight * min_chan * 0.0054
    );
    c.r = (abc.y + sqrt(abc.y * abc.y - 4 * abc.x * abc.z)) / (2.0 - hue_weight * 0.36);

    //glow module
    float s = SigmoidShaper(RGBToSaturation(c) * 5.0 - 2.0);
    c *= 1.0 + GlowRev(RGBToYC(c), 0.05 * s);

    static const float3x3 AP0_2_AP1 = float3x3(1.4514393, -0.2365107, -0.2149286, -0.0765538, 1.1762297, -0.0996759, 0.0083161, -0.0060324, 0.9977163);
    c = mul(AP0_2_AP1, c);

    return c;
}

float3 ApplyACESFull(float3 c)
{
    static const float3x3 AP1_2_AP0 = float3x3(0.6954522, 0.1406787, 0.1638690, 0.0447946, 0.8596711, 0.0955343, -0.0055259, 0.0040252, 1.0015007);
    c = mul(AP1_2_AP0, c);

    // glow module
    float saturation = RGBToSaturation(c);
    float s = SigmoidShaper(saturation * 5.0 - 2.0);
    c *= 1.0 + GlowFwd(RGBToYC(c), 0.05 * s);

    // red modifier
    float centered_hue = RGBToCenteredHue(c);
    float hue_weight = smoothstep(0.0, 1.0, 1.0 - abs(centered_hue / 67.5));
    hue_weight *= hue_weight;
    c.r += hue_weight * saturation * (0.03 - c.r) * 0.18;

    static const float3x3 AP0_2_AP1_2_RRT_SAT = float3x3(1.40427, -0.200087, -0.204184, -0.0626024, 1.15614, -0.0935414, 0.0188727, 0.0211722, 0.959956);
    c = max(0.0, c);
    c = mul(AP0_2_AP1_2_RRT_SAT, c);

    // apply SegmentedSplineC5Fwd
    c.r = SegmentedSplineC5Fwd(c.r);
    c.g = SegmentedSplineC5Fwd(c.g);
    c.b = SegmentedSplineC5Fwd(c.b);

    // end of RRT and beginning of ODT

    // apply SegmentedSplineC9Fwd
    c.r = SegmentedSplineC9Fwd(c.r);
    c.g = SegmentedSplineC9Fwd(c.g);
    c.b = SegmentedSplineC9Fwd(c.b);

    // scale luminance to linear code value
    c = (c - 0.02) / 47.98;

    static const float3x3 ODT_SAT_2_XYZ = float3x3(0.64153, 0.159, 0.154561, 0.278621, 0.661272, 0.0592381, 0.0202637, 0.0381523, 0.948922);
    c = mul(ODT_SAT_2_XYZ, c);

    // XYZ dark surround to dim surround
    c.y = POW(c.y, 0.9811);

    static const float3x3 D60XYZ_2_D65XYZ_2_BT709 = float3x3(3.20638, -1.53246, -0.475632, -0.995376, 1.89005, 0.0510547, 0.0750713, -0.234921, 1.14156);
    c = mul(D60XYZ_2_D65XYZ_2_BT709, c);

    return c;
}
#endif // disable ACESFull

float3 ACEScgToACEScct(float3 c)
{
    return c < 0.0078125 ? (10.5402377 * c + 0.0729055) : ((log2(c) + 9.72) / 17.52);
}

float3 ACEScctToACEScg(float3 c)
{
    return c > 0.1552511 ? exp2(c * 17.52 - 9.72) : ((c - 0.0729055) / 10.5402377);
}

float3 ACEScgToACEScc(float3 c)
{
    return c <= 0 ? -0.3584475 : c < 0.0000305 ? ((log2(0.0000153 + c * 0.5) + 9.72) / 17.52) : (log2(c) + 9.72) / 17.52;
}

float3 ACESccToACEScg(float3 c)
{
    return c < -0.3013699 ? (exp2(c * 17.52 - 9.72) * 2.0 - 0.0000306) : c < 1.4680365 ? exp2(c * 17.52 - 9.72) : FLOAT_MAX;
}

float ACESToLumi(float3 c)
{
    return dot(c, float3(0.272229, 0.674082, 0.0536895));
}

float3 RGBToACEScg(float3 c)
{
    static const float3x3 BT709_2_AP1 = float3x3(0.6130973, 0.3395229, 0.0473793, 0.0701942, 0.9163556, 0.0134526, 0.0206156, 0.1095698, 0.8698151);

    return mul(BT709_2_AP1, c);
}

float3 ACEScgToRGB(float3 c)
{
    static const float3x3 AP1_2_BT709 = float3x3(1.70505, -0.621791, -0.0832584, -0.130257, 1.1408, -0.0105485, -0.0240033, -0.128969, 1.15297);

    return mul(AP1_2_BT709, c);
}

float3 ApplyACESFitted(float3 c)
{
    static const float3x3 AP1_2_AP0 = float3x3(0.6954522, 0.1406787, 0.1638690, 0.0447946, 0.8596711, 0.0955343, -0.0055259, 0.0040252, 1.0015007);
    c = mul(AP1_2_AP0, c);

    // glow module
    float saturation = RGBToSaturation(c);
    float s = SigmoidShaper(saturation * 5.0 - 2.0);
    c *= 1.0 + GlowFwd(RGBToYC(c), 0.05 * s);

    // red modifier
    float centered_hue = RGBToCenteredHue(c);
    float hue_weight = smoothstep(0.0, 1.0, 1.0 - abs(centered_hue / 67.5)); hue_weight *= hue_weight;
    c.r += hue_weight * saturation * (0.03 - c.r) * 0.18;

    // RRT desaturation
    static const float3x3 AP0_2_AP1_2_RRT_SAT = float3x3(1.40427, -0.200087, -0.204184, -0.0626024, 1.15614, -0.0935414, 0.0188727, 0.0211722, 0.959956);
    c = max(0.0, c);
    c = mul(AP0_2_AP1_2_RRT_SAT, c);

    // Red is Hill's, Blue is color-science's curve https://www.desmos.com/calculator/to1kpt4pwc

    // Stephen Hill's curve
    /* c = (c * (c + 0.0245786) - 0.000090537) * RCP(c * (0.983729 * c + 0.4329510) + 0.238081); */
    // color-science curve
    c = (c * (278.5085 * c + 10.7772)) * RCP(c * (293.6045 * c + 88.7122) + 80.6889);

    static const float3x3 ODT_SAT_2_D60XYZ_2_D65XYZ_2_BT709 = float3x3(1.60475, -0.53108, -0.07367, -0.10208,  1.10813, -0.00605, -0.00327, -0.07276,  1.07602);
    c = mul(ODT_SAT_2_D60XYZ_2_D65XYZ_2_BT709, c);

    return c;
}
