extends "res://modules/visual/tentacle_warning.gd"
## Shared authored warning, compressed to the bee's existing windup duration.
@onready var bee:CharacterBody2D=get_parent()
func _ready()->void:
    super._ready()
    var ink=ShaderMaterial.new()
    ink.shader=preload("res://shaders/checkpoint_white_ink.gdshader")
    sprite.material=ink
    position=Vector2(0,-115)
    scale=Vector2.ONE*.65
func _process(_delta:float)->void:
    if bee.mode!=bee.Mode.WINDUP or not is_instance_valid(bee.encounter) or not bee.encounter.is_active():
        sample(-1.0)
        return
    sample(bee.elapsed/maxf(.01,bee.warning_seconds)*.72)
