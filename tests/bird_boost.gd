extends SceneTree
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func shift_key(pressed: bool, location: int=KEY_LOCATION_LEFT):
    var event:=InputEventKey.new()
    event.keycode=KEY_SHIFT
    event.physical_keycode=KEY_SHIFT
    event.location=location
    event.pressed=pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()
func tick(bird: Node,count: int) -> float:
    var upward:=0.0
    for i in count:
        bird.get_node("Input")._physics_process(.02)
        bird.get_node("Boost")._physics_process(.02)
        bird.get_node("Movement")._physics_process(.02)
        bird.get_node("Visual")._process(.02)
        bird.get_node("Boost")._process(.02)
        upward=minf(upward,bird.velocity.y)
    return upward
func run():
    var bird=load("res://scenes/actors/formal_canopy_bird.tscn").instantiate()
    root.add_child(bird)
    for name in ["Input","Movement","Boost","Patrol"]: bird.get_node(name).set_physics_process(false)
    bird.get_node("Boost").set_process(false)
    bird.get_node("Visual").set_process(false)
    var boost=bird.get_node("Boost")
    var motor=bird.get_node("Movement")
    var visual=bird.get_node("Visual")
    var shape=bird.get_node("Collision").shape
    var radius: float=shape.radius
    var sprite_scale: Vector2=bird.get_node("Visual/Sprite").scale
    bird.get_node("Host").take_control()
    Input.action_press(&"move_right")
    Input.action_press(&"flap")
    var normal_up: float=tick(bird,40)
    var normal_speed: float=bird.velocity.x
    var normal_flap_interval: float=motor.held_flap_interval
    check(normal_speed<370.0 and normal_speed>330.0,"Ordinary flight is one step slower for precise positioning")
    shift_key(true)
    check(Input.is_action_pressed(&"bird_boost"),"Physical Shift holds the bird boost action")
    var boosted_up: float=tick(bird,40)
    check(bird.velocity.x>1000.0,"Shift retains fast sideways flight")
    check(is_equal_approx(boosted_up,normal_up) and motor.held_flap_interval==normal_flap_interval,"Shift leaves actual upward flap speed and cadence unchanged")
    visual._wing=0.0
    visual._pulse=0.0
    visual._process(0.0)
    check(visual.scale==Vector2.ONE,"Boost preserves the normal bird proportions")
    check(boost._material.get_shader_parameter("blur_strength")>.1,"Fast flight enables a restrained motion blur")
    check(shape.radius==radius and bird.get_node("Visual/Sprite").scale==sprite_scale,"Boost preserves collision size and source sprite scale")
    shift_key(false)
    tick(bird,20)
    check(boost.amount==0.0 and is_equal_approx(motor.move_speed,430.0*.82) and is_equal_approx(motor.flap_speed,540.0*.87),"Releasing Shift restores the lower cruising speed")
    check(boost._material.get_shader_parameter("blur_strength")==0.0,"Releasing Shift removes the motion blur")
    shift_key(true)
    tick(bird,20)
    check(motor.move_speed<=430.0*2.401,"Repeated boosts do not compound their speed")
    motor.enabled=false
    boost._physics_process(.02)
    check(boost.amount==0.0 and motor.move_speed==430.0 and visual.scale.y>=.99,"Disabled cinematic controls cancel boost and restore the normal body shape immediately")
    bird.get_node("Host").reset()
    boost._physics_process(.02)
    check(boost.amount==0.0,"Unpossessed patrol bird cannot boost")
    bird.get_node("Host").take_control()
    Input.action_release(&"flap")
    bird.velocity=Vector2.ZERO
    tick(bird,5)
    check(bird.velocity.y>=0.0,"Shift alone does not replace W with automatic upward flapping")
    boost.reset()
    shift_key(false)
    shift_key(true,KEY_LOCATION_RIGHT)
    tick(bird,10)
    check(boost.amount>.99,"Right Shift also supports held acceleration")
    shift_key(false,KEY_LOCATION_RIGHT)
    boost.reset()
    Input.action_release(&"move_right")
    print("BIRD_BOOST_FAILURES=",failures.size())
    bird.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
