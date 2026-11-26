extends Node2D
## 在幽灵白色脸部内部绘制表情，不改用户的身体和外轮廓。
var happiness: float=0.0
var gaze:Vector2=Vector2.ZERO
var blink:float=0.0
func _draw() -> void:
    draw_rect(Rect2(16,22,34,43),Color.WHITE)
    var happy:float=clampf(happiness,0,1)
    for x in [23.0,40.0]:
        var points=PackedVector2Array()
        for i in 21:
            var u:float=float(i)/20.0
            var normal=Vector2(x+gaze.x,34.0+(28.0+13.0*u-34.0)*(1.0-.9*blink)+gaze.y)
            var smiling=Vector2(x-5.0+10.0*u,35.0-5.0*sin(PI*u))
            points.append(normal.lerp(smiling,happy))
        draw_polyline(points,Color.BLACK,5.0,true)
        draw_circle(points[0],2.5,Color.BLACK,true,-1,true)
        draw_circle(points[-1],2.5,Color.BLACK,true,-1,true)
