shader_type canvas_item;
uniform sampler2D eyes_art;
uniform sampler2D brows_art;
void fragment() {
 vec4 c=texture(TEXTURE,UV);
 float mask=0.0;
 // 使用原始整张画布的五官透明度，连同抗锯齿边缘清除身体内的旧五官。
 for(int x=-2;x<=2;x++) {
  for(int y=-2;y<=2;y++) {
   vec2 uv=UV+vec2(float(x),float(y))*TEXTURE_PIXEL_SIZE;
   mask=max(mask,max(texture(eyes_art,uv).a,texture(brows_art,uv).a));
  }
 }
 c.rgb=mix(c.rgb,vec3(1.0,224.0/255.0,210.0/255.0),smoothstep(0.0,0.12,mask));
 COLOR=c;
}
