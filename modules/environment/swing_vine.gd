class_name SwingVine
extends Node2D
## 分段软绳：固定上端，抓取处受力，末端自然滞后；接口兼容攀爬模块。
@export var length: float = 700.0
@export var gravity: float = 1900.0
@export var damping: float = 0.2
@export var grab_radius: float = 110.0
@export var distance_gain: float = 0.5
@export_range(8,48) var segment_count: int = 24
@export_range(4,16) var solver_iterations: int = 10
var angle: float = 0.0
var angular_velocity: float = 0.0
var rider: CharacterBody2D
var grip_length: float = 0.0
var climb_axis: float = 0.0
var pump_axis: float = 0.0
var rider_offset := Vector2(0,60)
var rope: VerletRope2D
var _ribbon: VineRibbon
var _rider_velocity:=Vector2.ZERO

func _ready() -> void:
	add_to_group("swing_vines")
	rope=VerletRope2D.new()
	rope.initialize(length,segment_count)
	var source:=get_node_or_null("Art") as Sprite2D
	if source!=null:
		_ribbon=VineRibbon.new()
		add_child(_ribbon)
		_ribbon.configure(source,segment_count)
		_ribbon.update_points(rope.points)

func closest_grip(world_hands: Vector2) -> Vector2:
	return to_global(rope.sample(rope.closest_distance(to_local(world_hands))))

func can_grab(world_hands: Vector2) -> bool:
	return rider==null and world_hands.distance_to(closest_grip(world_hands))<=grab_radius*global_scale.x

func catch(body: CharacterBody2D,incoming_velocity: Vector2,jump_origin: Vector2) -> void:
	rider=body
	grip_length=rope.closest_distance(to_local(body.global_position-rider_offset))
	rope.load_index=clampi(roundi(grip_length/rope.segment_length),1,segment_count)
	var distance:=jump_origin.distance_to(closest_grip(body.global_position-rider_offset))
	var gain:=1.0+distance_gain*clampf(distance/900.0,0,1.5)
	var tangent:=_tangent(grip_length)
	var direction:=signf(incoming_velocity.dot(tangent))
	if direction==0:
		direction=signf(body.global_position.x-jump_origin.x)
	var impulse:Vector2=(incoming_velocity+tangent*direction*incoming_velocity.length()*0.15)*gain
	var local_velocity:=to_local(global_position+impulse)-to_local(global_position)
	rope.add_velocity(grip_length,local_velocity)
	_rider_velocity=incoming_velocity

func release() -> Vector2:
	var velocity:=_rider_velocity
	rider=null
	rope.load_index=-1
	climb_axis=0
	pump_axis=0
	return velocity

func _physics_process(delta: float) -> void:
	var before:=to_global(rope.sample(grip_length))
	if is_instance_valid(rider):
		grip_length=clampf(grip_length+climb_axis*310.0*delta,35,length)
		rope.load_index=clampi(roundi(grip_length/rope.segment_length),1,segment_count)
	rope.gravity=gravity/maxf(global_scale.y,0.01)
	rope.damping=damping
	rope.iterations=solver_iterations
	rope.simulate(delta,pump_axis*1000.0/maxf(global_scale.x,0.01))
	var point:=rope.sample(grip_length if is_instance_valid(rider) else length)
	var old_angle:=angle
	angle=atan2(point.x,point.y)
	angular_velocity=(angle-old_angle)/maxf(delta,0.0001)
	if is_instance_valid(rider):
		var after:=to_global(rope.sample(grip_length))
		_rider_velocity=((after-before)/maxf(delta,0.0001)).limit_length(1700)
		var collision:=rider.move_and_collide(after+rider_offset-rider.global_position)
		if collision!=null:
			rope.correct_point(rope.load_index,to_local(rider.global_position-rider_offset))
			_rider_velocity*=0.3
		rider.velocity=_rider_velocity

func _tangent(distance: float) -> Vector2:
	var local:=rope.sample(distance+5)-rope.sample(maxf(distance-5,0))
	var along:Vector2=(to_global(local)-global_position).normalized()
	return Vector2(along.y,-along.x)

func _process(_delta: float) -> void:
	if _ribbon!=null:
		_ribbon.update_points(rope.points)

func reset() -> void:
	rider=null
	rope.reset()
	angle=0
	angular_velocity=0
	rotation=0
	climb_axis=0
	pump_axis=0
	_rider_velocity=Vector2.ZERO
	if _ribbon!=null:
		_ribbon.update_points(rope.points)
