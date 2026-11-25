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
    var counts: Array[int]=[]
    hail.row_spawned.connect(func(index,_gap):
        var row_data: Dictionary=hail.last_row_layout.duplicate()
        row_data.index=index
        rows.append(row_data)
        counts.append(row_data.count))
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
    check(hail.stones.size()==6 and rows.size()==1,"First row contains exactly six hailstones")
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
    for lane in 7:
        if lane not in occupied: missing.append(lane)
    check(missing.size()==1,"Exactly one empty slot forms the dodge gap")
    check(has_positive and has_negative,"Individual hailstones rotate in different directions")
    var first=hail.stones[0].art
    var old_position: Vector2=first.global_position
    var old_angle: float=first.rotation
    var step: float=(hail.horizontal_bounds.y-hail.horizontal_bounds.x)/7.0
    var left: float=layout.to_global(Vector2(hail.horizontal_bounds.x,0)).x
    bird.global_position=Vector2(left+(missing[0]+.5)*step,height+200)
    hail._previous_target=bird.global_position
    for i in 16: hail._physics_process(.05)
    check(not game.dead,"Bird passes through the single-slot gap safely")
    check(first.global_position.y>old_position.y and absf(first.rotation-old_angle)>.1,"Falling hail also self-rotates")
    bird.global_position.y=game.camera.global_position.y+2000
    hail._physics_process(hail.row_interval-.8+.02)
    check(rows.size()==2 and rows[1].count==7,"Following row alternates to seven hailstones")
    check(rows[0].safe_right<rows[1].safe_left or rows[1].safe_right<rows[0].safe_left,"Adjacent openings never leave a shared vertical shortcut")
    for row_data in rows:
        check((row_data.radius+26.0)*2>=row_data.pitch,"Ordinary gaps are too narrow for the bird")
    var motor=bird.get_node("Movement")
    Input.action_press(&"bird_boost")
    for i in 10: bird.get_node("Boost")._physics_process(.02)
    var boosted_speed: float=motor.move_speed
    var boosted_acceleration: float=motor.acceleration
    var shift_distance: float=absf(rows[1].center-rows[0].center)
    check(shift_distance/motor.move_speed+motor.move_speed/(2*motor.acceleration)<hail.row_interval,"Ordinary flight reaches the next staggered opening in time")
    Input.action_release(&"bird_boost")
    bird.get_node("Boost").reset()
    for i in int(ceil(hail.row_interval/.1))+2: hail._physics_process(.1)
    check(rows.size()==hail.rows_per_wave and not hail._emitting,"Each eagle departure produces a bounded burst")
    for expected_rows in [4,5,5]:
        rows.clear()
        hail._on_departed()
        for i in 120: hail._physics_process(.1)
        check(rows.size()==expected_rows,"Successive waves increase by one row, capped at five")
        for index in range(1,rows.size()):
            var before: Dictionary=rows[index-1]
            var after: Dictionary=rows[index]
            check(before.safe_right<after.safe_left or after.safe_right<before.safe_left,"Every later pair also blocks a straight vertical shortcut")
            var distance: float=absf(after.center-before.center)
            check(distance/boosted_speed+boosted_speed/(2*boosted_acceleration)<hail.row_interval,"Every staggered transition remains reachable at ordinary flight speed")
        check(not hail.is_wave_active(),"Completed wave clears all remaining falling hail")
    for i in counts.size():
        check(counts[i]==6+i%2,"Six/seven alternation continues across successive waves")
    sky.state=sky.State.HIDDEN
    sky._phase_elapsed=0.0
    hail._on_departed()
    sky._process(5.1)
    check(sky.state==sky.State.HIDDEN and sky._phase_elapsed==0.0,"Hail does not consume the quiet interval")
    for i in 120: hail._physics_process(.1)
    sky._process(sky.hidden_seconds-.1)
    check(sky.state==sky.State.HIDDEN,"Eagle waits the full configured rest after the final hailstone clears")
    sky._process(.11)
    check(sky.state==sky.State.REVEALING,"Eagle rises again after the shorter configured rest")
    sky._begin(true)
    var row_count: int=rows.size()
    hail._physics_process(2.0)
    check(rows.size()==row_count,"Returning eagle stops new row emission")
    sky.reset()
    check(hail.stones.is_empty() and not hail._emitting and hail._wave_count==0,"Replay clears hail, pending rows and difficulty progression")
    sky.state=sky.State.HIDDEN
    hail._on_departed()
    hail._physics_process(.31)
    var stone=hail.stones[0]
    bird.global_position=stone.art.global_position+Vector2(0,stone.speed*.025)
    hail._previous_target=bird.global_position
    hail._physics_process(.05)
    check(game.dead and game.death_reason==&"hail","A direct hail hit defeats the bird")
    check(not hail.stones.is_empty() and not hail._emitting,"Death preserves falling hail and stops subsequent rows")
    var falling: Sprite2D = hail.stones[0].art
    var before: Vector2 = falling.global_position
    hail._physics_process(.1)
    check(falling.global_position.y>before.y,"Hail continues falling after a hit")
    print("SKY_HAIL_ROWS_FAILURES=",failures.size())
    game.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
