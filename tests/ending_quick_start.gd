extends SceneTree
var failures: Array[String] = []
var starts: Array[int] = []
class FakeRun extends Node2D:
    signal died
    var dead := false
    var exit_in_progress := false
    var player: Node
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func until(predicate: Callable, seconds: float = 15.0) -> bool:
    var deadline: int = Time.get_ticks_msec()+int(seconds*1000)
    while Time.get_ticks_msec() < deadline:
        if predicate.call(): return true
        await process_frame
    return false
func seven():
    var key := InputEventKey.new()
    key.physical_keycode = KEY_7
    key.pressed = true
    root.push_input(key,true)
func is_ending() -> bool:
    return current_scene != null and current_scene.scene_file_path == "res://scenes/previews/settlement_descent.tscn"
func run():
    var quick := root.get_node("SegmentQuickStart")
    quick.segment_started.connect(func(i): starts.append(i))
    var old := FakeRun.new()
    root.add_child(old)
    current_scene = old
    var history = load("res://modules/cinematic/run_retrospective.gd").new()
    history.name = "RunRetrospective"
    history.recording_enabled = false
    old.add_child(history)
    history.deaths[&"hell"] = 3
    paused = true
    Engine.time_scale = .1
    seven()
    check(await until(func(): return starts.has(7)),"Physical key 7 works while paused and restores normal time")
    check(not paused and Engine.time_scale == 1.0,"Ending shortcut clears death freeze")
    var cloud = current_scene.get_node("OceanLink/FishStage/JungleLayout/SkyCloudExit")
    check(cloud.state == cloud.State.ENTERING and current_scene.exit_in_progress,"Key 7 immediately starts the original cloud transition")
    check(await until(is_ending),"Cloud transition automatically continues into the ending")
    if is_ending():
        check(root.canvas_transform.is_equal_approx(Transform2D.IDENTITY),"Ending does not inherit the sky camera's old offset")
        check(current_scene.oranges_total == 100 and current_scene.opening.oranges_total == 100,"Ending shortcut always grants the 100-orange halo preview")
        check(current_scene.data.deaths[&"hell"] == 3,"Existing run's death history survives the shortcut")
        current_scene.opening.sample(6.5)
        check(current_scene.opening.soul_halo.visible,"The ghost receives its halo")
    # 在结尾中再次按7，必须能重放整段穿云，随后按6可以取消旧结尾交接。
    seven()
    check(await until(func(): return starts.count(7) == 2),"Key 7 can restart from the ending itself")
    quick.start_segment(6)
    check(await until(func(): return starts.back() == 6),"Existing key 6 can interrupt the ending shortcut")
    var game_id: int = current_scene.get_instance_id()
    await create_timer(1.2).timeout
    check(current_scene.get_instance_id() == game_id and not is_ending(),"Cancelled cloud handoff does not later steal the scene")
    print("ENDING_QUICK_START_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
