extends Sprite2D
## 未激活时用同一套手绘感叹号提醒；只弹视觉，不影响鱼或镜头。
@export var repeat_seconds: float = 2.8
@export var hop_height: float = 7.0
@export var show_distance: float = 1100.0
var _clock: float = 0.0
var _rest_position: Vector2
var _rest_scale: Vector2
@onready var checkpoint: Node2D = get_parent()
func _ready() -> void:
    _rest_position = position
    _rest_scale = scale
    checkpoint.activated.connect(hide)
    hide()
func _process(delta: float) -> void:
    var stage: Node2D = checkpoint.stage
    visible = not checkpoint.active and stage.active and stage.host.claimed and stage.level.player==stage.fish and not stage.level.dead and stage.fish.global_position.distance_to(checkpoint.global_position)<show_distance
    if not visible:
        _clock=0.0
        return
    _clock=fmod(_clock+delta,repeat_seconds)
    var beat: float = -1.0
    if _clock<.26: beat=_clock/.26
    elif _clock>=.38 and _clock<.64: beat=(_clock-.38)/.26
    var hop: float = sin(beat*PI) if beat>=0 else 0.0
    position=_rest_position+Vector2(0,-hop*hop_height)
    scale=_rest_scale*Vector2(1-.09*hop,1+.12*hop)
