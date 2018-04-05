using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DualTextureScript : MonoBehaviour {

	public Vector4 patternTiles;
	public GameObject sprite;
	public Texture2D patternTexture;

	// Use this for initialization
	void Start () {

		SpriteRenderer renderer = sprite.GetComponent<SpriteRenderer> ();
		if (patternTexture) {
			renderer.material.SetTexture ("_PatternTex", patternTexture);
		}
		renderer.material.SetVector ("_PatternAtlasTiles", patternTiles);

	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
