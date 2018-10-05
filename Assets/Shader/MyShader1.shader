// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// defines the name of the shader
Shader "Cg basic shader"
{
   // Unity chooses the subshader that fits the GPU best
   SubShader
   {
      // some shaders require multiple passes
      Pass
      {
         CGPROGRAM // here begins the part in Unity's Cg
         // this specifies the vert function as the vertex shader
         #pragma vertex vert 
         // this specifies the frag function as the fragment shader
         #pragma fragment frag
         // vertex shader
         float4 vert(float4 vertexPos : POSITION) : SV_POSITION
         {
            return UnityObjectToClipPos(float4(1.0, 1.0, 1.0, 1.0)*vertexPos);
            // this line transforms the vertex input parameter
            // vertexPos with the built-in matrix UNITY_MATRIX_MVP
            // and returns it as a nameless vertex output parameter
         }
         // fragment shader
         float4 frag(void) : COLOR
         {
            return float4(0.2, 0.8, 0.0, 0.1);
            // this fragment shader returns a nameless fragment
            // output parameter (with semantic COLOR) that is set to
            // opaque red (red = 1, green = 0, blue = 0, alpha = 1)
         }
         ENDCG // here ends the part in Cg
      }
   }
}
