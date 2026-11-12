shader_type canvas_item;

uniform float blur_pixels : hint_range(0.0, 3.0) = 0.85;

void fragment() {
	vec2 step_uv = TEXTURE_PIXEL_SIZE * blur_pixels;
	// Premultiplied accumulation avoids white halos from transparent source pixels.
	vec4 c0 = texture(TEXTURE, UV);
	vec4 c1 = texture(TEXTURE, UV + vec2(step_uv.x, 0.0));
	vec4 c2 = texture(TEXTURE, UV - vec2(step_uv.x, 0.0));
	vec4 c3 = texture(TEXTURE, UV + vec2(0.0, step_uv.y));
	vec4 c4 = texture(TEXTURE, UV - vec2(0.0, step_uv.y));
	float alpha = (c0.a * 4.0 + c1.a + c2.a + c3.a + c4.a) / 8.0;
	vec3 rgb = (c0.rgb * c0.a * 4.0 + c1.rgb * c1.a + c2.rgb * c2.a + c3.rgb * c3.a + c4.rgb * c4.a) / 8.0;
	COLOR = vec4(rgb / max(alpha, 0.00001), alpha);
}
