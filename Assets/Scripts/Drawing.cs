using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class Drawing : MonoBehaviour {
	public Material mat;

	void Start () {
	}
	void Update () {
	}
	void OnRenderImage(RenderTexture src, RenderTexture dest) {
		Graphics.Blit(src, dest, mat);
	}
}
