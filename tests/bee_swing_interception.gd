extends SceneTree
var failures: Array[String]=[]
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok: failures.append(message); push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.set_physics_process(false)
    game.get_node("WallEntry").reset_for_replay()
    game.get_node("WallEntry").completed=true
    var stage=game.get_node("OceanLink/FishStage")
    stage.activate()
    stage.set_physics_process(false)
    for name in ["Shark","Octopus","PinkSharks","SideTentacle","JellyfishBoss","BossTentacleNet"]:
        stage.get_node(name).process_mode=Node.PROCESS_MODE_DISABLED
    var layout=stage.get_node("JungleLayout")
    var body=layout.get_node("Squirrel")
    body.get_node("Host").take_control()
    game.player=body
    body.set_physics_process(false)
    body.get_node("Movement").set_physics_process(false)
    body.get_node("VineClimber").set_physics_process(false)
    game.camera.set_process(false)
    var manager=layout.get_node("BeeEncounter")
    var vine=body.get_node("VineClimber").vine
    vine.global_position=Vector2(960,27000)
    var old_hits: int=0
    var new_hits: int=0
    for ranged in [false,true]:
        for angle in [-.7,.7]:
            for incoming in [-1100.0,1100.0]:
                for upgraded in [false,true]:
                    var probe=Probe.new()
                    probe.manager=manager
                    probe.body=body
                    root.add_child(probe)
                    vine.rider=body
                    vine.grip_length=320
                    vine.rope.load_index=roundi(vine.grip_length/vine.rope.segment_length)
                    var tangent:=Vector2(cos(angle),-sin(angle))
                    for i in vine.rope.points.size():
                        var p:=Vector2(0,vine.rope.segment_length*i).rotated(-angle)
                        vine.rope.points[i]=p
                        vine.rope.previous[i]=p-tangent*incoming*(float(i)/vine.rope.load_index)/120.0
                    body.global_position=vine.to_global(vine.rope.sample(vine.grip_length))+vine.rider_offset
                    body.velocity=tangent*incoming
                    body.get_node("Visual").rotation=0
                    var origin: Vector2=manager.target_position()+Vector2(-500,-100)
                    var enemy: Node2D
                    if ranged:
                        enemy=Node2D.new()
                        enemy.set_script(manager.STINGER)
                    else:
                        enemy=CharacterBody2D.new()
                        enemy.set_script(manager.BEE)
                    enemy.encounter=probe
                    root.add_child(enemy)
                    enemy.set_physics_process(false)
                    enemy.global_position=origin
                    if ranged:
                        if not upgraded:
                            enemy.speed=820
                            enemy.gravity=180
                            enemy.turn_rate=2.6
                            enemy.tracking_seconds=1.2
                        enemy.launch(manager.intercept_target(origin,enemy.speed))
                    else:
                        if not upgraded:
                            enemy.dart_speed=950
                            enemy.dart_turn_rate=3.2
                            enemy.dart_tracking_seconds=.55
                            enemy.dart_seconds=.7
                        enemy._set_mode(enemy.Mode.WINDUP)
                        enemy._aim=manager.target_position()
                    var start: Vector2=body.global_position
                    var travelled: float=0
                    for tick in 240:
                        vine.pump_axis=signf(body.velocity.x)*2.2
                        vine._physics_process(1.0/120.0)
                        body._process(1.0/120.0)
                        travelled=maxf(travelled,start.distance_to(body.global_position))
                        game.camera.global_position=body.global_position
                        enemy._physics_process(1.0/120.0)
                        if probe.hit or enemy.is_queued_for_deletion(): break
                        if not ranged and enemy.mode==enemy.Mode.RECOVERING: break
                    check(travelled>60,"Target genuinely moves on the real Verlet vine during the attack")
                    if probe.hit:
                        if upgraded: new_hits+=1
                        else: old_hits+=1
                    enemy.free()
                    probe.free()
    print("SWING_INTERCEPT_OLD_HITS=",old_hits,"/8 NEW_HITS=",new_hits,"/8")
    check(new_hits>=6 and new_hits>old_hits,"Improved interception hits substantially more swinging targets")
    print("BEE_SWING_INTERCEPTION_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
class Probe extends Node2D:
    var manager: Node
    var body: CharacterBody2D
    var hit: bool=false
    func can_simulate() -> bool: return not hit
    func bee_deflected() -> void: pass
    func player_spinning() -> bool: return false
    func is_active() -> bool: return not hit
    func is_on_screen(_point: Vector2) -> bool: return true
    func target_position() -> Vector2: return manager.target_position()
    func predicted_target(seconds: float) -> Vector2: return manager.predicted_target(seconds)
    func intercept_target(origin: Vector2,speed: float,lead: float=.3) -> Vector2: return manager.intercept_target(origin,speed,lead)
    func defeat_player() -> void: hit=true
    func enemies() -> Array: return []
    func flight_bounds() -> Rect2: return Rect2(0,20000,1920,9500)
