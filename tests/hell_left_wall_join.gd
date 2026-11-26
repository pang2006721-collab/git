extends SceneTree
var failures:Array[String]=[]
func _initialize():run.call_deferred()
func check(ok:bool,message:String):
    if not ok:failures.append(message);push_error(message)
func run():
    var game=load("res://scenes/levels/formal_hell_entry.tscn").instantiate()
    root.add_child(game)
    var wall=game.get_node("WorldLayers/Walls/Left/Tile24")
    var rock=game.get_node("Terrain/Rock06/RockArt03")
    var mat:ShaderMaterial=wall.material
    check(wall.position==Vector2(2,49110),"Wall tile stays at original position")
    check(mat!=null and mat.shader.resource_path=="res://shaders/hell_left_rock_join.gdshader","Affected junction uses its own local seam cleanup")
    check(mat.get_shader_parameter("rock_art")==rock.texture,"Junction samples the same original rock artwork")
    check(mat.get_shader_parameter("wall_origin")==wall.position-Vector2(0,1),"Shader registration includes the texture seam-protection row")
    var center:Vector2=mat.get_shader_parameter("rock_center")
    check(center.distance_to(game.to_local(rock.global_position))<.01,"Restored join color is registered to actual rock position")
    check(absf(float(mat.get_shader_parameter("rock_scale"))-rock.scale.x)<.0001 and rock.flip_h,"Rock scale and facing remain aligned with cleanup")
    check(game.get_node("WorldLayers/Walls/Right/Tile24").material==null,"Other wall is unchanged")
    check(game.get_node("WorldLayers/Walls/Left/Tile25").material.shader.resource_path=="res://shaders/hell_start_wall_outline.gdshader","Earlier opening outline repair is retained")
    print("HELL_LEFT_WALL_JOIN_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
