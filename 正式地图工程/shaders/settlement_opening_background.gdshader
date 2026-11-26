shader_type canvas_item;
uniform sampler2D opening_room : source_color, filter_linear, repeat_disable;
void fragment() {
    float y = UV.y*2048.0;
    if (y < 1080.0) {
        // 与光环动画使用同一张天堂背景；不用长图中下移487像素的另一位上帝。
        COLOR = texture(opening_room,vec2(UV.x,y/4706.0));
    } else {
        // 跳过长图里的上帝；在云区内连续接回原切片边界，后续结算位置保持原样。
        float source_y = y+487.0*(1.0-smoothstep(1080.0,2048.0,y));
        COLOR = texture(TEXTURE,vec2(UV.x,source_y/2048.0));
    }
}
