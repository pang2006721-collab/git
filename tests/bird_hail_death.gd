extends SceneTree
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
	if not ok:
		failures += 1
		push_error(message)
func until(predicate: Callable, seconds: float=6.0) -> bool:
	var end := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<end:
		if predicate.call(): return true
		await process_frame
	return false
func run():
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1920,1080)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var quick=root.get_node("SegmentQuickStart")
	quick.start_segment(6)
	await quick.segment_started
	var game=current_scene
	game.get_node("RunRetrospective").recording_enabled=false
	for name_key in ["Checkpoint","OceanCheckpoint","JungleCheckpoint"]: game.get_node(name_key).grace_remaining=0
	var layout=game.get_node("OceanLink/FishStage/JungleLayout")
	var bird=layout.get_node("Bird")
	bird.get_node("Movement").enabled=false
	bird.get_node("Input").enabled=false
	bird.get_node("Visual").set_process(false)
	bird.get_node("Visual/Sprite").flip_h=true
	bird.get_node("Boost").reset()
	var sky=layout.get_node("SkyEagle")
	sky.reset()
	sky.set_process(false)
	var hail=sky.get_node("Hail")
	hail.set_physics_process(false)
	game.camera.set_follow_target(bird,true)
	game.camera.set_process(false)
	game.camera.make_current()
	game.camera.force_update_scroll()
	hail._spawn_row()
	var ice: Dictionary=hail.stones[0]
	ice.art.global_position=bird.global_position+Vector2(0,-20)
	ice.speed=200.0
	hail._previous_target=bird.global_position
	var body_position: Vector2=bird.global_position
	var death_count: int=game.get_node("RunRetrospective").deaths[&"sky"]
	hail._physics_process(.001)
	check(game.dead and game.death_reason==&"hail","actual hail collision kills bird")
	var flow=game.get_node("DeathFlow")
	check(await until(func(): return flow.bird_death.falling,2),"hail routes into bird death animation")
	var death=flow.bird_death
	if death.corpse != null:
		check(death.corpse.texture.atlas.resource_path.ends_with("expressions/bird_dead.png"),"uses supplied cross-eye expression")
		check(death.corpse.texture.region==Rect2(526,2593,83,65),"empty source canvas is excluded")
		check(death.corpse.flip_h,"current facing is preserved")
		check(death.corpse.global_position.distance_to(body_position)<5,"death starts at the bird position")
		check(not bird.get_node("Visual").visible and not flow.overlay.visible,"original bird hidden and dialog waits for fall")
		var origin: Vector2=death.corpse.global_position
		var stone_before: Vector2=ice.art.global_position
		hail._physics_process(.15)
		await create_timer(.22).timeout
		check(death.corpse.global_position.y>origin.y+10,"bird falls while level is frozen")
		check(ice.art.global_position.y>stone_before.y and ice.art.visible,"ice continues after hit")
		check(bird.global_position.is_equal_approx(body_position),"visual fall does not move frozen collider")
		check(game.get_node("RunRetrospective").deaths[&"sky"]==death_count+1,"one real sky death counted")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("C:/Users/14930/Documents/Codex/2026-11-18/m/bird-hail-death-native.png")
	check(await until(func(): return flow.overlay.state==flow.overlay.State.OPEN,4),"retry dialog follows complete fall")
	check(not death.falling and not death.corpse.visible,"dead bird exits before dialog")
	flow._retry()
	check(await until(func(): return flow.state==flow.State.PLAYING,7),"retry restores normal play")
	check(death.corpse==null and not death.falling,"retry clears corpse and animation")
	check(bird.get_node("Visual").visible,"retry restores living bird art")
	print("BIRD_HAIL_DEATH_FAILURES=",failures)
	quit(failures)
