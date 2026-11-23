shader_type canvas_item;
// 沿用现有手绘笔画：白纸透明、黑色墨迹变纯白，保留抗锯齿边缘。
void fragment() {
    vec4 original = texture(TEXTURE, UV);
    float ink = 1.0-smoothstep(0.12,0.72,dot(original.rgb,vec3(0.299,0.587,0.114)));
    COLOR = vec4(vec3(1.0),original.a*ink*COLOR.a);
}
