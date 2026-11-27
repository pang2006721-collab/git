extends SceneTree
var game
func _initialize(): run.call_deferred()
func wait_frames(count:int):
    for i in count: await process_frame
func run():
    root.size=Vector2i(1280,720)
    game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    game.set_meta("skip_tutorial",true)
    game.get_node("FlyingEnemies").enabled=false
    root.add_child(game)
    current_scene=game
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("CameraAttention").enabled=false
    game.get_node("RisingLava").set_physics_process(false)
    game.soul.show()
    game.soul.global_position=game.demon.global_position+Vector2(-165,0)
    game.soul.get_node("Movement").enabled=false
    game.soul.get_node("Input").enabled=false
    game.camera.enabled=true
    game.camera.set_follow_target(game.soul)
    game.camera.global_position=game.demon.global_position+Vector2(0,-180)
    await wait_frames(60)
    game.possession.enabled=true
    assert(game.possession.request_possession())
    await wait_frames(100)
    var rig=game.get_node("Fork")
    rig.reset()
    var target=game.get_node("Fork/Targets/Target01")
    game.demon.get_node("Movement").enabled=false
    game.demon.get_node("Input").enabled=false
    game.demon.global_position=target.global_position+Vector2(-210,330)
    game.camera.set_follow_target(game.demon)
    game.camera.global_position=target.global_position+Vector2(0,100)
    await wait_frames(60)
    rig.selected=target
    rig._throw()
    await wait_frames(115)
    print("TUTORIAL_RECORDING_COMPLETE")
    quit()
