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
    preview.oranges_total=99
    preview.sample(8.5)
    check(not preview.soul_halo.visible and preview.face.happiness==0,"Below one hundred does not start the reward")
    print("HALO_REWARD_PREVIEW_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
