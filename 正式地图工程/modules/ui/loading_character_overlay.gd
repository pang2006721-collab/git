extends CanvasLayer
## 屏幕固定的加载提示，只依赖 begin_loading/finish_loading 两个接口。
signal finished
enum State { IDLE, ENTERING, LOADING, EXITING }
@export_range(0.0, 1.0) var dim_strength: float = 1.0
@export var stagger: float = 0.12
@export var wave_delay: float = 0.15
@export var wave_period: float = 1.65
@export var minimum_loading_time: float = 1.65
var state: State = State.IDLE
var _actors: Array[Node] = []
var _entered_count: int = 0
var _exited_count: int = 0
var _elapsed: float = 0.0
var _wave_time: float = 0.0
var _finish_requested: bool = false
var _dim_done: bool = false
var _fade: Tween

func _ready() -> void:
	_actors = $Layout/Corner.get_children()
	for actor in _actors:
		actor.entered.connect(_actor_entered)
		actor.exited.connect(_actor_exited)
	$Layout/Dim.color.a = 0.0
	visible = false

func begin_loading() -> void:
	if state != State.IDLE:
		return
	state = State.ENTERING
	_entered_count = 0
	_exited_count = 0
	_elapsed = 0.0
	_wave_time = 0.0
	_finish_requested = false
	visible = true
	if is_instance_valid(_fade):
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property($Layout/Dim, "color:a", dim_strength, 0.32)
	for i in range(_actors.size()):
		_actors[i].enter(i * stagger)

func finish_loading() -> void:
	if state == State.IDLE or state == State.EXITING:
		return
	_finish_requested = true

func _actor_entered() -> void:
	_entered_count += 1
	if _entered_count == _actors.size():
		state = State.LOADING

func _process(delta: float) -> void:
	if state == State.ENTERING or state == State.LOADING:
		_elapsed += delta
	if state == State.LOADING:
		_wave_time += delta
		for i in range(_actors.size()):
			_actors[i].wave(_wave_time - i * wave_delay, maxf(wave_period, 0.8))
		if _finish_requested and _elapsed >= minimum_loading_time:
			_start_exit()

func _start_exit() -> void:
	state = State.EXITING
	_dim_done = false
	for i in range(_actors.size()):
		_actors[i].leave(i * stagger)
	if is_instance_valid(_fade):
		_fade.kill()
	_fade = create_tween()
	_fade.tween_interval(0.30)
	_fade.tween_property($Layout/Dim, "color:a", 0.0, maxf(0.55, stagger * (_actors.size() - 1)))
	_fade.tween_callback(_dim_finished)

func _actor_exited() -> void:
	_exited_count += 1
	_try_finish()

func _dim_finished() -> void:
	_dim_done = true
	_try_finish()

func _try_finish() -> void:
	if not _dim_done or _exited_count != _actors.size():
		return
	state = State.IDLE
	visible = false
	finished.emit()
