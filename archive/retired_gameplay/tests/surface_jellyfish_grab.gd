extends SceneTree
var failures: Array[String] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func run():
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed = true
    var stage = game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    var fish = stage.fish
    var motor = fish.get_node("Movement")
    motor.set_physics_process(false)
    fish.get_node("Patrol").stop()
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(name).process_mode = Node.PROCESS_MODE_DISABLED
    var grab = stage.get_node("SurfaceGrab")
    grab.set_physics_process(false)
    var shore = stage.get_node("ShoreExit")
    shore.set_physics_process(false)
    var blink = fish.get_node("Teleport")
    fish.position = Vector2(960,shore.surface_y+1500)
    fish.velocity = Vector2(0,-420)
    grab._physics_process(.01)
    check(grab.state==grab.State.WAITING,"Deep water cannot start the final grab")
    fish.position.y = shore.surface_y+1000
    game.get_node("CameraAttention").enabled = false
    game.camera.set_follow_target(fish,true)
    game.camera.set_process(false)
    game.camera.global_position = fish.global_position
    game.camera.zoom = Vector2.ONE*1.35
    grab._physics_process(.01)
    check(grab.state==grab.State.WARNING and grab._warning_arms.size()==4,"Four tendrils announce the final encounter before any grab")
    var first_position: Vector2 = grab._warning_arms[0].global_position
    for i in 60:
        fish.position += fish.velocity*.01
        game.camera.global_position = fish.global_position
        grab._physics_process(.01)
    check(grab.state==grab.State.WARNING and motor.enabled,"Warning leaves swimming available and cannot grab early")
    check(grab._warning_arms[0].rotation!=0 and grab._warning_arms[0].global_position.y<first_position.y,"Tendrils rise independently with a smooth sway")
    check(grab._warning_arms[0].get_node("Warning").visible,"Emerging tendrils visibly show the warning art")
    for arm in grab._warning_arms:
        check(not arm.dangerous and arm.body.collision_layer==0,"Every warning tendril is harmless")
    if DisplayServer.get_name()!="headless":
        game.camera.make_current()
        game.camera.force_update_scroll()
        await process_frame
        await process_frame
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/work/surface-grab-warning.png")
    for i in 82:
        fish.position += fish.velocity*.01
        game.camera.global_position = fish.global_position
        grab._physics_process(.01)
    check(grab.state==grab.State.REACHING,"Grab begins only after the full warning")
    for i in 65:
        fish.position += fish.velocity*.01
        grab._physics_process(.01)
        if grab.state==grab.State.CAUGHT: break
    check(grab.state==grab.State.CAUGHT,"A swimming fish that does not blink is caught by the reaching tip")
    check(not motor.enabled and not fish.get_node("Visual").visible and grab._caught_art.visible,"Capture stops swimming and displays the supplied entangled artwork")
    grab._physics_process(.06)
    check(grab._caught_art.scale!=Vector2.ONE,"Capture has a visible squash and rebound")
    var caught_y: float = fish.global_position.y
    for i in 80: grab._physics_process(.01)
    check(fish.global_position.y>caught_y+25,"The tentacle keeps pulling the caught fish down instead of holding a static pose")
    var original_zoom: Vector2 = grab.shot._zoom
    grab.shot._process(.2)
    grab.prompt._process(.2)
    check(game.camera.zoom.x>original_zoom.x and game.camera.zoom.x<=original_zoom.x*1.06,"Grab camera adds only a restrained close-up")
    check(game.camera.cinematic_offset.y>0,"Grab camera framing moves slightly downward with the tug")
    check(grab.prompt.visible and grab.prompt.active and grab.prompt.sprite.position.y<grab.prompt.get_viewport().get_visible_rect().size.y*.2,"Supplied Shift prompt pops near the top of the screen")
    var cue_position: Vector2 = grab.prompt.sprite.position
    grab.prompt._process(.04)
    check(grab.prompt.sprite.position!=cue_position,"The Shift cue bounces continuously")
    check(not game.dead and grab.state==grab.State.CAUGHT,"Capture leaves the player a chance to escape rather than killing immediately")
    game.get_node("CameraAttention").enabled = false
    game.camera.set_follow_target(fish,true)
    game.camera.set_process(false)
    game.camera.global_position = fish.global_position
    game.camera.zoom = Vector2.ONE*1.35
    game.camera.make_current()
    game.camera.force_update_scroll()
    if DisplayServer.get_name()!="headless":
        await process_frame
        await process_frame
        root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/work/surface-grab.png")
    check(not blink.try_teleport(Vector2.UP),"A caught fish cannot escape with one ordinary teleport")
    var key := InputEventKey.new()
    key.physical_keycode = KEY_SHIFT
    key.location = KEY_LOCATION_LEFT
    key.pressed = true
    root.push_input(key,true)
    check(grab.struggle_presses==1 and grab.state==grab.State.CAUGHT,"One Shift press causes struggle without releasing the fish")
    key.echo = true
    for i in 8: root.push_input(key,true)
    check(grab.struggle_presses==1,"Holding Shift and OS key repeats cannot count as repeated struggles")
    key.echo = false
    var before_struggle_y: float = fish.global_position.y
    grab._physics_process(.04)
    check(fish.global_position.y<before_struggle_y,"A Shift tap physically wins ground upward against the pulling tentacle")
    check(grab._caught_art.rotation!=0,"Each struggle adds an immediate wriggling response")
    for i in range(grab.struggle_presses_required-1):
        key.pressed = false
        root.push_input(key,true)
        key.pressed = true
        root.push_input(key,true)
    check(grab.state==grab.State.FINISHED and motor.enabled and fish.get_node("Visual").visible,"Six separate Shift taps free the fish and restore swimming")
    check(grab._caught_art==null and grab._arm==null,"Successful struggle removes the wrapped art and arm")
    check(not grab.blocks_exit() and grab.attacks_started==1,"Only one attack is required before the shore route opens")
    grab.shot._process(.5)
    grab.prompt._process(.25)
    check(game.camera.zoom.is_equal_approx(original_zoom) and game.camera.cinematic_offset==grab.shot._offset,"Escape smoothly restores the exact original zoom and framing")
    check(not grab.prompt.visible,"Escape dismisses the Shift prompt")
    grab.reset()
    blink.reset()
    fish.position.y = shore.surface_y+600
    fish.velocity = Vector2(0,-420)
    grab._on_blink(Vector2.ZERO,fish.global_position)
    grab._physics_process(.01)
    check(grab.state==grab.State.WARNING and grab._warning_arms.size()==4,"The single encounter still starts with a visible warning")
    grab.reset()
    fish.position.y = shore.surface_y+600
    grab._physics_process(.01)
    check(grab.state==grab.State.WARNING,"Retry starts with warning rather than a surprise reach")
    check(blink.try_teleport(Vector2.RIGHT),"Player can dodge during the reaching animation")
    await create_timer(.12).timeout
    check(grab.state==grab.State.WARNING and grab._evaded,"Blink during the warning commits this attack to missing the fish")
    stage.reset()
    check(grab.state==grab.State.WAITING and grab._arm==null,"Retry rearms one clean final grab")
    print("SURFACE_GRAB_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
