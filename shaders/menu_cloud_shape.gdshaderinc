// 上帝前方的完整云沿，避免按白色像素筛选时把胡须碎片也挑进来。
float cloud_edge(float x) {
 if (x<975.0) return mix(237.0,198.0,smoothstep(925.0,975.0,x));
 if (x<1040.0) return mix(198.0,230.0,smoothstep(975.0,1040.0,x));
 if (x<1080.0) return mix(230.0,215.0,smoothstep(1040.0,1080.0,x));
 return mix(215.0,277.0,smoothstep(1080.0,1155.0,x));
}
vec4 clean_menu_background(sampler2D art, sampler2D god, vec2 uv) {
 vec4 c=texture(art,uv);
 vec2 p=uv*vec2(1920.0,1080.0);
 float mask=texture(god,uv).a;
 // 旧身体连同眉毛、胡须边缘一起清理，云沿下方补回云的原色。
 float front=smoothstep(cloud_edge(p.x)-0.7,cloud_edge(p.x)+0.7,p.y);
 vec4 sky=texture(art,vec2(1250.0/1920.0,uv.y));
 vec4 cloud=vec4(vec3(243.0/255.0),1.0);
 return mix(c,mix(sky,cloud,front),smoothstep(0.001,0.20,mask));
}
