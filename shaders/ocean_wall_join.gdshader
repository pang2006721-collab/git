shader_type canvas_item;
uniform sampler2D shore_art : filter_linear;
uniform sampler2D shore_edges : filter_nearest;
uniform sampler2D ocean_edges : filter_nearest;
uniform vec2 shore_origin;
uniform vec2 shore_size;
uniform float seam_y;
uniform float world_scale=1.0;
varying vec2 world_point;
varying vec2 ocean_origin;
varying vec2 ocean_size;
void vertex() {
	world_point=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;
	ocean_origin=(MODEL_MATRIX*vec4(-960.0,-1620.0,0.0,1.0)).xy;
	ocean_size=vec2(length(MODEL_MATRIX[0].xy)*1920.0,length(MODEL_MATRIX[1].xy)*3240.0);
}
void fragment() {
	float sy=clamp((world_point.y-shore_origin.y)/shore_size.y,0.0,0.9999);
	vec2 se=texture(shore_edges,vec2(0.5,sy)).rg;
	vec2 oe=texture(ocean_edges,vec2(0.5,UV.y)).rg;
	float blend=smoothstep(96.0,560.0,(world_point.y-seam_y)/world_scale);
	vec2 bounds=mix(shore_origin.x+se*shore_size.x,ocean_origin.x+oe*ocean_size.x,blend);
	bool left=world_point.x<(bounds.x+bounds.y)*0.5;
	float outer=left?mix(shore_origin.x,ocean_origin.x,blend):mix(shore_origin.x+shore_size.x,ocean_origin.x+ocean_size.x,blend);
	float inner=left?bounds.x:bounds.y;
	float f=(world_point.x-outer)/(inner-outer);
	float sx=left?f*se.r:1.0-f*(1.0-se.g);
	float ox=left?f*oe.r:1.0-f*(1.0-oe.g);
	vec4 a=texture(shore_art,vec2(clamp(sx,0.0,1.0),sy));
	vec4 b=texture(TEXTURE,vec2(clamp(ox,0.0,1.0),UV.y));
	COLOR=mix(a,b,blend);
	COLOR.a*=float(f>=0.0 && f<=1.0);
}
