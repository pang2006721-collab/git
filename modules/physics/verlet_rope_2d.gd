class_name VerletRope2D
extends RefCounted
## 独立的二维软绳求解器：Verlet 预测位置，分段距离约束保持绳长。
var points := PackedVector2Array()
var previous := PackedVector2Array()
var segment_length: float
var segments: int = 24
var iterations: int = 10
var gravity: float = 1900.0
var damping: float = 0.2
var load_index: int = -1
var _last_step: float = 1.0 / 240.0

func initialize(rope_length: float, count: int) -> void:
	segments=maxi(count,4)
	segment_length=rope_length/segments
	points.resize(segments+1)
	previous.resize(segments+1)
	reset()

func reset() -> void:
	for i in range(segments+1):
		points[i]=Vector2(0,segment_length*i)
		previous[i]=points[i]
	load_index=-1
	_last_step=1.0/240.0

func simulate(delta: float, sideways_acceleration: float = 0.0) -> void:
	if delta<=0.0:
		return
	var count:=maxi(1,ceili(minf(delta,0.1)*240.0))
	var step:=minf(delta,0.1)/count
	for substep in range(count):
		for i in range(1,segments+1):
			var position:=points[i]
			var velocity:Vector2=(position-previous[i])/maxf(_last_step,0.0001)
			previous[i]=position
			var force:=Vector2(0,gravity)
			if i==load_index:
				force.x=sideways_acceleration
			points[i]=position+velocity.limit_length(2200)*exp(-damping*step)*step+force*step*step
		_last_step=step
		for pass_index in range(iterations):
			points[0]=Vector2.ZERO
			for i in range(segments):
				_solve_pair(i,i+1,segment_length,1.0)
			# 轻微抗折叠，保留绳身弯曲和自由末端的滞后运动。
			for i in range(segments-1):
				_solve_pair(i,i+2,segment_length*2,0.006)
		points[0]=Vector2.ZERO
		previous[0]=Vector2.ZERO

func _solve_pair(a: int,b: int,rest: float,strength: float) -> void:
	var difference:=points[b]-points[a]
	var distance:=difference.length()
	if distance<0.00001:
		return
	var wa:=_inverse_mass(a)
	var wb:=_inverse_mass(b)
	var correction:=difference*((distance-rest)/distance)*strength/(wa+wb)
	points[a]+=correction*wa
	points[b]-=correction*wb

func _inverse_mass(index: int) -> float:
	if index==0:
		return 0.0
	return 0.04 if index==load_index else 1.0

func sample(distance: float) -> Vector2:
	var f:=clampf(distance/segment_length,0,segments)
	var i:=mini(int(f),segments-1)
	return points[i].lerp(points[i+1],f-i)

func closest_distance(point: Vector2,minimum: float=35.0) -> float:
	var best:=INF
	var along:=minimum
	for i in range(segments):
		var closest:=Geometry2D.get_closest_point_to_segment(point,points[i],points[i+1])
		var distance:=point.distance_squared_to(closest)
		var fraction:=points[i].distance_to(closest)/maxf(points[i].distance_to(points[i+1]),0.001)
		var candidate:float=(i+fraction)*segment_length
		if candidate>=minimum and distance<best:
			best=distance
			along=candidate
	return clampf(along,minimum,segment_length*segments)

func add_velocity(distance: float,velocity: Vector2) -> void:
	var index:=clampi(roundi(distance/segment_length),1,segments)
	for i in range(maxi(1,index-2),mini(segments,index+2)+1):
		var influence:=exp(-pow(float(i-index),2)*0.6)
		previous[i]-=velocity.limit_length(1800)*_last_step*influence

func correct_point(index: int,position: Vector2) -> void:
	var correction:=position-points[index]
	points[index]=position
	previous[index]+=correction*0.8
