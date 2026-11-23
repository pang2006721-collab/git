shader_type canvas_item;
uniform float blur_strength = 0.0;
uniform vec2 blur_direction = vec2(1.0,0.0);
uniform float blur_pixels = 7.0;
uniform vec4 frame_uv = vec4(0.0,0.0,1.0,1.0);
varying vec4 tint;
void vertex(){tint=COLOR;}
vec4 premultiply(vec4 c){return vec4(c.rgb*c.a,c.a);}
float inside_frame(vec2 uv){
    return step(frame_uv.x,uv.x)*step(frame_uv.y,uv.y)*step(uv.x,frame_uv.z)*step(uv.y,frame_uv.w);
}
void fragment(){
    vec2 d=blur_direction*TEXTURE_PIXEL_SIZE*blur_pixels;
    vec2 first=UV+d*.35;
    vec2 second=UV+d*.70;
    vec2 third=UV+d;
    vec4 c=premultiply(texture(TEXTURE,UV))*(1.0-blur_strength);
    c+=premultiply(texture(TEXTURE,first))*inside_frame(first)*blur_strength*.55;
    c+=premultiply(texture(TEXTURE,second))*inside_frame(second)*blur_strength*.30;
    c+=premultiply(texture(TEXTURE,third))*inside_frame(third)*blur_strength*.15;
    COLOR=vec4(c.rgb/max(c.a,.00001),c.a)*tint;
}
