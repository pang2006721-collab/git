shader_type canvas_item;
#include "res://shaders/formal_sky_reference.gdshaderinc"
uniform float reveal_alpha = 0.0;
uniform vec2 gaze = vec2(0.0);
uniform float pose_index = 0.0;
uniform vec4 eye_centers = vec4(.46575,.43024,.51458,.43024);
varying vec2 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
float cloud(vec2 p){vec3 c=sky_pixel(p).rgb;return smoothstep(.82,.9,min(c.r,min(c.g,c.b)));}
// Author palette: fixed flat fills shared by all three drawings.
vec3 flat_color(vec3 source,vec2 local_uv){
    float peak=max(source.r,max(source.g,source.b));
    if(peak<.34) return source;
    vec3 fill=vec3(125.0,80.0,19.0)/255.0;
    if(source.b>source.r*.84 && source.g>source.r*.87){
        fill=vec3(1.0);
    }else if(local_uv.y>.66 && source.g>source.r*.76 && source.b>source.r*.48){
        fill=vec3(201.0,184.0,144.0)/255.0;
        if(source.g>source.r*.88 && source.b<source.r*.63) fill=vec3(1.0,.91,.43);
    }else if(source.g>source.r*.83 && source.b<source.r*.65){
        fill=vec3(1.0,.91,.43);
    }else if(source.g>source.r*.76 && source.b>source.r*.48){
        fill=vec3(172.0,139.0,94.0)/255.0;
    }
    return mix(source,fill,smoothstep(.34,.48,peak));
}
void fragment(){
    vec2 p=(world_position-map_origin)/map_scale;
    // Sample the original painted cloud banks so the eagle stays behind their outlines.
    float cover=max(cloud(p),max(cloud(p+vec2(-14.0,0.0)),cloud(p+vec2(14.0,0.0))));
    cover=max(cover,max(cloud(p+vec2(0.0,-14.0)),cloud(p+vec2(0.0,14.0))));
    vec2 local_uv=UV*vec2(3.0,1.0)-vec2(pose_index,0.0);
    vec2 left=(local_uv-eye_centers.xy)*1024.0;
    vec2 right=(local_uv-eye_centers.zw)*1024.0;
    // Move the pupil texture only within the eye; the head and brow stay anchored.
    float eyes=max(1.0-smoothstep(7.0,13.0,length(left)),1.0-smoothstep(7.0,13.0,length(right)));
    vec2 shift=gaze*vec2(2.8,2.2)/1024.0;
    vec4 c=texture(TEXTURE,UV);
    vec4 looking=texture(TEXTURE,UV-shift/vec2(3.0,1.0));
    c=mix(c,looking,eyes);
    c.rgb=flat_color(c.rgb,local_uv);
    c.a*=(1.0-cover)*reveal_alpha;
    if(p.x<0.0 || p.x>1920.0 || p.y<0.0) c.a=0.0;
    COLOR=c;
}
