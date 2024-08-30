class_name Beetle
extends Enemy

enum State {
	WALK,
	SHELL,
	SHOOT,
	RECOVERING,
	DEAD,
}

const SHOOTABLE_STATE := [State.SHELL, State.RECOVERING]
const SPEED := 30.0
const SHOOT_SPEED := 150.0
const SCORE := {
	"stomped" : 100,
	"charged": 200,
	"bumped": 100,
	"shoot_on_shell": 400,
	"shoot_on_recover": 1000,
}

# 原始颜色，顺序为壳、肉、壳边
const COLOR_ORIGIN := [
	Vector4(0.0, 0.0, 0.0, 1.0),
	Vector4(1.0, 0.78, 0.72, 1.0),
	Vector4(0.6, 0.29, 0.04, 1.0),
]

const COLOR_CYAN := [
	Vector4(0.06, 0.19, 0.22, 1.0),
	Vector4(0.68, 0.91, 0.91, 1.0),
	Vector4(0.11, 0.40, 0.46, 1.0)
]

const COLOR_GREY := [
	Vector4(0.33, 0.33, 0.33, 1.0),
	Vector4(1.0, 1.0, 1.0, 1.0),
	Vector4(0.65, 0.65, 0.65, 1.0)
]

@onready var recover_timer: Timer = $RecoverTimer
@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D


func _ready() -> void:
	await GameManager.world_ready
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == GameManager.WorldType.UNDER:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
	elif GameManager.current_world_type == GameManager.WorldType.CASTLE:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_GREY.duplicate())
	else:
		sprite_material.set_shader_parameter("shader_enabled", false)

func get_next_state(state: State) -> int:
	if charged or bumped:
		return State.DEAD if state != State.DEAD else state_machine.KEEP_CURRENT
		
	match state:
		State.WALK:
			if stomped:
				return State.SHELL
		State.SHOOT:
			if stomped:
				return State.SHELL
		State.SHELL:
			if stomped:
				return State.SHOOT
			if recover_timer.time_left == 0:
				return State.RECOVERING
		State.RECOVERING:
			if stomped:
				return State.SHOOT
			if not animation_player.is_playing():
				return State.WALK
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	if is_on_wall():
		direction = Direction.LEFT if direction == Direction.RIGHT else Direction.RIGHT
	
	match state:
		State.WALK:
			move(SPEED, direction, delta)
		State.SHOOT:
			if is_on_wall():
				SoundManager.play_sfx("Bump")
			move(SHOOT_SPEED, direction, delta)
		State.SHELL, State.RECOVERING:
			velocity = Vector2.ZERO
		State.DEAD:
			move(DEAD_BOUNCE.x, attack_direction, delta)


func transition_state(from: State, to: State) -> void:
	match from:
		State.SHOOT:
			set_collision_mask_value(3, true)
		
	match to:
		State.WALK:
			stomped = false
			velocity = Vector2.ZERO
			animation_player.play("walk")
		State.SHELL:
			stomped = false
			recover_timer.start()
			direction = Direction.RIGHT if direction == Direction.LEFT else Direction.LEFT
			animation_player.play("shell")
			ScoreManager.add_score(SCORE["stomped"], self)
		State.SHOOT:
			stomped = false
			# 不再碰到敌人反弹
			set_collision_mask_value(3, false)
			animation_player.play("shell")
			match from:
				State.SHELL:
					ScoreManager.add_score(SCORE["shoot_on_shell"], self)
				State.RECOVERING:
					ScoreManager.add_score(SCORE["shoot_on_recover"], self)
		State.RECOVERING:
			animation_player.play("recovering")
		State.DEAD:
			animation_player.play("shell")
			if charged:
				ScoreManager.add_score(SCORE["charged"], self)
			elif bumped:
				ScoreManager.add_score(SCORE["bumped"], self)
			die(false)

# 被踩
func on_stomped(player: Player) -> void:
	stomped = true
	direction = Direction.LEFT if player.global_position.x > global_position.x else Direction.RIGHT
	if state_machine.current_state in SHOOTABLE_STATE:
		SoundManager.play_sfx("Kill")
	else:
		SoundManager.play_sfx("Stomp")
	if state_machine.current_state not in SHOOTABLE_STATE:
		# 给玩家施加一个向上小跳的力
		player.velocity.y = PLAYER_STOMPED_BOUNCE

# 被火球打
func on_hit(body: CharacterBody2D) -> void:
	pass
