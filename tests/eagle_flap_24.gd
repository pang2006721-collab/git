extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var eagle = load("res://modules/visual/eagle_flap_visual.gd").new()
    root.add_child(eagle)
    eagle.set_process(false)
    var target := Node2D.new()
    root.add_child(target)
    eagle.look_target = target
    var strokes: Array[int] = []
    eagle.downstroke.connect(func(): strokes.append(1))
    check(eagle._frames.size() == 3, "Exactly three selected poses")
    target.position = Vector2(700, 250)
    for i in 110: eagle._process(.01)
    check(strokes.size() == 1, "Exactly one downstroke impulse per cycle")
    check(eagle.gaze.x > 0 and eagle.gaze.y > 0, "Eyes follow player to lower right")
    target.position = Vector2(-700, -500)
    for i in 35: eagle._process(.01)
    check(eagle.gaze.x < 0 and eagle.gaze.y < 0, "Eyes follow player to upper left")
    eagle.reset()
    check(eagle.frame_index == 0 and eagle.gaze == Vector2.ZERO and eagle.sprite.position == Vector2.ZERO, "Reset returns pose, gaze and bounce to rest")
    eagle._process(eagle.cycle_seconds * .8)
    check(is_zero_approx(eagle.sprite.position.y), "Downstroke bounce settles before recovery ends")
    print("EAGLE_THREE_POSE_FAILURES=", failures.size())
    quit(0 if failures.is_empty() else 1)
