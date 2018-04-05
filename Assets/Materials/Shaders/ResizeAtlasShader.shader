Shader "Unlit/fish_shader"
{
    Properties
    {
        // we have removed support for texture tiling/offset,
        // so make them not be displayed in material inspector
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		_Scaling ("Scaling", Vector) = (1, 1, 1, 1)
		_Align("Align? 0-None, 1-Top, 2-Right, 3-Bottom, 4-Left", float) = 0.0
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

            };

            // vertex shader outputs ("vertex to fragment")
            struct v2f
            {
                float4 vertex : SV_POSITION; // clip space position
                half2 texCoord : TEXCOORD0; // texture coordinate
            };

            // texture we will sample
            sampler2D 	_MainTex;
            fixed4 		_Scaling;
            fixed 		_Align;

            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            // vertex shader
            v2f vert (appdata v)
            {
                 v2f o;
                 o.vertex = UnityObjectToClipPos(v.vertex);
                 o.texCoord = TRANSFORM_TEX(v.uv_MainTex, _MainTex);

                 return o;
            }

            // pixel shader; returns low precision ("fixed4" type)
            // color ("SV_Target" semantic)
            fixed4 frag (v2f pix) : SV_Target
            {
            	float2 oneOverScale = 1 / _Scaling.xy;

            	float tilesWide = _Scaling.z;
            	float tilesHigh = _Scaling.w;
            	float tileWidth = 1.0/tilesWide;
            	float tileHeight = 1.0/tilesHigh;

            	float tileStartX = floor(pix.texCoord.x * tilesWide) / tilesWide;
            	float tileStartY = floor(pix.texCoord.y * tilesHigh) / tilesHigh;

            	float diffX = (tileWidth - (tileWidth * oneOverScale.x)) / 2.0;
            	float diffY = (tileHeight - (tileHeight * oneOverScale.y)) / 2.0;

            	float tileMidX = tileStartX + (tileWidth / 2.0);
            	float tileMidY = tileStartY + (tileHeight / 2.0);

            	float2 originalTexCoord = pix.texCoord;

            	float2 scaledTexCoord = originalTexCoord;// = ((originalTexCoord - (tileMidX,tileMidY)) * oneOverScale) + (tileMidX,tileMidY);
            	scaledTexCoord.x = ((originalTexCoord.x - tileMidX) * oneOverScale.x) + tileMidX;
            	scaledTexCoord.y = ((originalTexCoord.y - tileMidY) * oneOverScale.y) + tileMidY;

            	scaledTexCoord.x += _Align > 1.5 && _Align < 2.5 ? diffX : 0;
            	scaledTexCoord.x += _Align > 3.5 && _Align < 4.5 ? -diffX * 0.999 : 0;
            	scaledTexCoord.x = max(scaledTexCoord.x, tileStartX);
            	scaledTexCoord.x = scaledTexCoord.x < tileStartX ? tileStartX : scaledTexCoord.x;
            	scaledTexCoord.x = min(scaledTexCoord.x, tileStartX+tileWidth);

            	scaledTexCoord.y += _Align > 0.5 && _Align < 1.5 ? diffY : 0;
            	scaledTexCoord.y += _Align > 2.5 && _Align < 3.5 ? -diffY * 0.999 : 0;
            	scaledTexCoord.y = max(scaledTexCoord.y, tileStartY);
            	scaledTexCoord.y = scaledTexCoord.y < tileStartY ? tileStartY : scaledTexCoord.y;
            	scaledTexCoord.y = min(scaledTexCoord.y, tileStartY+tileHeight);

                // sample texture with new scaled coordinates
				fixed4 col = tex2D(_MainTex, scaledTexCoord);
                fixed4 newColor = col;

				if(_Scaling.x < 1.0) {
					if(scaledTexCoord.x <= tileStartX || scaledTexCoord.x > (tileStartX + tileWidth)) {
						newColor.a = 0.0;
					}
				}
				if(_Scaling.y < 1.0) {
					if(scaledTexCoord.y <= tileStartY || scaledTexCoord.y > (tileStartY + tileHeight)) {
						newColor.a = 0.0;
					}
				}

                return newColor;
            }
            ENDCG
        }

    }
}



