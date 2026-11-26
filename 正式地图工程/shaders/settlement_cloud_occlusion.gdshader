shader_type canvas_item;
uniform sampler2D cloud_edge : filter_linear, repeat_disable;
uniform float source_y = 0.0;
void fragment() {
    vec4 paint = texture(TEXTURE, UV);
    float edge = texture(cloud_edge,vec2(UV.x,.5)).r*6144.0;
    float y = source_y+UV.y*2048.0;
    paint.a *= 1.0-smoothstep(edge-.5,edge+.5,y);
    COLOR = paint;
}
