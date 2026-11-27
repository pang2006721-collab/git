extends Node2D
## 保持原来的世界姿势，缓慢沉回画面下方，完全离开后才释放。
var elapsed: float = 0
var duration: float = 1.2
var distance: float = 700
var _camera: Camera2D
var _arms: Array[Node2D] = []
var _rotations: Array[float] = []
func configure(arms: Array[Node2D], camera: Camera2D) -> void:
    _camera = camera
    var highest := INF
    for arm in arms:
        arm.reparent(self,true)
        arm.body.collision_layer = 0
        arm.dangerous = false
        arm.get_node("Warning").hide()
        _arms.append(arm)
        _rotations.append(arm.rotation)
        for point in arm.centerline:
            highest = minf(highest,arm.to_global(point).y-arm.thickness*.5)
    var bottom := camera.global_position.y+camera.offset.y+camera.get_viewport_rect().size.y*.5/camera.zoom.y
    distance = maxf(500,bottom+180-highest)
func _physics_process(delta: float) -> void:
    elapsed += delta
    var u := clampf(elapsed/duration,0,1)
    position.y = distance*smoothstep(0,1,u)+maxf(0,elapsed-duration)*800
    for i in _arms.size():
        _arms[i].rotation = _rotations[i]+sin(u*PI)*sin(elapsed*4+i)*.025
    if u>=1:
        if not is_instance_valid(_camera):
            queue_free()
            return
        var highest := INF
        for arm in _arms:
            for point in arm.centerline:
                highest = minf(highest,arm.to_global(point).y-arm.thickness*.5)
        var bottom := _camera.global_position.y+_camera.offset.y+_camera.get_viewport_rect().size.y*.5/_camera.zoom.y
        if highest>bottom+60: queue_free()
