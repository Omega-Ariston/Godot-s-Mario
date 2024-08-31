class_name Bullet
extends Enemy

const SCORE := 200

enum State {
	FLY,
	DEAD,
}

const SPEED := 80

@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func get_next_state(state: State) -> int:
	if state == State.FLY and stomped:
		return State.DEAD
			
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	match state:
		State.FLY:
			move(SPEED, direction, delta, 0.0)
		State.DEAD:
			move(0, direction, delta)
	

func transition_state(_from: State, to: State) -> void:
	match to:
		State.FLY:
			SoundManager.play_sfx("Fireworks")
		State.DEAD:
			die()
		
# 被无敌星撞或被龟壳撞
func on_charged(_body: CharacterBody2D) -> void:
	pass

# 被火球打
func on_hit(_body: CharacterBody2D) -> void:
	pass

# 被砖块从下面顶
func on_bumped(_bumpable: Bumpable) -> void:
	pass

func die(_pause := false) -> void:
	SoundManager.play_sfx("Kill")
	ScoreManager.add_score(SCORE, self)
	# 速度归0，并上移两个像素
	velocity = Vector2.ZERO
	global_position.y -= 2
	# 禁用碰撞
	hurtbox.set_deferred("monitoring", false)
	# 来到屏幕前面
	z_index = DEAD_Z_INDEX
