shader_type canvas_item;
uniform vec2 gaze_pixels=vec2(0.0);
float eye_region(vec2 p){
    return ((p.x>=852.0 && p.x<=901.0 && p.y>=450.0 && p.y<=518.0) ||
            (p.x>=1013.0 && p.x<=1066.0 && p.y>=450.0 && p.y<=518.0)) ? 1.0 : 0.0;
}
void fragment(){
    vec4 original=texture(TEXTURE,UV);
    vec2 p=UV/TEXTURE_PIXEL_SIZE;
    vec3 skin=texture(TEXTURE,vec2(960.0,480.0)*TEXTURE_PIXEL_SIZE).rgb;
    vec3 base=mix(original.rgb,skin,eye_region(p));
    vec4 moved=texture(TEXTURE,UV-gaze_pixels*TEXTURE_PIXEL_SIZE);
    float black=1.0-smoothstep(.12,.35,max(moved.r,max(moved.g,moved.b)));
    COLOR=vec4(mix(base,vec3(0.0),eye_region(p-gaze_pixels)*black),original.a);
}
