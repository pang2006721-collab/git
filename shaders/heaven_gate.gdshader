shader_type canvas_item;
uniform bool gate=false;
void fragment() {
	vec4 c=texture(TEXTURE,UV);
	if(gate) {
		c.a*=float(c.r>0.85 && c.g>0.65 && c.b>0.60);
	} else {
		c.a*=1.0-smoothstep(0.975,1.0,UV.y);
	}
	COLOR=c;
}
