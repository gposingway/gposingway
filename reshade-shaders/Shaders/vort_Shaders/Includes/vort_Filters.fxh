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
#include "Includes/vort_Defs.fxh"

/*******************************************************************************
    Globals
*******************************************************************************/

static const int2 COORDS_13_TAPS[13] = {
    int2(-2,-2), int2(0,-2), int2(2,-2),
    int2(-1,-1), int2(1,-1),
    int2(-2, 0), int2(0, 0), int2(2, 0),
    int2(-1, 1), int2(1, 1),
    int2(-2, 2), int2(0, 2), int2(2, 2)
};

static const float WEIGHTS_13_TAPS[13] = {
    0.03125, 0.0625, 0.03125,
    0.125, 0.125,
    0.06250, 0.1250, 0.06250,
    0.125, 0.125,
    0.03125, 0.0625, 0.03125
};

static const int2 COORDS_9_TAPS[9] = {
    int2(-1.0,-1.0), int2(0.0,-1.0), int2(1.0,-1.0),
    int2(-1.0, 0.0), int2(0.0, 0.0), int2(1.0, 0.0),
    int2(-1.0, 1.0), int2(0.0, 1.0), int2(1.0, 1.0)
};

static const float WEIGHTS_9_TAPS[9] = {
    0.0625, 0.1250, 0.0625,
    0.1250, 0.2500, 0.1250,
    0.0625, 0.1250, 0.0625
};

static const float2 COORDS_8_TAPS[8] = {
    float2(-0.7577, -0.7577), float2(0.7577, -0.7577),
    float2(0.7577, 0.7577), float2(-0.7577, 0.7577),
    float2(2.907, 0), float2(-2.907, 0),
    float2(0, 2.907), float2(0, -2.907)
};

static const float WEIGHTS_8_TAPS[8] = {
    0.37487566, 0.37487566,
    0.37487566, 0.37487566,
    -0.12487566, -0.12487566,
    -0.12487566, -0.12487566
};

/*******************************************************************************
    Functions
*******************************************************************************/

/*
 *   13 tap dual kawase filter
 *
 *   Coords       Weights
 *   a - b - c    1 - 2 - 1
 *   - d - e -    - 4 - 4 -
 *   f - g - h    2 - 4 - 2
 *   - i - j -    - 4 - 4 -
 *   k - l - m    1 - 2 - 1
 *
 *                0.03125
 */

float3 Filter13Taps(float2 uv, sampler samp, int mip)
{
    float2 texelsize = BUFFER_PIXEL_SIZE * exp2(mip);
    float3 color = 0;
    float2 offset = 0;
    float2 tap_uv = 0;

    [loop]for(int j = 0; j < 13; j++)
    {
        offset = COORDS_13_TAPS[j] * texelsize;
        tap_uv = uv + offset;

        // repeat
        /* tap_uv = saturate(tap_uv); */

        // mirror
        tap_uv = (tap_uv < 0 || tap_uv > 1) ? (uv - offset) : tap_uv;

        color += WEIGHTS_13_TAPS[j] * Sample(samp, tap_uv).rgb;
    }

    return color;
}

/*
 *   9-tap tent filter
 *
 *   Coords   Weights
 *   a b c    1 2 1
 *   d e f    2 4 2
 *   g h i    1 2 1
 *
 *            0.0625
 */

float3 Filter9Taps(float2 uv, sampler samp, int mip)
{
    float2 texelsize = BUFFER_PIXEL_SIZE * exp2(mip);
    float3 color = 0;
    float2 offset = 0;
    float2 tap_uv = 0;

    [loop]for(int j = 0; j < 9; j++)
    {
        offset = COORDS_9_TAPS[j] * texelsize;
        tap_uv = uv + offset;

        // repeat
        /* tap_uv = saturate(tap_uv); */

        // mirror
        tap_uv = (tap_uv < 0 || tap_uv > 1) ? (uv - offset) : tap_uv;

        color += WEIGHTS_9_TAPS[j] * Sample(samp, tap_uv).rgb;
    }

    return color;
}

/*
 * 8-tap Wronski filter
 *
 * https://www.shadertoy.com/view/fsjBWm
 */

float3 Filter8Taps(float2 uv, sampler samp, int mip)
{
    float2 texelsize = BUFFER_PIXEL_SIZE * exp2(mip);
    float3 color = 0;
    float2 offset = 0;
    float2 tap_uv = 0;

    [loop]for(int j = 0; j < 8; j++)
    {
        offset = COORDS_8_TAPS[j] * texelsize;
        tap_uv = uv + offset;

        // repeat
        /* tap_uv = saturate(tap_uv); */

        // mirror
        tap_uv = (tap_uv < 0 || tap_uv > 1) ? (uv - offset) : tap_uv;

        color += WEIGHTS_8_TAPS[j] * Sample(samp, tap_uv).rgb;
    }

    return color;
}
