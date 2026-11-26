shader_type canvas_item;
// 用户新版数字带整片半透明黑底；仅保留白色笔画和抗锯齿覆盖。
void fragment(){
    float ink=max(COLOR.r,max(COLOR.g,COLOR.b));
    COLOR=vec4(vec3(1.0),COLOR.a*ink);
}
