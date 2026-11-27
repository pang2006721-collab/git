extends SceneTree
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout=stage.get_node("JungleLayout")
    var body=layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    game.player=body
    body.set_physics_process(false)
    body.get_node("Movement").set_physics_process(false)
    body.get_node("VineClimber").set_physics_process(false)
    game.camera.set_process(false)
    var encounter=layout.get_node("BeeEncounter")
    encounter._spawn(layout.get_node("Beehives/Beehive07"))
    var bee=encounter.get_child(0)
    bee.set_physics_process(false)
    game.camera.global_position=body.global_position
    bee._set_mode(bee.Mode.DARTING)
    bee.global_position=encounter.target_position()+Vector2(-500,0)
    bee._dart_velocity=Vector2(950,0)
    check(body.get_node("VineClimber").vine!=null,"Fixture squirrel is still hanging from a vine")
    for tick in 90:
        if not game.dead: bee._physics_process(1.0/120.0)
    check(game.dead and game.death_reason==&"bee","Bee reaches and defeats a hanging squirrel from 500 pixels away")
    check(body.get_node("Defeat").corpse.visible and not body.get_node("Visual/Sprite").visible,"Melee hit displays stunned artwork")
    check(not bee.is_queued_for_deletion(),"Defeat leaves the attacking bee alive")
    layout.reset()
    check(not body.get_node("Defeat").corpse.visible,"Replay removes the stunned pose")
    print("SQUIRREL_BEE_DEFEAT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
