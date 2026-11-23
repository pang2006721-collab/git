shader_type canvas_item;
// 保留原绑藤笔触，加粗绿色内芯与黑色外缘，不改源图。
uniform float core_pixels = 1.25;
uniform float outline_pixels = 3.5;
varying vec4 vertex_tint;
void vertex() {
    vertex_tint = COLOR;
}
void fragment() {
    float core = texture(TEXTURE, UV).a;
    float edge = core;
    for (int i = 0; i < 16; i++) {
        float angle = float(i) * 0.3926990817;
        vec2 direction = vec2(cos(angle),sin(angle))*TEXTURE_PIXEL_SIZE;
        core = max(core,texture(TEXTURE,UV+direction*core_pixels).a);
        edge = max(edge,texture(TEXTURE,UV+direction*outline_pixels).a);
    }
    vec3 green = vec3(0.31,0.61,0.09);
    COLOR = vec4(mix(vec3(0.0),green,core),edge)*vertex_tint;
}
