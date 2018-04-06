Shader "Unlit/fish_shader"
{
	// these are variables you can pass to the shader from the inspector or from a script
    Properties
    {
        // we have removed support for texture tiling/offset,
        // so make them not be displayed in material inspector
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		_Scaling ("Scaling", Vector) = (1, 1, 1, 1)
		_Align("Align? 0-None, 1-Top, 2-Right, 3-Bottom, 4-Left", float) = 0.0
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

            };

            // vertex shader outputs ("vertex to fragment")
            struct v2f
            {
                float4 vertex : SV_POSITION; // clip space position
                half2 texCoord : TEXCOORD0; // texture coordinate
            };

            sampler2D 	_MainTex; // texture we will sample
            fixed4 		_Scaling; // scaling data, we only use x and y
            fixed 		_Align;  //variable to let us know how to align the scale, 0 is center, 1 - top, 2 - right, 3 - bottom, 4 - left

            // varibles filled by Unity automagically
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
            	// we want a scaling less than 1 to shrink our image, and a scaling greater than 1 to increase it
            	// the way the scaling shader works is by using a pixel from another location instead of our original pixel
            	// if the scale is 0.5, and we are at pixel (x,y), we want to instead show the pixel from (2x, 2y)
            	// if the scale is 2.0, and we are at pixel (x,y), we want to instead show the pixel from (0.5x, 0.5y)
            	// to achieve this we calculate 1/scale and use that to figure out which pixel color to use
            	float2 oneOverScale = 1 / _Scaling.xy;

            	// we need to figure out our tile location
            	// it is theoretically possible to figure out the tile information from _MainTex_ST, but the values I received from Unity made no sense
            	// so instead I manually have to tell the shader how many tiles wide and high the texture atlas is
            	float tilesWide = _Scaling.z;
            	float tilesHigh = _Scaling.w;
            	float tileWidth = 1.0/tilesWide;
            	float tileHeight = 1.0/tilesHigh;

            	// figure out which tile we are on
            	float tileStartX = floor(pix.texCoord.x * tilesWide) / tilesWide;
            	float tileStartY = floor(pix.texCoord.y * tilesHigh) / tilesHigh;

            	// calculate how much different there is between scale 1.0 and this new scale, so we can align our scaled image to one of the walls if needed
            	float diffX = (tileWidth - (tileWidth * oneOverScale.x)) / 2.0;
            	float diffY = (tileHeight - (tileHeight * oneOverScale.y)) / 2.0;

            	// figure out this tile's middle uv coordinates so we can scale it relative to this tile's origin
            	float tileMidX = tileStartX + (tileWidth / 2.0);
            	float tileMidY = tileStartY + (tileHeight / 2.0);

            	// calculate the new scale, relative to this tile's origin
            	float2 scaledTexCoord;
            	scaledTexCoord.x = ((pix.texCoord.x - tileMidX) * oneOverScale.x) + tileMidX;
            	scaledTexCoord.y = ((pix.texCoord.y - tileMidY) * oneOverScale.y) + tileMidY;

            	// if _Align is 2.0, we want to shift the image to the right by diffX
            	scaledTexCoord.x += _Align > 1.5 && _Align < 2.5 ? diffX : 0;
            	// if _Align is 4.0, we want to shift the image to the left by diffX
            	scaledTexCoord.x += _Align > 3.5 && _Align < 4.5 ? -diffX * 0.999 : 0; // diffY can't be 1.0, not sure why

            	// if _Align is 1.0, we want to shift the image down by diffY
            	scaledTexCoord.y += _Align > 0.5 && _Align < 1.5 ? diffY : 0;
            	// if _Align is 3.0, we want to shift the image up by diffY
            	scaledTexCoord.y += _Align > 2.5 && _Align < 3.5 ? -diffY * 0.999 : 0; // diffY can't be 1.0, not sure why

                // sample texture with new scaled coordinates
				fixed4 col = tex2D(_MainTex, scaledTexCoord);
                fixed4 newColor = col;

                // make sure we don't show other parts of the texture atlas when scaling down
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



