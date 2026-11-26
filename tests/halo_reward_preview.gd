extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func run():
    var preview=load("res://scenes/previews/halo_reward_preview.tscn").instantiate()
    root.add_child(preview)
    preview.set_process(false)
    preview.sample(.5)
    check(preview.god_halo.visible and not preview.soul_halo.visible,"Starts with one floating halo")
    preview.sample(2.5)
    check(preview.god_halo.position.y<200,"God's halo rises before splitting")
    preview.sample(3.6)
    check(preview.soul_halo.visible and preview.soul_halo.position.distance_to(preview.god_halo.position)>250,"Two halos separate in the air")
    preview.sample(4.8)
    check(preview.god_halo.position.distance_to(preview.GOD_HOME)<12,"One halo settles back on God")
    preview.sample(6.8)
    check(preview.soul_halo.position.distance_to(preview.SOUL_HOME)<30,"Other halo lands on the ghost")
    preview.sample(8.5)
    check(preview.face.happiness==1 and preview.soul_halo.visible,"Ghost finishes with happy eyes and a halo")
    check(preview.soul.scale==Vector2.ONE*1.8,"Duang returns to the original body proportions")
    var previous_god:Vector2=Vector2.ZERO
    var previous_soul:Vector2=Vector2.ZERO
    var previous_visible:bool=false
    var max_step:float=0.0
    var max_head_overlap:float=-INF
    for frame in range(505):
        var t:float=float(frame)/60.0
        preview.sample(t)
        if frame>0:
            max_step=maxf(max_step,preview.god_halo.position.distance_to(previous_god))
            if previous_visible and preview.soul_halo.visible:
                max_step=maxf(max_step,preview.soul_halo.position.distance_to(previous_soul))
        check(absf(preview.soul.scale.x*preview.soul.scale.y-3.24)<.001,"Ghost squash/stretch conserves its drawn body area")
        if t>=5.35:
            var head_y:float=preview.soul.position.y-90.0*preview.soul.scale.y
            var halo_bottom:float=preview.soul_halo.position.y+43.0*preview.soul_halo.scale.y
            max_head_overlap=maxf(max_head_overlap,halo_bottom-head_y)
        previous_god=preview.god_halo.position
        previous_soul=preview.soul_halo.position
        previous_visible=preview.soul_halo.visible
    check(max_step<55,"60 FPS playback has fast motion without a position reset or teleport")
    check(max_head_overlap<5,"Impact halo catches the head rather than passing through the ghost")
    preview.sample(2.25)
    check(preview.soul_halo.scale.x*preview.soul_halo.scale.y>1.5,"New halo visibly overshoots on its duang entrance")
    preview.sample(8.0)
    check(preview.soul.scale==Vector2.ONE*1.8,"Secondary reaction fully returns to its rest pose")
    preview.oranges_total=99
    preview.sample(8.5)
    check(not preview.soul_halo.visible and preview.face.happiness==0,"Below one hundred does not start the reward")
    print("HALO_REWARD_PREVIEW_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
