class_name ShoreBackdrop
extends Node2D
## 岸边挪动后，用作者原图保留的水下重合区域接回海底，避免露出空带。
@export_node_path("Sprite2D") var art_path: NodePath = ^"Art"
@export var ocean_seam_y: float = 0.0
@export var overlap_pixels: float = 96.0
var _authored_height: float = 0.0
var _walls: Sprite2D
var _ocean_material: ShaderMaterial

func _ready() -> void:
	update_coverage()
	process_priority=40

func _process(_delta: float) -> void:
	if _ocean_material!=null:
		var art:=get_node(art_path) as Sprite2D
		_ocean_material.set_shader_parameter("shore_origin",art.global_position)
		_ocean_material.set_shader_parameter("shore_size",Vector2(1920,3240)*art.global_scale)
		_ocean_material.set_shader_parameter("seam_y",get_parent().to_global(Vector2(0,ocean_seam_y)).y)
		_ocean_material.set_shader_parameter("world_scale",global_scale.y)

func update_coverage() -> void:
	var art := get_node(art_path) as Sprite2D
	var original := art.texture as AtlasTexture
	if original == null:
		return
	if _authored_height == 0.0:
		_authored_height = original.region.size.y
	var local_atlas := original.duplicate() as AtlasTexture
	var required_bottom := ocean_seam_y - position.y + overlap_pixels
	var required_height := (required_bottom - art.position.y) / art.scale.y
	local_atlas.region.size.y = clampf(maxf(_authored_height, required_height), 0, original.atlas.get_height() - original.region.position.y)
	art.texture = local_atlas
	# 重合区域末端柔和接回原海底颜色，避免补回图像后产生新的水平硬接缝。
	var join_material := ShaderMaterial.new()
	join_material.shader = preload("res://shaders/shore_join.gdshader")
	var atlas_height := float(original.atlas.get_height())
	join_material.set_shader_parameter("fade_start", (local_atlas.region.end.y - overlap_pixels * 0.6) / atlas_height)
	join_material.set_shader_parameter("fade_end", local_atlas.region.end.y / atlas_height)
	art.material = join_material
	var outline=preload("res://modules/environment/wall_outline.gd").read(original.atlas,2250)
	if _walls==null:
		_walls=Sprite2D.new()
		_walls.name="ShoreWalls"
		_walls.centered=false
		_walls.z_index=11
		add_child(_walls)
	_walls.texture=local_atlas
	_walls.position=art.position
	_walls.scale=art.scale
	var wall_material:=ShaderMaterial.new()
	wall_material.shader=preload("res://shaders/shore_walls.gdshader")
	wall_material.set_shader_parameter("edges",outline)
	wall_material.set_shader_parameter("fade_start",(local_atlas.region.end.y-overlap_pixels*0.6)/atlas_height)
	wall_material.set_shader_parameter("fade_end",local_atlas.region.end.y/atlas_height)
	_walls.material=wall_material
	var ocean_art:=get_parent().get_node_or_null("Foreground/Art") as Sprite2D
	if ocean_art!=null:
		_ocean_material=ShaderMaterial.new()
		_ocean_material.shader=preload("res://shaders/ocean_wall_join.gdshader")
		_ocean_material.set_shader_parameter("shore_art",original.atlas)
		_ocean_material.set_shader_parameter("shore_edges",outline)
		_ocean_material.set_shader_parameter("ocean_edges",preload("res://modules/environment/wall_outline.gd").read(ocean_art.texture))
		ocean_art.material=_ocean_material
		_process(0)
