shader_type canvas_item;
uniform bool foreground=false;
void fragment() {
	vec4 c=texture(TEXTURE,UV);
	if(foreground) {
		c.a*=float(UV.y>0.87 && c.r<0.30 && c.g<0.40 && c.b<0.12);
	} else {
		c.a*=1.0-smoothstep(0.985,1.0,UV.y);
	}
	COLOR=c;
}
