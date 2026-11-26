shader_type canvas_item;
// 竖长岩台接墙处只保留主墙原有笔画，去掉提取时残留的凸齿和尖尾。
void fragment(){
    vec2 pixel=UV/TEXTURE_PIXEL_SIZE;
    if(pixel.x>=190.0 && pixel.x<=245.0 && pixel.y>=350.0 && pixel.y<=1040.0){
        float edge=245.0;
        for(int x=175;x<225;x++){
            vec4 ink=texture(TEXTURE,vec2((float(x)+.5)*TEXTURE_PIXEL_SIZE.x,UV.y));
            if(ink.a>.9 && max(ink.r,max(ink.g,ink.b))<.18){
                edge=float(x)+26.5;
                break;
            }
        }
        COLOR.a*=1.0-smoothstep(edge-.5,edge+.5,pixel.x);
    }
}
