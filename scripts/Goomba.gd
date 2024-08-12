class_name Goomba
extends Enemy

enum State {
	WALK,
	STOMPED,
	DEAD,
}

const SPEED := 30.0
const SCORE := 100

func get_next_state(state: State) -> int:
	match state:
		State.WALK:
			if hit or charged or bumped:
				return State.DEAD
			if stomped:
				return State.STOMPED
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	if is_on_wall():
		direction = Direction.LEFT if direction == Direction.RIGHT else Direction.RIGHT
	
	match state:
		State.WALK:
			move(SPEED, direction, delta)
		State.STOMPED:
			velocity.x = 0.0
		State.DEAD:
			move(DEAD_BOUNCE.x, attack_direction, delta)


func transition_state(_from: State, to: State) -> void:
	match to:
		State.WALK:
			animation_player.play("walk")
		State.STOMPED:
			ScoreManager.add_score(global_position, SCORE, ScoreText.Speed.FAST)
			animation_player.play("stomped")
		State.DEAD:
			die()
