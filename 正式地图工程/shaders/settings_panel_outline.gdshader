shader_type canvas_item;
uniform float outline_width = 12.0;

float body_alpha(sampler2D source, vec2 uv, vec2 pixel_size) {
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return 0.0;
    vec4 paint = texture(source,uv);
    vec2 pixel = uv/pixel_size;
    vec2 extent = vec2(1.0)/pixel_size;
    float distance_to_edge = min(min(pixel.x,extent.x-pixel.x),min(pixel.y,extent.y-pixel.y));
    float perimeter = 1.0-smoothstep(45.0,48.0,distance_to_edge);
    float white = smoothstep(0.70,0.92,min(paint.r,min(paint.g,paint.b)));
    return paint.a*(1.0-perimeter*white);
}

void fragment() {
    vec4 paint = texture(TEXTURE,UV);
    vec2 pixel = UV/TEXTURE_PIXEL_SIZE;
    vec2 extent = vec2(1.0)/TEXTURE_PIXEL_SIZE;
    float distance_to_edge = min(min(pixel.x,extent.x-pixel.x),min(pixel.y,extent.y-pixel.y));
    float fill = body_alpha(TEXTURE,UV,TEXTURE_PIXEL_SIZE);
    float border = fill;
    // 围绕棕色实边向外扩同样的像素距离，不沿旧白边的留白画黑块。
    if (distance_to_edge < 65.0) {
        for (int i = 0; i < 32; i++) {
            float angle = float(i)*6.28318530718/32.0;
            vec2 offset = vec2(cos(angle),sin(angle))*outline_width*TEXTURE_PIXEL_SIZE;
            border = max(border,body_alpha(TEXTURE,UV+offset,TEXTURE_PIXEL_SIZE));
        }
    }
    float perimeter = 1.0-smoothstep(45.0,48.0,distance_to_edge);
    vec3 brown = texture(TEXTURE,vec2(0.5,40.0/extent.y)).rgb;
    // 原白底抗锯齿混入了灰白色，外沿统一用原棕色填充，覆盖残留亮点。
    vec3 ink = mix(paint.rgb,brown,perimeter);
    COLOR = vec4(ink*fill/max(border,0.0001),border);
}
