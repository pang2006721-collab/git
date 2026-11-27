shader_type canvas_item;
uniform sampler2D frame_art : source_color, filter_linear;
uniform bool frame_only = false;
void fragment(){
 vec2 p=UV*vec2(830.0,545.0);
 vec4 art=texture(frame_art,(p+vec2(248.0,497.0))/vec2(1280.0,4667.0));
 float low=min(art.r,min(art.g,art.b));
 float high=max(art.r,max(art.g,art.b));
 float white=smoothstep(.86,.96,low);
 if(high-low<.09){white=low;art.rgb=vec3(0.0);}
 bool inside=p.x>50.0 && p.x<785.0 && p.y>42.0 && p.y<505.0;
 vec2 movie_uv=(p-vec2(50.0,42.0))/vec2(735.0,463.0);
 movie_uv.x=(movie_uv.x-.5)*.893+.5;
 vec4 movie=texture(TEXTURE,movie_uv);
 COLOR=frame_only ? vec4(art.rgb,1.0-white) : vec4(movie.rgb,inside ? white : 0.0);
}
