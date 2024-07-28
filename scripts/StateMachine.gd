class_name StateMachine 
extends Node

const KEEP_CURRENT := -1

var enabled := true

var current_state: int = -1:
	set(v):
		owner.transition_state(current_state, v)
		current_state = v
		state_time = 0
var last_state : int = -1

var state_time: float

func _ready() -> void:
	await owner.ready
	current_state = 0
	
func _physics_process(delta: float) -> void:
	if enabled:
		while true:
			var next := owner.get_next_state(current_state) as int
			if  next == KEEP_CURRENT:
				break;
			else:
				last_state = current_state
				current_state = next
		
		owner.tick_physics(current_state, delta)
		state_time += delta
