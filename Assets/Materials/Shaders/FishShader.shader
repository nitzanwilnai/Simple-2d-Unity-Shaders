Shader "Unlit/fish_shader"
{
    Properties
    {
        // we have removed support for texture tiling/offset,
        // so make them not be displayed in material inspector
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _PatternTex ("Texture", 2D) = "white" {}
 		_ColorRedTint ("Red Color Tint", Color) = (1,1,1)
		_ColorGreenTint ("Green Color Tint", Color) = (1,1,1)
		_ColorBlueTint ("Blue Color Tint", Color) = (1,1,1)
		_ColorStroke ("Stroke Color", Color) = (1,1,1)
		_Scaling ("Scaling", Vector) = (1, 1, 1, 1)
		_Align("Align? 0-None, 1-Top, 2-Right, 3-Bottom, 4-Left", float) = 0.0
		_PatternAtlasTiles("Pattern Atlas Location", Vector) = (0, 0, 0, 0)
    }
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
//                float2 uv2_PatternTex : TEXCOORD1;
            };

            // vertex shader outputs ("vertex to fragment")
            struct v2f
            {
                float4 vertex : SV_POSITION; // clip space position
                half2 texCoord : TEXCOORD0; // texture coordinate
//                half2 texCoord1: TEXCOORD1;
            };

            // texture we will sample
            sampler2D _MainTex;
            sampler2D _PatternTex;
            fixed3 _ColorRedTint;
            fixed3 _ColorGreenTint;
            fixed3 _ColorBlueTint;
            fixed3 _ColorStroke;
            fixed4 _Scaling;
            fixed  _Align;
            fixed4 _PatternAtlasTiles;

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
//                 o.texCoord1 = TRANSFORM_TEX(v.uv2_PatternTex, _PatternTex);
                 return o;
            }

            // pixel shader; returns low precision ("fixed4" type)
            // color ("SV_Target" semantic)
            fixed4 frag (v2f pix) : SV_Target
            {
            	float flipX = _Scaling.x < 0 ? 1.0 : 0.0;
            	float flipY = _Scaling.y < 0 ? 1.0 : 0.0;

                float2 oneOverScale = 1 / (_Scaling.xy);

            	float tilesWide = _Scaling.z;
            	float tilesHigh = _Scaling.w;
            	float tileWidth = 1.0/tilesWide;
            	float tileHeight = 1.0/tilesHigh;

            	float tileStartX = floor(pix.texCoord.x * tilesWide) / tilesWide;
            	float tileStartY = floor(pix.texCoord.y * tilesHigh) / tilesHigh;

            	float diffX = (tileWidth - (tileWidth * abs(oneOverScale.x))) / 2.0;
            	float diffY = (tileHeight - (tileHeight * abs(oneOverScale.y))) / 2.0;

            	float tileMidX = tileStartX + (tileWidth / 2.0);
            	float tileMidY = tileStartY + (tileHeight / 2.0);

            	float2 originalTexCoord = pix.texCoord;

            	float2 scaledTexCoord = originalTexCoord;// = ((originalTexCoord - (tileMidX,tileMidY)) * oneOverScale) + (tileMidX,tileMidY);
            	scaledTexCoord.x = ((originalTexCoord.x - tileMidX) * oneOverScale.x) + tileMidX;
            	scaledTexCoord.y = ((originalTexCoord.y - tileMidY) * oneOverScale.y) + tileMidY;

            	scaledTexCoord.x += _Align > 1.5 && _Align < 2.5 ? diffX : 0;
            	scaledTexCoord.x += _Align > 3.5 && _Align < 4.5 ? -diffX * 0.999 : 0; // diffY can't be 1.0, not sure why

            	scaledTexCoord.y += _Align > 0.5 && _Align < 1.5 ? diffY : 0;
            	scaledTexCoord.y += _Align > 2.5 && _Align < 3.5 ? -diffY * 0.999 : 0; // diffY can't be 1.0, not sure why

                // sample texture with new scaled coordinates
				fixed4 col = tex2D(_MainTex, scaledTexCoord);
                fixed4 newColor = col;

				if(abs(_Scaling.x) < 1.0) {
					if(scaledTexCoord.x <= tileStartX || scaledTexCoord.x > (tileStartX + tileWidth)) {
						newColor.a = 0.0;
					}
				}
				if(abs(_Scaling.y) < 1.0) {
					if(scaledTexCoord.y <= tileStartY || scaledTexCoord.y > (tileStartY + tileHeight)) {
						newColor.a = 0.0;
					}
				}

                float maxRadius = 6; // stroke size;


                if(newColor.a != 0) {

                	float2 patternCoord = scaledTexCoord;
                	patternCoord.x += (_PatternAtlasTiles.x * 0.25 - tileStartX);
                	patternCoord.y += (_PatternAtlasTiles.y * 0.25 - tileStartY);
    	            fixed4 pattern = tex2D(_PatternTex, patternCoord);


	                fixed3 tintedColor = col.r * _ColorRedTint + col.g * _ColorGreenTint + col.b * _ColorBlueTint;
	                newColor.rgb = pattern.a != 0 ? (pattern.r * _ColorRedTint + pattern.g * _ColorGreenTint + pattern.b * _ColorBlueTint) : tintedColor.rgb;

//	                fixed3 tintedColor = newColor;
//	                tintedColor = col.r * _ColorRedTint + col.g * _ColorGreenTint + col.b * _ColorBlueTint;
//	                newColor.rgb = tintedColor.rgb;

					// is there an alpha between 0 and 1 in my radius?
					int alphaFound = 0;
					float alphaRadius = 1;
					for(float radius = 1; radius <= maxRadius; radius+=1) {

						for(int x = -radius; x <= radius; x++) {
							int y = sqrt(radius * radius - x * x);

							for(int index = 0; index < 2; index++) {
								y = (index==1) ? -y : y;
								fixed2 checkTexCoord = scaledTexCoord + fixed2(_MainTex_TexelSize.x * x * oneOverScale.x, _MainTex_TexelSize.y * y * oneOverScale.y);
								fixed4 pixel = tex2D(_MainTex, checkTexCoord);

								if(pixel.a == 0) {
									alphaFound = 1;
									alphaRadius = radius;
								}
							}
						}

						if(alphaFound > 0.5) {
							break;
						}
					}

					// did we find an alpha pixel?
					if(alphaFound > 0.5) {
						float strokeBlend = 2;
						newColor.rgb = _ColorStroke;
						if(alphaRadius > maxRadius-strokeBlend) {
							alphaRadius -= (maxRadius-strokeBlend);
							float alphaDiff = alphaRadius / strokeBlend;
							newColor.rgb = _ColorStroke.rgb * (1-alphaDiff) + tintedColor.rgb * alphaDiff;
						}
					}

				}

                return newColor;
            }
            ENDCG
        }

    }
}
