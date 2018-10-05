// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Cg shader for RGB cube" 
{ 
   SubShader 
   { 
      Pass 
      { 
         CGPROGRAM 
 		 // vert function is the vertex shader 
         #pragma vertex vert 
         // frag function is the fragment shader
         #pragma fragment frag 
 
         // for multiple vertex output parameters an output structure 
         // is defined:
		 struct vertexOutput {
		    float4 pos : SV_POSITION;
		    float4 col : TEXCOORD0;
		 };
 		 // vertex shader 
         vertexOutput vert(float4 vertexPos : POSITION) 
         {
            vertexOutput output; // we don't need to type 'struct' here
 
            output.pos =  UnityObjectToClipPos(vertexPos);
            output.col = vertexPos + float4(0.5, 0.5, 0.5, 0.0);
            // Here the vertex shader writes output data
            // to the output structure. We add 0.5 to the 
            // x, y, and z coordinates, because the 
            // coordinates of the cube are between -0.5 and
            // 0.5 but we need them between 0.0 and 1.0. 
            return output;
         }
 		 // fragment shader
         float4 frag(vertexOutput input) : COLOR 
         {
            return input.col; 
            // Here the fragment shader returns the "col" input 
            // parameter with semantic TEXCOORD0 as nameless
            // output parameter with semantic COLOR.
         }
         ENDCG  
      }
   }
}