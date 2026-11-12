shader_type canvas_item;
uniform bool foreground = false;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float y = UV.y * 1980.0;
	if (foreground) {
		// 只让树冠遮挡身体，下方树林不覆盖玩家。
		float canopy = y < 1690.0 ? 1.0 : float(c.r < 0.18 && c.g < 0.20 && c.b < 0.06);
		c.a *= canopy * (1.0 - smoothstep(1795.0, 1810.0, y));
	} else {
		c.a *= 1.0 - smoothstep(1900.0, 1980.0, y);
	}
	COLOR = c;
}
