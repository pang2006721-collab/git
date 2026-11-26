extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func make_flight() -> Node:
    var scene = load("res://scenes/previews/settlement_descent.tscn").instantiate()
    scene.auto_play = false
    scene.interactive = false
    root.add_child(scene)
    scene.set_process(false)
    scene.sample(22)
    return scene
func run():
    var scene = make_flight()
    var flight = scene.flight
    for dir in [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]:
        flight.position = Vector2(960,600)
        flight.velocity = Vector2.ZERO
        for i in 60: flight.advance(1.0/120,dir)
        check((flight.position-Vector2(960,600)).dot(dir) > 100, "Every direction flies freely")
    for dir in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
        for i in 240: flight.advance(1.0/60,dir)
        var b: Rect2 = flight.flight_bounds()
        check(flight.position.x >= b.position.x and flight.position.x <= b.end.x and flight.position.y >= b.position.y and flight.position.y <= b.end.y,"Ordinary flight stays on screen")
    flight.position = Vector2(960,600)
    flight.velocity = Vector2(300,0)
    flight.advance(1.0/60,Vector2.ZERO)
    check(flight.velocity.x > 0 and flight.velocity.x < 300,"Releasing input decelerates instead of stopping abruptly")
    for i in 120: flight.advance(1.0/60,Vector2.ZERO)
    check(flight.velocity.length() < .01,"Idle settles without endless sliding")
    check(absf(flight.body.scale.x*flight.body.scale.y-1.35*1.35)<.001,"Smaller ghost preserves its body area")
    var other = make_flight()
    flight.position = Vector2(800,600)
    flight.velocity = Vector2.ZERO
    other.flight.position = flight.position
    for i in 30: flight.advance(1.0/30,Vector2.RIGHT)
    for i in 120: other.flight.advance(1.0/120,Vector2.RIGHT)
    check(flight.position.distance_to(other.flight.position)<.01,"30 and 120 fps give the same flight path")
    for i in 120:
        flight.advance(1.0/120,Vector2.UP)
        check(flight.halo.position.y+22 < flight.body.position.y-90*flight.body.scale.y+1,"Halo stays above the head while flying upward")
    check(scene.ghost_layer.layer < scene.cloud_layer.layer,"Clouds occlude the ghost")
    # 不触发真实换场，只验证退场唯一允许飞出上边界，且只发一次完成信号。
    flight.exited.disconnect(scene._on_ghost_exited)
    var exits := [0]
    flight.exited.connect(func(): exits[0] += 1)
    flight.leave_upward()
    for i in 300: flight.advance(1.0/60,Vector2.DOWN)
    check(flight.position.y < -140 and exits[0] == 1,"Ending overrides steering and exits above the screen once")
    scene.free()
    other.free()
    print("SETTLEMENT_FLIGHT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
