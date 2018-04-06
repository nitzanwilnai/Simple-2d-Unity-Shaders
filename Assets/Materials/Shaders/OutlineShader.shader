Shader "Unlit/fish_shader"
{
	// these are variables you can pass to the shader from the inspector or from a script
    Properties
    {
        // we have removed support for texture tiling/offset,
        // so make them not be displayed in material inspector
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" {}
		_ColorStroke ("Stroke Color", Color) = (1,1,1)
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

            sampler2D _MainTex; // texture we will sample
            fixed3 _ColorStroke; // the color for the outline

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
                // sample texture and return it
				fixed4 originalColor = tex2D(_MainTex, pix.texCoord);
				fixed4 newColor = originalColor;

                //stroke size has to be hard coded because it is use in a for loop and need to be compiled
                float maxRadius = 8; // stroke size;

                if(newColor.a != 0) {

					// is there an alpha between 0 and 1 in my radius?
					int alphaFound = 0;
					float alphaRadius = 1;
					for(float radius = 1; radius <= maxRadius; radius+=1) {

						for(int x = -radius; x <= radius; x++) {
							int y = sqrt(radius * radius - x * x);

							for(int index = 0; index < 2; index++) {
								y = (index==1) ? -y : y;
								fixed2 checkTexCoord = pix.texCoord + fixed2(_MainTex_TexelSize.x * x, _MainTex_TexelSize.y * y);
								fixed4 pixel = tex2D(_MainTex, checkTexCoord);

								if(pixel.a == 0) {
									alphaFound = 1;
									alphaRadius = radius;
								}
							}

							// boolean check and early exit if we found an alpha pixel near us
							if(alphaFound > 0.5) {
								break;
							}

						}

						// boolean check and early exit if we found an alpha pixel near us
						if(alphaFound > 0.5) {
							break;
						}
					}

					fixed3 yellowColor;
					yellowColor.r = 1.0;
					yellowColor.g = 1.0;
					yellowColor.b = 0.0;

										// did we find an alpha pixel?
					if(alphaFound > 0.5) {
						float strokeBlend = 2.0;
						newColor.rgb = _ColorStroke;
						if(alphaRadius > maxRadius-strokeBlend) {
							alphaRadius -= (maxRadius-strokeBlend);
							float alphaDiff = alphaRadius / strokeBlend;
							newColor.rgb = _ColorStroke.rgb * (1-alphaDiff) + originalColor.rgb * alphaDiff;
							//newColor.rgb = yellowColor.rgb * (1-alphaDiff) + (originalColor.rgb * alphaDiff);
						}
					}

				}

                return newColor;
            }
            ENDCG
        }

    }
}
