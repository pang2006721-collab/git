extends SceneTree
func _initialize():run.call_deferred()
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("FlyingEnemies").enabled=false
    game.get_node("DeathFlow").queue_free()
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    var layout=stage.get_node("JungleLayout")
    var bird=layout.get_node("Bird")
    bird.get_node("Host").take_control()
    game.player=bird
    bird.show()
    bird.get_node("Patrol").set_physics_process(false)
    bird.get_node("Movement").set_physics_process(false)
    bird.get_node("Movement").enabled=true
    bird.get_node("Input").enabled=true
    bird.get_node("Input").external_control=false
    bird.velocity=Vector2.ZERO
    bird.global_position=Vector2(960,18000)
    game.camera.set_process(false)
    game.camera.global_position=bird.global_position
    var sky=layout.get_node("SkyEagle")
    sky.set_process(false)
    var hail=sky.get_node("Hail")
    hail.set_physics_process(false)
    hail._spawn_row()
    var stone:Dictionary=hail.stones[0]
    for other in hail.stones.slice(1):other.art.queue_free()
    hail.stones.clear()
    hail.stones.append(stone)
    var fire=bird.get_node("Boost")
    fire.set_physics_process(false)
    var hint=game.get_node("SkyShiftReminder")
    assert(not game.has_node("SkyTutorial") and not paused)
    fire.heat=1.0
    stone.art.global_position=bird.global_position+Vector2(0,-650)
    await create_timer(.2).timeout
    assert(not hint.visible,"Distant hail gives no premature reminder")
    stone.art.global_position=bird.global_position+Vector2(0,-float(stone.radius)-hail.BIRD_RADIUS-140)
    assert(hint._danger_near(),"Predict imminent impact before contact")
    await create_timer(.2).timeout
    assert(hint.visible and hint.hold_demo and not paused)
    var sprite=bird.get_node("Visual/Sprite")
    var transform:Transform2D=sprite.get_global_transform_with_canvas()
    var rect:Rect2=sprite.get_rect()
    var bottom:float=-INF
    for corner in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:bottom=maxf(bottom,(transform*corner).y)
    assert(hint.anchor_below and hint.head_target().y-hint.art.size.y*.5>bottom+20,"Sky reminder sits below the bird with a clear gap")
    hint._age=.9
    hint._process(0)
    assert(hint.art.scale.y<.7,"Danger lesson shows a sustained press")
    stone.art.position.x+=500
    await create_timer(1.1).timeout
    assert(not hint.visible,"Safely outside hail path hides the prompt")
    stone.art.global_position=bird.global_position+Vector2(0,-float(stone.radius)-hail.BIRD_RADIUS-140)
    fire.heat=.8
    await create_timer(.2).timeout
    assert(not hint.visible,"80 percent heat alone cannot ignite and must not prompt")
    fire.heat=1.0
    await create_timer(.2).timeout
    Input.action_press(&"bird_boost")
    fire.tick(.01,true)
    await create_timer(.2).timeout
    assert(fire.is_burning() and hint.visible and hint.art.scale.y<.7,"Actual held Shift stays depressed while burning")
    Input.action_release(&"bird_boost")
    fire.tick(.01,false)
    hail.stone_melted.emit()
    assert(hint.successes==1,"One complete melt keeps guidance available")
    hail.stone_melted.emit()
    hint._process(.2)
    assert(hint.successes==2 and not hint.visible,"Two completed melts disable sky guidance")
    game.player=stage.fish
    await create_timer(.2).timeout
    assert(not hint.visible,"Other stages cannot see sky guidance")
    root.get_node("SegmentQuickStart").start_segment(6)
    for i in 240:
        await create_timer(.02).timeout
        if current_scene!=game and current_scene!=null:break
    await create_timer(.5).timeout
    assert(not current_scene.has_node("SkyTutorial") and not paused)
    print("SKY_SHIFT_PROMPT_PASS: collision prediction, reachable escape, heat readiness, hold, no modal, key6")
    quit()
