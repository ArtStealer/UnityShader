// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/sea"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		NUM_STEPS("NUM_STEPS",Int) = 8
		ITER_GEOMETRY("ITER_GEOMETRY",Int) = 3
		ITER_FRAGMENT("ITER_FRAGMENT",Int) = 5
		SEA_HEIGHT("SEA_HEIGHT",Float) = 0.6
		SEA_CHOPPY("SEA_CHOPPY",Float) = 4.0
		SEA_SPEED("SEA_SPEED",Float) = 0.8
		SEA_FREQ("SEA_FREQ",Float) = 0.16
		SEA_BASE("SEA_BASE",Vector) = (0.1,0.19,0.22)
		SEA_WATER_COLOR("SEA_WATER_COLOR",Vector) = (0.8,0.9,0.6)
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#define PI 3.1415
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				//o.uv = v.uv;
				o.uv = ComputeScreenPos(o.vertex);
				return o;
			}
			sampler2D _MainTex;

			int NUM_STEPS;
			int ITER_GEOMETRY;
			int ITER_FRAGMENT;
			float SEA_HEIGHT;
			float SEA_CHOPPY;
			float SEA_SPEED;
			float SEA_FREQ;
			float4 SEA_BASE;
			float4 SEA_WATER_COLOR;

			float3x3 fromEuler(float3 ang){
				
				float2 a1 = float2(sin(ang.x),cos(ang.x));
				float2 a2 = float2(sin(ang.y),cos(ang.y));
				float2 a3 = float2(sin(ang.y),cos(ang.z));
				float3x3 m;
				m[0] = float3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
				m[1] = float3(-a2.y*a1.x,a1.y*a2.y,a2.x);
				m[2] = float3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
				return m;
			}

			float hash(float2 p){
				float h = dot(p,float2(127.1,311.7));
				return frac(sin(h)*43758.5453123);
			}

			float noise(float2 p){
				float2 i = floor(p);
				float2 f = frac(p);
				float2 u = f*f*(3.0-2.0*f);
				return -1.0+2.0*lerp(
					lerp(hash(i + float2(0.0,0.0)),hash(i + float2(1.0,0.0)),u.x),
					lerp(hash(i + float2(0.0,1.0)),hash(i + float2(1.0,1.0)),u.x),
					u.y
					);
			}

			float getDiffuse(float3 n,float3 l,float p){
				return pow(dot(n,l) * 0.4 + 0.6,p);
			}

			float getSpecular(float3 n,float3 l,float3 e,float s){
				float nrm = (s + 8.0) / (PI * 8.0);
				return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
			}

			//sky
			float3 getSkyColor(float3 e){
				e.y = max(e.y,0.0);
				return float3(pow(1.0-e.y,2.0),1.0-e.y,0.6+(1.0-e.y)*0.4);
			}

			// sea
			float getSeaOctave(float2 uv, float choppy){
				uv += noise(uv);
				float2 wv = 1.0-abs(sin(uv));
				float2 swv = abs(cos(uv));
				wv = lerp(wv,swv,wv);
				return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
			}

			float getMap(float3 p,float seatime,int n){
				float2x2 octave_m = float2x2(1.6,1.2,-1.2,1.6);
				float freq = SEA_FREQ;
				float amp = SEA_HEIGHT;
				float choppy = SEA_CHOPPY;
				float2 uv = p.xz;
				uv.x *= 0.75;

				float d,h = 0.0;
				for(int i = 0;i < n;i++){
					d = getSeaOctave((uv+seatime)*freq,choppy);
					d += getSeaOctave((uv-seatime)*freq,choppy);
					h += d * amp;
					uv = mul(uv,octave_m);
					freq *= 1.9;
					amp *= 0.22;
					choppy = lerp(choppy,1.0,0.2);
				}
				return p.y - h;
			}

			float3 getSeaColor(float3 p,float3 n,float3 l,float3 eye,float3 dist){
				float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
				fresnel = pow(fresnel,3.0) * 0.65;
				float3 seaColorBase = SEA_BASE.xyz;
				float3 seaColorWater = SEA_WATER_COLOR.xyz;
				float3 reflected = getSkyColor(reflect(eye,n));
				float3 refracted = seaColorBase + getDiffuse(n,l,80.0) * seaColorWater * 0.12;

				float3 color = lerp(refracted,reflected,fresnel);

				float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
				color += seaColorWater * (p.y - SEA_HEIGHT) * 0.18 * atten;

				float sp = getSpecular(n,l,eye,60.0);
				color += float3(sp,sp,sp);
				return color;
			}

			float3 getNormal(float3 p,float eps,float seatime){
				float3 n;
				n.y = getMap(p,seatime,ITER_FRAGMENT);
				n.x = getMap(float3(p.x+eps,p.y,p.z),seatime,ITER_FRAGMENT) - n.y;
				n.z = getMap(float3(p.x,p.y,p.z+eps),seatime,ITER_FRAGMENT) - n.y;
				n.y = eps;
				return normalize(n);
			}

			float getHeightMapTracing(float3 ori,float3 dir,float seatime,out float3 p){
				float tm = 0.0;
				float tx = 1000.0;
				float hx = getMap(ori + dir * tx,seatime,ITER_GEOMETRY);
				if (hx > 0.0){
					return tx;
				}
				float hm = getMap(ori + dir * tm,seatime,ITER_GEOMETRY);
				float tmid = 0.0;
				for (int i = 0; i < NUM_STEPS; i++){
					tmid = lerp(tm,tx,hm/(hm-hx));
					p = ori + dir * tmid;
					float hmid = getMap(p,seatime,ITER_GEOMETRY);
					if (hmid < 0.0){
						tx = tmid;
						hx = hmid;
					} else {
						tm = tmid;
						hm = hmid;
					}
				}
				return tmid;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float2 uv = i.uv.xy;
				//float2 uv = (i.uv.xy/i.uv.w);
				float t = _Time.y;
				float seatime = 1.0 + t * SEA_SPEED;
				float epsilon = 0.1/_ScreenParams.x;

				uv = uv * 2.0 - 1.0;
				uv.x *= _ScreenParams.x/_ScreenParams.y;
				float time = t * 0.3;

				//ray
				float3 ang = float3(sin(time*3.0)*0.1,sin(time)*0.2+0.3,time);
				float3 ori = float3(0.0,3.5,time*5.0);
				float3 dir = normalize(float3(uv.xy,-2.0));
				dir.z += length(uv) * 0.15;
				dir = mul(normalize(dir),fromEuler(ang));

				//tracing
				float3 p = float3(0.0,0.0,0.0);
				getHeightMapTracing(ori,dir,seatime,p);
				float3 dist = p - ori;
				float3 n = getNormal(p,dot(dist,dist) * epsilon,seatime);
				float3 light = normalize(float3(0.0,1.0,0.8));

				//color
				float3 sky = getSkyColor(dir);
				float3 sea = getSeaColor(p,n,light,dir,dist);
				float3 color = lerp(
							sky,
							sea,
							pow(smoothstep(0.0,-0.05,dir.y),0.3));

				return fixed4(pow(color,float3(0.75,0.75,0.75)),1.0);
			}
			ENDCG
		}
	}
}
