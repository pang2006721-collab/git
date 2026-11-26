extends SceneTree
var failures:=0
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures+=1
        push_error(message)
func run():
    root.size=Vector2i(1280,720)
    root.content_scale_size=Vector2i(1920,1080)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("RunRetrospective").recording_enabled=false
    var trail=game.get_node("JungleOranges")
    var ledger=game.get_node("HellOranges")
    var body=trail.body
    body.get_node("Host").take_control()
    body.get_node("VineClimber").detach(false)
    game.player=body
    game.process_mode=Node.PROCESS_MODE_DISABLED
    game.get_node("TextureStreamer").process_mode=Node.PROCESS_MODE_ALWAYS
    game.get_node("CameraOutput").process_mode=Node.PROCESS_MODE_ALWAYS
    check(trail.get_child_count()==24,"Exactly 24 jungle oranges")
    var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/jungle/formal/orange_arcs.json"))
    check(data.groups.size()==6,"Upper six vine transfers retain short trails")
    check(trail.get_children().all(func(o):return o.position.y<28500),"Bottom two orange groups are removed")
    for a in trail.get_children():
        for b in trail.get_children():
            if a==b:continue
            check(a.position.distance_to(b.position)>=90,"Orange spacing stays clear")
    if DisplayServer.get_name()!="headless":
        body.global_position=game.to_global(Vector2(900,28050))
        body.show()
        game.camera.set_follow_target(body,true)
        game.camera.make_current()
        await create_timer(2).timeout
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/jungle-orange-arcs.png")
    for group in data.groups:
        var pos:=Vector2(group.start[0],group.start[1])
        var velocity:=Vector2(group.velocity[0],group.velocity[1])
        var jumped:=false
        trail._previous=Vector2.INF
        for frame in roundi(group.duration*120):
            if group.jump_time>=0 and frame/120.0>=group.jump_time and not jumped:
                velocity.y=minf(velocity.y,-1210*.8)
                jumped=true
            velocity.y=minf(velocity.y+2200*.8*.8/120.0,1600*.8)
            pos+=velocity/120.0
            body.global_position=game.to_global(pos)
            trail._physics_process(1.0/120)
    check(ledger.collected_count==24,"Measured reachable flight paths collect every orange")
    check(trail.get_children().all(func(o):return o.collected and o._collector==body),"All pickups absorb into squirrel")
    trail._physics_process(.01)
    check(ledger.collected_count==24,"Repeated overlap cannot duplicate shared total")
    body.get_node("Defeat").reset()
    check(ledger.collected_count==24 and trail.get_child(0).collected,"Squirrel reset preserves collected progress")
    print("JUNGLE_ORANGE_ARCS failures=",failures)
    quit(1 if failures else 0)
