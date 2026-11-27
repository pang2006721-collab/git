extends Node
## 快捷入口只定位到正式地图原有入口，不加载旧原型地图。
const SURFACE = preload("res://modules/environment/hell_surface.gd")
@onready var level: Node2D = get_parent()

func start_segment(index: int) -> void:
    var entry = level.get_node("WallEntry")
    var camera: FollowCamera = level.camera
    # 对齐正常开场完成后的 1.35 倍视野；先设缩放，再计算入口构图和边界。
    camera.zoom = Vector2.ONE * 1.35
    if index == 1:
        entry.reset_for_replay()
        camera.set_follow_target(level.soul,true)
        camera.set_process(true)
        camera.make_current()
        Bgm.play_track(Bgm.Track.HELL)
        entry.play()
    elif index == 2:
        entry.reset_for_replay()
        entry.completed = true
        level.soul.hide()
        level.awake = true
        level.sleeping.hide()
        level.zzz.hide()
        level.demon.get_node("Visual").show()
        level.demon.get_node("Host").take_control()
        level.player = level.demon
        level.possession.state = PossessionController.State.POSSESSED
        level.possession.enabled = false
        level.demon.global_position = SURFACE.landing_on(level.get_node("Platforms/Breakable09"))+Vector2(0,-3)
        level.demon.velocity = Vector2.ZERO
        level.demon.reset_physics_interpolation()
        level.get_node("RisingLava").start_at_checkpoint(level.demon)
        camera.set_follow_target(level.demon,true)
        camera.set_process(true)
        camera.make_current()
        Bgm.play_track(Bgm.Track.HELL)

    elif index == 7:
        _start_upper_sky()
        var layout := level.get_node("OceanLink/FishStage/JungleLayout")
        var cloud := layout.get_node("SkyCloudExit")
        var bird := layout.get_node("Bird")
        bird.position = Vector2(960,cloud.height_at("sky",960)+15)
        bird.velocity = Vector2.ZERO
        bird.reset_physics_interpolation()
        camera.set_follow_target(bird,true)
        level.get_node("RunRetrospective").recording_enabled = false
        cloud._enter()

    elif index == 6:
        _start_upper_sky()

    elif index in [3,4,5]:
        entry.reset_for_replay()
        entry.completed = true
        level.soul.hide()
        level.demon.hide()
        level.sleeping.hide()
        level.zzz.hide()
        level.awake = true
        level.possession.enabled = false
        level.get_node("CameraAttention").enabled = false
        level.get_node("FlyingEnemies").enabled = false
        level.get_node("FlyingEnemies").reset()
        level.get_node("Fork").set_physics_process(false)
        level.get_node("Fork").set_process_unhandled_input(false)
        var link := level.get_node("OceanLink")
        link.stage = link.Stage.OCEAN
        var stage := link.get_node("FishStage")
        stage.activate()
        stage.fish.position = Vector2(960,32400)
        stage.fish.reset_physics_interpolation()
        stage.host.take_control()
        stage.possession.state = PossessionController.State.POSSESSED
        stage.possession.enabled = false
        stage._on_transfer_finished(stage.host)
        var boss := stage.get_node("JellyfishBoss")
        boss.enabled = index==3
        boss._start_y = stage.fish.global_position.y+boss.ascent_before_entrance
        boss._has_baseline = true
        camera.set_follow_target(stage.fish,true)
        camera.set_process(true)
        camera.make_current()
        if index==3:
            boss._begin_entrance()
        else:
            var shore := stage.get_node("ShoreExit")
            var squirrel := stage.get_node("JungleLayout/Squirrel")
            shore.start_on_shore(squirrel.global_position.x+120)
            stage.get_node("JungleLayout")._update_nearby()
            stage.get_node("JungleHandoff")._physics_process(0)
            stage.get_node("JunglePossession")._physics_process(0)
            camera.set_follow_target(stage.fish,true)
        if index==5:
            var layout := stage.get_node("JungleLayout")
            var squirrel := layout.get_node("Squirrel")
            var possession := stage.get_node("JunglePossession")
            possession.clear_selection()
            possession.state = PossessionController.State.POSSESSED
            possession.enabled = false
            possession.soul.hide()
            squirrel.get_node("Host").take_control()
            level.player = squirrel
            stage.get_node("ShoreExit").release_soul()
            layout.get_node("CanopyTransition").preview_from_top_vine()
        Bgm.play_track(Bgm.Track.OCEAN)

func _start_upper_sky() -> void:
    # 重载后的全新场景，直接使用天空宿主，不触发树冠跳出或附身过场。
    level.get_node("WallEntry").reset_for_replay()
    level.get_node("OceanCheckpoint").restore_player()
    var stage := level.get_node("OceanLink/FishStage")
    stage.host.reset()
    stage.fish.get_node("Patrol").stop()
    stage.fish.get_node("Input").enabled=false
    stage.fish.get_node("Movement").enabled=false
    stage.fish.get_node("Teleport").enabled=false
    stage.fish.hide()
    var shore := stage.get_node("ShoreExit")
    shore.state=shore.State.DEAD
    var layout := stage.get_node("JungleLayout")
    var bird := layout.get_node("Bird")
    var possession := layout.get_node("CanopyPossession")
    possession.enabled=false
    possession.state=PossessionController.State.POSSESSED
    possession.clear_selection()
    bird.get_node("Host").take_control()
    bird.get_node("Boost").reset()
    bird.position=Vector2(960,layout.get_node("SkyCloudExit").height_at("sky",960)+1300)
    bird.velocity=Vector2.ZERO
    bird.reset_physics_interpolation()
    bird.show()
    layout.get_node("CanopyBirdStage")._finished(bird.get_node("Host"))
    level.camera.set_follow_target(bird,true)
    level.camera.set_process(true)
    level.camera.make_current()
    Bgm.play_track(Bgm.Track.SKY)
