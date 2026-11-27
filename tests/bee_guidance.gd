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
    body.global_position=Vector2(960,28000)
    game.camera.global_position=body.global_position
    var encounter=layout.get_node("BeeEncounter")
    encounter._spawn(layout.get_node("Beehives/Beehive07"))
    var bee=encounter.get_child(0)
    bee.set_physics_process(false)
    bee.global_position=Vector2(600,27750)
    bee._set_mode(bee.Mode.DARTING)
    bee._dart_velocity=Vector2(950,0)
    bee._physics_process(.01)
    check(bee._dart_velocity.angle()>0 and bee._dart_velocity.angle()<=.0601,"Dash turns toward a moving target with a capped angular speed")
    var direction: Vector2=bee._dart_velocity
    bee.elapsed=.85
    bee._physics_process(.01)
    check(bee._dart_velocity==direction,"Dash tracking expires before the end of the strike")
    bee.elapsed=0
    body.global_position=Vector2(400,28000)
    bee._physics_process(.01)
    check(bee._dart_velocity==direction,"Dash cannot turn back after passing the player")
    body.global_position=Vector2(960,28000)
    bee._set_mode(bee.Mode.WINDUP)
    bee._aim=Vector2(800,27950)
    bee._physics_process(.1)
    check(bee._aim.x>800,"Warning follows the player before its final lock")
    var locked: Vector2=bee._aim
    bee.elapsed=.48
    body.global_position.x+=150
    bee._physics_process(.01)
    check(bee._aim==locked,"Final warning remains locked to allow a last-second dodge")
    body.global_position=Vector2(960,28000)
    encounter.fire_stinger(Vector2(560,27750),Vector2(1200,27750))
    var needle=encounter.get_child(encounter.get_child_count()-1)
    needle.set_physics_process(false)
    needle.gravity=0
    needle.velocity=Vector2(680,0)
    needle._physics_process(.1)
    check(needle.velocity.angle()>0 and needle.velocity.angle()<=.5001,"Stinger gently tracks the player with a capped turn")
    var shot: Vector2=needle.velocity
    needle._age=1.9
    needle._physics_process(.01)
    check(needle.velocity==shot,"Stinger continues straight after its short tracking window")
    needle._age=0
    body.global_position=Vector2(400,28000)
    needle._physics_process(.01)
    check(needle.velocity==shot,"Stinger never makes a U-turn")
    print("BEE_GUIDANCE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
