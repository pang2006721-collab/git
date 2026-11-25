extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok: failures.append(message);push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    game.get_node("CameraAttention").enabled=false
    game.died.disconnect(game.get_node("DeathFlow")._on_death)
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet","SurfaceGrab"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout=stage.get_node("JungleLayout")
    var bird=layout.get_node("Bird")
    bird.get_node("Host").take_control()
    bird.get_node("Movement").set_physics_process(false)
    bird.get_node("Patrol").set_physics_process(false)
    game.player=bird
    var sky=layout.get_node("SkyEagle")
    sky.set_process(false)
    var hail=sky.get_node("Hail")
    hail.set_physics_process(false)
    hail._rng.seed=43
    game.camera.zoom=Vector2.ONE
    game.camera.global_position=bird.global_position
    game.camera.set_process(false)

    bird.get_node("Input").external_control=false
    var fire=bird.get_node("Boost")
    fire.set_physics_process(false)
    fire.tick(3.0,false)
    check(not fire.is_burning() and is_equal_approx(fire.heat,.5),"Bird gradually charges and reddens without Shift")
    fire.tick(.2,true)
    check(not fire.is_burning(),"Half-red bird cannot ignite before accumulating a full charge")
    fire.tick(3.1,false)
    fire.tick(.2,true)
    check(fire.is_burning() and fire.heat<1.0,"Fully charged bird can release flame")
    fire.tick(1.0,true)
    check(not fire.is_burning() and fire.heat>0,"Duration cap ends flame without wasting all saved heat")
    fire.tick(6.1,true)
    fire.tick(.1,true)
    check(not fire.is_burning() and fire.heat==1,"Holding Shift cannot relight automatically after refill")
    fire.tick(.01,false)
    fire.tick(.1,true)
    check(fire.is_burning(),"A fresh press releases the replenished flame")
    hail._spawn_row()
    var stone:Dictionary=hail.stones[0]
    for other in hail.stones.slice(1): other.art.queue_free()
    hail.stones.clear()
    hail.stones.append(stone)
    bird.global_position=stone.art.global_position+Vector2(0,40)
    var old_scale:Vector2=stone.art.scale
    var heat_before: float=fire.heat
    hail._physics_process(.01)
    check(is_equal_approx(heat_before,fire.heat),"Contact does not prepay or instantly complete the entire ice block")
    check(not game.dead and stone.get("melting",false),"Burning contact starts melting without killing bird")
    var paid_heat:float=fire.heat
    var point:Vector2=stone.art.global_position
    hail._physics_process(.15)
    check(stone.art.scale.x<old_scale.x and stone.art.scale.x>0,"Hail shrinks gradually instead of instantly disappearing")
    check(stone.art.global_position.y<bird.global_position.y and absf(stone.art.global_position.x-bird.global_position.x)<1,"Melting hail settles on top of the bird")
    bird.global_position.x+=80
    hail._physics_process(.1)
    check(absf(stone.art.global_position.x-bird.global_position.x)<1,"Melting block moves with the bird head")
    check(is_equal_approx(paid_heat-fire.heat,.4*.25/.8),"Heat is transferred gradually in proportion to actual melting time")
    hail._physics_process(.56)
    check(not hail.stones.has(stone) and not game.dead,"Sustained flame fully melts the block safely")
    check(is_equal_approx(paid_heat-fire.heat,.4),"Complete melt consumes exactly forty percent in total")
    hail.reset()
    fire.reset()
    fire.heat=1.0
    fire.tick(.01,true)
    hail._spawn_row()
    var solid:Dictionary=hail.stones[0]
    for other in hail.stones.slice(1): other.art.queue_free()
    hail.stones.clear()
    hail.stones.append(solid)
    bird.global_position=solid.art.global_position+Vector2(0,40)
    hail._previous_target=bird.global_position
    hail._physics_process(.001)
    hail._physics_process(.15)
    var partial_scale:Vector2=solid.art.scale
    fire.heat=.001
    hail._physics_process(.05)
    check(game.dead and game.death_reason==&"hail","Running out of heat under an unfinished block kills the bird immediately")
    check(hail.stones.has(solid) and not solid.melting and solid.art.scale==partial_scale,"Lethal unfinished ice stays visible and does not disappear")
    var death_position:Vector2=solid.art.global_position
    hail._physics_process(.1)
    check(solid.art.global_position.y>death_position.y,"Ice continues falling after crushing bird")
    check(fire.heat==0 and not fire.burning,"Death resets accumulated heat and burning")
    print("BIRD_FIRE_MELT_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
