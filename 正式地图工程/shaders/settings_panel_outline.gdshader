shader_type canvas_item;
// 旧PSD底板的白色外沿按新版参考图改黑，仅影响底板，不改装饰与控件。
void fragment() {
    vec4 paint = texture(TEXTURE, UV);
    vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
    vec2 extent = vec2(1.0) / TEXTURE_PIXEL_SIZE;
    float edge_distance = min(min(pixel.x, extent.x-pixel.x), min(pixel.y, extent.y-pixel.y));
    float border_only = 1.0-smoothstep(45.0,48.0,edge_distance);
    float white_edge = border_only*smoothstep(0.65, 0.92, min(paint.r, min(paint.g, paint.b)));
    COLOR = vec4(mix(paint.rgb, vec3(0.0), white_edge), paint.a);
}
