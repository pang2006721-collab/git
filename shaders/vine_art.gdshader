shader_type canvas_item;
void fragment() {
	if(COLOR.g<0.45||COLOR.g<COLOR.r*1.1||COLOR.b>0.4) COLOR.a=0.0;
}
