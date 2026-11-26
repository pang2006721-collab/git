extends SceneTree
class Level extends Node2D:
 signal died
 var dead := false
 var exit_in_progress := false
 var player: Node
var failures := 0
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
 if not ok:
  failures+=1
  push_error(message)
func run():
 root.size=Vector2i(1280,720)
 root.content_scale_size=Vector2i(1920,1080)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var level=Level.new()
 root.add_child(level)
 current_scene=level
 var paint=ColorRect.new()
 paint.color=Color.RED
 paint.size=Vector2(1920,1080)
 level.add_child(paint)
 var actor=Node.new()
 actor.name="Demon"
 level.add_child(actor)
 level.player=actor
 var history=load("res://modules/cinematic/run_retrospective.gd").new()
 level.add_child(history)
 await create_timer(0.6).timeout
 check(history.recent[&"hell"].size()>=2,"real replay continues recording")
 if not history.recent[&"hell"].is_empty():
  var image=Image.new()
  check(image.load_jpg_from_buffer(history.recent[&"hell"][-1])==OK,"replay JPEG decodes")
  check(image.get_size()==Vector2i(640,360),"GPU downsamples before readback")
  check(image.get_pixel(320,180).r>0.8 and image.get_pixel(320,180).g<0.2,"replay contains the actual current screen")
 paint.color=Color.GREEN
 await create_timer(0.5).timeout
 if not history.recent[&"hell"].is_empty():
  var image=Image.new()
  image.load_jpg_from_buffer(history.recent[&"hell"][-1])
  check(image.get_pixel(320,180).g>0.8 and image.get_pixel(320,180).r<0.2,"replay updates instead of keeping a stale screen")
 level.died.emit()
 check(history.deaths[&"hell"]==1 and not history.failures[&"hell"].is_empty(),"death history and first failure remain available")
 history.frozen=true
 await process_frame
 var count: int=history.recent[&"hell"].size()
 await create_timer(0.3).timeout
 check(history.recent[&"hell"].size()==count,"handoff freeze stops capture")
 print("RETROSPECTIVE_CAPTURE_FAILURES=",failures)
 quit(failures)
