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
    var climber=body.get_node("VineClimber")
    var spin=body.get_node("AirSpin")
    climber.detach(false)
    check(spin.is_invulnerable(),"A real vine release grants invulnerability while the air spin is active")
    game.camera.global_position=body.global_position
    var momentum: Vector2=body.velocity
    for nest_name in ["Beehive07","Beehive06"]:
        encounter._spawn(layout.get_node("Beehives/"+nest_name))
        var bee=encounter.get_child(encounter.get_child_count()-1)
        bee.set_physics_process(false)
        bee.global_position=encounter.target_position()+Vector2(40,0)
        bee._set_mode(bee.Mode.FLYING)
        bee._physics_process(.01)
        check(bee.mode==bee.Mode.DEFLECTED and bee.is_defeated(),"Touching either bee type during spin knocks it away, even outside an attack")
        check(bee.visual.scale.x>bee.art_scale*1.5,"Deflection starts with a pronounced duang squash")
        for tick in 8: bee._physics_process(.01)
        var before: Vector2=bee.global_position
        bee._physics_process(.01)
        check(bee.global_position.distance_to(before)>5 and bee.velocity.x>500,"Deflected bee physically flies away")
        for tick in 185:
            if not bee.is_queued_for_deletion(): bee._physics_process(.01)
        check(bee.is_queued_for_deletion(),"Deflected bee stops attacking and is cleaned up")
    check(not game.dead and body.velocity==momentum,"Spin contact never defeats the squirrel or alters its launch arc")
    encounter.fire_stinger(encounter.target_position()+Vector2(-60,0),encounter.target_position())
    var needle=encounter.get_child(encounter.get_child_count()-1)
    needle.set_physics_process(false)
    needle.velocity=Vector2(1200,0)
    needle._physics_process(.02)
    check(not game.dead and needle.is_queued_for_deletion(),"Spinning squirrel blocks and clears stingers")
    encounter.defeat_player()
    check(not game.dead,"Central bee damage gate also respects spin invulnerability")
    climber.adopt_vine(body.vine)
    check(not spin.is_invulnerable(),"Catching a vine ends protection immediately, before the next visual frame")
    encounter._spawn(layout.get_node("Beehives/Beehive07"))
    var attacker=encounter.get_child(encounter.get_child_count()-1)
    attacker.set_physics_process(false)
    attacker.global_position=encounter.target_position()+Vector2(-40,0)
    attacker._set_mode(attacker.Mode.DARTING)
    attacker._dart_velocity=Vector2(1450,0)
    attacker._physics_process(.01)
    check(game.dead and body.get_node("Defeat").corpse.visible,"After recatching, a hit loses the run and shows the stunned pose")
    print("SQUIRREL_SPIN_DEFLECT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
