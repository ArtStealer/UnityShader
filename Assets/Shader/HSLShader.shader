// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/HSLShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DH("Hue",Range(0,360)) = 0
		_DS("Saturation",Range(-1,1)) = 0
		_DL("Lightness",Range(-1,1)) = 0
	}
	SubShader
	{
		// No culling or depth
		//Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float _DH;
			float _DS;
			float _DL;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}


			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				float r = col.r;
				float g = col.g;
				float b = col.b;
				float a = col.a;
				float h;
				float s;
				float l;
				float maxv = max(max(r,g),b);
				float minv = min(min(r,g),b);
				if (maxv == minv){
					h = 0.0;
				} else if (maxv == r && g >= b){
					h = 60.0*(g-b)/(maxv-minv)+0.0;
				} else if (maxv == r && g < b ){
					h = 60.0*(g-b)/(maxv-minv)+360.0;
				} else if (maxv == g){
					h = 60.0*(b-r)/(maxv-minv)+120.0;
				} else if (maxv == b){
					h = 60.0*(r-g)/(maxv-minv)+240.0;
				}
				l = 0.5*(maxv+minv);
				if (l == 0.0 || maxv == minv){
					s = 0.0;
				} else if (0.0 <= l && l <= 0.5){
					s = (maxv-minv)/(2.0*l);
				} else if (l > 0.5){
					s = (maxv-minv)/(2.0-2.0*l);
				}

				h = h + _DH;
				s = min(1.0,max(0.0,s+_DS));
				l = l + _DL;

				// final color
				float q;
				if (l < 0.5){
					q = l*(1.0+s);
				}else if (l >= 0.5){
					q = l+s-l*s;
				}
				float p = 2.0*l-q;
				float hk = h/360.0;
				float t[3];
				t[0] = hk+1.0/3.0;
				t[1] = hk;
				t[2] = hk-1.0/3.0;
				for(int i=0;i<3;i++){
					if (t[i] < 0.0){
						t[i] += 1.0;
					}else if (t[i] > 1.0){
						t[i] -= 1.0;
					}
				}
				float c[3];
				for (int i=0;i<3;i++){
					if (t[i] < 1.0/6.0){
						c[i] = p+((q-p)*6.0*t[i]);
					}else if (1.0/6.0 <= t[i] && t[i] < 0.5){
						c[i] = q;
					}else if (0.5 <= t[i] && t[i] < 2.0/3.0){
						c[i] = p+((q-p)*6.0*(2.0/3.0-t[i]));
					}else{
						c[i] = p;
					}
				}

				fixed4 finalColor = fixed4(c[0],c[1],c[2],a);
				finalColor += fixed4(_DL,_DL,_DL,0.0);

				return finalColor;
			}
			ENDCG
		}
	}
}
