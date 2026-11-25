extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("FlyingEnemies").enabled=false
    game.get_node("RisingLava").set_physics_process(false)
    game.demon.get_node("Host").take_control()
    game.player=game.demon
    game.demon.get_node("Movement").set_physics_process(false)
    game.died.disconnect(game.get_node("DeathFlow")._on_death)
    var weapon=game.get_node("Fork")
    weapon.set_physics_process(false)
    var parry=weapon.get_node("Parry")
    parry.set_physics_process(false)
    game.demon.global_position=Vector2(9900,10000)
    weapon.flying=true
    weapon.fork.show()
    weapon.fork.global_position=Vector2(10000,10000)
    weapon.fork.rotation=0
    parry._physics_process(0)
    var enemy=load("res://scenes/enemies/enemy_fork.tscn").instantiate()
    enemy.encounter=game.get_node("FlyingEnemies")
    game.get_node("FlyingEnemies/Projectiles").add_child(enemy)
    enemy.set_physics_process(false)
    enemy.position=Vector2(10000,9850)
    enemy.gravity=0
    enemy.velocity=Vector2(0,2000)
    enemy.rotation=0
    enemy._physics_process(.15)
    check(enemy.deflected and enemy.visible and not enemy.is_queued_for_deletion(),"Fast crossing enemy fork is deflected rather than disappearing")
    check(enemy.velocity.x>0 and enemy.velocity.y<0,"Enemy fork rebounds upward and away from player")
    var angle:float=enemy.rotation
    var before:Vector2=enemy.position
    enemy._physics_process(.1)
    check(enemy.position!=before and absf(enemy.rotation-angle)>1,"Deflected fork keeps flying and visibly spins")
    enemy.position=game.demon.global_position+Vector2(-100,-56)
    enemy.velocity=Vector2(2000,0)
    enemy._physics_process(.1)
    check(not game.dead,"Reflected projectile cannot hurt protagonist")
    weapon.flying=false
    check(not parry.try_deflect(enemy,Vector2(10000,9900),Vector2(10000,10100)),"Inactive player weapon cannot parry")
    enemy.queue_free()
    var missed=load("res://scenes/enemies/enemy_fork.tscn").instantiate()
    missed.encounter=game.get_node("FlyingEnemies")
    game.get_node("FlyingEnemies/Projectiles").add_child(missed)
    missed.set_physics_process(false)
    weapon.flying=true
    weapon.fork.hide()
    check(not parry.try_deflect(missed,Vector2(10000,9900),Vector2(10000,10100)),"Hidden fork cannot provide invisible protection")
    weapon.fork.show()
    check(not parry.try_deflect(missed,Vector2(10300,9900),Vector2(10300,10100)),"Nearby but separated trajectories do not parry")
    missed.position=Vector2(10000,9900)
    missed.rotation=0
    weapon.fork.position=Vector2(10200,10000)
    parry._previous=Transform2D(0,Vector2(9800,10000))
    parry._was_active=true
    check(parry.try_deflect(missed,Vector2(10000,9980),Vector2(10000,9980)),"Swept player weapon also detects high-speed crossing")
    weapon.reset()
    check(weapon.fork.scale.is_equal_approx(Vector2.ONE),"Replay restores weapon recoil scale")
    print("FORK_PARRY_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
