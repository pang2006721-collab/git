class_name VineRibbon
extends Node2D
## 沿软绳分段变形作者的整条藤蔓图，叶片和绳身使用同一套原图坐标。
var _strips: Array[Polygon2D]=[]
var _region: Rect2
var _left: float
var _right: float

func configure(source: Sprite2D,count: int) -> void:
	# 藤蔓位于松鼠身后，角色保持清楚可见。
	z_index=-1
	var atlas:=source.texture as AtlasTexture
	if atlas==null:
		return
	_region=atlas.region
	_left=source.position.x
	_right=_left+_region.size.x
	for i in range(count):
		var strip:=Polygon2D.new()
		strip.texture=atlas.atlas
		strip.material=source.material
		var top:=_region.position.y+_region.size.y*float(i)/count
		var bottom:=_region.position.y+_region.size.y*float(i+1)/count
		strip.uv=PackedVector2Array([Vector2(_region.position.x,top),Vector2(_region.end.x,top),Vector2(_region.end.x,bottom),Vector2(_region.position.x,bottom)])
		strip.polygons=[PackedInt32Array([0,1,2]),PackedInt32Array([0,2,3])]
		add_child(strip)
		_strips.append(strip)
	source.hide()

func update_points(points: PackedVector2Array) -> void:
	if points.size()!=_strips.size()+1:
		return
	var normals:=PackedVector2Array()
	normals.resize(points.size())
	for i in range(points.size()):
		var tangent:Vector2=(points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
		normals[i]=Vector2(tangent.y,-tangent.x)
	for i in range(_strips.size()):
		_strips[i].polygon=PackedVector2Array([points[i]+normals[i]*_left,points[i]+normals[i]*_right,points[i+1]+normals[i+1]*_right,points[i+1]+normals[i+1]*_left])
