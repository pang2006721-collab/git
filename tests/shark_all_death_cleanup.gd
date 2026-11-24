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
    var stage = game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.host.take_control()
    stage._on_transfer_finished(stage.host)
    stage.set_physics_process(false)
    stage.fish.get_node("Movement").enabled = false
    stage.fish.global_position=game.to_global(Vector2(960,33000))
    game.camera.set_follow_target(stage.fish,true)
    var shark = stage.get_node("Shark")
    shark.set_physics_process(false)
    shark.set_process(false)
    for reason in [&"tentacle",&"jellyfish_net",&"pink_shark",&"shark",&"stranded",&"impact"]:
        for dashing in [false,true]:
            game.dead = false
            shark.reset()
            shark.enabled = true
            shark._begin_lock()
            if dashing:
                shark._physics_process(.5)
                shark._begin_dash()
            game.dead = true
            game.death_reason = reason
            stage._on_player_died()
            var fixed: Vector2 = shark.global_position
            shark._physics_process(.2)
            shark._process(.2)
            check(shark.state!=shark.State.WAITING and shark.visible and not shark.enabled,"Every death cause preserves current sharks: "+str(reason))
            if dashing: check(shark.global_position!=fixed,"Committed shark keeps advancing after death")
            shark.enabled=true
            check(not shark.enabled,"Recovery cannot re-enable damage on a finishing attack")
            for i in 300: shark._physics_process(.02)
            check(shark.state==shark.State.WAITING and not shark.visible,"Attack exits naturally after death")
    game.dead = false
    shark.reset()
    shark.enabled = true
    shark._begin_lock()
    shark._physics_process(.5)
    shark._begin_dash()
    game.dead = true
    shark._physics_process(.1)
    check(shark.visible and shark.state==shark.State.DASHING and not shark.enabled,"Shark self-check preserves a committed dash even before death callback")
    print("SHARK_ALL_DEATH_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
