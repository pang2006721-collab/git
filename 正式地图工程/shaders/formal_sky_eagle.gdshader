shader_type canvas_item;
#include "res://shaders/formal_sky_reference.gdshaderinc"
uniform float reveal_alpha = 0.0;
uniform vec2 gaze = vec2(0.0);
uniform float pose_index = 0.0;
uniform vec4 eye_centers = vec4(.46575,.43024,.51458,.43024);
varying vec2 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
float cloud(vec2 p){vec3 c=sky_pixel(p).rgb;return smoothstep(.82,.9,min(c.r,min(c.g,c.b)));}
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
    // A continuous brown-only color wash leaves eyes, pale fills and contour coverage intact.
    float r=max(c.r,.001);
    float brown=smoothstep(.20,.28,(c.r-c.g)/r)*smoothstep(.36,.44,(c.r-c.b)/r);
    float interior=smoothstep(.20,.40,c.r);
    c.rgb=mix(c.rgb,vec3(125.0,80.0,19.0)/255.0,brown*interior);
    c.a*=(1.0-cover)*reveal_alpha;
    if(p.x<0.0 || p.x>1920.0 || p.y<0.0) c.a=0.0;
    COLOR=c;
}
