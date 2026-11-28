shader_type canvas_item;
// Extend a real wall column across the transparent outer padding.
void fragment(){
 vec4 wall=texture(TEXTURE,vec2(16.5*TEXTURE_PIXEL_SIZE.x,UV.y));
 COLOR=vec4(wall.rgb,1.0);
}
