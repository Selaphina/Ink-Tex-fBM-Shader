Shader "FX/InkTextest01"
{
	Properties
	{
		[Header(Base)]
		_BaseColor ("基础颜色 (Base Color)", Color) = (0.95, 0.93, 0.88, 1)

		[Header(fBM Noise)]
		_NoiseScale     ("噪波缩放 (Noise Scale)",     Range(0.1, 5.0))  = 0.2
		_NoiseDetail    ("细节 (Detail)",               Range(0, 15))    = 6.0
		_NoiseRoughness ("糙度 (Roughness)",            Range(0, 2))     = 1.5
		_NoiseLacunarity("间隙度 (Lacunarity)",         Range(1, 4))     = 2.0
		_NoiseDistortion("畸变 (Distortion)",           Range(0, 1))    = 0.0
		_DarkNoiseScale ("黑噪波大小 (Dark Noise Scale)", Range(0.1, 4.0)) = 0.15
		_LightNoiseScale("白噪波大小 (Light Noise Scale)", Range(0.1, 4.0)) = 0.85
		_DarkNoiseStrength ("黑噪波强度 (Dark Noise Strength)",   Range(0, 1)) = 0.12
		_LightNoiseStrength("白噪波强度 (Light Noise Strength)",  Range(0, 1)) = 0.04

		[Header(Ink Ramp Colors)]
		_DeepInkColor   ("浓墨色 (Deep Ink)",    Color) = (0.05, 0.05, 0.08, 1)
		_MediumInkColor ("中墨色 (Medium Ink)",  Color) = (0.25, 0.24, 0.26, 1)
		_LightWashColor ("淡墨色 (Light Wash)",  Color) = (0.55, 0.53, 0.50, 1)
		_PaperWhiteColor("纸白色 (Paper White)", Color) = (0.95, 0.93, 0.88, 1)

		[Header(Edge)]
		_EdgeSharpness  ("边缘锐度 (Edge Sharpness)",   Range(0.001, 0.2)) = 0.05
		_EdgeDarken     ("边缘加深 (Edge Darken)",       Range(0, 1))       = 0.4

		[Header(Brush)]
		_BrushTex       ("笔触贴图 (Brush Texture)", 2D)              = "white" {}
		_BrushScale     ("笔触大小 (Brush Scale)",   Range(0.1, 10))  = 1.0
		_BrushStrength  ("笔触强度 (Brush Strength)", Range(0, 1))    = 0.3

		[Header(OutLine)]
		_StrokeColor       ("描边颜色 (Stroke Color)", Color) = (0, 0, 0, 1)
		_OutlineNoise      ("描边噪波贴图 (Outline Noise Map)", 2D)    = "white" {}
		_Outline           ("描边宽度 (Outline Width)", Range(0, 1))   = 0.06
		_OutsideNoiseWidth ("外侧噪波宽度 (Outside Noise Width)", Range(1, 2)) = 1.13
		_MaxOutlineZOffset ("最大Z偏移 (Max Outline Z Offset)", Range(0, 1))    = 0.05
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }

		// =============================================
		// Pass 1: OUTLINE — noise-modulated outline
		// (from MountainShader)
		// =============================================
		Pass
		{
			NAME "OUTLINE"
			Cull Front

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float _Outline;
			float4 _StrokeColor;
			sampler2D _OutlineNoise;
			half _MaxOutlineZOffset;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
			};

			v2f vert(a2v v)
			{
				float4 burn = tex2Dlod(_OutlineNoise, v.vertex);

				v2f o = (v2f)0;
				float3 scaledir = mul((float3x3)UNITY_MATRIX_MV, v.normal);
				scaledir += 0.5;
				scaledir.z = 0.01;
				scaledir = normalize(scaledir);

				// camera space
				float4 position_cs = mul(UNITY_MATRIX_MV, v.vertex);
				position_cs /= position_cs.w;

				float3 viewDir = normalize(position_cs.xyz);
				float3 offset_pos_cs = position_cs.xyz + viewDir * _MaxOutlineZOffset;

				float linewidth = -position_cs.z / unity_CameraProjection[1].y;
				linewidth = sqrt(linewidth);
				position_cs.xy = offset_pos_cs.xy + scaledir.xy * linewidth * burn.x * _Outline;
				position_cs.z = offset_pos_cs.z;

				o.pos = mul(UNITY_MATRIX_P, position_cs);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return _StrokeColor;
			}
			ENDCG
		}

		// =============================================
		// Pass 2: OUTLINE 2 — wider random-clipped outline
		// (from MountainShader)
		// =============================================
		Pass
		{
			NAME "OUTLINE 2"
			Cull Front

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float _Outline;
			float4 _StrokeColor;
			sampler2D _OutlineNoise;
			float _OutsideNoiseWidth;
			half _MaxOutlineZOffset;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv  : TEXCOORD0;
			};

			v2f vert(a2v v)
			{
				float4 burn = tex2Dlod(_OutlineNoise, v.vertex);

				v2f o = (v2f)0;
				float3 scaledir = mul((float3x3)UNITY_MATRIX_MV, v.normal);
				scaledir += 0.5;
				scaledir.z = 0.01;
				scaledir = normalize(scaledir);

				float4 position_cs = mul(UNITY_MATRIX_MV, v.vertex);
				position_cs /= position_cs.w;

				float3 viewDir = normalize(position_cs.xyz);
				float3 offset_pos_cs = position_cs.xyz + viewDir * _MaxOutlineZOffset;

				float linewidth = -position_cs.z / unity_CameraProjection[1].y;
				linewidth = sqrt(linewidth);
				position_cs.xy = offset_pos_cs.xy + scaledir.xy * linewidth * burn.y * _Outline * 1.1 * _OutsideNoiseWidth;
				position_cs.z = offset_pos_cs.z;

				o.pos = mul(UNITY_MATRIX_P, position_cs);
				o.uv = v.texcoord.xy;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 burn = tex2D(_OutlineNoise, i.uv).rgb;
				if (burn.x > 0.5)
					discard;
				return _StrokeColor;
			}
			ENDCG
		}

		// =============================================
		// Pass 3: INK INTERIOR — Blender-style 3D fBM
		// =============================================
		Pass
		{
			NAME "INK_INTERIOR"
			Tags { "LightMode"="ForwardBase" }
			Cull Back

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma target 3.5
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			// ---- Properties ----
			fixed4 _BaseColor;
			float _NoiseScale;
			float _NoiseDetail;
			float _NoiseRoughness;
			float _NoiseLacunarity;
			float _NoiseDistortion;
			float _DarkNoiseScale;
			float _LightNoiseScale;
			float _EdgeSharpness;
			float _EdgeDarken;
			sampler2D _BrushTex;
			float4 _BrushTex_ST;
			float _BrushScale;
			float _BrushStrength;
			float _DarkNoiseStrength;
			float _LightNoiseStrength;
			fixed4 _DeepInkColor;
			fixed4 _MediumInkColor;
			fixed4 _LightWashColor;
			fixed4 _PaperWhiteColor;

			// ---- Structs ----
			struct a2v
			{
				float4 vertex   : POSITION;
				float3 normal   : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos         : SV_POSITION;
				float2 uv          : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos    : TEXCOORD2;
				float3 objectPos   : TEXCOORD3;
				SHADOW_COORDS(4)
			};

			// =============================================
			// Blender-style 3D Perlin Noise
			// (ported from gpu_shader_material_noise.glsl)
			// =============================================

			// ---- Integer Hash (Bob Jenkins one-at-a-time) ----
			uint blender_hash(uint kx)
			{
				uint c = 0xdeadbeefu + (1u << 2u) + 13u;
				uint a = c, b = c;
				a += kx;
				c ^= b; c -= (b << 14u) | (b >> 18u);
				a ^= c; a -= (c << 11u) | (c >> 21u);
				b ^= a; b -= (a << 25u) | (a >> 7u);
				c ^= b; c -= (b << 16u) | (b >> 16u);
				a ^= c; a -= (c << 4u)  | (c >> 28u);
				b ^= a; b -= (a << 14u) | (a >> 18u);
				c ^= b; c -= (b << 24u) | (b >> 8u);
				return c;
			}

			uint blender_hash2(uint kx, uint ky)
			{
				uint c = 0xdeadbeefu + (2u << 2u) + 13u;
				uint a = c, b = c;
				b += ky; a += kx;
				c ^= b; c -= (b << 14u) | (b >> 18u);
				a ^= c; a -= (c << 11u) | (c >> 21u);
				b ^= a; b -= (a << 25u) | (a >> 7u);
				c ^= b; c -= (b << 16u) | (b >> 16u);
				a ^= c; a -= (c << 4u)  | (c >> 28u);
				b ^= a; b -= (a << 14u) | (a >> 18u);
				c ^= b; c -= (b << 24u) | (b >> 8u);
				return c;
			}

			uint blender_hash3(uint kx, uint ky, uint kz)
			{
				uint c = 0xdeadbeefu + (3u << 2u) + 13u;
				uint a = c, b = c;
				c += kz; b += ky; a += kx;
				c ^= b; c -= (b << 14u) | (b >> 18u);
				a ^= c; a -= (c << 11u) | (c >> 21u);
				b ^= a; b -= (a << 25u) | (a >> 7u);
				c ^= b; c -= (b << 16u) | (b >> 16u);
				a ^= c; a -= (c << 4u)  | (c >> 28u);
				b ^= a; b -= (a << 14u) | (a >> 18u);
				c ^= b; c -= (b << 24u) | (b >> 8u);
				return c;
			}

			// ---- Quintic fade (C2 continuous) ----
			float fade(float t)
			{
				return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
			}

			// ---- Negate conditionally ----
			float negate_if(float val, uint condition)
			{
				return (condition != 0u) ? -val : val;
			}

			// ---- 3D gradient from hash (12 directions, matching Blender) ----
			float noise_grad3(uint hash, float x, float y, float z)
			{
				uint h = hash & 15u;
				float u = (h < 8u) ? x : y;
				float vt = ((h == 12u) || (h == 14u)) ? x : z;
				float v = (h < 4u) ? y : vt;
				return negate_if(u, h & 1u) + negate_if(v, h & 2u);
			}

			// ---- Trilinear interpolation ----
			float tri_mix(float v0, float v1, float v2, float v3,
			              float v4, float v5, float v6, float v7,
			              float x, float y, float z)
			{
				float x1 = 1.0 - x;
				float y1 = 1.0 - y;
				float z1 = 1.0 - z;
				return z1 * (y1 * (v0 * x1 + v1 * x) + y * (v2 * x1 + v3 * x)) +
				       z  * (y1 * (v4 * x1 + v5 * x) + y * (v6 * x1 + v7 * x));
			}

			// ---- 3D Perlin noise (Blender exact port) ----
			float noise_perlin3(float3 vec)
			{
				float fx = vec.x - floor(vec.x);
				float fy = vec.y - floor(vec.y);
				float fz = vec.z - floor(vec.z);
				int ix = (int)floor(vec.x);
				int iy = (int)floor(vec.y);
				int iz = (int)floor(vec.z);

				float u = fade(fx);
				float v = fade(fy);
				float w = fade(fz);

				float r = tri_mix(
					noise_grad3(blender_hash3((uint)ix,     (uint)iy,     (uint)iz),     fx,       fy,       fz),
					noise_grad3(blender_hash3((uint)(ix+1), (uint)iy,     (uint)iz),     fx - 1.0, fy,       fz),
					noise_grad3(blender_hash3((uint)ix,     (uint)(iy+1), (uint)iz),     fx,       fy - 1.0, fz),
					noise_grad3(blender_hash3((uint)(ix+1), (uint)(iy+1), (uint)iz),     fx - 1.0, fy - 1.0, fz),
					noise_grad3(blender_hash3((uint)ix,     (uint)iy,     (uint)(iz+1)), fx,       fy,       fz - 1.0),
					noise_grad3(blender_hash3((uint)(ix+1), (uint)iy,     (uint)(iz+1)), fx - 1.0, fy,       fz - 1.0),
					noise_grad3(blender_hash3((uint)ix,     (uint)(iy+1), (uint)(iz+1)), fx,       fy - 1.0, fz - 1.0),
					noise_grad3(blender_hash3((uint)(ix+1), (uint)(iy+1), (uint)(iz+1)), fx - 1.0, fy - 1.0, fz - 1.0),
					u, v, w);

				return r;
			}

			// ---- Signed noise [-1, 1] with precision protection ----
			float snoise3(float3 p)
			{
				// Repeat every 100000 to avoid float precision issues
				float3 precision_correction = 0.5 * float3(
					(abs(p.x) >= 1000000.0) ? 1.0 : 0.0,
					(abs(p.y) >= 1000000.0) ? 1.0 : 0.0,
					(abs(p.z) >= 1000000.0) ? 1.0 : 0.0);
				p = fmod(p, 100000.0) + precision_correction;
				// Blender noise_scale3 = 0.982
				return 0.982 * noise_perlin3(p);
			}

			// ---- Unsigned noise [0, 1] ----
			float unoise3(float3 p)
			{
				return 0.5 * snoise3(p) + 0.5;
			}

			// =============================================
			// fBM — Blender exact port
			// (from gpu_shader_material_fractal_noise.glsl)
			// =============================================
			float noise_fbm(float3 co, float detail, float roughness, float lacunarity)
			{
				float3 p = co;
				float fscale = 1.0;
				float amp = 1.0;
				float maxamp = 0.0;
				float sum = 0.0;

				int iDetail = (int)detail;
				for (int i = 0; i <= iDetail; i++)
				{
					float t = snoise3(fscale * p);
					sum += t * amp;
					maxamp += amp;
					amp *= roughness;
					fscale *= lacunarity;
				}

				// Fractional detail blending (Blender supports e.g. Detail=2.5)
				float rmd = detail - floor(detail);
				if (rmd != 0.0)
				{
					float t = snoise3(fscale * p);
					float sum2 = sum + t * amp;
					return lerp(0.5 * sum / maxamp + 0.5, 0.5 * sum2 / (maxamp + amp) + 0.5, rmd);
				}
				else
				{
					return 0.5 * sum / maxamp + 0.5;
				}
			}

			// =============================================
			// Distortion — Blender exact port
			// (from gpu_shader_material_tex_noise.glsl)
			// =============================================
			float3 applyDistortion(float3 p, float distortion)
			{
				if (distortion != 0.0)
				{
					// Each axis distorted by an independent noise evaluation
					// with large random offsets to decorrelate axes
					p += float3(
						snoise3(p + float3(113.0, 57.0, 211.0)) * distortion,
						snoise3(p + float3(37.0,  199.0, 89.0)) * distortion,
						snoise3(p + float3(173.0, 43.0, 151.0)) * distortion
					);
				}
				return p;
			}

			// =============================================
			// RGB to HSV conversion
			// =============================================
			float3 rgb2hsv(float3 c)
			{
				float4 K = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
				float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
				float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
				float d = q.x - min(q.w, q.y);
				float e = 1.0e-10;
				return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}

			// =============================================
			// Generate 3-channel color noise and extract Hue
			// Evaluates fBM three times with decorrelated offsets
			// to produce an RGB color, then returns the HSV Hue.
			// =============================================
			float noise_fbm_hue(float3 co, float detail, float roughness, float lacunarity)
			{
				// Three decorrelated fBM evaluations -> RGB color noise
				float r = noise_fbm(co,                              detail, roughness, lacunarity);
				float g = noise_fbm(co + float3(31.7, 73.1, 157.3),  detail, roughness, lacunarity);
				float b = noise_fbm(co + float3(97.3, 41.9, 223.7),  detail, roughness, lacunarity);
				// Convert to HSV, return only Hue channel
				float3 hsv = rgb2hsv(float3(r, g, b));
				return hsv.x; // Hue [0, 1]
			}

			// =============================================
			// Vertex Shader
			// =============================================
			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.objectPos = v.vertex.xyz;
				TRANSFER_SHADOW(o);
				return o;
			}

			// =============================================
			// Fragment Shader — Ink Wash Surface (3D fBM)
			// =============================================
			float4 frag(v2f i) : SV_Target
			{
				// ---- Lighting (Half-Lambert) ----
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				float NdotL = dot(worldNormal, worldLightDir) * 0.5 + 0.5;

				// ---- 3D fBM noise (Blender-style) ----
				// Use object-space position for stable 3D procedural texture
				float3 noiseCoord = i.objectPos * _NoiseScale;

				// Apply distortion (coordinate warping)
				noiseCoord = applyDistortion(noiseCoord, _NoiseDistortion);

				// Dark ink noise — extract Hue from 3-channel color noise
				// (HSV decomposition: only Hue drives the color mapping)
				float darkNoise = noise_fbm_hue(
					noiseCoord * _DarkNoiseScale,
					_NoiseDetail, _NoiseRoughness, _NoiseLacunarity);

				// Light ink noise — Hue from decorrelated color noise
				float lightNoise = noise_fbm_hue(
					noiseCoord * _LightNoiseScale + float3(7.3, 2.9, 5.1),
					_NoiseDetail, _NoiseRoughness, _NoiseLacunarity);

				// ---- Combine noise into ramp UV ----
				float rampInput = NdotL;
				rampInput -= darkNoise * _DarkNoiseStrength;   // Dark noise pulls toward ink
				rampInput += lightNoise * _LightNoiseStrength; // Light noise pulls toward paper
				rampInput = saturate(rampInput);

				// ---- Approach 2: ddx/ddy edge detection + darkening ----
				// Compute screen-space gradient of rampInput
				// Where noise changes rapidly → edge → darken (pigment accumulation)
				float edgeGradient = length(float2(ddx(rampInput), ddy(rampInput)));
				float edgeFactor = saturate(edgeGradient / max(_EdgeSharpness, 0.001));
				rampInput -= edgeFactor * _EdgeDarken;
				rampInput = saturate(rampInput);

				// ---- Approach 1: smoothstep color band sharpening ----
				// Sharp transitions at ink boundaries instead of linear lerp
				float s = _EdgeSharpness; // narrow transition width
				float band1 = smoothstep(0.25 - s, 0.25 + s, rampInput);
				float band2 = smoothstep(0.50 - s, 0.50 + s, rampInput);
				float band3 = smoothstep(0.75 - s, 0.75 + s, rampInput);

				// ---- Ink wash ramp mapping (sharp-edged 4-step) ----
				float3 deepInk    = _DeepInkColor.rgb;
				float3 mediumInk  = _MediumInkColor.rgb;
				float3 lightWash  = _LightWashColor.rgb;
				float3 paperWhite = _PaperWhiteColor.rgb;

				float3 rampColor = lerp(deepInk,
				                   lerp(mediumInk,
				                   lerp(lightWash, paperWhite, band3),
				                   band2),
				                   band1);

				// ---- Brush stroke texture ----
				float2 brushUV = i.uv * _BrushScale;
				brushUV = TRANSFORM_TEX(brushUV, _BrushTex);
				float brushTex = tex2D(_BrushTex, brushUV).r;
				float brushEffect = lerp(1.0, brushTex, _BrushStrength);

				// ---- Shadow attenuation ----
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				// ---- Final composition ----
				float3 finalColor = _BaseColor.rgb * rampColor * brushEffect;
				finalColor *= atten;

				return float4(finalColor, 1.0);
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
