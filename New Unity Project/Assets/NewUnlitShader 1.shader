﻿Shader "Unlit/NewUnlitShader 1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AmbientRate("Ambient Rate",Range(0,1)) = 0.2
            _SpeculaColor("Specula Color",Color) = (0.3,0.3,1.0,1.0)
            _SpecularPower("Specular Power",Range(0,200))=80
            _LineColor("Line Color", Color) = (1, 1, 1, 1)
        _LineWidth("Line Width", Range(0.01,0.1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

       Pass
        {
          
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _LineWidth;
            fixed4 _LineColor;

            v2f vert(appdata v)
            {
                
                float3 normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
                float2 offset = TransformViewToProjection(normal.xy);

                
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex.xy = o.vertex.xy + offset * _LineWidth;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = _LineColor;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal:TEXCOORD1;
                float3 viewDir:TEXCOORD2;
                UNITY_FOG_COORDS(1)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform float _AmbientRate;
            uniform float _SpecularPower;
            uniform float3 _SpeculaColor;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 N = normalize(i.normal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 V = normalize(i.viewDir);


                float4 albedo = tex2D(_MainTex, i.uv);
                float3 ambient = _LightColor0.xyx * albedo.xyz;
                float3 NL = dot(N, L);
                float3 diffuse = _LightColor0.xyz * albedo.xyz * max(0.0, NL);
                float3 lambert = _AmbientRate * ambient + (1.0 - _AmbientRate) * diffuse;

                float3 H = normalize(V + L);
                float3 specular = _LightColor0.xyz * _SpeculaColor * pow(max(0.0, dot(H, N)),_SpecularPower);

                float4 col = float4(lambert + specular, 1.0);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
