//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade 4.0 effect file
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Multi-LUT shader, using a texture atlas with multiple LUTs
// by Otis / Infuse Project.
// Based on Marty's LUT shader 1.0 for ReShade 3.0
// Further improvements including overall intensity, multiple texture support, and increased precision added by seri14 and Marot Satil.
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// wShade_Salty.png was created by Wifi Photospire
// Follow them on Twitter here: https://twitter.com/WiFi_photospire
//
// wShade_Sour.png was created by Wifi Photospire
// Follow them on Twitter here: https://twitter.com/WiFi_photospire
//
// wShade_Savory.png was created by Wifi Photospire
// Follow them on Twitter here: https://twitter.com/WiFi_photospire
//
// wShade_Sweet.png was created by Wifi Photospire
// Follow them on Twitter here: https://twitter.com/WiFi_photospire
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Lightly optimized by Marot Satil for the GShade project.


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Lut Definitions
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef fLUT_SALTextureName
    #define fLUT_SALTextureName "wShade_Salty.png" //
#endif
#ifndef fLUT_SOUTextureName
    #define fLUT_SOUTextureName "wShade_Sour.png" // 
#endif
#ifndef fLUT_SAVTextureName
    #define fLUT_SAVTextureName "wShade_Savory.png" // 
#endif
#ifndef fLUT_SWETextureName
    #define fLUT_SWETextureName "wShade_Sweet.png" // 
#endif


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Lut Sizing 
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef fLUT_ZTileSizeXY // SIZE
    #define fLUT_ZTileSizeXY 32
#endif
#ifndef fLUT_ZTileAmount // X-COUNT 
    #define fLUT_ZTileAmount 32
#endif
#ifndef fLUT_ZLut_Amount // ROWS 
    #define fLUT_ZLut_Amount 20
#endif
#ifndef fLUT_ZLut_AmountLOW
    #define fLUT_ZLut_AmountLOW 8
#endif
#ifndef fLUT_ZLut_AmountMAX
    #define fLUT_ZLut_AmountMAX 32
#endif
#ifndef fLUT_ZLut_AmountMID
    #define fLUT_ZLut_AmountMID 16
#endif


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// PASS 1
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int fLUT_WifiLutSelector <
    ui_category = "Pass 1";
    ui_type = "combo";
    ui_items = " Salty\0 Sour\0 Savory\0 Sweet\0";
    ui_label = "The WifiLut file to use.";
    ui_tooltip = "Set this to whatever build your preset was made with!";
    ui_bind = "WifiLutTexture_Source";
> = 0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef WifiLutTexture_Source
    #undef WifiLutTexture_Source // No idea why yet but if this isn't here, it causes issues under DirectX 9.
    #define WifiLutTexture_Source 0
#endif

uniform int fLUT_LutSelector < 
    ui_category = "Pass 1";
    ui_type = "combo";

#if WifiLutTexture_Source == 0 // Salty
    ui_items = " Truffle\0 Tart\0 Souffle\0 Sorbet\0 Macaron\0 Pudding\0 Crisp\0 Mousse\0 Cheesecake\0 Cannoli\0 Brownie\0 Parfait\0 Tiramisu\0 Eclair\0 Baklava\0 Blondie\0 Clafoutis\0 Gelato\0 Creme\0 Brulee\0 ";
#elif WifiLutTexture_Source == 1// Sour
    ui_items = " Scone\0 Fudge\0 Cupcake\0 Profiterole\0 Crumble\0 Shortcake\0 Trifle\0 Biscotti\0 Marshmallow\0 Pavlova\0 Sundae\0 Caramel\0 PannaCotta\0 Flan\0 Churro\0 Brioche\0 Croissant\0 Beignet\0 Danish\0 Cinnamon\0 ";
#elif WifiLutTexture_Source == 2// Savory
    ui_items = " Gourmet\0 Umami\0 Quiche\0 Risotto\0 Bruschetta\0 Tapenade\0 Frittata\0 Galette\0 Ratatouille\0 Crostini\0 Gratin\0 Empanada\0 Croquette\0 Samosa\0 Gyoza\0 Pate\0 Borscht\0 Ciabatta\0 Focaccia\0 Calzone\0 ";
#elif WifiLutTexture_Source == 3// Sweet
    ui_items = " Dolcissimo\0 Celestia\0 Amarena\0 Fruttato\0 Pistacchio\0 Bacio\0 Cioccolato\0 Limoncello\0 Stracciatella\0 Zabaglione\0 Fiorito\0 Noisette\0 Caramello\0 Mandoria\0 Zenzero\0 Mora\0 Cannella\0 Fragola\0 Pesca\0 Vaniglia\0 ";

#else
    ui_items = "Color0 (Usually Neutral)\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10 | Colors above 10\0Color11 | may not work for\0Color12 | all WifiLut files.\0Color13\0Color14\0Color15\0Color16\0Color17\0";



#endif
    ui_label = "LUT to use.";
    ui_tooltip = "LUT to use for color transformation.";
> = 0;

uniform float fLUT_Intensity <
    ui_category = "Pass 1";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Intensity";
    ui_tooltip = "Overall intensity of the LUT effect.";
> = 1.00;

uniform float fLUT_AmountChroma <
    ui_category = "Pass 1";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Chroma Amount";
    ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float fLUT_AmountLuma <
    ui_category = "Pass 1";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Luma Amount";
    ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  PASS 2
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


uniform bool fLUT_WifiLutPass2 <
    ui_category = "Pass 2";
    ui_label = "Enable Pass 2";
    ui_bind = "WifiLutTexture2";
> = 0;

#ifndef WifiLutTexture2
    #define WifiLutTexture2 0
#endif

#if WifiLutTexture2
uniform int fLUT_WifiLutSelector2 <
    ui_category = "Pass 2";
    ui_type = "combo";
    ui_items = " Salty\0 Sour\0 Savory\0 Sweet\0";
    ui_label = "The WifiLut file to use.";
    ui_tooltip = "The WifiLut table to use on Pass 2.";
    ui_bind = "WifiLutTexture2_Source";
> = 1;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef WifiLutTexture2_Source
    #undef WifiLutTexture2_Source // No idea why yet but if this isn't here, it causes issues under DirectX 9.
    #define WifiLutTexture2_Source 1
#endif

uniform int fLUT_LutSelector2 < 
    ui_category = "Pass 2";
    ui_type = "combo";
	
#if WifiLutTexture_Source == 0 // Salty
    ui_items = " Truffle\0 Tart\0 Souffle\0 Sorbet\0 Macaron\0 Pudding\0 Crisp\0 Mousse\0 Cheesecake\0 Cannoli\0 Brownie\0 Parfait\0 Tiramisu\0 Eclair\0 Baklava\0 Blondie\0 Clafoutis\0 Gelato\0 Creme\0 Brulee\0 ";
#elif WifiLutTexture_Source == 1// Sour
    ui_items = " Scone\0 Fudge\0 Cupcake\0 Profiterole\0 Crumble\0 Shortcake\0 Trifle\0 Biscotti\0 Marshmallow\0 Pavlova\0 Sundae\0 Caramel\0 PannaCotta\0 Flan\0 Churro\0 Brioche\0 Croissant\0 Beignet\0 Danish\0 Cinnamon\0 ";
#elif WifiLutTexture_Source == 2// Savory
    ui_items = " Gourmet\0 Umami\0 Quiche\0 Risotto\0 Bruschetta\0 Tapenade\0 Frittata\0 Galette\0 Ratatouille\0 Crostini\0 Gratin\0 Empanada\0 Croquette\0 Samosa\0 Gyoza\0 Pate\0 Borscht\0 Ciabatta\0 Focaccia\0 Calzone\0 ";
#elif WifiLutTexture_Source == 3// Sweet
    ui_items = " Dolcissimo\0 Celestia\0 Amarena\0 Fruttato\0 Pistacchio\0 Bacio\0 Cioccolato\0 Limoncello\0 Stracciatella\0 Zabaglione\0 Fiorito\0 Noisette\0 Caramello\0 Mandoria\0 Zenzero\0 Mora\0 Cannella\0 Fragola\0 Pesca\0 Vaniglia\0 ";
	
#else

    ui_items = "Color0 (Usually Neutral)\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10 | Colors above 10\0Color11 | may not work for\0Color12 | all WifiLut files.\0Color13\0Color14\0Color15\0Color16\0Color17\0";
#endif

    ui_label = "LUT to use.";
    ui_tooltip = "LUT to use for color transformation on Pass 2.";
> = 0;

uniform float fLUT_Intensity2 <
    ui_category = "Pass 2";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Intensity";
    ui_tooltip = "Overall intensity of the LUT effect.";
> = 1.00;

uniform float fLUT_AmountChroma2 <
    ui_category = "Pass 2";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Chroma Amount";
    ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float fLUT_AmountLuma2 <
    ui_category = "Pass 2";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Luma Amount";
    ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;
#endif


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// PASS 3
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



uniform bool fLUT_WifiLutPass3 <
    ui_category = "Pass 3";
    ui_label = "Enable Pass 3";
    ui_bind = "WifiLutTexture3";
> = 0;

#ifndef WifiLutTexture3
    #define WifiLutTexture3 0
#endif

#if WifiLutTexture3
uniform int fLUT_WifiLutSelector3 <
    ui_category = "Pass 3";
    ui_type = "combo";
    ui_items = " Salty\0 Sour\0 Savory\0 Sweet\0";
    ui_label = "The WifiLut file to use.";
    ui_tooltip = "The WifiLut table to use on Pass 3.";
    ui_bind = "WifiLutTexture3_Source";
> = 1;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef WifiLutTexture3_Source
    #undef WifiLutTexture3_Source // No idea why yet but if this isn't here, it causes issues under DirectX 9.
    #define WifiLutTexture3_Source 1
#endif

uniform int fLUT_LutSelector3 < 
    ui_category = "Pass 3";
    ui_type = "combo";

#if WifiLutTexture_Source == 0 // Salty
    ui_items = " Truffle\0 Tart\0 Souffle\0 Sorbet\0 Macaron\0 Pudding\0 Crisp\0 Mousse\0 Cheesecake\0 Cannoli\0 Brownie\0 Parfait\0 Tiramisu\0 Eclair\0 Baklava\0 Blondie\0 Clafoutis\0 Gelato\0 Creme\0 Brulee\0 ";
#elif WifiLutTexture_Source == 1// Sour
    ui_items = " Scone\0 Fudge\0 Cupcake\0 Profiterole\0 Crumble\0 Shortcake\0 Trifle\0 Biscotti\0 Marshmallow\0 Pavlova\0 Sundae\0 Caramel\0 PannaCotta\0 Flan\0 Churro\0 Brioche\0 Croissant\0 Beignet\0 Danish\0 Cinnamon\0 ";
#elif WifiLutTexture_Source == 2// Savory
    ui_items = " Gourmet\0 Umami\0 Quiche\0 Risotto\0 Bruschetta\0 Tapenade\0 Frittata\0 Galette\0 Ratatouille\0 Crostini\0 Gratin\0 Empanada\0 Croquette\0 Samosa\0 Gyoza\0 Pate\0 Borscht\0 Ciabatta\0 Focaccia\0 Calzone\0 ";
#elif WifiLutTexture_Source == 3// Sweet
    ui_items = " Dolcissimo\0 Celestia\0 Amarena\0 Fruttato\0 Pistacchio\0 Bacio\0 Cioccolato\0 Limoncello\0 Stracciatella\0 Zabaglione\0 Fiorito\0 Noisette\0 Caramello\0 Mandoria\0 Zenzero\0 Mora\0 Cannella\0 Fragola\0 Pesca\0 Vaniglia\0 ";

#else
    ui_items = "Color0 (Usually Neutral)\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10 | Colors above 10\0Color11 | may not work for\0Color12 | all WifiLut files.\0Color13\0Color14\0Color15\0Color16\0Color17\0";
	
#endif
    ui_label = "LUT to use.";
    ui_tooltip = "LUT to use for color transformation on Pass 3.";
> = 0;

uniform float fLUT_Intensity3 <
    ui_category = "Pass 3";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Intensity";
    ui_tooltip = "Overall intensity of the LUT effect.";
> = 1.00;

uniform float fLUT_AmountChroma3 <
    ui_category = "Pass 3";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Chroma Amount";
    ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float fLUT_AmountLuma3 <
    ui_category = "Pass 3";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Luma Amount";
    ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  LUT AMOUNTS AND SHIT
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  PASS1
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#if WifiLutTexture_Source == 0 // Salty wShade_Salty.png
    #define _SOURCE_WifiLut_FILE fLUT_SALTextureName
    #define _SOURCE_WifiLut_AMOUNT fLUT_ZLut_Amount

#elif WifiLutTexture_Source == 1 // Sour wShade_Sour.png
    #define _SOURCE_WifiLut_FILE fLUT_SOUTextureName
    #define _SOURCE_WifiLut_AMOUNT fLUT_ZLut_Amount

#elif WifiLutTexture_Source == 2 // Savory wShade_Savory.png
    #define _SOURCE_WifiLut_FILE fLUT_SAVTextureName
    #define _SOURCE_WifiLut_AMOUNT fLUT_ZLut_Amount

#elif WifiLutTexture_Source == 3 // Sweet wShade_Sweet.png
    #define _SOURCE_WifiLut_FILE fLUT_SWETextureName
    #define _SOURCE_WifiLut_AMOUNT fLUT_ZLut_Amount
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  PASS 2
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#if WifiLutTexture_Source == 0 // Salty wShade_Salty.png
    #define _SOURCE_WifiLut_FILE2 fLUT_SALTextureName
    #define _SOURCE_WifiLut_AMOUNT2 fLUT_ZLut_Amount

#elif WifiLutTexture_Source == 1 // Sour wShade_Sour.png
    #define _SOURCE_WifiLut_FILE2 fLUT_SOUTextureName
    #define _SOURCE_WifiLut_AMOUNT2 fLUT_ZLut_Amount

#elif WifiLutTexture_Source == 2 // Savory wShade_Savory.png
    #define _SOURCE_WifiLut_FILE2 fLUT_SAVTextureName
    #define _SOURCE_WifiLut_AMOUNT2 fLUT_ZLut_Amount

#elif WifiLutTexture_Source == 3 // Sweet wShade_Sweet.png
    #define _SOURCE_WifiLut_FILE2 fLUT_SWETextureName
    #define _SOURCE_WifiLut_AMOUNT2 fLUT_ZLut_Amount
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  PASS 3
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


#if WifiLutTexture_Source == 0 // Salty wShade_Salty.png
    #define _SOURCE_WifiLut_FILE3 fLUT_SALTextureName
    #define _SOURCE_WifiLut_AMOUNT3 fLUT_ZLut_Amount

#elif WifiLutTexture_Source == 1 // Sour wShade_Sour.png
    #define _SOURCE_WifiLut_FILE3 fLUT_SOUTextureName
    #define _SOURCE_WifiLut_AMOUNT3 fLUT_ZLut_Amount

#elif WifiLutTexture_Source == 2 // Savory wShade_Savory.png
    #define _SOURCE_WifiLut_FILE3 fLUT_SAVTextureName
    #define _SOURCE_WifiLut_AMOUNT3 fLUT_ZLut_Amount

#elif WifiLutTexture_Source == 3 // Sweet wShade_Sweet.png
    #define _SOURCE_WifiLut_FILE3 fLUT_SWETextureName
    #define _SOURCE_WifiLut_AMOUNT3 fLUT_ZLut_Amount
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  SIZING CODE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

texture texWifiLut < source = _SOURCE_WifiLut_FILE; > { Width = fLUT_ZTileSizeXY * fLUT_ZTileAmount; Height = fLUT_ZTileSizeXY * _SOURCE_WifiLut_AMOUNT; Format = RGBA8; };
sampler SamplerWifiLut { Texture = texWifiLut; };

#if WifiLutTexture2
    texture texWifiLut2 < source = _SOURCE_WifiLut_FILE2; > { Width = fLUT_ZTileSizeXY * fLUT_ZTileAmount; Height = fLUT_ZTileSizeXY * _SOURCE_WifiLut_AMOUNT2; Format = RGBA8; };
    sampler SamplerWifiLut2{ Texture = texWifiLut2; };
#endif

#if WifiLutTexture3
    texture texWifiLut3 < source = _SOURCE_WifiLut_FILE3; > { Width = fLUT_ZTileSizeXY * fLUT_ZTileAmount; Height = fLUT_ZTileSizeXY * _SOURCE_WifiLut_AMOUNT3; Format = RGBA8; };
    sampler SamplerWifiLut3{ Texture = texWifiLut3; };
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float3 apply(in const float3 color, in const int tex, in const float lut)
{
    const float2 texelsize = 1.0 / float2(fLUT_ZTileSizeXY * fLUT_ZTileAmount, fLUT_ZTileSizeXY);
    float3 lutcoord = float3((color.xy * fLUT_ZTileSizeXY - color.xy + 0.5) * texelsize, (color.z  * fLUT_ZTileSizeXY - color.z));

    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z - lerpfact) * texelsize.y;
    lutcoord.y = lut / _SOURCE_WifiLut_AMOUNT + lutcoord.y / _SOURCE_WifiLut_AMOUNT;

    return lerp(tex2D(SamplerWifiLut, lutcoord.xy).xyz, tex2D(SamplerWifiLut, float2(lutcoord.x + texelsize.y, lutcoord.y)).xyz, lerpfact);
}

#if WifiLutTexture2
float3 apply2(in const float3 color, in const int tex, in const float lut)
{
    const float2 texelsize = 1.0 / float2(fLUT_ZTileSizeXY * fLUT_ZTileAmount, fLUT_ZTileSizeXY);
    float3 lutcoord = float3((color.xy * fLUT_ZTileSizeXY - color.xy + 0.5) * texelsize, (color.z * fLUT_ZTileSizeXY - color.z));

    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z - lerpfact) * texelsize.y;
    lutcoord.y = lut / _SOURCE_WifiLut_AMOUNT2 + lutcoord.y / _SOURCE_WifiLut_AMOUNT2;

    return lerp(tex2D(SamplerWifiLut2, lutcoord.xy).xyz, tex2D(SamplerWifiLut2, float2(lutcoord.x + texelsize.y, lutcoord.y)).xyz, lerpfact);
}
#endif

#if WifiLutTexture3
float3 apply3(in const float3 color, in const int tex, in const float lut)
{
    const float2 texelsize = 1.0 / float2(fLUT_ZTileSizeXY * fLUT_ZTileAmount, fLUT_ZTileSizeXY);
    float3 lutcoord = float3((color.xy * fLUT_ZTileSizeXY - color.xy + 0.5) * texelsize, (color.z * fLUT_ZTileSizeXY - color.z));

    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z - lerpfact) * texelsize.y;
    lutcoord.y = lut / _SOURCE_WifiLut_AMOUNT3 + lutcoord.y / _SOURCE_WifiLut_AMOUNT3;

    return lerp(tex2D(SamplerWifiLut3, lutcoord.xy).xyz, tex2D(SamplerWifiLut3, float2(lutcoord.x + texelsize.y, lutcoord.y)).xyz, lerpfact);
}
#endif

void PS_WifiLut_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float3 res : SV_Target)
{
    const float3 color = tex2D(ReShade::BackBuffer, texcoord).xyz;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Pass 1
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#if !WifiLutTexture2 && !WifiLutTexture3
    const float3 lutcolor = lerp(color, apply(color, fLUT_WifiLutSelector, fLUT_LutSelector), fLUT_Intensity);
#else
    float3 lutcolor = lerp(color, apply(color, fLUT_WifiLutSelector, fLUT_LutSelector), fLUT_Intensity);
#endif

    res = lerp(normalize(color), normalize(lutcolor), fLUT_AmountChroma)
        * lerp(   length(color),    length(lutcolor),   fLUT_AmountLuma);

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Pass 2
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#if WifiLutTexture2
    res = saturate(res);
    lutcolor = lerp(res, apply2(res, fLUT_WifiLutSelector2, fLUT_LutSelector2), fLUT_Intensity2);

    res = lerp(normalize(res), normalize(lutcolor), fLUT_AmountChroma2)
        * lerp(   length(res),    length(lutcolor),   fLUT_AmountLuma2);
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Pass 3
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#if WifiLutTexture3
    res = saturate(res);
    lutcolor = lerp(res, apply3(res, fLUT_WifiLutSelector3, fLUT_LutSelector3), fLUT_Intensity3);

    res = lerp(normalize(res), normalize(lutcolor), fLUT_AmountChroma3)
        * lerp(   length(res),    length(lutcolor),   fLUT_AmountLuma3);
#endif

#if GSHADE_DITHER
	res += TriDither(res, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique WifiLUT
{
    pass WifiLut_Apply
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_WifiLut_Apply;
    }
}
