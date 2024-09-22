class_name CheapCheap
extends Enemy

const SCORE := 200

enum State {
	FLY,
	DEAD,
}

const SPEED_RANGE := [30, 120]
const JUMP_FORCE := -260.0

@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D

var speed: float

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	speed = GameManager.rng.randf_range(SPEED_RANGE[0], SPEED_RANGE[1])
	if GameManager.rng.randf() > 0.5:
		direction = Direction.LEFT

func get_next_state(state: State) -> int:
	if state == State.FLY and (hit or charged or stomped or shot):
		return State.DEAD
			
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	match state:
		State.FLY:
			move(speed, direction, delta, default_gravity / 4)
		State.DEAD:
			move(0, 0, delta)
	

func transition_state(_from: State, to: State) -> void:
	match to:
		State.FLY:
			velocity.y = JUMP_FORCE
		State.DEAD:
			ScoreManager.add_score(SCORE, self)
			die()
