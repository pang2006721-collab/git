extends Node2D
## 短促的光环弹出笔画，只在冲击瞬间出现，不用满屏闪光。
var marks:Array=[]
func _draw() -> void:
    for mark:Dictionary in marks:
        var age:float=mark.age
        if age<0.0 or age>.28:continue
        var u:float=age/.28
        var strength:float=mark.strength
        var center:Vector2=mark.position
        var color=Color(1.0,.92,.47,(1.0-u)*(1.0-u)*strength)
        for i in 7:
            var angle:float=-PI+float(i)*TAU/7.0
            var direction=Vector2(cos(angle),sin(angle)*.65)
            var a:Vector2=center+direction*(65+u*42)
            var b:Vector2=a+direction*(10+9*sin(PI*u))
            draw_line(a,b,color,4.0,true)
