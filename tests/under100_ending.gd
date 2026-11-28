extends SceneTree
var failures:=0
func _initialize():run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures+=1
        push_error(message)
func run():
    root.size=Vector2i(1280,720)
    root.content_scale_size=Vector2i(1920,1080)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    var scene=load("res://scenes/previews/halo_reward_preview.tscn")
    var opening=scene.instantiate()
    opening.oranges_total=99
    opening.auto_play=false
    root.add_child(opening)
    var reaction=opening.under100
    check(reaction!=null and opening.duration==7.2,"99 oranges chooses the reaction timeline")
    for pair in [[1.0,"question"],[2.0,"cry"],[3.0,"plead"],[4.1,"shake"],[5.5,"accept"]]:
        opening.sample(pair[0])
        check(not opening.soul_halo.visible,"Unqualified soul receives no halo")
        if pair[1]=="question":check(reaction.question.visible,"God asks about 100 oranges")
        if pair[1]=="cry":check(reaction.expression.texture==reaction.cry and reaction.expression.visible,"Cry sprite replaces normal face")
        if pair[1]=="plead":check(reaction.plead.visible,"Plea follows crying")
        if pair[1]=="shake":
            check(absf(float(opening.gaze.get_shader_parameter("head_shake")))>1,"God shakes his head")
            check(float(opening.gaze.get_shader_parameter("head_bow"))>.95 and float(opening.gaze.get_shader_parameter("blink"))>.95,"God bows with eyes closed before acceptance")
            check(not reaction.accept.visible,"Checkmark waits for the head shake")
        if pair[1]=="accept":check(reaction.accept.visible and reaction.expression.texture==reaction.relieved,"Checkmark appears and tears are removed")
        if DisplayServer.get_name()!="headless":
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/under100-"+pair[1]+".png")
    opening.sample(2.9)
    var drift_before:Vector2=reaction.question.position
    opening.sample(3.0)
    check(reaction.question.position.distance_to(drift_before)>.05,"Conversation art drifts smoothly in both directions")
    check(reaction.plead_offset.length()<Vector2(145,-175).length(),"Plea is closer to the ghost")
    reaction.restore()
    check(float(opening.gaze.get_shader_parameter("head_bow"))==0.0 and float(opening.gaze.get_shader_parameter("blink"))==0.0,"God returns to the neutral pose")
    check(opening.face.visible and not reaction.expression.visible,"Review restores normal soul without tears")
    opening.queue_free()
    await process_frame
    var rewarded=scene.instantiate()
    rewarded.oranges_total=100
    rewarded.auto_play=false
    root.add_child(rewarded)
    rewarded.sample(5.5)
    check(rewarded.under100==null and rewarded.soul_halo.visible,"100 oranges retains original halo reward")
    rewarded.queue_free()
    await process_frame
    var settlement=load("res://scenes/previews/settlement_descent.tscn").instantiate()
    settlement.oranges_total=99
    root.add_child(settlement)
    settlement.set_process(false)
    var initial_x: float=settlement.gate.position.x
    var move:=InputEventKey.new()
    move.physical_keycode=KEY_D
    move.keycode=KEY_D
    move.pressed=true
    Input.parse_input_event(move)
    Input.flush_buffered_events()
    await process_frame
    for i in 60:settlement._process(1.0/60)
    move.pressed=false
    Input.parse_input_event(move)
    Input.flush_buffered_events()
    check(settlement.gate.position.x>initial_x+200,"Player can move freely during the under-100 conversation")
    settlement.elapsed=2.8
    settlement._process(.01)
    var reaction2=settlement.opening.under100
    var before: Vector2=reaction2.plead.position
    settlement.gate.position.x-=150
    settlement._process(.01)
    check(reaction2.plead.position.x<before.x and reaction2.plead.position.x>before.x-140,"Plea lags behind movement rather than snapping")
    for i in 60:settlement._process(1.0/60)
    check(reaction2.plead.position.distance_to(reaction2.plead_target())<6.0,"Plea catches up smoothly after stopping")
    check(absf(reaction2.plead.rotation)<.06,"Bubble lean stays restrained")
    settlement.gate.position.y=settlement.gate.floor_y
    settlement.gate.velocity=Vector2.ZERO
    settlement.elapsed=settlement.opening.duration-.01
    settlement._process(.02)
    check(settlement.gate.phase==settlement.gate.Phase.DIVING,"After reaction original cloud fold dive starts")
    for i in 65:settlement._process(1.0/60)
    check(settlement._review_started and not settlement.opening.soul_halo.visible,"Review continues without granting a halo")
    print("UNDER100_ENDING failures=",failures)
    quit(1 if failures else 0)
