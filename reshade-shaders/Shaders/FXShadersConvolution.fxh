////////////////////////////////////////////////////////
// FXShadersConvolution.fxh
// Author: luluco250
// License: MIT
// Repository: https://github.com/luluco250/FXShaders
////////////////////////////////////////////////////////
/*
MIT License

Copyright (c) 2017 Lucas Melo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#pragma once

#include "FXShadersMath.fxh"

namespace FXShaders
{

/**
 * Standard normal distribution formula.
 * Adapted from: https://en.wikipedia.org/wiki/Normal_distribution#General_normal_distribution
 *
 * @param x The value to distribute.
 * @param u The distribution mean.
 * @param o The distribution sigma.
 *          This value is squared in this function, so there's no need to square
 *          it beforehand, unlike the standard formula.
 */
float NormalDistribution(float x, float u, float o)
{
	o *= o;

	const float b = ((x - u) * (x - u)) / 2.0 * o;

	return (1.0 / sqrt(2.0 * Pi * o)) * exp(-(b));
}

/**
 * One dimensional gaussian distribution formula.
 *
 * @param x The value to distribute.
 * @param o The distribution sigma.
 *          This parameter is squared in this function, so there's no need to
 *          square it beforehand.
 */
float Gaussian1D(float x, float o)
{
	o *= o;
	const float b = (x * x) / (2.0 * o);
	return  (1.0 / sqrt(2.0 * Pi * o)) * exp(-b);
}

/**
 * One dimensional alternative gaussian distribution formula with less
 * instructions.
 *
 * @param x The value to distribute.
 * @param o The distribution sigma.
 *          This parameter is squared in this function, so there's no need to
 *          square it beforehand.
 */
float Gaussian1DFast(float x, float o)
{
	// NOTE: It does not seem to actually make the code noticeably faster.

	return exp(-(x * x) / (2.0 * o * o));
}

/**
 * Two dimensional gaussian distribution formula.
 *
 * @param i The x and y values to distribute.
 * @param o The distribution sigma.
 *          This parameter is squared in this function, so there's no need to
 *          square it beforehand.
 */
float Gaussian2D(float2 i, float o)
{
	o *= o;
	const float b = (i.x * i.x + i.y * i.y) / (2.0 * o);
	return (1.0 / (2.0 * Pi * o)) * exp(-b);
}

/**
 * One dimensional gaussian blur.
 *
 * @param sp The sampler to read from.
 * @param uv The normalized screen coordinates used for reading from the
 *           sampler.
 * @param dir The 2D direction and scale of the blur.
 *            Remember to pass the pixel/texel size here.
 * @param sigma The sigma value used for the gaussian distribution.
 *              This does not need to be squared.
 * @param samples The amount of blur samples to perform.
 *                This value must be constant.
 */
float4 GaussianBlur1D(
	sampler sp,
	float2 uv,
	float2 dir,
	float sigma,
	int samples)
{
	const float halfSamples = (samples - 1) * 0.5;

	float4 color = 0.0;
	float accum = 0.0;

	uv -= halfSamples * dir;

	[unroll]
	for (int i = 0; i < samples; ++i)
	{
		float weight = Gaussian1DFast(i - halfSamples, sigma);

		color += tex2D(sp, uv) * weight;
		accum += weight;

		uv += dir;
	}

	return color / accum;
}

/**
 * Two dimensional gaussian blur.
 *
 * @param sp The sampler to read from.
 * @param uv The normalized screen coordinates used for reading from the
 *           sampler.
 * @param scale The scale of the blur.
 *              Remember to pass the pixel/texel size here.
 * @param sigma The sigma value used for the gaussian distribution.
 *              This does not need to be squared.
 * @param samples The amount of blur samples to perform.
 *                This value must be constant.
 */
float4 GaussianBlur2D(
	sampler sp,
	float2 uv,
	float2 scale,
	float sigma,
	int2 samples)
{
	const float2 halfSamples = samples * 0.5;

	float4 color = 0.0;
	float accum = 0.0;

	uv -= halfSamples * scale;

	[unroll]
	for (int x = 0; x < samples.x; ++x)
	{
		float initX = uv.x;

		[unroll]
		for (int y = 0; y < samples.y; ++y)
		{
			float2 pos = float2(x, y);
			float weight = Gaussian2D(abs(pos - halfSamples), sigma);

			color += tex2D(sp, uv) * weight;
			accum += weight;

			uv.x += scale.x;
		}

		uv.x = initX;
		uv.y += scale.y;
	}

	return color / accum;
}

float4 LinearBlur1D(sampler sp, float2 uv, float2 dir, int samples)
{
	const float halfSamples = (samples - 1) * 0.5;
	uv -= halfSamples * dir;

	float4 color = 0.0;

	[unroll]
	for (int i = 0; i < samples; ++i)
	{
		color += tex2D(sp, uv);
		uv += dir;
	}

	return color / samples;
}

float4 MaxBlur1D(sampler sp, float2 uv, float2 dir, int samples)
{
	const float halfSamples = (samples - 1) * 0.5;
	uv -= halfSamples * dir;

	float4 color = 0.0;

	[unroll]
	for (int i = 0; i < samples; ++i)
	{
		color = max(color, tex2D(sp, uv));
		uv += dir;
	}

	return color;
}

float4 SharpBlur1D(sampler sp, float2 uv, float2 dir, int samples, float sharpness)
{
	static const float halfSamples = (samples - 1) * 0.5;
	static const float weight = 1.0 / samples;

	uv -= halfSamples * dir;

	float4 color = 0.0;

	[unroll]
	for (int i = 0; i < samples; ++i)
	{
		float4 pixel = tex2D(sp, uv);
		color = lerp(color + pixel * weight, max(color, pixel), sharpness);
		uv += dir;
	}

	return color;
}

} // Namespace.
