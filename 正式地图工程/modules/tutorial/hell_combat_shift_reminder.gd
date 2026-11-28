extends Node
## Only the first two spawned enemies of an attempt receive the contextual attack cue.
@export var enemy_limit:int=2
var _seen:int=0
var _candidates:Dictionary={}
var _used:Dictionary={}
var _target:Node2D
@onready var level:Node2D=get_parent()
@onready var fork:Node2D=level.get_node("Fork")
func _ready():
    level.get_node("FlyingEnemies").enemy_spawned.connect(_on_spawn)
    fork.selection_changed.connect(_on_selection)
    fork.thrown.connect(_on_throw)
    level.died.connect(_reset_attempt)
func _on_spawn(enemy:Node2D):
    _seen+=1
    if _seen<=enemy_limit:_candidates[enemy.get_instance_id()]=true
func _on_selection(target:Node2D):
    _target=target if is_instance_valid(target) and _candidates.has(target.get_instance_id()) else null
func _on_throw():
    if is_instance_valid(_target) and fork.get("_enemy_attack_target")==_target:
        _used[_target.get_instance_id()]=true
        _target=null
func is_reminding()->bool:
    return is_instance_valid(_target) and fork.selected==_target and not _target.is_defeated() and not _used.has(_target.get_instance_id())
func _reset_attempt():
    _seen=0
    _candidates.clear()
    _used.clear()
    _target=null
