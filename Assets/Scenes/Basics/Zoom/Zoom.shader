Shader "My Shaders/Zoom" {



    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Zoom ("Zoom", Range(0, 1)) = 0
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
                float _Zoom;
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

                // Lerp the texture coordinates from the original texture coordinates to the center based on the zoom factor.
                // If the zoom factor is 0, the texture coordinates remain the same (original texture coordinates).
                // If the zoom factor is 1, the texture coordinates are lerped to the center (0.5, 0.5).
                // So, it draws the texture to the mesh from the texture center to the edges based on the zoom factor.
                float u = lerp(IN.uv.x, 0.5, _Zoom);
                float v = lerp(IN.uv.y, 0.5, _Zoom);
                
                float2 uv = float2(u, v);
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv); // Sample the texture color using the texture coordinates.
                return col;
            }

            ENDHLSL

        }

    }



}
