Shader "My Shaders/Rotation" {



    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        [Header(Rotation Settings)]
        [Space(10)]
        _Speed ("Rotation Speed", Vector) = (1, 1, 1, 0) // Declare float3 as a Vector property. Last value is not used.
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
                float3 _Speed;
            CBUFFER_END



            float3 rotate(float3 vertex, float3 angle) {
                // Create a 3D rotation matrix based on the rotation angles.
                float3x3 rotationMatrix = float3x3(
                    cos(angle.x) * cos(angle.y), cos(angle.x) * sin(angle.y) * sin(angle.z) - sin(angle.x) * cos(angle.z), cos(angle.x) * sin(angle.y) * cos(angle.z) + sin(angle.x) * sin(angle.z),
                    sin(angle.x) * cos(angle.y), sin(angle.x) * sin(angle.y) * sin(angle.z) + cos(angle.x) * cos(angle.z), sin(angle.x) * sin(angle.y) * cos(angle.z) - cos(angle.x) * sin(angle.z),
                    -sin(angle.y), cos(angle.y) * sin(angle.z), cos(angle.y) * cos(angle.z)
                );

                return mul(rotationMatrix, vertex);
            }



            // Vertex shader entry point.
            v2f vert (appdata IN) {
                v2f OUT;
                float3 angle = float3(_Speed.x, _Speed.y, _Speed.z) * _Time.y; // Calculate the rotation angles based on the time and speed.
                float3 rotatedVertex = rotate(IN.positionOS.xyz, angle); // Rotate the vertex position based on the angle

                OUT.positionHCS = TransformObjectToHClip(rotatedVertex); // Transform the vertex position from object space to homogeneous clip space.
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex); // Transform the texture coordinates.
                return OUT;
            }



            // Fragment shader entry point.
            // SV_Target specifies the output render target.
            half4 frag (v2f IN) : SV_Target {
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv); // Sample the texture color using the texture coordinates.
                return col;
            }

            ENDHLSL

        }

    }



}
