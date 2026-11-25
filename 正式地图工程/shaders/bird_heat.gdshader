shader_type canvas_item;
uniform float heat = 0.0;
void fragment(){
    vec4 c = COLOR;
    float colored = smoothstep(.15,.4,max(c.r,max(c.g,c.b)));
    c.rgb = mix(c.rgb,vec3(1.0,.14,.055),heat*.72*colored);
    COLOR = c;
}
