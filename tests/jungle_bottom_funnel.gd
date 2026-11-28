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
    var layout=game.get_node("OceanLink/FishStage/JungleLayout")
    layout.get_node("BeeEncounter").enabled=false
    layout.set_process(false)
    var body=layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    game.player=body
    body.set_physics_process(false)
    body.get_node("VineClimber").detach(false)
    body.get_node("VineClimber").set_physics_process(false)
    body.get_node("Movement").set_physics_process(false)
    body.get_node("FallDeath").set_physics_process(false)
    layout.get_node("SoftSideReturn").set_physics_process(false)
    for vine in layout.vines:vine.set_physics_process(false)
    body.collision_layer=2
    body.collision_mask=32
    var funnel=layout.get_node("BottomFunnel")
    await physics_frame
    for side in [-1,1]:
        body.position=Vector2(420 if side<0 else 1500,funnel.floor_y-3)
        var hit=body.move_and_collide(Vector2(side*900,0),true)
        assert(hit!=null,"Bottom cannot be walked out of")
        body.position=Vector2(-200 if side<0 else 2120,funnel.floor_y-1350)
        body.velocity=Vector2(0,800)
        var touched:bool=false
        for i in 360:
            body.velocity.y=minf(body.velocity.y+2200.0/120.0,1600)
            body.move_and_slide()
            touched=touched or body.is_on_wall()
            if body.is_on_floor():break
            await physics_frame
        assert(touched,"Outside fall actually touches a steep slide")
        assert(body.position.x>180 and body.position.x<1740,"Slide carries the squirrel into the visible bottom")
        assert(body.is_on_floor(),"Slide rejoins the existing bank")
        assert(not game.dead,"Test disables death only to measure slide geometry")
        body.position=Vector2(80 if side<0 else 1840,funnel.floor_y-2000)
        assert(body.move_and_collide(Vector2(side*300,0),true)==null,"Higher swing space stays open")
    assert(body.get_node("FallDeath").fatal_drop_pixels==1500)
    print("JUNGLE_BOTTOM_FUNNEL_PASS: actual both-side collision slides, ground exit blocked, upper space open, 1500 threshold")
    quit()
