Shader "My Shaders/Circle" {



    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Center ("Center", Range(0, 1)) = 0.5
        _Radius ("Radius", Range(0, 1)) = 0.3
        _Smoothness ("Smoothness", Range(0, 1)) = 0.1
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
                float _Center;
                float _Radius;
                float _Smoothness;
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
                half4 texCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv); // Sample the texture color using the texture coordinates.
                float len = length(IN.uv - _Center);
                float stepCol = smoothstep(len - _Smoothness, len + _Smoothness, _Radius);
                return texCol * stepCol;
            }

            ENDHLSL

        }

    }



}
