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
    bee.global_position=encounter.target_position()+Vector2(300,-100)
    bee._set_mode(bee.Mode.FLYING)
    game.camera.global_position=body.global_position
    encounter.fire_stinger(encounter.target_position()+Vector2(-60,0),encounter.target_position())
    var needle=encounter.get_child(encounter.get_child_count()-1)
    needle.set_physics_process(false)
    needle.velocity=Vector2(1200,0)
    needle._physics_process(.02)
    check(game.dead and not needle.is_queued_for_deletion() and bee.visible,"A lethal sting leaves bees and the piercing projectile in the scene")
    var defeat=body.get_node("Defeat")
    var corpse_start: Vector2=defeat.corpse.global_position
    defeat._process(.25)
    check(defeat.corpse.global_position.y>corpse_start.y+50,"Stunned squirrel immediately falls downward without an upward launch")
    var needle_start: Vector2=needle.global_position
    needle._physics_process(.1)
    check(needle.global_position.x>needle_start.x+80,"Lethal stinger keeps moving forward after piercing")
    var bee_start: Vector2=bee.global_position
    bee._physics_process(.1)
    check(bee.global_position.distance_to(bee_start)>0 and not bee.is_queued_for_deletion(),"Bees keep flying after player defeat")
    await process_frame
    await process_frame
    check(encounter.can_process() and defeat.can_process(),"Bees and falling corpse keep processing while the rest of the level is frozen")
    for tick in 180:
        if defeat.falling: defeat._process(.01)
    check(not defeat.falling and not defeat.corpse.visible,"Corpse only disappears below the viewport")
    layout.reset()
    check(bee.is_queued_for_deletion() and needle.is_queued_for_deletion(),"Retry still clears old bees and projectiles")
    print("BEE_STING_FALL_THROUGH_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
