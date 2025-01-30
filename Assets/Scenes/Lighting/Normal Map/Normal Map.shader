Shader "My Shaders/Normal Map" {



    Properties {
        _MainTex ("Texture", 2D) = "white" { }
        _NormalMap ("Normal Map", 2D) = "white" { }
        [Space(10)]
        _Diffuse ("Light Intensity", Float) = 1
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

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);



            // To ensure that the Unity shader is SRP Batcher compatible, 
            // declare all Material properties inside a single CBUFFER block with the name UnityPerMaterial.
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST; // _ST suffix is necessary for the tiling and offset function to work.
                float4 _NormalMap_ST;
                float _Diffuse;
            CBUFFER_END



            // Declare the vertex shader inputs.
            struct appdata {
                float4 positionOS : POSITION; // Object space position.
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL; // Object space normal.
                float4 tangentOS : TANGENT; // Object space tangent.
            };



            // Declare the vertex shader outputs and fragment shader inputs.
            struct v2f {
                float4 positionHCS : SV_POSITION; // Homogeneous clip space position.
                float2 uv : TEXCOORD0;
                float2 uvNormalMap : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 binormalWS : TEXCOORD4;
            };



            // Vertex shader entry point.
            v2f vert (appdata IN) {
                v2f OUT;
                ZERO_INITIALIZE(v2f, OUT); // Initialize the output structure (it is necessary for normal map support).

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); // Transform the vertex position from object space to homogeneous clip space.
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex); // Transform the texture coordinates.

                OUT.uvNormalMap = TRANSFORM_TEX(IN.uv, _NormalMap);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS); // Transform the normal from object space to world space.
                OUT.tangentWS = TransformObjectToWorldDir(IN.tangentOS.xyz); // Transform the tangent from object space to world space.
                OUT.binormalWS = normalize(cross(OUT.normalWS, OUT.tangentWS.xyz) * IN.tangentOS.w); // Calculate the binormal.

                // GetVertexPositionInputs() // Returns world space, view space, and clip space positions of the vertex.
                // GetVertexNormalInputs() // Returns world space normal, tangent, and bitangent.
                // These 2 built-in functions are used to calculate those upper transformations. So, we can use them instead of manual calculations.
                // Also, do lighting calculations in the vertex shader to improve performance instead of doing them in the fragment shader (if possible).
                // This shader is an example of how to do lighting calculations in the fragment shader and it is not optimized.
                
                return OUT;
            }



            // Fragment shader entry point.
            // SV_Target specifies the output render target.
            half4 frag (v2f IN) : SV_Target {
                half4 texCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv); // Sample the texture color using the texture coordinates.

                half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, IN.uvNormalMap);
                half3 normalUnpacked = UnpackNormal(normalMap); // Unpack the normal map texture. It is necessary since Unity uses DXT5nm compression for normal maps.

                float3x3 TBN_matrix = float3x3 (
                    IN.tangentWS,
                    IN.binormalWS,
                    IN.normalWS
                );
                
                half3 normalColor = TransformWorldToTangent(normalUnpacked, TBN_matrix); // Transform the normal map from world space to tangent space.

                // Normal maps do not work with unlit shaders, so we need to calculate lighting. Use the Lambertian diffuse reflection model as an example.
                float3 lightDir = GetMainLight().direction; // Get the main light direction.
                half3 diffuseLambert = max(0, dot(normalColor, lightDir)) * _MainLightColor.rgb; // Calculate the Lambertian diffuse reflection.
                diffuseLambert *= _Diffuse; // Adjust the light intensity.

                // NOTE: Unity's built-in lighting system is not used in this shader. Unity has a built-in lighting system.
                
                texCol.rgb *= diffuseLambert;
                return texCol;
            }

            ENDHLSL

        }

    }



}
