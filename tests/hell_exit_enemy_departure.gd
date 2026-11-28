extends SceneTree
var failures:=0
func _initialize():run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures+=1
        push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("RunRetrospective").recording_enabled=false
    game.demon.get_node("Host").take_control()
    game.player=game.demon
    var encounter=game.get_node("FlyingEnemies")
    encounter.set_physics_process(false)
    var camera=game.camera
    camera.set_process(false)
    camera.adopt_view(game.to_global(Vector2(960,42000)),Vector2.ONE)
    camera.make_current()
    camera.force_update_scroll()
    var enemy=encounter.ENEMY.instantiate()
    enemy.encounter=encounter
    encounter.get_node("Enemies").add_child(enemy)
    enemy.global_position=camera.global_position+Vector2(150,-100)
    enemy.velocity=Vector2(80,0)
    enemy.set_physics_process(false)
    var fork=encounter.PROJECTILE.instantiate()
    fork.encounter=encounter
    encounter.get_node("Projectiles").add_child(fork)
    fork.global_position=camera.global_position
    fork.velocity=Vector2.ZERO
    fork.set_physics_process(false)
    var link=game.get_node("OceanLink")
    link._capture(game.demon)
    check(encounter.departing and not encounter.enabled,"Actual volcano entry starts departure")
    check(enemy.visible and not enemy.is_queued_for_deletion(),"Enemy does not vanish on entry")
    encounter._physics_process(.1)
    check(not enemy.is_queued_for_deletion() and not fork.is_queued_for_deletion(),"Visible enemy and fork remain during transition")
    var before: Vector2=enemy.global_position
    enemy._physics_process(.1)
    check(enemy.global_position!=before,"Enemy keeps moving naturally")
    var shots: int=encounter.total_shots
    encounter._shoot(game.demon.global_position,enemy.global_position)
    check(encounter.total_shots==shots,"Transition stops new attacks")
    fork._age=fork.lifetime+1
    fork._physics_process(0)
    check(not fork.is_queued_for_deletion(),"Visible fork does not expire abruptly during departure")
    camera.adopt_view(camera.global_position-Vector2(0,4000),Vector2.ONE)
    camera.force_update_scroll()
    encounter._physics_process(.1)
    check(enemy.is_queued_for_deletion() and fork.is_queued_for_deletion(),"Art is removed only after camera leaves it behind")
    await process_frame
    check(encounter.enemies().is_empty() and encounter.get_node("Projectiles").get_child_count()==0,"Offscreen departure fully cleans up")
    encounter.reset()
    check(not encounter.departing,"Retry clears departure state")
    print("HELL_EXIT_ENEMY_DEPARTURE failures=",failures)
    quit(1 if failures else 0)
