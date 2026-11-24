extends Node2D
## 固定高度的鲨鱼队列：玩家抵达前从对应画面边缘起游，死亡不重置。
signal player_hit(direction: Vector2)
@export var swim_speed: float = 450.0
@export var approach_distance: float = 1400.0
@export var following_gap: float = 340.0
@export_enum("从左到右:1","从右到左:-1") var direction: int = 1
@export var bob_amplitude: float = 14.0
@export var bob_period: float = 3.6
var running: bool = false
var damage_enabled: bool = false
var started: bool = false
var target: CharacterBody2D
var camera: Camera2D
var distance: float = 0.0
var left_edge: float = -260.0
var right_edge: float = 2180.0
var _clock: float = 0.0
var _anchors: Array
var _contacts: Dictionary = {}
@onready var sharks: Array[Node] = get_children()
@onready var lead: Area2D = $Lead
@onready var follower: Area2D = $Follower

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _anchors = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/ocean/pink_shark/anchors.json"))
    for shark in sharks:
        var sprite: AnimatedSprite2D = shark.get_node("Art")
        sprite.frame_changed.connect(_register_frame.bind(sprite))
    reset()

func configure(player: CharacterBody2D, view: Camera2D) -> void:
    target = player
    camera = view

func _physics_process(delta: float) -> void:
    if not running: return
    if not started:
        if not damage_enabled or not is_instance_valid(camera): return
        var view := _view_rect()
        if not is_instance_valid(target): return
        var ahead := target.global_position.y-global_position.y
        if ahead<0 or ahead>approach_distance: return
        # 入场边界取此刻镜头，第一只从完全出画的位置开始，不跳到画面中间。
        left_edge = view.position.x-global_position.x-140
        right_edge = view.end.x-global_position.x+140
        started = true
        distance = 0.0
        _clock = 0.0
        _place_pair()
        for shark in sharks: shark.show()
        return
    distance += swim_speed*delta
    _clock += delta
    _place_pair()
    if not damage_enabled or not is_instance_valid(target): return
    var teleport := target.get_node_or_null("Teleport")
    if teleport != null and teleport.is_invulnerable(): return
    for shark in sharks:
        var id: int = shark.get_instance_id()
        if shark.overlaps_body(target):
            if not _contacts.has(id):
                _contacts[id] = true
                player_hit.emit(Vector2(float(direction),0))
        else:
            _contacts.erase(id)

func _view_rect() -> Rect2:
    var size := camera.get_viewport_rect().size/camera.zoom
    return Rect2(camera.global_position+camera.offset-size*.5,size)

func _place_pair() -> void:
    var loop_length := right_edge-left_edge+following_gap*(sharks.size()-1)
    for i in sharks.size():
        var travel := fposmod(distance-i*following_gap,loop_length)
        var x := left_edge+travel if direction>0 else right_edge-travel
        sharks[i].position = Vector2(x,sin(TAU*(_clock/bob_period+i*.17))*bob_amplitude)
        sharks[i].scale.x = absf(sharks[i].scale.x)*direction

func _register_frame(sprite: AnimatedSprite2D) -> void:
    var pivot: Array = _anchors[sprite.frame]
    sprite.offset = Vector2(256,256)-Vector2(pivot[0],pivot[1])

func reset() -> void:
    _contacts.clear()
    running = false
    damage_enabled = false
    started = false
    distance = 0.0
    _clock = 0.0
    _place_pair()
    for i in sharks.size():
        sharks[i].hide()
        var sprite: AnimatedSprite2D = sharks[i].get_node("Art")
        sprite.play(&"mouth")
        sprite.frame = (i*2)%6
        _register_frame(sprite)
