extends SceneTree
var failures:Array[String]=[]
func _initialize() -> void:run.call_deferred()
func check(ok:bool,message:String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)
func run() -> void:
	var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
	game.get_node("FlyingEnemies").enabled=false # 单项检查不运行定时敌人。
	root.add_child(game)
	current_scene=game
	await create_timer(.85).timeout
	game.soul.position=game.demon.position+Vector2(-90,0)
	for i in 5:await physics_frame
	check(game.possession.request_possession(),"Possession starts")
	await create_timer(2.6).timeout
	var rig=game.get_node("Fork")
	var attention=game.get_node("CameraAttention")
	var camera=game.camera
	var original_zoom:Vector2=camera.zoom
	var camera_id=root.get_camera_2d().get_instance_id()
	for number in [2,3]:
		rig.reset()
		var target=game.get_node("Fork/Targets/Target%02d"%number)
		game.demon.get_node("Movement").enabled=false
		game.demon.get_node("Input").enabled=false
		game.demon.velocity=Vector2.ZERO
		game.demon.global_position=target.global_position+Vector2(-260,260)
		camera.set_follow_target(game.demon,true)
		await create_timer(.8).timeout
		var peek:Vector2=camera.framing_bias*camera.zoom
		check(peek.x>5 and peek.y<0,"Camera looks gently toward the target")
		check(absf(peek.x)<=attention.maximum_peek_pixels.x+.01 and absf(peek.y)<=attention.maximum_peek_pixels.y+.01,"Interest offset is capped in screen pixels")
		check(rig.selected==target,"Automatic target selection remains functional")
		rig._throw()
		check(not rig.held,"Throw immediately removes the held fork")
		await create_timer(.1).timeout
		check(not rig.held and rig.flying,"Fork stays out of the hand during its flight")
		check(rig.lodged==target,"Fork flight retains the intended target")
		var previous:Vector2=camera.global_position
		var largest_step:=0.0
		for frame in 180:
			await process_frame
			if rig.held:
				check(not rig.fork.visible,"Teleport never leaves the fork at the old position")
			var step:float=camera.global_position.distance_to(previous)
			largest_step=maxf(largest_step,step)
			previous=camera.global_position
		check(largest_step<70.0,"Exchange has no camera position snap")
		check(rig.held,"Teleport restores the held fork")
		check(not rig.swapping and not rig.launching,"Exchange and bounce still complete")
		check(game.demon.get_node("Input").enabled,"Control is restored after the bounce")
		check(camera.zoom.is_equal_approx(original_zoom),"Mechanism framing does not pump the zoom")
		check(root.get_camera_2d().get_instance_id()==camera_id,"The display camera is unchanged")
		print("TARGET",number," MAX_CAMERA_STEP=",largest_step," PEEK_PIXELS=",peek)
	rig.reset()
	game.demon.get_node("Movement").enabled=false
	game.demon.get_node("Input").enabled=false
	game.demon.collision_layer=0
	var upper=game.get_node("Fork/Targets/Target02")
	game.demon.global_position=upper.global_position+Vector2(180,500)
	camera.set_follow_target(game.demon,true)
	await create_timer(1.6).timeout
	var screen_point:Vector2=(upper.global_position-camera.global_position)*camera.zoom+camera.get_viewport_rect().size*.5
	print("UPPER_TARGET_SCREEN=",screen_point," VIEW=",camera.get_viewport_rect().size)
	check(screen_point.y>75,"Upper target is framed inside the image instead of cropped at the top")
	check(rig.selected==upper,"Upper left target remains selectable")
	rig._throw()
	var incoming:Vector2=(upper.global_position-rig.fork.global_position).normalized()
	var tip:Vector2=Vector2.RIGHT.rotated(rig.fork.global_rotation+deg_to_rad(rig.fork_tip_angle_degrees))
	check(incoming.dot(tip)>.999,"Flying fork tip points along its travel direction")
	while rig.flying:await process_frame
	check(Vector2.RIGHT.rotated(upper.art.rotation).dot(incoming)>.999,"Embedded fork retains the incoming direction from the right")
	rig.reset()
	game.demon.get_node("Movement").enabled=false
	game.demon.get_node("Input").enabled=false
	game.demon.collision_layer=0
	game.demon.global_position=game.get_node("Platforms/Moving19").global_position+Vector2(-160,230)
	camera.set_follow_target(game.demon,true)
	await create_timer(.8).timeout
	check(is_instance_valid(attention._platform_interest) and camera.framing_bias.length()>5,"Nearby active platforms also attract a small camera bias")
	attention.enabled=false
	await create_timer(1.2).timeout
	check(camera.framing_bias.length()<2,"Disabling interest returns the framing gently to neutral")
	game.demon.collision_layer=2
	game.restart()
	check(camera.framing_bias.is_zero_approx(),"Restart clears stale mechanism framing")
	print("FORK_CAMERA_FAILURES=",failures.size())
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
