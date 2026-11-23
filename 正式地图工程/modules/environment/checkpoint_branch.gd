extends StaticBody2D
## 只在重生时出现的小树枝；踩稳后计时，预抖，再分片掉落。
signal broken_apart
@export var stand_seconds: float = 2.4
@export var warning_seconds: float = 0.6
var armed: bool = false
var broken: bool = false
var loaded: bool = false
var elapsed: float = 0.0
var _body: CharacterBody2D
var _pieces: Array[Dictionary] = []

func prepare(body: CharacterBody2D) -> void:
    _body=body
    armed=false
    broken=false
    loaded=false
    elapsed=0
    for piece in _pieces: piece.node.queue_free()
    _pieces.clear()
    $Art.show()
    $Art.position=Vector2.ZERO
    $Art.rotation=0
    $Collision.set_deferred("disabled",false)
    show()

func arm() -> void:
    armed=true

func _physics_process(delta: float) -> void:
    if not armed or broken or not is_instance_valid(_body): return
    if not loaded and _body.is_on_floor():
        for i in _body.get_slide_collision_count():
            if _body.get_slide_collision(i).get_collider()==self: loaded=true
    if not loaded: return
    elapsed+=delta
    if elapsed>=stand_seconds: break_apart()
    elif elapsed>stand_seconds-warning_seconds:
        var u: float=(elapsed-stand_seconds+warning_seconds)/warning_seconds
        $Art.position=Vector2(sin(elapsed*52)*2.5*u,absf(sin(elapsed*34))*2*u)
        $Art.rotation=sin(elapsed*45)*.018*u

func break_apart() -> void:
    if broken: return
    broken=true
    $Collision.set_deferred("disabled",true)
    $Art.hide()
    var texture: AtlasTexture=$Art.texture
    var width: float=texture.region.size.x/4.0
    for i in 4:
        var crop:=AtlasTexture.new()
        crop.atlas=texture.atlas
        crop.region=Rect2(texture.region.position+Vector2(width*i,0),Vector2(width,texture.region.size.y))
        crop.filter_clip=true
        var shard:=Sprite2D.new()
        shard.texture=crop
        shard.scale=$Art.scale
        shard.position=Vector2((i-1.5)*width*$Art.scale.x,0)
        add_child(shard)
        _pieces.append({"node":shard,"velocity":Vector2((i-1.5)*85,-90-25*(i%2)),"spin":(i-1.5)*2.2,"age":0.0})
    broken_apart.emit()

func _process(delta: float) -> void:
    for piece in _pieces.duplicate():
        piece.age+=delta
        piece.velocity.y+=900*delta
        piece.node.position+=piece.velocity*delta
        piece.node.rotation+=piece.spin*delta
        piece.node.modulate.a=1-smoothstep(1.0,1.6,piece.age)
        if piece.age>=1.6:
            piece.node.queue_free()
            _pieces.erase(piece)
