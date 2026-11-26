extends Node
## 海底动作只订阅已发生的事件，预警、取消和被锁定不提前播放攻击声。
@onready var level: Node2D = get_parent()
@onready var link: Node2D = level.get_node("OceanLink")
@onready var stage: Node2D = level.get_node("OceanLink/FishStage")

func _ready() -> void:
    link.get_node("Exit").capture_started.connect(_on_capture)
    link.get_node("Exit").capture_finished.connect(_on_travel)
    link.ocean_entered.connect(_on_eruption)
    stage.possession.possession_started.connect(_on_possession_started)
    stage.possession.possession_finished.connect(_on_possession_finished)
    stage.get_node("SideTentacle").strike_started.connect(func():Sfx.play(&"tentacle_slap"))
    stage.get_node("Shark").dash_started.connect(func():Sfx.play(&"shark_dash"))
    stage.get_node("BossTentacleNet").strike_started.connect(func():Sfx.play(&"jellyfish_strike"))
    stage.fish.get_node("Teleport").teleported.connect(_on_blink)
    for visitor in stage.get_node("Octopus").get_children():
        visitor.ink_released.connect(func():Sfx.play(&"octopus_ink"))

func _on_capture(_body: CharacterBody2D) -> void:
    Sfx.play(&"transition_mouth")

func _on_travel(_body: CharacterBody2D) -> void:
    Sfx.play(&"transition_travel")

func _on_eruption() -> void:
    Sfx.play(&"transition_mouth")

func _on_possession_started(host: PossessableHost) -> void:
    if host==stage.host: Sfx.play(&"soul_exit")

func _on_possession_finished(host: PossessableHost) -> void:
    if host==stage.host: Sfx.play(&"fish_enter")

func _on_blink(_from: Vector2,_to: Vector2) -> void:
    Sfx.play(&"fish_blink")
