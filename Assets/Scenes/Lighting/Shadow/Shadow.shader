Shader "My Shaders/Shadow" {

    // Since this shader is unlit, surfaces which are in shadow can seem bad. To fix this, you can add lighting to the shader.



    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(10)]
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 0)
    }



    SubShader {

        Tags {
            "RenderType"="Opaque" // This shader is opaque.
            "Queue" = "Geometry" // This shader is rendered after the geometry has been rendered.
            "RenderPipeline" = "UniversalPipeline" // This shader is compatible with the Universal Render Pipeline.
        }



        LOD 100



        Pass {

            Tags {
                // If you don't specify the LightMode tag, it will set default to "SRPDefaultUnlit" however, "UniversalForward" is more performant.
                "LightMode"="UniversalForward" // This shader is compatible with the Universal Forward renderer.
            }



            HLSLPROGRAM

            // Include the Core.hlsl file to get access to the Unity shader library functions.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



            // Declare the vertex and fragment shader entry points (names).
            #pragma vertex vert
            #pragma fragment frag


            // Add this pragma to your shader, so it can access the shadow maps for additional lights.
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT



            TEXTURE2D(_MainTex); // This macro declares _MainTex as a Texture2D object.
            SAMPLER(sampler_MainTex); // This macro declares the sampler for the _MainTex texture.



            // To ensure that the Unity shader is SRP Batcher compatible, 
            // declare all Material properties inside a single CBUFFER block with the name UnityPerMaterial.
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST; // _ST suffix is necessary for the tiling and offset function to work.
                float4 _ShadowColor; // The shadow color.
            CBUFFER_END



            // Declare the vertex shader inputs.
            struct appdata {
                float4 positionOS : POSITION; // Object space position.
                float2 uv : TEXCOORD0;
            };



            // Declare the vertex shader outputs and fragment shader inputs.
            struct v2f {
                float4 positionHCS : SV_POSITION; // Homogeneous clip space position.
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1; // World space position.
            };



            // Vertex shader entry point.
            v2f vert (appdata IN) {
                v2f OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); // Transform the vertex position from object space to homogeneous clip space.
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex); // Transform the texture coordinates.
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz); // Get the world space position.
                return OUT;
            }



            // Fragment shader entry point.
            // SV_Target specifies the output render target.
            half4 frag (v2f IN) : SV_Target {
                half4 texCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv); // Sample the texture color using the texture coordinates.

                float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
                Light mainLight = GetMainLight(shadowCoord); // Get the main light with the shadow coordinate.
                
                if (mainLight.shadowAttenuation.x == 0) // If the shadow attenuation is 0, the pixel is in shadow.
                    texCol.rgb *= _ShadowColor.rgb;

                return texCol;
            }

            ENDHLSL

        }



        // This pass is used to render the shadow caster pass. It uses the Universal Render Pipeline's ShadowCaster pass of the Lit shader via the UsePass command.
        // This pass is necessary to cast shadows from the object that uses this shader onto other objects. Without this pass, the object will not cast shadows.
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"



    }



}
