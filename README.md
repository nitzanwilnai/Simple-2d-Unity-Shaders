# Simple, 2d, Unity shaders


* **Tint Shader** - A shader that let's you change the colors of the red, green and blue channels in a texture.

![Pre tint texture](Readme-Images/Tint-2.png?raw=true "Tint 1") gets tinted to ![Post tint texture](Readme-Images/Tint-1.png?raw=true "Tint 2")


* **Resize Shader** - A shader that let's you resize the texture. You can set the x and y axis scale, and the alignment so the scale happens from the center, top, right, bottom, or left side.

![Pre resize texture](Readme-Images/Resize-1.png?raw=true "Tint 1") resized to ![Post resize texture](Readme-Images/Resize-2.png?raw=true "Tint 2")


* **Resize Atlas Shader** - A shader that let's you resize textures that are imported from a texture atlas.

![Pre resize atlas texture](Readme-Images/Resize-Atlas-1.png?raw=true "Tint 1") resized to ![Post resize atlas texture](Readme-Images/Resize-Atlas-2.png?raw=true "Tint 2")


* **Outline Shader** - A shader that let's you add an outline around an image. You can set the outline color and the width of the outline. Similar to the "stroke" feature in Photoshop.

![Pre outline texture](Readme-Images/Outline-1.png?raw=true "Tint 1") black outline is added ![Post outline texture](Readme-Images/Outline-2.png?raw=true "Tint 2")


* **Dual Texture Tint** - A tint shader that let's you mix two different tint textures.

![Dual texture](Readme-Images/test_texture2.png?raw=true "Texture") ![Pattern texture](Readme-Images/test_pattern.png?raw=true "Pattern") combined and tinted ![Combo tint texture](Readme-Images/Dual-Texture.png?raw=true "Combo")


* **Dual Texture Atlas Tint** - A tint shader that let's you mix two different tint textures, both imported from a texture atlas.

![Dual texture](Readme-Images/atlas_texture.png?raw=true "Texture") ![Pattern texture](Readme-Images/atlas_pattern.png?raw=true "Pattern") combined and tinted ![Combo tint texture](Readme-Images/Dual-Texture-Atlas.png?raw=true "Combo")

# Tint Shader
This shader let's you apply a different color to the red, green and blue color channels.

In the material you can specify which color to replace each of the RGB channels with:

![Tint material settings](Readme-Images/Tint-Material-Settings.png?raw=true "Tint Material Settings")


# Resize Shader
This shader let's you resize a texture. You can specify a different scale for the x and y axis, plus you can set the scaling alignment.

![Resize material settings](Readme-Images/Resize-Material-Settings.png?raw=true "Resize material settings")


# Resize Atlas Shader
This shader let's you resize a texture that was imported from a texture atlas.

Becuase the UV coordinates are different for each tile, we need to know how many tiles wide and high the source atlas was. It is theoretically possible to get this information from the _MainTex_ST variable that is automagically filled by Unity, but I could not get it to work. Instead the developer needs to specify the tile size to the material.

![Resize atlas settings](Readme-Images/Resize-Atlas-Settings.png?raw=true "Resize atlas settings")

# Outline Shader
This shader adds a stroke effect around objects. Users can specify the color of the stroke in the material. The size (thickness) of the stroke is hard coded into the shader and needs to be modified there. That is becuase shaders are pre-compiled and so any variables that control the size of a loop (we loop according to the thickness of the stroke in the shader) need to be compiled into the shader.

![Outline settings](Readme-Images/Outline-Settings.png?raw=true "Outline settings")

The shader works by checking a circle of pixels around the current pixel. The shader starts by checking pixels from radius 1, and then incrementing the radius until the desired stroke width is reached. If an alpha pixel is encountered, the loop exits early and we color this pixel the color of the stroke color. If we are at almost the maximum distance from an alpha pixel, we smoothly anti-alias the inside of our stroke by combining a fraction of the stroke color with the original pixel color.


# Dual Texture Tint

This shader combines and tints two textures. It let's you apply different patterns on top of a texture, plus to tint them both.

![Dual texture tint settings](Readme-Images/Dual-Texture-Settings.png?raw=true "Dual texture tint settings")


# Dual Texture Atlas Tint

This shader is identical to the non-atlas version, except becasue UV coordinates are shared between textures, the developer needs to specify the tile coordinates of the pattern they want to apply from the second texture. Both textures need to have the same tile numbers. 

Example atlas texture:
![Atlas](Readme-Images/atlas_texture.png?raw=true "Atlas texture")

Example atlas of patterns:
![Pattern atlas](Readme-Images/atlas_pattern.png?raw=true "Atlas pattern")

If you want the top left pattern, you need to specify tile position (0,0). 

if you want the bottom left pattern, you can need to specify tile position (0,1).

![Dual texture atlas script](Readme-Images/Dual-Texture-Atlas-Script.png?raw=true "Dual texture atlas tint script")

![Dual texture atlas tint settings](Readme-Images/Dual-Texture-Atlas-Settings.png?raw=true "Dual texture atlas tint settings")



## Note! You have to make sure all your imported textures have their mesh type set to Full Rect.
Sprite Mode -> Mesh Type -> Full Rect

![Full rect material](Readme-Images/Full-Rect-Material.png?raw=true "Full rect material")

