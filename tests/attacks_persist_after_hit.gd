extends SceneTree
class TestLevel extends Node2D:
    var player: CharacterBody2D
    var hits: int = 0
    func die(): hits+=1
class TestEncounter extends Node2D:
    var level: Node2D
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var level=TestLevel.new()
    root.add_child(level)
    var player=CharacterBody2D.new()
    player.collision_layer=2
    var collision=CollisionShape2D.new()
    var shape=CircleShape2D.new()
    shape.radius=20
    collision.shape=shape
    player.add_child(collision)
    level.add_child(player)
    player.position=Vector2(300,300)
    level.player=player
    var encounter=TestEncounter.new()
    encounter.level=level
    level.add_child(encounter)
    encounter.process_mode=Node.PROCESS_MODE_ALWAYS
    var fork=load("res://scenes/enemies/enemy_fork.tscn").instantiate()
    fork.encounter=encounter
    encounter.add_child(fork)
    fork.position=Vector2(240,300)
    fork.gravity=0
    fork.velocity=Vector2(600,0)
    fork.set_physics_process(false)
    await physics_frame
    await physics_frame
    fork._physics_process(.2)
    check(level.hits==1,"Fork actually hits the player collider")
    check(fork.visible and not fork._stuck and not fork.is_queued_for_deletion() and fork.position.x>300,"Fork crosses player without hiding or sticking")
    fork.position=Vector2(240,300)
    fork._physics_process(.2)
    check(level.hits==1,"A piercing fork reports player damage only once")
    level.process_mode=Node.PROCESS_MODE_DISABLED
    var before:Vector2=fork.position
    fork.set_physics_process(true)
    await create_timer(.1).timeout
    check(fork.position.x>before.x,"Committed projectile continues while the level is frozen")
    fork._physics_process(fork.lifetime+1)
    check(fork.is_queued_for_deletion(),"Normal projectile lifetime still ends")
    print("ATTACKS_PERSIST_AFTER_HIT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
