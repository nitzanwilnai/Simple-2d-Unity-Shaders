Shader "Unlit/fish_shader"
{
    Properties
    {
        // we have removed support for texture tiling/offset,
        // so make them not be displayed in material inspector
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
 		_ColorRedTint ("Red Color Tint", Color) = (1,1,1)
		_ColorGreenTint ("Green Color Tint", Color) = (1,1,1)
		_ColorBlueTint ("Blue Color Tint", Color) = (1,1,1)
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
            fixed3 _ColorRedTint;
            fixed3 _ColorGreenTint;
            fixed3 _ColorBlueTint;

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
                // sample texture and return it
				fixed4 col = tex2D(_MainTex, pix.texCoord);
                fixed4 newColor = col;

                if(newColor.a != 0) {

	                fixed3 tintedColor = col.r * _ColorRedTint + col.g * _ColorGreenTint + col.b * _ColorBlueTint;
	                newColor.rgb = tintedColor.rgb;
				}

                return newColor;
            }
            ENDCG
        }

    }
}
