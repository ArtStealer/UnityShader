// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Cg shader using blending" 
{
   SubShader 
   {
      Tags { "Queue" = "Transparent" } 
      // draw after all opaque geometry has been drawn
      
      Pass 
      {
      	 //Cull off
         Cull Front // first pass renders only back faces 
         // (the "inside")
         ZWrite Off // don't write to depth buffer 
         // in order not to occlude other objects
         Blend SrcAlpha OneMinusSrcAlpha // use alpha blending
 
         CGPROGRAM 
 
         #pragma vertex vert 
         #pragma fragment frag
         
         struct vertexOutput {
            float4 pos : SV_POSITION;
            float4 posInObjectCoords : TEXCOORD0; //测试使用，可以删除
         };
 
         vertexOutput vert(float4 vertexPos : POSITION) //: SV_POSITION 
         {
         	vertexOutput output;
            output.pos = UnityObjectToClipPos(vertexPos);
            output.posInObjectCoords = vertexPos; //测试使用，可以删除
            return output;
         }
 
         float4 frag(vertexOutput input) : COLOR 
         {
         	if (input.posInObjectCoords.y > 0.0) //测试使用，可以删除
            {
               discard; // drop the fragment if y coordinate > 0
            }
            return float4(1.0, 0.0, 0.0, 0.3);
               // the fourth component (alpha) is important: 
               // this is semitransparent red
         }
         ENDCG  
      }
 
      Pass 
      {
      	 //Cull off
         //Cull Back // second pass renders only front faces 
         // (the "outside")
         ZWrite Off // don't write to depth buffer 
         // in order not to occlude other objects
         Blend SrcAlpha OneMinusSrcAlpha // use alpha blending
 
         CGPROGRAM 
 
         #pragma vertex vert 
         #pragma fragment frag
         
         struct vertexOutput {
            float4 pos : SV_POSITION;
            float4 posInObjectCoords : TEXCOORD0; //测试使用，可以删除
         };
 
         vertexOutput vert(float4 vertexPos : POSITION) //: SV_POSITION 
         {
         	vertexOutput output;
            output.pos = UnityObjectToClipPos(vertexPos);
            output.posInObjectCoords = vertexPos; //测试使用，可以删除
            return output;
         }
 
         float4 frag(vertexOutput input) : COLOR 
         {
         	if (input.posInObjectCoords.y > 0.0) //测试使用，可以删除
            {
               discard; // drop the fragment if y coordinate > 0
            }
            return float4(0.0, 1.0, 0.0, 0.3);
            // the fourth component (alpha) is important: 
            // this is semitransparent green
         }
         ENDCG  
      }
      
   }
}