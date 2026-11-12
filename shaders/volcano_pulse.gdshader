shader_type canvas_item;
// Deform only the volcano in the supplied full seabed image; keep the floor fixed.
uniform float pulse_y = 0.0;
uniform float stretch_y = 1.0;
uniform float base_y = 3125.0;
uniform vec2 inner_x = vec2(905.0, 1110.0);
uniform vec2 outer_x = vec2(775.0, 1240.0);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	float weight_x = smoothstep(outer_x.x, inner_x.x, pixel.x)
		* (1.0 - smoothstep(inner_x.y, outer_x.y, pixel.x));
	float weight_y = 1.0 - smoothstep(base_y - 45.0, base_y, pixel.y);
	float weight = weight_x * weight_y;
	float sampled_y = base_y + (pixel.y - base_y - pulse_y) / stretch_y;
	vec2 sample_uv = vec2(UV.x, mix(pixel.y, sampled_y, weight) * TEXTURE_PIXEL_SIZE.y);
	COLOR = vertex_tint * texture(TEXTURE, sample_uv);
}
