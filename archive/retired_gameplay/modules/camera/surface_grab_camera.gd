extends Node
## 只叠加轻微拉近和向下构图，仍由正式跟随相机及开场相机输出显示。
var camera: FollowCamera
var active: bool = false
var _owned: bool = false
var _weight: float = 0
var _clock: float = 0
var _kick: float = 0
var _zoom := Vector2.ONE
var _offset := Vector2.ZERO
func _ready() -> void:
    process_priority = 5
func begin(view: FollowCamera) -> void:
    if _owned: reset()
    camera = view
    _zoom = camera.zoom
    _offset = camera.cinematic_offset
    _weight = 0
    _clock = 0
    _kick = 0
    active = true
    _owned = true
func pulse() -> void:
    _kick = 1
func release(immediate: bool = false) -> void:
    active = false
    if immediate: reset()
func _process(delta: float) -> void:
    if not _owned or not is_instance_valid(camera): return
    _clock += delta
    _kick = move_toward(_kick,0,delta*6)
    _weight = move_toward(_weight,1.0 if active else 0.0,delta/(.32 if active else .42))
    var eased := smoothstep(0,1,_weight)
    camera.zoom = _zoom.lerp(_zoom*1.055,eased)
    var tug := sin(_clock*TAU/1.15)*4-_kick*6
    camera.cinematic_offset = _offset+Vector2(sin(_clock*2.6)*1.5,42+tug)*eased
    if not active and _weight<=0: reset()
func reset() -> void:
    if _owned and is_instance_valid(camera):
        camera.zoom = _zoom
        camera.cinematic_offset = _offset
    _owned = false
    active = false
    _weight = 0
func _exit_tree() -> void:
    reset()
