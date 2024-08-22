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
	SHELL,
	SHOOT,
	RECOVERING,
	DEAD,
}

const SHOOTABLE_STATE := [State.SHELL, State.RECOVERING]
const SPEED := 30.0
const SHOOT_SPEED := 150.0
const JUMP_VELOCITY := -230.0
const SCORE := {
	"stomped" : 100,
	"hit": 200,
	"charged": 200,
	"bumped": 100,
	"shoot_on_shell": 400,
	"shoot_on_recover": 500,
}

# 原始颜色，顺序为龟壳、龟肉、龟壳边缘
const COLOR_ORIGIN := [
	Vector4(0.12, 0.52, 0.0, 1.0),
	Vector4(0.84, 0.55, 0.13, 1.0),
	Vector4(1.0, 1.0, 1.0, 1.0),
]

const COLOR_RED := [
	Vector4(0.61, 0.15, 0.13, 1.0),
	Vector4(0.84, 0.55, 0.13, 1.0),
	Vector4(1.0, 1.0, 1.0, 1.0),
]

const COLOR_CYAN := [
	Vector4(0.11, 0.40, 0.46, 1.0),
	Vector4(0.51, 0.22, 0.06, 1.0),
	Vector4(0.98, 0.73, 0.67, 1.0)
]

@export var iq: IQ
@export var type: Type

@onready var recover_timer: Timer = $RecoverTimer
@onready var wake_up_timer: Timer = $WakeUpTimer
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D


func _ready() -> void:
	await state_machine.initial_state_set
	await GameManager.world_ready
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if type == Type.FLY:
		state_machine.current_state = Type.FLY
	if iq == IQ.SMART:
		# 改颜色
		floor_checker.enabled = true
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_RED.duplicate())
	elif GameManager.current_world_type in [GameManager.WorldType.UNDER, GameManager.WorldType.CASTLE]:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())

func get_next_state(state: State) -> int:
	if hit or charged or bumped:
		return State.DEAD if state != State.DEAD else state_machine.KEEP_CURRENT
		
	match state:
		State.WALK:
			if stomped:
				return State.SHELL
		State.FLY:
			if stomped:
				return State.WALK
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
			if wake_up_timer.time_left == 0:
				return State.WALK
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	if is_on_wall() or (is_on_floor() and floor_checker.enabled and not floor_checker.is_colliding()):
		direction = Direction.LEFT if direction == Direction.RIGHT else Direction.RIGHT
	
	match state:
		State.WALK:
			move(SPEED, direction, delta)
		State.FLY:
			if is_on_floor():
				# 碰到地就跳
				velocity.y = JUMP_VELOCITY
			move(SPEED, direction, delta, default_gravity / 2)
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
		State.FLY:
			animation_player.play("fly")
		State.SHELL:
			stomped = false
			recover_timer.start()
			direction = Direction.RIGHT if direction == Direction.LEFT else Direction.LEFT
			animation_player.play("shell")
			ScoreManager.add_score(SCORE["stomped"], self)
		State.SHOOT:
			stomped = false
			floor_checker.enabled = false
			# 不再碰到敌人反弹
			set_collision_mask_value(3, false)
			animation_player.play("shell")
			match from:
				State.SHELL:
					ScoreManager.add_score(SCORE["shoot_on_shell"], self)
				State.RECOVERING:
					ScoreManager.add_score(SCORE["shoot_on_recover"], self)
		State.RECOVERING:
			wake_up_timer.start()
			animation_player.play("recovering")
		State.DEAD:
			animation_player.play("shell")
			if charged:
				ScoreManager.add_score(SCORE["charged"], self)
			elif hit:
				ScoreManager.add_score(SCORE["hit"], self)
			elif bumped:
				ScoreManager.add_score(SCORE["bumped"], self)
			die(false)

# 被踩
func on_stomped(player: Player) -> void:
	stomped = true
	if state_machine.current_state != State.FLY:
		direction = Direction.LEFT if player.global_position.x > global_position.x else Direction.RIGHT
	if state_machine.current_state in SHOOTABLE_STATE:
		SoundManager.play_sfx("Kill")
	else:
		SoundManager.play_sfx("Stomp")
	if state_machine.current_state not in SHOOTABLE_STATE:
		# 给玩家施加一个向上小跳的力
		player.velocity.y = PLAYER_STOMPED_BOUNCE
