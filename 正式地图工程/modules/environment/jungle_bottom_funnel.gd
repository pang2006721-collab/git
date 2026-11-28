extends Node2D
## Invisible steep side slopes funnel outside falls back onto the existing bank.
@export var funnel_height:float=1450.0
@export var outer_x:float=-420.0
@export var inner_x:float=180.0
@export var bottom_vertical:float=160.0
var floor_y:float=0.0
func _ready():rebuild()
func rebuild():
    var layout:Node2D=get_parent()
    var floor_shape:CollisionShape2D=layout.get_node("JungleFloor/Collision")
    floor_y=to_local(floor_shape.to_global(Vector2(0,-floor_shape.shape.size.y*.5))).y
    for side in [-1,1]:
        var label:String="Left" if side<0 else "Right"
        var wall:StaticBody2D=get_node_or_null(label)
        if wall==null:
            wall=StaticBody2D.new()
            wall.name=label
            wall.collision_layer=32
            wall.collision_mask=2
            add_child(wall)
            var shape=CollisionPolygon2D.new()
            shape.name="Slope"
            wall.add_child(shape)
        var points:=PackedVector2Array([Vector2(outer_x-900,floor_y-funnel_height),Vector2(outer_x,floor_y-funnel_height),Vector2(inner_x,floor_y-bottom_vertical),Vector2(inner_x,floor_y+400),Vector2(outer_x-900,floor_y+400)])
        if side>0:
            for i in points.size():points[i].x=1920.0-points[i].x
            points.reverse()
        wall.get_node("Slope").polygon=points
