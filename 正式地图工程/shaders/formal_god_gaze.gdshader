shader_type canvas_item;
// 在正式原图中移走黑色瞳孔并填回同色脸部，再绘制偏移后的原瞳孔。
uniform vec2 gaze_pixels = vec2(0.0);
float in_eyes(vec2 pixel) {
    bool left = pixel.x>=860.0 && pixel.x<=899.0 && pixel.y>=938.0 && pixel.y<=1003.0;
    bool right = pixel.x>=1022.0 && pixel.x<=1062.0 && pixel.y>=938.0 && pixel.y<=1003.0;
    return (left || right) ? 1.0 : 0.0;
}
float ink(vec3 color) { return 1.0-smoothstep(.12,.35,max(color.r,max(color.g,color.b))); }
void fragment() {
    vec4 source=texture(TEXTURE,UV);
    vec2 pixel=UV/TEXTURE_PIXEL_SIZE;
    float old_ink=in_eyes(pixel);
    vec3 skin_color=texture(TEXTURE,vec2(960.0,970.0)*TEXTURE_PIXEL_SIZE).rgb;
    vec3 base=mix(source.rgb,skin_color,old_ink);
    vec2 shifted=pixel-gaze_pixels;
    float new_ink=in_eyes(shifted)*ink(texture(TEXTURE,UV-gaze_pixels*TEXTURE_PIXEL_SIZE).rgb);
    COLOR=vec4(mix(base,vec3(0.0),new_ink),source.a);
}
