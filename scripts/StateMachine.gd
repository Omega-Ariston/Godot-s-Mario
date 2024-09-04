class_name StateMachine 
extends Node

const KEEP_CURRENT := -1
const MAX_STATES_SIZE := 10 # 最大存储的历史状态个数

var enabled := true

var current_state: int = -1:
	set(v):
		owner.transition_state(current_state, v)
		current_state = v
		state_time = 0
		
var past_states : Array = [] # 记录状态转换历史，方便回溯

var state_time: float

signal initial_state_set

func _ready() -> void:
	await owner.ready
	current_state = 0
	initial_state_set.emit()
	
func _physics_process(delta: float) -> void:
	if enabled:
		while true:
			var next := owner.get_next_state(current_state) as int
			if  next == KEEP_CURRENT:
				break;
			else:
				past_states.append(current_state)
				if past_states.size() > MAX_STATES_SIZE:
					past_states.pop_front()
				current_state = next
		
		owner.tick_physics(current_state, delta)
		state_time += delta

func get_last_safe_state(isSafe: Callable = func (_state : int): return true) -> int:
	var last_safe_state = 0
	for i in range(past_states.size() - 1, -1, -1):
		if isSafe.bind(past_states[i]).call() == true:
			last_safe_state = past_states[i]
			break
	return last_safe_state
