extends Node2D
## 抛物线飞行，逐帧扫过前后位置，防止高速叉子穿过角色或平台。
@export var gravity: float = 420.0
@export var speed: float = 680.0
@export var lifetime: float = 4.0
var velocity: Vector2
var encounter: Node
var _age: float = 0.0
var _stuck: bool = false
var _pierced_player: bool = false

func launch(aim: Vector2) -> void:
    var seconds := clampf(global_position.distance_to(aim)/speed,0.25,1.1)
    velocity=(aim-global_position-Vector2(0,gravity*seconds*seconds*.5))/seconds
    rotation=velocity.angle()+PI*.5

func _physics_process(delta: float) -> void:
    _age+=delta
    if _age>lifetime:queue_free();return
    if _stuck:return
    var previous:=global_position
    var next:=previous+velocity*delta+Vector2(0,gravity*delta*delta*.5)
    velocity.y+=gravity*delta
    var player:CharacterBody2D=encounter.level.player
    var query:=PhysicsRayQueryParameters2D.create(previous,next,9|player.collision_layer)
    if _pierced_player: query.exclude=[player.get_rid()]
    var hit:=get_world_2d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        global_position=next
        rotation=velocity.angle()+PI*.5
    elif hit.collider==player:
        _pierced_player=true
        global_position=next
        rotation=velocity.angle()+PI*.5
        encounter.level.die()
    else:
        global_position=hit.position
        _stuck=true
        lifetime=_age+.55
