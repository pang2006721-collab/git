shader_type canvas_item;
uniform sampler2D cloud_edge : filter_linear, repeat_disable;
uniform float source_y = 0.0;
uniform bool align_opening = false;
void fragment() {
    vec2 paint_uv = UV;
    if (align_opening) {
        float y = UV.y*2048.0;
        paint_uv.y = (y+487.0*(1.0-smoothstep(1080.0,2048.0,y)))/2048.0;
    }
    vec4 paint = texture(TEXTURE, paint_uv);
    float edge = texture(cloud_edge,vec2(UV.x,.5)).r*6144.0;
    float y = source_y+UV.y*2048.0;
    paint.a *= 1.0-smoothstep(edge-.5,edge+.5,y);
    COLOR = paint;
}
