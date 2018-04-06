using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DualTextureScript : MonoBehaviour {

	public Vector4 patternTiles; // (x,y) specifies the location of which tile to use (0,0 is top left), (w,z) specifies how many tiles wide and high the atlas is
	public GameObject sprite; // a link to the sprite that holds this texture
	public Texture2D patternTexture; // a link to the pattern texture

	// Use this for initialization
	void Start () {

		SpriteRenderer renderer = sprite.GetComponent<SpriteRenderer> (); // grab the renderer from the sprite game object so you can access the shader material
		if (patternTexture) {
			renderer.material.SetTexture ("_PatternTex", patternTexture); // pass the second pattern texture to the shader
		}
		renderer.material.SetVector ("_PatternAtlasTiles", patternTiles); // pass the pattern tiles information to the shader

	}
}
