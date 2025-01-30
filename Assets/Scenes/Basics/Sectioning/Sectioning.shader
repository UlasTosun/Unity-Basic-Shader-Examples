Shader "My Shaders/Sectioning" {



    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Sections ("Sections", Range(2, 10)) = 5
    }



    SubShader {

        Tags {
            "RenderType"="Transparent" // This shader is opaque.
            "Queue" = "Transparent" // This shader is rendered after the geometry has been rendered.
            "RenderPipeline" = "UniversalPipeline" // This shader is compatible with the Universal Render Pipeline.
        }



        Blend SrcAlpha OneMinusSrcAlpha // Standard alpha blending.
        ZWrite Off // Do not write to the depth buffer to prevent z-fighting when rendering transparent objects.
        


        LOD 100



        Pass {

            HLSLPROGRAM

            // Include the Core.hlsl file to get access to the Unity shader library functions.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"



            // Declare the vertex and fragment shader entry points (names).
            #pragma vertex vert
            #pragma fragment frag



            // Declare the vertex shader inputs.
            struct appdata {
                float4 positionOS : POSITION; // Object space position.
                float2 uv : TEXCOORD0;
            };



            // Declare the vertex shader outputs and fragment shader inputs.
            struct v2f {
                float4 positionHCS : SV_POSITION; // Homogeneous clip space position.
                float2 uv : TEXCOORD0;
            };



            TEXTURE2D(_MainTex); // This macro declares _MainTex as a Texture2D object.
            SAMPLER(sampler_MainTex); // This macro declares the sampler for the _MainTex texture.



            // To ensure that the Unity shader is SRP Batcher compatible, 
            // declare all Material properties inside a single CBUFFER block with the name UnityPerMaterial.
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST; // _ST suffix is necessary for the tiling and offset function to work.
                float4 _Color;
                float _Sections;
            CBUFFER_END



            // Vertex shader entry point.
            v2f vert (appdata IN) {
                v2f OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); // Transform the vertex position from object space to homogeneous clip space.
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex); // Transform the texture coordinates.
                return OUT;
            }



            // Fragment shader entry point.
            // SV_Target specifies the output render target.
            half4 frag (v2f IN) : SV_Target {
                half tanVal = abs(tan(IN.uv.y * PI * _Sections)); // Calculate the tangent of the texture coordinate.
                tanVal = saturate(tanVal); // Clamp the tangent value between 0 and 1.
                half4 texCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv); // Sample the texture color using the texture coordinates.
                half4 col = texCol * _Color; // Multiply the texture color by the color property.
                col.a *= tanVal; // Multiply the alpha channel of the color by the tangent value.
                return col; // Multiply the texture color by the tangent value.
            }

            ENDHLSL

        }

    }



}
