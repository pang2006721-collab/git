shader_type canvas_item;
uniform sampler2D frame_art : source_color, filter_linear_mipmap;
uniform sampler2D movie_texture : source_color, filter_linear;
uniform bool movie_ready = false;
uniform float outer_outline_pixels = 3.5;
float coverage(vec2 p){
 vec3 c=texture(frame_art,(p+vec2(248.0,497.0))/vec2(1280.0,4667.0)).rgb;
 return 1.0-min(c.r,min(c.g,c.b));
}
// Composite once in premultiplied space, so the hole and outline share coverage.
vec4 compose_sample(vec2 p){
 vec3 art=texture(frame_art,(p+vec2(248.0,497.0))/vec2(1280.0,4667.0)).rgb;
 float low=min(art.r,min(art.g,art.b));
 float high=max(art.r,max(art.g,art.b));
 float pigment=smoothstep(.02,.12,high-low);
 float alpha=mix(1.0-low,1.0,pigment);
 vec3 ink=mix(vec3(0.0),art,pigment);
 if(p.x<35.0 || p.x>800.0 || p.y<32.0 || p.y>520.0){
  float expanded=alpha;
  for(int i=0;i<8;i++){
   float angle=float(i)*.78539816;
   expanded=max(expanded,coverage(p+vec2(cos(angle),sin(angle))*outer_outline_pixels));
  }
  ink*=alpha/max(expanded,.0001);
  alpha=expanded;
 }
 vec2 movie_uv=(p-vec2(50.0,42.0))/vec2(735.0,463.0);
 movie_uv.x=(movie_uv.x-.5)*.893+.5;
 bool inside=p.x>50.0 && p.x<785.0 && p.y>42.0 && p.y<505.0;
 if(inside && movie_ready){return vec4(ink*alpha+texture(movie_texture,movie_uv).rgb*(1.0-alpha),1.0);}
 return vec4(ink*alpha,alpha);
}
void fragment(){
 vec2 p=UV*vec2(846.0,561.0)-vec2(8.0);
 vec2 footprint=fwidth(p)*.25;
 vec4 sum=compose_sample(p+vec2(-footprint.x,-footprint.y));
 sum+=compose_sample(p+vec2(footprint.x,-footprint.y));
 sum+=compose_sample(p+vec2(-footprint.x,footprint.y));
 sum+=compose_sample(p+vec2(footprint.x,footprint.y));
 sum*=.25;
 COLOR=vec4(sum.rgb/max(sum.a,.0001),sum.a);
}
