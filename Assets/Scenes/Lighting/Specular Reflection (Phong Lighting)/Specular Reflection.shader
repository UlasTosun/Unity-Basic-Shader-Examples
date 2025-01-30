Shader "My Shaders/Specular Reflection" {



    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        [Space(10)]
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1) // You do not have to use specular color, it is just for demonstration purposes.
        _SpecularIntensity ("Specular Intensity", Range(0, 1)) = 1 // You do not have to use specular intensity, it is just for demonstration purposes.
        _SpecularPower ("Specular Power", Range(1, 128)) = 64 // You do not have to use specular power, it is just for demonstration purposes.
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
                half3 _SpecularColor;
                float _SpecularIntensity;
                float _SpecularPower;
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
                float3 positionWS : TEXCOORD3; // World space position.
            };



            // Instead of this manual calculation, you can use the Unity function LightingBlinnPhong().
            // Unity function LightingBlinnPhong() also adds diffuse reflection and ambient light as well.
            half3 BlinnPhong(half3 specularColor, half3 lightColor, half3 lightIntensity, float3 lightDir, float3 normal, float3 viewDir, float specularPow) {
                float3 halfway = normalize(lightDir + viewDir); // halfway vector
                return specularColor * lightColor * lightIntensity * pow(max(0, dot(normal, halfway)), specularPow);
            }



            // Instead of this manual calculation, you can use the Unity function LightingLambert().
            half3 Lambert(float3 normal, float3 lightDir, half3 lightColor, half3 lightIntensity) {
                // Commonly, lambert lighting does not use light intensity, assuming it is 1.
                return max(0, dot(normal, lightDir)) * lightColor * lightIntensity;
            }



            // Vertex shader entry point.
            v2f vert (appdata IN) {
                v2f OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); // Transform the vertex position from object space to homogeneous clip space.
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex); // Transform the texture coordinates.
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS); // Get the world space normal.
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz); // Get the world space position.
                return OUT;
            }



            // Fragment shader entry point.
            // SV_Target specifies the output render target.
            half4 frag (v2f IN) : SV_Target {
                half4 texCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv); // Sample the texture color using the texture coordinates.

                Light mainLight = GetMainLight(); // Get the main light
                float3 viewDir = normalize(GetCameraPositionWS() - IN.positionWS); // Calculate the view direction.
                half3 specular = BlinnPhong(_SpecularColor, mainLight.color, _SpecularIntensity, mainLight.direction, IN.normalWS, viewDir, _SpecularPower); // Calculate the specular reflection.
                
                half3 diffuse = Lambert(IN.normalWS, mainLight.direction, mainLight.color, 1); // Calculate the diffuse color.
                
                texCol.rgb = texCol.rgb * diffuse + specular;
                return texCol;
            }

            ENDHLSL

        }

    }



}
