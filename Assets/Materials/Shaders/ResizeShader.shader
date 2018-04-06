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
            	float2 oneOverScale = 1 / _Scaling;

            	// we want to scale relative to the origin, so move each pixel (-0.5, -0.5), scale it, then move it back (+0.5, +0.5)
            	float midX = 0.5;
            	float midY = 0.5;
            	float2 scaledTexCoord = (pix.texCoord - (midX,midY)) * oneOverScale + (midX,midY);

            	// normally the scaling will happen from the center of the image, but we want to use our _Align variable to scale from one of the sides
            	// first calculate the leftover space after scaling 
            	float diffX = (1.0 - (abs(oneOverScale.x))) / 2.0;
            	float diffY = (1.0 - (abs(oneOverScale.y))) / 2.0;

            	// if _Align is 2.0, we want to shift the image to the right by diffX
            	scaledTexCoord.x += _Align > 1.5 && _Align < 2.5 ? diffX : 0;
            	// if _Align is 4.0, we want to shift the image to the left by diffX
            	scaledTexCoord.x += _Align > 3.5 && _Align < 4.5 ? -diffX * 0.999 : 0; // diffY can't be 1.0, not sure why

            	// if _Align is 1.0, we want to shift the image down by diffY
            	scaledTexCoord.y += _Align > 0.5 && _Align < 1.5 ? diffY : 0;
            	// if _Align is 3.0, we want to shift the image up by diffY
            	scaledTexCoord.y += _Align > 2.5 && _Align < 3.5 ? -diffY * 0.999 : 0; // diffY can't be 1.0, not sure why

            	// for some reason that I have not figure out yet, shifting up or to the left by excatly -diffX or -diffY causes the image to disappear, so we shift by 0.999x instead

                // sample texture and return it using our new scaled texture coordinates
				fixed4 newColor = tex2D(_MainTex, scaledTexCoord);

                return newColor;
            }
            ENDCG
        }

    }
}
