shader_type canvas_item;
uniform float fade_start = 0.8;
uniform float fade_end = 0.9;
void fragment() {
	COLOR.a *= 1.0 - smoothstep(fade_start, fade_end, UV.y);
}
