extends SceneTree
var failures: Array[String] = []
class FakeLevel extends Node2D:
    signal died
    var dead := false
    var exit_in_progress := false
    var player: Node
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var level := FakeLevel.new()
    root.add_child(level)
    var history = load("res://modules/cinematic/run_retrospective.gd").new()
    history.recording_enabled = false
    level.add_child(history)
    for stage in ["Demon", "Fish", "Squirrel", "Bird"]:
        var body := Node.new()
        body.name = stage
        level.add_child(body)
        level.player = body
        level.died.emit()
    check(history.deaths.values() == [1,1,1,1], "Every stage records its own deaths")
    var snap: Dictionary = history.snapshot()
    level.died.emit()
    check(history.deaths[&"sky"] == 2 and snap.deaths[&"sky"] == 1, "Retry keeps totals; snapshot remains independent")
    for i in 100: history.append_frame(&"hell", PackedByteArray([i]))
    check(history.recent[&"hell"].size() == 48, "Replay memory stays bounded at six seconds")
    history.current_stage = &"jungle"
    var soul := Node.new()
    soul.name = "Soul"
    check(history.stage_for_player(soul) == &"jungle", "Transfers remain attributed to the leaving stage")
    soul.free()
    var preview = load("res://scenes/previews/settlement_descent.tscn").instantiate()
    preview.auto_play = false
    root.add_child(preview)
    preview.set_history(snap)
    var previous: float = 0
    var max_step: float = 0
    for frame in 3001:
        var y: float = preview.scroll_at(frame/60.0)
        check(y >= previous-.001, "Camera never reverses at a handoff")
        max_step = maxf(max_step,y-previous)
        previous = y
    check(max_step < 60, "No one-frame camera jumps")
    check(absf(preview.scroll_at(8.4)) < .001, "Descent waits for the halo reward")
    preview.sample(22)
    check(preview.opening.soul.get_parent() == preview.ghost_layer, "Ghost control separates from scrolling scenery")
    var before: float = preview.opening.soul.position.y
    preview.flight.velocity = Vector2(0,-400)
    preview.move_ghost(.01)
    check(preview.opening.soul.position.y < before, "Ghost remains movable during settlement")
    check(preview.ghost_layer.layer < preview.cloud_layer.layer, "Clouds are drawn above the ghost")
    for i in 4:
        check(preview.numbers[i].get_child_count() == 1, "One numeric overlay per original underline")
    var image := Image.create(16,9,false,Image.FORMAT_RGB8)
    image.fill(Color.RED)
    snap.clips[&"hell"] = [image.save_jpg_to_buffer()]
    preview.set_history(snap)
    preview.sample(22)
    check(preview.screens[0].visible and preview.screens[0].texture != null, "Recorded JPEGs play inside the frame")
    var replay_size: Vector2 = Vector2(preview.screens[0].texture.get_size())*preview.screens[0].scale
    check(replay_size.is_equal_approx(preview.WINDOWS[0].size),"16:9 recordings fill the replay opening without side gaps")
    check(is_equal_approx(preview.screens[0].scale.x,preview.screens[0].scale.y),"Replay characters and scenery keep their original proportions")
    check(not preview.screens[1].visible, "Missing recordings are never replaced with invented replays")
    var counts={"deaths":{&"hell":0,&"ocean":1,&"jungle":9,&"sky":11},"clips":{},"fps":8}
    for repeat in 2:
        preview.set_history(counts)
        for i in 4:
            var expected:String=["1","2","10","12"][i]
            var digits=preview.numbers[i].get_children()
            check(digits.size()==expected.length(),"Each stage displays its own attempt count")
            for j in mini(digits.size(),expected.length()):
                check(digits[j].texture==preview._digit_textures[int(expected[j])],"Attempts equal deaths plus the successful run")
    check(counts.deaths[&"hell"]==0 and counts.deaths[&"sky"]==11,"Repeated settlement rendering never changes recorded deaths")
    print("SETTLEMENT_FAILURES=",failures.size(), " MAX_SCROLL_STEP=",max_step)
    preview.free()
    level.free()
    quit(0 if failures.is_empty() else 1)
