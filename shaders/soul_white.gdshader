shader_type canvas_item;
void fragment() {
	// 浅粉身体显示为白色，黑色五官、描边和透明边缘保持原样。
	float value=max(COLOR.r,max(COLOR.g,COLOR.b));
	COLOR.rgb=vec3(value);
}
