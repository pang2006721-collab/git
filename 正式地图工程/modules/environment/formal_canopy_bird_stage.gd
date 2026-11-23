extends Node
## 鸟从关卡载入时就在树冠上方巡飞；过场只带来镜头，不生成或重置鸟。
var _spawn:=Vector2.ZERO
@onready var layout: Node2D=get_parent()
@onready var stage: Node=get_node("../..")
@onready var crown: Node=layout.get_node("CanopyTransition")
@onready var bird: CharacterBody2D=layout.get_node("Bird")
@onready var possession: PossessionController=layout.get_node("CanopyPossession")
func _ready() -> void:
    process_physics_priority=-1
    _spawn=Vector2(crown.landing_x,crown.canopy_y(crown.landing_x)-180)
    bird.position=_spawn
    bird.get_node("Patrol").center=_spawn
    possession.soul_initially_hidden=true
    possession.possession_started.connect(_started)
    possession.possession_finished.connect(_finished)
    if stage.has_node("ShoreExit"): stage.get_parent().get_parent().died.connect(_on_died)
func _physics_process(_delta: float) -> void:
    if not stage.has_node("ShoreExit"): return
    var squirrel: CharacterBody2D=layout.get_node("Squirrel")
    var bounce=crown.play.bouncer
    possession.enabled=stage.active and not stage.level.dead and crown.state==crown.State.COMPLETE and bounce.enabled and not bounce.buried and not bounce.released and stage.level.player==squirrel
    if possession.state==PossessionController.State.TRANSFERRING:
        possession.enabled=not stage.level.dead
    if possession.enabled and possession.state==PossessionController.State.ROAMING:
        possession.set_source_body(squirrel,squirrel.get_node("Visual/Sprite").global_position-squirrel.global_position)
    if bird.get_node("Host").claimed:
        bird.position.x=clampf(bird.position.x,80,1840)
func _started(_host: PossessableHost) -> void:
    crown.play.bouncer.release_host()
    stage.level.player=possession.soul
func _finished(host: PossessableHost) -> void:
    stage.level.player=host.body
    layout.get_node("SkyEagle").arm()
func _on_died() -> void:
    bird.get_node("Boost").reset()
    if possession.state==PossessionController.State.TRANSFERRING: possession.reset()
    possession.enabled=false
    possession.clear_selection()
func reset() -> void:
    possession.reset()
    possession.enabled=false
    bird.position=_spawn
    bird.get_node("Movement").reset()
    bird.get_node("Host").reset()
    bird.get_node("Patrol").center=_spawn
    bird.reset_physics_interpolation()
