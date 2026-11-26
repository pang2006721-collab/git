shader_type canvas_item;
uniform sampler2D poster : source_color, filter_linear, repeat_disable;
uniform sampler2D clean_poster : source_color, filter_linear, repeat_disable;
uniform float band_top = 0.0;
uniform float inset_pixels = 85.333333;
uniform vec4 frame_bounds[4];

void fragment() {
    vec4 paint = texture(poster,UV);
    vec2 p = vec2(UV.x*1920.0,UV.y*2048.0+band_top);
    for (int i=0;i<4;i++) {
        vec4 b = frame_bounds[i];
        if (p.x < b.x || p.x > b.z || p.y < b.y || p.y > b.w) continue;
        // 同一张原画未叠框的干净底图，含上下各1像素拼接余量；无需猜色或修补背景。
        paint = texture(clean_poster,vec2(UV.x,(UV.y*2048.0+1.0)/2050.0));
        float center = (b.x+b.z)*.5;
        float source_x = p.x+(p.x < center ? -inset_pixels : inset_pixels);
        if (p.x >= b.x+inset_pixels && p.x <= b.z-inset_pixels) {
            vec3 source = texture(poster,vec2(source_x/1920.0,UV.y)).rgb;
            vec3 paper = texture(clean_poster,vec2(source_x/1920.0,(UV.y*2048.0+1.0)/2050.0)).rgb;
            // 原框为白墨，从合成图与底图还原其抗锯齿覆盖率，只平移两侧、不缩放笔画。
            vec3 coverage = (source-paper)/max(vec3(.01),vec3(1.0)-paper);
            float ink = clamp(max(coverage.r,max(coverage.g,coverage.b)),0.0,1.0);
            paint = mix(paint,vec4(1.0),ink);
        }
    }
    COLOR = paint;
}
