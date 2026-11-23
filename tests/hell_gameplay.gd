extends SceneTree
var failed := 0
func check(value: bool, label: String) -> void:
    if not value:
        push_error(label)
        failed += 1
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    var game = load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    await create_timer(0.9).timeout
    check(game.get_node("WallEntry").completed, "Vertical entry completes")
    check(absf(game.soul.position.x - 240) < 1, "Entry stays at lower left")
    check(not game.awake and game.zzz.visible, "Demon sleeps before approach")
    game.soul.position = game.demon.position + Vector2(-100,0)
    await physics_frame
    await physics_frame
    check(game.awake and not game.zzz.visible, "Approach wakes demon")
    check(game.possession.request_possession(), "Existing possession can start")
    await create_timer(0.7).timeout
    check(game.demon.get_node("Host").claimed, "Possession transfers control")
    check(game.player == game.demon, "Camera/player handoff uses demon")
    var moving
    var floating
    var brittle
    for platform in game.platforms:
        if platform.kind == "moving": moving=platform
        if platform.kind == "floating": floating=platform
        if platform.kind == "breakable": brittle=platform
    moving.set_physics_process(false)
    moving.progress = 0.5
    moving.direction = 1
    moving._physics_process(0.001)
    var middle_delta: float = moving.progress - 0.5
    moving.progress = 0
    moving._physics_process(0.001)
    check(absf(moving.progress / middle_delta - 0.9) < 0.01, "Platform endpoints run at 90 percent")
    game.demon.get_node("Input").external_control = true
    game.demon.get_node("Input").clear()
    game.demon.position = floating.position + Vector2(0,-30)
    game.demon.velocity = Vector2(0,300)
    await create_timer(0.35).timeout
    check(game.demon.is_on_floor(), "Floating platform carries player")
    check(absf(floating.position.y-floating.origin.y) < 9, "Floating motion remains mild")
    game.demon.position = brittle.position + Vector2(0,-30)
    game.demon.velocity = Vector2(0,300)
    await create_timer(0.2).timeout
    check(brittle.loaded, "Landing triggers fracture")
    await create_timer(1.1).timeout
    check(not brittle.broken, "Platform supports player until 1.5 seconds")
    await create_timer(0.5).timeout
    check(brittle.broken and brittle.collision.disabled, "Platform collapses after fracture")
    game.demon.position = Vector2(1300,51830)
    game.demon.velocity = Vector2.ZERO
    game.demon.get_node("Movement").enabled = false
    var fork = game.get_node("Fork")
    await physics_frame
    await physics_frame
    check(is_instance_valid(fork.selected), "Fork locks from lava platform edge")
    fork._throw()
    await create_timer(0.6).timeout
    check(not fork.flying and fork.held, "Fork hit automatically exchanges and returns the fork")
    check(fork.swapping or fork.launching, "One Shift continues into swap and bounce")
    await create_timer(1.2).timeout
    check(not fork.launching and game.demon.position.y < 51400, "Bounce reaches a platform above target")
    game.restart()
    await physics_frame
    check(not game.awake and not game.demon.get_node("Host").claimed, "Restart restores sleeping demon and possession")
    print("HELL_GAMEPLAY_FAILURES=",failed)
    quit(1 if failed else 0)
