shader_type canvas_item;
uniform sampler2D cloud_profile : filter_linear, repeat_disable;
uniform bool below_profile = false;
void fragment() {
    vec4 source=texture(TEXTURE,UV);
    float edge=texture(cloud_profile,vec2(UV.x,.5)).r;
    float mask=below_profile ? step(edge,UV.y) : step(UV.y,edge);
    COLOR=vec4(source.rgb,source.a*mask);
}
