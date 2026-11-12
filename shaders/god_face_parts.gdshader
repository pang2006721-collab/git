shader_type canvas_item;
uniform sampler2D eyes_art;
uniform sampler2D brows_art;
void fragment() {
	vec4 c=texture(TEXTURE,UV);
	float mask=max(texture(eyes_art,UV).a,texture(brows_art,UV).a);
	vec2 p=UV/TEXTURE_PIXEL_SIZE;
	// 两次导出的抗锯齿边缘略有差异，连同旧轮廓一起清掉，避免双眼残影。
	bool old_eyes=p.x>=480.0 && p.x<=600.0 && p.y>=247.0 && p.y<=291.0;
	bool old_brows=p.x>=468.0 && p.x<=612.0 && p.y>=229.0 && p.y<=254.0;
	mask=max(mask,float(old_eyes || old_brows));
	// 原整体图中的旧眼睛和眉毛用脸部原色覆盖，再显示独立部件。
	c.rgb=mix(c.rgb,vec3(1.0,0.894118,0.827451),mask);
	COLOR=c;
}
