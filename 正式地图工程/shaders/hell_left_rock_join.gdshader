shader_type canvas_item;
// 清掉贴墙岩块内部旧墙描边与分层时留下的窄填色条。
uniform sampler2D rock_art : source_color, filter_linear, repeat_disable;
uniform vec2 wall_origin=vec2(-1.0,49109.0);
uniform vec2 rock_center=vec2(368.5,50072.50597);
uniform float rock_scale=.66848814;
void fragment(){
    vec2 pixel=UV/TEXTURE_PIXEL_SIZE;
    if(pixel.y>=770.0 && pixel.y<=1335.0 && pixel.x>=180.0 && pixel.x<=245.0){
        // 以同一行主墙黑边左沿和原笔画宽度截掉旧提取框尾巴。
        float edge=245.0;
        for(int x=175;x<225;x++){
            vec4 line=texture(TEXTURE,vec2((float(x)+.5)*TEXTURE_PIXEL_SIZE.x,UV.y));
            if(line.a>.9 && max(line.r,max(line.g,line.b))<.18){edge=float(x)+26.5;break;}
        }
        vec2 world=pixel+wall_origin;
        vec2 local=(world-rock_center)/rock_scale+vec2(274.5,277.5);
        local.x=549.0-local.x;
        vec2 size=vec2(textureSize(rock_art,0));
        if(local.x>=0.0 && local.x<549.0 && local.y>30.0 && local.y<525.0){
            vec4 rock=texture(rock_art,local/size);
            if(local.x>size.x-65.0){rock=texture(rock_art,vec2((size.x-110.0)/size.x,local.y/size.y));}
            if(rock.a>.9 && rock.r>.3 && pixel.x>=edge-29.0){COLOR.rgb=rock.rgb;}
        }

        if(pixel.x>edge){COLOR.a=0.0;}
    }
}
