Shader "My Shaders/Diffuse Reflection" {



    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(10)]
        _LightIntensity ("Light Intensity", Range(0, 1)) = 1 // You do not have to use light intensity, it is just for demonstration purposes.
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



            // Declare the vertex and fragment shader entry points (names).
            #pragma vertex vert
            #pragma fragment frag



            TEXTURE2D(_MainTex); // This macro declares _MainTex as a Texture2D object.
            SAMPLER(sampler_MainTex); // This macro declares the sampler for the _MainTex texture.



            // To ensure that the Unity shader is SRP Batcher compatible, 
            // declare all Material properties inside a single CBUFFER block with the name UnityPerMaterial.
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST; // _ST suffix is necessary for the tiling and offset function to work.
                float _LightIntensity;
            CBUFFER_END



            // Declare the vertex shader inputs.
            struct appdata {
                float4 positionOS : POSITION; // Object space position.
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL; // Object space normal.
            };



            // Declare the vertex shader outputs and fragment shader inputs.
            struct v2f {
                float4 positionHCS : SV_POSITION; // Homogeneous clip space position.
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD2; // Diffuse color.
            };



            // Instead of this manual calculation, you can use the Unity function LightingLambert().
            half3 Lambert (float3 normal, float3 lightDir, half3 lightColor, half3 lightIntensity) {
                // Commonly, lambert lighting does not use light intensity, assuming it is 1. 
                return max(0, dot(normal, lightDir)) * lightColor * lightIntensity;
            }



            // Vertex shader entry point.
            v2f vert (appdata IN) {
                v2f OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); // Transform the vertex position from object space to homogeneous clip space.
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex); // Transform the texture coordinates.
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS); // Get the world space normal.
                return OUT;
            }



            // Fragment shader entry point.
            // SV_Target specifies the output render target.
            half4 frag (v2f IN) : SV_Target {
                half4 texCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv); // Sample the texture color using the texture coordinates.

                Light mainLight = GetMainLight(); // Get the main light.
                half3 diffuseColor = Lambert(IN.normalWS, mainLight.direction, mainLight.color, _LightIntensity); // Calculate the diffuse color.
                texCol.rgb *= diffuseColor; // Multiply the texture color by the diffuse color.
                return texCol;
            }

            ENDHLSL

        }

    }



}
