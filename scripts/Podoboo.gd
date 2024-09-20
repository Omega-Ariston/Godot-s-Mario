class_name Podoboo
extends Enemy

enum State {
	WAIT,
	JUMP,
	FALL,
}

const JUMP_SPEED := -550

@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D
@onready var timer: Timer = $Timer

var can_jump := false

func get_next_state(state: State) -> int:
	match state:
		State.WAIT:
			if can_jump:
				return State.JUMP
		State.JUMP:
			if velocity.y > 0:
				return State.FALL
		State.FALL:
			if global_position.y >= Variables.BOTTOM_BOUNDARY + sprite_2d.get_rect().size.y:
				return State.WAIT
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	match state:
		State.JUMP, State.FALL:
			move(0, 0, delta)


func transition_state(_from: State, to: State) -> void:
	match to:
		State.JUMP:
			can_jump = false
			velocity.y = JUMP_SPEED
			sprite_2d.scale.y = 1
		State.FALL:
			sprite_2d.scale.y = -1
		State.WAIT:
			timer.start()
			velocity.y = 0

# 被踩
func on_stomped() -> void:
	player.hurt(self)
	
# 被无敌星撞或被龟壳撞
func on_charged(_body: CharacterBody2D) -> void:
	pass
	
# 被火球打
func on_hit(body: Fireball) -> void:
	body.on_hit_enemy()

func _on_timer_timeout() -> void:
	can_jump = true
