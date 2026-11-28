shader_type canvas_item;
uniform vec2 gaze_pixels=vec2(0.0);
uniform float blink=0.0;
uniform float head_shake=0.0;
uniform float head_bow=0.0;
float eye_region(vec2 p){
    return ((p.x>=852.0 && p.x<=901.0 && p.y>=450.0 && p.y<=518.0) ||
            (p.x>=1013.0 && p.x<=1066.0 && p.y>=450.0 && p.y<=518.0)) ? 1.0 : 0.0;
}
void fragment(){
    vec2 p=UV/TEXTURE_PIXEL_SIZE;
    // Fade the local head motion into the untouched room, avoiding a rectangular cut edge.
    float head_mask=smoothstep(640.0,760.0,p.x)*(1.0-smoothstep(1160.0,1280.0,p.x))
        *smoothstep(300.0,370.0,p.y)*(1.0-smoothstep(620.0,680.0,p.y));
    p.x-=head_shake*head_mask;
    p.y-=(14.0+(p.y-480.0)*.035)*head_bow*head_mask;
    vec4 original=texture(TEXTURE,p*TEXTURE_PIXEL_SIZE);
    vec3 skin=texture(TEXTURE,vec2(960.0,480.0)*TEXTURE_PIXEL_SIZE).rgb;
    vec3 base=mix(original.rgb,skin,eye_region(p));
    vec2 shifted=p-gaze_pixels;
    shifted.y=483.0+(shifted.y-483.0)/max(.09,1.0-blink*.91);
    vec4 moved=texture(TEXTURE,shifted*TEXTURE_PIXEL_SIZE);
    float black=1.0-smoothstep(.12,.35,max(moved.r,max(moved.g,moved.b)));
    COLOR=vec4(mix(base,vec3(0.0),eye_region(shifted)*black),original.a);
}
