shader_type canvas_item;
// 分层时误裁的黑边只从同坐标原稿恢复，不补画或移动岩壁。
uniform sampler2D original_art : source_color, filter_linear, repeat_disable;
void fragment(){
    vec2 pixel=UV/TEXTURE_PIXEL_SIZE;
    bool in_repair=pixel.x>=185.0 && pixel.x<=580.0 && pixel.y>=130.0 && pixel.y<=370.0 && pixel.y>=pixel.x*.38+40.0;
    if(in_repair){
        vec4 original=texture(original_art,pixel/vec2(textureSize(original_art,0)));
        if(max(original.r,max(original.g,original.b))<.18 && original.a>.9){
            COLOR=vec4(original.rgb,1.0);
        }
    }
}
