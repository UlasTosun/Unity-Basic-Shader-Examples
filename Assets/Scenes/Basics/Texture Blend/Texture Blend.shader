Shader "My Shaders/Texture Blend" {



    Properties {
        [MainTexture] _FirstTex ("First Texture", 2D) = "white" { } // Since its name is not _MainTex, make sure to specify the [MainTexture] attribute.
        _SecondTex ("Second Texture", 2D) = "white" { }
        [Space(10)]
        _Blend ("Blend", Range(0, 1)) = 0.5
    }



    SubShader {

        Tags {
            "RenderType"="Opaque" // This shader is opaque.
            "Queue" = "Geometry" // This shader is rendered after the geometry has been rendered.
            "RenderPipeline" = "UniversalPipeline" // This shader is compatible with the Universal Render Pipeline.
        }



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
                float2 uv_1 : TEXCOORD0;
                float2 uv_2 : TEXCOORD1;
            };



            // Declare the vertex shader outputs and fragment shader inputs.
            struct v2f {
                float4 positionHCS : SV_POSITION; // Homogeneous clip space position.
                float2 uv_1 : TEXCOORD0;
                float2 uv_2 : TEXCOORD1;
            };



            TEXTURE2D(_FirstTex);
            SAMPLER(sampler_FirstTex);

            TEXTURE2D(_SecondTex);
            SAMPLER(sampler_SecondTex);



            // To ensure that the Unity shader is SRP Batcher compatible, 
            // declare all Material properties inside a single CBUFFER block with the name UnityPerMaterial.
            CBUFFER_START(UnityPerMaterial)
                float4 _FirstTex_ST;
                float4 _SecondTex_ST;
                float _Blend;
            CBUFFER_END



            // Vertex shader entry point.
            v2f vert (appdata IN) {
                v2f OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); // Transform the vertex position from object space to homogeneous clip space.
                OUT.uv_1 = TRANSFORM_TEX(IN.uv_1, _FirstTex);
                OUT.uv_2 = TRANSFORM_TEX(IN.uv_2, _SecondTex);
                return OUT;
            }



            // Fragment shader entry point.
            // SV_Target specifies the output render target.
            half4 frag (v2f IN) : SV_Target {
                half4 col_1 = SAMPLE_TEXTURE2D(_FirstTex, sampler_FirstTex, IN.uv_1);
                half4 col_2 = SAMPLE_TEXTURE2D(_SecondTex, sampler_SecondTex, IN.uv_2);
                half4 blendCol = lerp(col_1, col_2, _Blend);
                return blendCol;
            }

            ENDHLSL

        }

    }



}
