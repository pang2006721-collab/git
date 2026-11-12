shader_type canvas_item;
#include "res://shaders/menu_cloud_shape.gdshaderinc"
uniform sampler2D god_art;
void fragment() {
 COLOR=clean_menu_background(TEXTURE,god_art,UV);
}
