extends Node2D
## 按作者示例排版；只有垂挂细藤蔓进入抓取组，粗主藤蔓没有碰撞。
var camera: Camera2D
var _elapsed: float = 0
@onready var vines: Array[Node] = $InteractiveVines.get_children()
func _ready() -> void:
    for vine in vines:
        vine.set_physics_process(false)
        vine.set_process(false)
    $Squirrel.set_active(false)
func configure(view: Camera2D, map_transform: Transform2D) -> void:
    camera = view
    global_transform = map_transform
    _update_nearby()
func align_floor_to_bank(bank: CollisionShape2D) -> void:
    # 延伸原岸线，不用长地图常量覆盖编辑器中已调整的站立高度。
    var top: Vector2 = bank.to_global(Vector2(0,-bank.shape.size.y*.5))
    var floor_shape: CollisionShape2D = $JungleFloor/Collision
    var center: Vector2 = floor_shape.global_position
    center.y = top.y+floor_shape.shape.size.y*.5*floor_shape.global_scale.y
    floor_shape.global_position = center
    $BottomFunnel.rebuild()
func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed<.15: return
    _elapsed = 0
    _update_nearby()
func _update_nearby() -> void:
    if not is_instance_valid(camera): return
    if $Squirrel/Host.claimed: $Squirrel.set_active(true)
    var half: float = camera.get_viewport_rect().size.y*.5/camera.zoom.y
    var center: float = camera.global_position.y+camera.offset.y
    for vine in vines:
        var top: float = vine.global_position.y
        var bottom: float = top+vine.length
        var player_riding: bool = vine.rider!=null and not vine.rider.is_in_group("idle_vine_squirrels")
        var near: bool = player_riding or (top<center+half+900 and bottom>center-half-900)
        vine.set_physics_process(near)
        vine.set_process(near)
        if vine.rider!=null and vine.rider.is_in_group("idle_vine_squirrels"):
            vine.rider.set_active(near)
func reset() -> void:
    $SkyCloudExit.reset()
    $SkyEagle.reset()
    $CanopyTransition.reset()
    $CanopyBirdStage.reset()
    $BeeEncounter.reset()
    for hive in $Beehives.get_children(): hive.reset()
    for vine in vines: vine.reset()
    $Squirrel.reset()
    _update_nearby()
