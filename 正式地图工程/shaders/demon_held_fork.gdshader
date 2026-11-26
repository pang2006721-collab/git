shader_type canvas_item;
// 直接保留原纹理像素；空手时只遮去叉子一侧，不重复乘纹理颜色。
uniform bool has_fork = true;
uniform bool enemy_art = false;
void fragment() {
    float y = UV.y / TEXTURE_PIXEL_SIZE.y;
    float edge = mix(40.0, 46.0, smoothstep(30.0, 40.0, y));
    edge = mix(edge, 40.0, smoothstep(40.0, 50.0, y));
    edge = mix(edge, 37.0, smoothstep(50.0, 60.0, y));
    edge = mix(edge, 35.0, smoothstep(60.0, 70.0, y));
    edge = mix(edge, 33.0, smoothstep(70.0, 90.0, y));
    edge = mix(edge, 34.0, smoothstep(90.0, 100.0, y));
    edge = mix(edge, 38.0, smoothstep(100.0, 115.0, y));
    if (enemy_art) {
        edge = mix(50.0, 40.0, smoothstep(50.0, 90.0, y));
    }
    if (!has_fork) {
        COLOR.a *= smoothstep(edge - 0.5, edge + 0.5, UV.x / TEXTURE_PIXEL_SIZE.x);
    }
}
