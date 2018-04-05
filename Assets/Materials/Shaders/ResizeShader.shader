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
            sampler2D _MainTex;
            fixed4 _Scaling;
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
            	float2 oneOverScale = 1 / _Scaling;

            	float midX = 0.5;
            	float midY = 0.5;

            	float2 originalTexCoord = pix.texCoord;

            	// scaled texCoord2
            	float2 scaledTexCoord = originalTexCoord;
            	scaledTexCoord = (scaledTexCoord - (midX,midY)) * oneOverScale + (midX,midY);

            	float diffX = (1.0 - (abs(oneOverScale.x))) / 2.0;
            	float diffY = (1.0 - (abs(oneOverScale.y))) / 2.0;

            	scaledTexCoord.x += _Align > 1.5 && _Align < 2.5 ? diffX : 0;
            	scaledTexCoord.x += _Align > 3.5 && _Align < 4.5 ? -diffX * 0.999 : 0; // diffY can't be 1.0, not sure why

            	scaledTexCoord.y += _Align > 0.5 && _Align < 1.5 ? diffY : 0;
            	scaledTexCoord.y += _Align > 2.5 && _Align < 3.5 ? -diffY * 0.999 : 0; // diffY can't be 1.0, not sure why

                // sample texture and return it
				fixed4 col = tex2D(_MainTex, scaledTexCoord);
                fixed4 newColor = col;

//                if((texCoord.x < 0.0) || (texCoord.x > _Scaling.x)) {
//                	newColor.a = 0.0;
//                }
//                if((texCoord.y < 0.0) || (texCoord.y > _Scaling.y)) {
//                	newColor.a = 0.0;
//                }

                return newColor;
            }
            ENDCG
        }

    }
}
