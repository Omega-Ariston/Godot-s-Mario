class_name MainCamera
extends Camera2D

enum State {
	STOP,
	SLOW_FOLLOW,
	CHASE,
	SMOOTH_RIGHT, # 结局动画中使用
}

const SPEED_SLOW_FOLLOW := 45.0
const SLOW_FOLLOW_X := Variables.TILE_SIZE.x * 5.5
const CHASE_X := Variables.TILE_SIZE.x * 7.5

var player: Player

var smooth_right_speed : float

@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func get_next_state(state: State) -> int:
	match state:
		State.STOP:
			if player.get_global_transform_with_canvas().origin.x >= SLOW_FOLLOW_X and player.velocity.x > 0:
				return State.SLOW_FOLLOW
		State.SLOW_FOLLOW:
			if player.get_global_transform_with_canvas().origin.x >= CHASE_X:
				return State.CHASE
			if player.velocity.x <= 0:
				return State.STOP
		State.CHASE:
			if player.velocity.x <= 0:
				return State.STOP
				
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	match state:
		State.SLOW_FOLLOW:
			position.x += delta * min(player.velocity.x, SPEED_SLOW_FOLLOW)
		State.CHASE:
			position.x += delta * player.velocity.x
		State.STOP:
			reset_camera_center()
		State.SMOOTH_RIGHT:
			position.x += delta * smooth_right_speed

func transition_state(_from: State, _to: State) -> void:
	pass

func smooth_move_right(speed: float) -> void:
	smooth_right_speed = speed
	state_machine.current_state = State.SMOOTH_RIGHT

func reset_camera_center() -> void:
	position.x = get_screen_center_position().x
