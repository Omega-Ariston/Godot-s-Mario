class_name Turtle
extends Enemy

enum IQ {
	NORMAL,
	SMART,
}

enum Type {
	NORMAL,
	FLY,
}

enum State {
	WALK,
	FLY,
	STOMPED,
	SHOOT,
	RECOVERING,
	DEAD,
}


const SPEED := 30.0
const SHOOT_SPEED := 150.0

@export var iq: IQ
@export var type: Type

@onready var recover_timer: Timer = $RecoverTimer
@onready var wake_up_timer: Timer = $WakeUpTimer

func get_next_state(state: State) -> int:
	match state:
		State.WALK, State.FLY, State.SHOOT:
			if hit or charged or bumped:
				return State.DEAD
			if stomped:
				return State.WALK if state == State.FLY else State.STOMPED
		State.STOMPED:
			if stomped:
				return State.SHOOT
			if recover_timer.time_left == 0:
				return State.RECOVERING
		State.RECOVERING:
			if wake_up_timer.time_left == 0:
				return State.WALK
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	if is_on_wall():
		direction = Direction.LEFT if direction == Direction.RIGHT else Direction.RIGHT
	
	match state:
		State.WALK:
			move(SPEED, direction, delta)
		State.SHOOT:
			move(SHOOT_SPEED, direction, delta)
		State.STOMPED, State.RECOVERING:
			velocity = Vector2.ZERO
		State.DEAD:
			move(DEAD_BOUNCE.x, attack_direction, delta)


func transition_state(_from: State, to: State) -> void:
	match to:
		State.WALK:
			animation_player.play("walk")
		State.FLY:
			animation_player.play("fly")
		State.STOMPED:
			stomped = false
			recover_timer.start()
			direction *= -1
			animation_player.play("stomped")
		State.SHOOT:
			stomped = false
		State.RECOVERING:
			wake_up_timer.start()
			animation_player.play("recovering")
		State.DEAD:
			animation_player.play("stomped")
			die(false)

# 被踩
func on_stomped(player: Player) -> void:
	stomped = true
	direction = Direction.LEFT if player.global_position.x > global_position.x else Direction.RIGHT
	if state_machine.current_state == State.STOMPED:
		SoundManager.play_sfx("Kill")
	else:
		SoundManager.play_sfx("Stomp")
	if state_machine.current_state != State.STOMPED:
		# 给玩家施加一个向上小跳的力
		player.velocity.y = PLAYER_STOMPED_BOUNCE
