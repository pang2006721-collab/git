extends SceneTree
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("CameraAttention").enabled=false
    game.died.disconnect(game.get_node("DeathFlow")._on_death)
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet","SurfaceGrab"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout=stage.get_node("JungleLayout")
    var bird=layout.get_node("Bird")
    bird.get_node("Host").take_control()
    bird.get_node("Movement").set_physics_process(false)
    bird.get_node("Patrol").set_physics_process(false)
    game.player=bird
    var sky=layout.get_node("SkyEagle")
    sky.set_process(false)
    var hail=sky.get_node("Hail")
    hail.set_physics_process(false)
    hail._rng.seed=43
    game.camera.zoom=Vector2.ONE
    game.camera.global_position=bird.global_position
    game.camera.set_process(false)
    var rows: Array[Dictionary]=[]
    hail.row_spawned.connect(func(index,gap): rows.append({"index":index,"gap":gap}))
    sky.state=sky.State.ACTIVE
    hail._physics_process(.5)
    check(hail.stones.is_empty(),"No hail falls while the eagle circles")
    sky.circling_seconds=.01
    sky._process(.02)
    hail._physics_process(.5)
    check(sky.state==sky.State.SCREECHING and hail.stones.is_empty(),"Calling alone does not start the hail")
    sky._process(sky.screech_seconds+.01)
    hail._physics_process(.5)
    check(hail.stones.is_empty(),"Hail waits until the eagle has completely departed")
    sky._process(sky.departure_seconds+.01)
    hail._physics_process(hail.first_row_delay+.01)
    check(hail.stones.size()==6 and rows.size()==1,"Each row contains exactly six hailstones")
    var occupied: Array[int]=[]
    var height: float=hail.stones[0].art.global_position.y
    var has_positive:=false
    var has_negative:=false
    for stone in hail.stones:
        occupied.append(stone.lane)
        check(absf(stone.art.global_position.y-height)<.01,"Hailstones form a horizontal row")
        has_positive=has_positive or stone.spin>0
        has_negative=has_negative or stone.spin<0
    var missing: Array[int]=[]
    for lane in 8:
        if lane not in occupied: missing.append(lane)
    check(missing.size()==2 and missing[1]==missing[0]+1,"Two adjacent empty slots form the dodge gap")
    check(has_positive and has_negative,"Individual hailstones rotate in different directions")
    var first=hail.stones[0].art
    var old_position: Vector2=first.global_position
    var old_angle: float=first.rotation
    var step: float=(hail.horizontal_bounds.y-hail.horizontal_bounds.x)/8.0
    var left: float=layout.to_global(Vector2(hail.horizontal_bounds.x,0)).x
    bird.global_position=Vector2(left+(missing[0]+1)*step,height+200)
    hail._previous_target=bird.global_position
    for i in 16: hail._physics_process(.05)
    check(not game.dead,"Bird passes through the two-slot gap safely")
    check(first.global_position.y>old_position.y and absf(first.rotation-old_angle)>.1,"Falling hail also self-rotates")
    bird.global_position.y=game.camera.global_position.y+2000
    hail._physics_process(.4)
    check(rows.size()==2 and abs(rows[1].gap-rows[0].gap)<=1,"Following row shifts its gap by at most one slot")
    var motor=bird.get_node("Movement")
    check(step/motor.move_speed+motor.move_speed/(2* motor.acceleration)<hail.row_interval,"Actual bird controller can move one lane between rows")
    for i in 13: hail._physics_process(.1)
    check(rows.size()==hail.rows_per_wave and not hail._emitting,"Each eagle departure produces a bounded burst")
    sky._begin(true)
    var row_count: int=rows.size()
    hail._physics_process(2.0)
    check(rows.size()==row_count,"Returning eagle stops new row emission")
    sky.reset()
    check(hail.stones.is_empty() and not hail._emitting,"Replay clears all hail and pending rows")
    sky.state=sky.State.HIDDEN
    hail._on_departed()
    hail._physics_process(.31)
    var stone=hail.stones[0]
    bird.global_position=stone.art.global_position+Vector2(0,stone.speed*.025)
    hail._previous_target=bird.global_position
    hail._physics_process(.05)
    check(game.dead and game.death_reason==&"hail","A direct hail hit defeats the bird")
    check(hail.stones.is_empty() and not hail._emitting,"Death clears the active hail burst")
    print("SKY_HAIL_ROWS_FAILURES=",failures.size())
    game.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
