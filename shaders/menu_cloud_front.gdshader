shader_type canvas_item;
#include "res://shaders/menu_cloud_shape.gdshaderinc"
uniform sampler2D god_art;
void fragment() {
 vec4 c=clean_menu_background(TEXTURE,god_art,UV);
 vec2 p=UV*vec2(1920.0,1080.0);
 float cloud=smoothstep(cloud_edge(p.x)-0.7,cloud_edge(p.x)+0.7,p.y);
 float white=smoothstep(0.84,0.92,min(c.r,min(c.g,c.b)));
 bool region=p.x>925.0 && p.x<1175.0 && p.y<375.0;
 COLOR=vec4(c.rgb,region ? c.a*cloud*white : 0.0);
}
