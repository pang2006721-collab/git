extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    if not ok: failures.append(message); push_error(message)
func key(code: Key, pressed: bool):
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.keycode = code
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()
func run():
    var scene = load("res://scenes/previews/settlement_descent.tscn").instantiate()
    scene.arrival_position = Vector2(960,837)
    scene.arrival_velocity = Vector2(0,-620)
    scene.opening_offset = Vector2(0,-86)
    root.add_child(scene)
    scene.set_process(false)
    check(scene.gate.position == Vector2(960,837) and scene.gate.velocity.y == -620,"Handoff preserves the original pop position and velocity")
    var start: Vector2 = scene.opening.soul.position
    key(KEY_D,true)
    await process_frame
    for i in 60: scene._process(1.0/60)
    key(KEY_D,false)
    check(scene.opening.soul.position.x > start.x+250,"Player can move while God awards the halo")
    check(scene.opening.soul.get_parent() == scene.gate.clip,"The same player is clipped by the cloud surface")
    scene.gate.position = Vector2(950,scene.gate.floor_y)
    scene.gate.velocity = Vector2.ZERO
    key(KEY_W,true)
    await process_frame
    scene._process(1.0/60)
    key(KEY_W,false)
    check(scene.gate.velocity.y < -500,"Jump remains available during the award")
    scene.elapsed = 5.33
    scene.gate.position = Vector2(1100,scene.gate.floor_y)
    scene.gate.velocity = Vector2.ZERO
    key(KEY_A,true)
    scene._process(.02)
    key(KEY_A,false)
    var head: Vector2 = scene.opening.soul.position+Vector2(0,-90*scene.opening.soul.scale.y-28)
    check(scene.opening.soul_halo.position.distance_to(head) < 25,"Award halo lands on the moving player, not a fixed old position")
    scene.elapsed = 8.39
    scene.gate.position.y = scene.gate.floor_y
    scene.gate.velocity.y = 0
    scene._process(.02)
    check(scene.gate.phase == scene.gate.Phase.DIVING and scene.gate.ripple.visible,"A cloud fold opens before the ghost falls")
    check(not scene._review_started and absf(scene.scroll_at(8.4)) < .001,"Camera waits at the cloud during the dive")
    for i in 20: scene._process(1.0/60)
    check(scene.gate.position.y > scene.gate.floor_y+90 and not scene._review_started,"Body drops through the fold before retrospective movement")
    check(scene.gate.clip.clip_contents,"The cloud hides the descending body instead of fading its opacity")
    for i in 40: scene._process(1.0/60)
    check(scene._review_started and not scene.gate.ripple.visible,"Retrospective begins only after the fold closes")
    check(scene.opening.soul.get_parent() == scene.ghost_layer,"Free flight resumes beneath the cloud after diving")
    scene.free()
    # 按真实帧推进，验证可操作模式没有再次吃掉戴环回弹，也没有把物理位置推走。
    var bounce = load("res://scenes/previews/settlement_descent.tscn").instantiate()
    bounce.interactive = false
    root.add_child(bounce)
    bounce.set_process(false)
    var minimum: float = INF
    var maximum: float = 0
    for i in 480:
        bounce._process(1.0/60)
        var t: float = bounce.elapsed
        if t >= 5.25 and t <= 5.42: minimum = minf(minimum,bounce.opening.soul.scale.y)
        if t >= 5.43 and t <= 5.75: maximum = maxf(maximum,bounce.opening.soul.scale.y)
        if t >= 5.1 and t <= 6.3:
            var body: Node2D = bounce.opening.soul
            check(absf(body.scale.x*body.scale.y-1.96)<.001,"Duang preserves the character's drawn body area")
            check(absf(bounce.gate.position.y-bounce.gate.floor_y)<.001,"Award bounce is visual and does not move the player's collision position")
    check(minimum<1.4*.90 and maximum>1.4*1.08,"Controllable ghost visibly squashes then stretches when receiving the halo")
    check(bounce.opening.soul.scale.distance_to(Vector2.ONE*1.4)<.005,"Duang settles back to the player's original size")
    bounce.free()
    print("SEAMLESS_HALO_GATE_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
