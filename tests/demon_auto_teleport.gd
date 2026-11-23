extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("CameraAttention").enabled=false
    game.demon.get_node("Host").take_control()
    game.player=game.demon
    game.demon.collision_layer=0
    game.demon.get_node("Movement").enabled=false
    var rig=game.get_node("Fork")
    rig.set_physics_process(false)
    var target=game.get_node("Fork/Targets/Target02")
    game.demon.global_position=target.global_position+Vector2(-200,300)
    rig.selected=target
    var arrivals: Array[Vector2]=[]
    rig.exchanged.connect(func(body): arrivals.append(body.global_position))
    var key:=InputEventKey.new()
    key.keycode=KEY_SHIFT
    key.physical_keycode=KEY_SHIFT
    key.location=KEY_LOCATION_LEFT
    key.pressed=true
    rig._unhandled_input(key)
    check(rig.flying,"One Shift throws the fork")
    await create_timer(.7).timeout
    check(arrivals.size()==1,"Fork hit automatically teleports without another Shift")
    check(rig.held and not rig.flying and rig.lodged==null,"Automatic exchange returns fork and releases the target")
    await create_timer(1.1).timeout
    check(not rig.swapping and not rig.launching and game.demon.get_node("Input").enabled,"Bounce finishes and returns control")
    rig.reset()
    game.demon.get_node("Movement").enabled=false
    game.demon.global_position=target.global_position+Vector2(-200,300)
    rig.selected=target
    rig._unhandled_input(key)
    await create_timer(.08).timeout
    rig.reset()
    await create_timer(.5).timeout
    check(arrivals.size()==1 and rig.held and not rig.swapping,"Reset during throw cancels the pending automatic teleport")
    rig.lodged=target
    game.dead=true
    rig._auto_exchange(target)
    check(not rig.swapping,"Death prevents an automatic exchange")
    rig.reset()
    print("DEMON_AUTO_TELEPORT_FAILURES=",failures.size())
    game.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
