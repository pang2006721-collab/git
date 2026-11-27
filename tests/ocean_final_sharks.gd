extends SceneTree
var failures:Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok:bool,message:String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)
func until(predicate:Callable,seconds:float=5.0) -> bool:
    var end:=Time.get_ticks_msec()+int(seconds*1000)
    while Time.get_ticks_msec()<end:
        if predicate.call():return true
        await process_frame
    return false
func shot(label:String) -> void:
    if DisplayServer.get_name()=="headless":return
    await process_frame
    await process_frame
    RenderingServer.force_draw(false)
    root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/final-sharks-"+label+".png")
func run() -> void:
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    await process_frame
    game.get_node("SegmentStart").start_segment(3)
    var stage=game.get_node("OceanLink/FishStage")
    stage.get_node("JellyfishBoss").reset()
    stage.get_node("JellyfishReveal").reset()
    var fish=stage.fish
    var trio=stage.get_node("FinalSharks")
    var shore=stage.get_node("ShoreExit")
    fish.get_node("Movement").enabled=false
    fish.position=Vector2(960,shore.surface_y+2200)
    fish.velocity=Vector2(0,-100)
    game.camera.set_process(false)
    game.camera.adopt_view(fish.global_position,Vector2.ONE*1.1)
    await create_timer(.2).timeout
    check(not trio.triggered,"Wave waits until surface approach")
    fish.position.y=shore.surface_y+1000
    game.camera.adopt_view(fish.global_position,Vector2.ONE*1.1)
    check(await until(func():return trio.triggered),"Ascending triggers final wave")
    check(trio.sharks.size()==3,"Exactly three skinny sharks")
    check(trio.sharks.all(func(s):return s.state==s.State.LOCKING),"All sharks lock simultaneously")
    check(not stage.has_node("SurfaceGrab"),"Retired four-arm grab is absent")
    check(not stage.get_node("Shark").enabled,"Ordinary shark stays suppressed")
    await create_timer(.5).timeout
    await shot("lock")
    check(absf(trio.sharks[0].global_position.y-trio.sharks[1].global_position.y)>140,"Entry heights are separated")
    check(await until(func():return trio.sharks.all(func(s):return s.state==s.State.DASHING)),"All three dash simultaneously")
    var directions:Array=[]
    for shark in trio.sharks:directions.append(shark.dash_direction)
    fish.global_position+=Vector2(0,-300)
    await create_timer(.06).timeout
    for i in 3:check(trio.sharks[i].dash_direction.is_equal_approx(directions[i]),"Dash direction stays committed")
    await shot("dash")
    check(await until(func():return trio.finished),"Dodged sharks leave screen and finish")
    await create_timer(1.2).timeout
    check(trio.sharks.all(func(s):return s.state==s.State.WAITING),"Final wave does not repeat")
    trio.reset()
    fish.position=Vector2(960,shore.surface_y+1000)
    fish.velocity=Vector2(0,-100)
    check(await until(func():return trio.triggered),"Reset rearms wave")
    trio.player_hit.emit(Vector2.LEFT)
    check(game.dead and game.death_reason==&"shark","Final sharks can hit in shallow water")
    check(trio.sharks.all(func(s):return s.visible and not s.enabled),"Death preserves all final sharks and stops further damage")
    check(await until(func():return trio.sharks.all(func(s):return s.state==s.State.WAITING)),"Final sharks naturally finish their committed attacks after death")
    print("OCEAN_FINAL_SHARKS_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
