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
    // 洞口提取时黑边外残留的窄红条不应盖住正在探出的幽灵。
    if(pixel.x>=100.0 && pixel.x<=225.0 && pixel.y>=400.0 && pixel.y<=650.0
        && max(COLOR.r,max(COLOR.g,COLOR.b))>=.18){
        for(int d=1;d<=16;d++){
            vec4 left=texture(TEXTURE,(pixel-vec2(float(d),0.0))*TEXTURE_PIXEL_SIZE);
            if(left.a>.9 && max(left.r,max(left.g,left.b))<.18){
                COLOR.a=0.0;
                break;
            }
        }
    }
}
