Shader "My Shaders/Environmental Reflection" {



    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _ReflectionTex ("Reflection Texture", Cube) = "white" { }
        [Space(10)]
        _ReflectionInt ("Reflection Intensity", Range(0, 1)) = 1
        _ReflectionMet ("Reflection Metallic", Range(0, 1)) = 0
        _ReflectionDet ("Reflection Detail", Range(1, 9)) = 1
        _ReflectionExp ("Reflection Exposure", Range(1, 3)) = 1
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

            //TEXTURECUBE(_ReflectionTex); // This macro declares _ReflectTex as a TextureCube object.
            //SAMPLER(sampler_ReflectionTex); // This macro declares the sampler for the _ReflectTex texture.



            // To ensure that the Unity shader is SRP Batcher compatible, 
            // declare all Material properties inside a single CBUFFER block with the name UnityPerMaterial.
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST; // _ST suffix is necessary for the tiling and offset function to work.
                samplerCUBE _ReflectionTex;
                float _ReflectionInt;
                float _ReflectionMet;
                half _ReflectionDet;
                float _ReflectionExp;
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



            // Instead of this manual calculation, you can use the Unity macro SAMPLE_TEXTURECUBE_LOD().
            half3 AmbientReflection(samplerCUBE reflectionTex, float reflectionInt, half reflectionDet, float3 normal, float3 viewDir, float reflectionExp) {
                float3 reflection = reflect(-viewDir, normal); // Calculate the reflection vector.
                float4 cubeMapPoint = float4(reflection, reflectionDet); // xyz is the reflection vector, w is the detail level.
                half4 reflectionColor = texCUBElod(reflectionTex, cubeMapPoint); // Sample the reflection texture.
                return reflectionColor.rgb * reflectionInt * reflectionColor.a * reflectionExp;
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

                // Manual calculation.
                half3 ambient = AmbientReflection(_ReflectionTex, _ReflectionInt, _ReflectionDet, IN.normalWS, viewDir, _ReflectionExp); // Calculate the ambient reflection.
                texCol.rgb *= ambient + _ReflectionMet;

                // Instead of calculating manually, environmenta reflection can be found by using Unity macro SAMPLE_TEXTURECUBE_LOD().
                //float3 reflection = reflect(-viewDir, IN.normalWS);
                //half3 reflectionData = SAMPLE_TEXTURECUBE_LOD(_ReflectionTex, sampler_ReflectionTex, reflection, _ReflectionDet);
                //texCol.rgb *= reflectionData + _ReflectionMet;


                return texCol;
            }

            ENDHLSL

        }

    }



}
