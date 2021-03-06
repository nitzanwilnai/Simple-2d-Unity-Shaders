﻿Shader "Unlit/fish_shader"
{
	// these are variables you can pass to the shader from the inspector or from a script
    Properties
    {
        // we have removed support for texture tiling/offset,
        // so make them not be displayed in material inspector
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _PatternTex ("Texture", 2D) = "white" {} // our secondary, pattern texture
 		_ColorRedTint ("Red Color Tint", Color) = (1,1,1)
		_ColorGreenTint ("Green Color Tint", Color) = (1,1,1)
		_ColorBlueTint ("Blue Color Tint", Color) = (1,1,1)
		_PatternAtlasTiles("Pattern Atlas Location", Vector) = (0, 0, 0, 0) // information about the atlas, the pattern tile (x,y), and the num tiles wide/high for the atlas
    }

    // actual shader code begins here
    SubShader
    {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 100

		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha 

        Pass
        {
            CGPROGRAM
			// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct appdata members uv2_MainTex2)
			#pragma exclude_renderers d3d11
            // use "vert" function as the vertex shader
            #pragma vertex vert
            // use "frag" function as the pixel (fragment) shader
            #pragma fragment frag

             #include "UnityCG.cginc"

            // vertex shader inputs
            struct appdata
            {
                float4 vertex : POSITION; // vertex position
                float2 uv_MainTex : TEXCOORD0;
                float2 uv2_PatternTex : TEXCOORD1;
            };

            // vertex shader outputs ("vertex to fragment")
            struct v2f
            {
                float4 vertex : SV_POSITION; // clip space position
                half2 texCoord : TEXCOORD0; // texture coordinate
                half2 texCoord2: TEXCOORD1;
            };


            sampler2D _MainTex; // primary texture
            sampler2D _PatternTex; // secondary, pattern texture
            fixed3 _ColorRedTint; // tint colors
            fixed3 _ColorGreenTint;
            fixed3 _ColorBlueTint;
            fixed4 _PatternAtlasTiles; // (x,y) is which tile we want (0,0 is top left), (z,w) is how many tiles wide and high the atlas is

            // varibles filled by Unity automagically for each texture
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            float4 _PatternTex_ST;
            float4 _PatternTex_TexelSize;

            // vertex shader
            v2f vert (appdata v)
            {
                 v2f o;
                 o.vertex = UnityObjectToClipPos(v.vertex);
                 o.texCoord = TRANSFORM_TEX(v.uv_MainTex, _MainTex);
                 o.texCoord2 = TRANSFORM_TEX(v.uv2_PatternTex, _PatternTex);
                 return o;
            }

            // pixel shader; returns low precision ("fixed4" type)
            // color ("SV_Target" semantic)
            fixed4 frag (v2f pix) : SV_Target
            {
            	// we need to figure out our tile location
	            float tilesWide = _PatternAtlasTiles.z;
	            float tilesHigh = _PatternAtlasTiles.w;
            	float tileStartX = floor(pix.texCoord.x * tilesWide) / tilesWide;
            	float tileStartY = floor(pix.texCoord.y * tilesHigh) / tilesHigh;
            	float tileWidth = 1 / _PatternAtlasTiles.z;
            	float tileHeight = 1 / _PatternAtlasTiles.w;

                // sample texture and return it
				fixed4 originalCol = tex2D(_MainTex, pix.texCoord);
                fixed4 newColor = originalCol;

            	float2 patternCoord = pix.texCoord;
            	patternCoord.x += (_PatternAtlasTiles.x * tileWidth - tileStartX);
            	patternCoord.y += (_PatternAtlasTiles.y * tileHeight - tileStartY);
	            fixed4 pattern = tex2D(_PatternTex, patternCoord);

                if(newColor.a != 0) {

                	// calculate the new tinted color of the original pixel
	                fixed3 tintedColor = originalCol.r * _ColorRedTint + originalCol.g * _ColorGreenTint + originalCol.b * _ColorBlueTint;
	                //replace it with the tinted color from the pattern, if the pattern alpha is greater than 0
	                newColor.rgb = pattern.a != 0 ? (pattern.r * _ColorRedTint + pattern.g * _ColorGreenTint + pattern.b * _ColorBlueTint) : tintedColor.rgb;
				}

                return newColor;
            }
            ENDCG
        }

    }
}
