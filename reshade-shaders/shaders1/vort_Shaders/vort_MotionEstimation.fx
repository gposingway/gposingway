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

#include "Includes/vort_MotionVectors.fxh"
#include "Includes/vort_MotVectUtils.fxh"

/*******************************************************************************
    Shaders
*******************************************************************************/

void PS_Debug(PS_ARGS3) { o = MotVectUtils::Debug(i.uv, sMotVectTexVort, 1.0); }

/*******************************************************************************
    Techniques
*******************************************************************************/

technique vort_MotionEstimation
<
    ui_label = "vort_MotionEstimation (read the tooltip before enabling)";
    ui_tooltip =
        "Only needed if you want to use my motion vectors with other than my shaders\n"
        "or you've disabled the auto inclusion (Ex: V_MOT_BLUR_VECTORS_MODE isn't 0)\n"
        "\n"
        "Put them before other shaders which would require motion vectors.";
>
{
    PASS_MOT_VECT

    #if V_MOT_VECT_DEBUG
        pass { VertexShader = PostProcessVS; PixelShader = PS_Debug; }
    #endif
}
