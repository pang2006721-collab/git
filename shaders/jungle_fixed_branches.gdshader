shader_type canvas_item;

// 独立原画保留树枝与缠绕藤叶；垂下的三根长藤由软绳模块绘制。
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 p = UV / TEXTURE_PIXEL_SIZE;
	bool hanging = (p.x > 435.0 && p.x < 540.0 && p.y >= 275.0 && p.y < 1186.0)
		|| (p.x > 1113.0 && p.x < 1210.0 && p.y >= 1010.0 && p.y < 2029.0)
		|| (p.x > 475.0 && p.x < 585.0 && p.y >= 2250.0 && p.y < 2898.0);
	if (hanging && c.g > 0.45 && c.g > c.r * 1.1 && c.b < 0.4) {
		c.a = 0.0;
	}
	COLOR = c;
}
