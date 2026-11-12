shader_type canvas_item;
uniform sampler2D edges : filter_nearest;
uniform float fade_start;
uniform float fade_end;
void fragment() {
	vec2 boundary=texture(edges,vec2(0.5,UV.y)).rg;
	float wall=float(UV.x<boundary.r || UV.x>boundary.g);
	COLOR.a*=wall*(1.0-smoothstep(fade_start,fade_end,UV.y));
}
