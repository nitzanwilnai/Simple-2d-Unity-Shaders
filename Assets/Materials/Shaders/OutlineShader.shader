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

                //stroke size has to be hard coded because it is used to determine the size of our for loop and the shader needs to be compiled
                float maxRadius = 8; // stroke size;

                // the way this shader works is, for each pixel, we check all the pixels in a circle around it, slowly increasing our radius from 1 to maxRadius. 
                // if we encounted an alpha pixel, we exit early. 
                // if the pixel we encountered is very far way, at or near maxRadius, we apply anti-aliasing by adding some color from the original pixel and the stroke color

                // we are drawing our outline on the inside, so no point in looking at pixels that are already alpha
                if(newColor.a != 0) {

					// is there an alpha between 0 and 1 in my radius?
					int alphaFound = 0;
					float alphaRadius = 1;
					// loop from radius 1 to maxRadius
					for(float radius = 1; radius <= maxRadius; radius+=1) {

						// we are checking a circle, so need to check both + and - of radius
						for(int x = -radius; x <= radius; x++) {

							// circle equation
							int y = sqrt(radius * radius - x * x);

							// need to check both + and - y, since the result of a sqrt is +/-
							for(int index = 0; index < 2; index++) {
								y = (index==1) ? -y : y;

								// multiply our location by the texel size to get the correct pixel
								fixed2 checkTexCoord = pix.texCoord + fixed2(_MainTex_TexelSize.x * x, _MainTex_TexelSize.y * y);
								fixed4 pixel = tex2D(_MainTex, checkTexCoord);

								// if alpha is found, save the info
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

					// did we find an alpha pixel?
					if(alphaFound > 0.5) {
						float strokeBlend = 2.0; // how many pixels on the inside of the stroke do we want to use for anti-aliasing

						// we are in the stroke/outline, so use the stroke color
						newColor.rgb = _ColorStroke;

						// check if we are in the anti-aliasing for the inside
						// the outside anti-aliasing is free because we are using the alpha of the current pixel
						if(alphaRadius > maxRadius-strokeBlend) {
							alphaRadius -= (maxRadius-strokeBlend);
							float alphaDiff = alphaRadius / strokeBlend;
							// mix the stroke color and the original pixel color to produce anti-aliaisng on the inside of the outline
							newColor.rgb = _ColorStroke.rgb * (1-alphaDiff) + originalColor.rgb * alphaDiff;
						}
					}
				}

                return newColor;
            }
            ENDCG
        }

    }
}
