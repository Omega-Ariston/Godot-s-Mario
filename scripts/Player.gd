class_name Player
extends CharacterBody2D

const WALK_SPEED := 100.0
const WALK_ACCELERATION := WALK_SPEED / 0.4
const AIR_ACCELERATION := WALK_SPEED / 0.3
const JUMP_VELOCITY := -320.0
const MIN_ANIMATION_SPEED := 0.8
const MIN_TURN_SPEED = WALK_SPEED / 1.5

enum State {
	IDLE,
	WALK,
	TURN,
	JUMP,
	FALL,
	ENLARGE,
	ONFIRE,
	HURT,
}

enum Mode {
	SMALL,
	LARGE,
	FIRE
}

enum Direction {
	LEFT = -1,
	RIGHT = +1
}

enum RequestableAction {
	NONE,
	JUMP,
	FIRE
}

const GROUND_STATES := [
	State.IDLE, State.WALK, State.TURN
]

const TRANSFORM_STATES := [
	State.ENLARGE, State.ONFIRE, State.HURT
]

@export var curr_mode := Mode.SMALL as Mode:
	set(v):
		print_debug(
		"Mode: [%s] %s => %s" % [
		Engine.get_physics_frames(),
		Mode.keys()[curr_mode],
		Mode.keys()[v]
	])
		curr_mode = v
		
@export var direction := Direction.RIGHT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		sprite_2d.scale.x = direction

var is_first_tick := false
var action_requested := RequestableAction.NONE
var can_enlarge := false
var can_onfire := false
var direction_before_turn := Direction.RIGHT
var is_invincible := false

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var small_animator: AnimationPlayer = $SmallAnimator
@onready var big_animator: AnimationPlayer = $BigAnimator
@onready var fire_animator: AnimationPlayer = $FireAnimator
@onready var blink_animator: AnimationPlayer = $BlinkAnimator
@onready var state_machine: StateMachine = $StateMachine
@onready var on_fire_timer: Timer = $OnFireTimer
@onready var star_timer: Timer = $StarTimer
@onready var invincible_timer: Timer = $InvincibleTimer

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		action_requested = RequestableAction.JUMP
	if event.is_action_released("jump"):
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2
		if action_requested == RequestableAction.JUMP:
			action_requested = RequestableAction.NONE


func tick_physics(state: State, delta: float) -> void:
	if is_invincible:
		if invincible_timer.time_left == 0:
			is_invincible = false
			if state != State.ONFIRE:
				blink_animator.stop()
				_set_shader_enabled(false)
		elif invincible_timer.time_left <= 2 and state != State.ONFIRE:
			blink_animator.play("invincible", -1, 0.25, false)
		
	match state:
		State.IDLE:
			move(GameManager.default_gravity, delta)
		State.WALK, State.TURN:
			# 动画播放速度与走路速度正相关
			_get_animator().speed_scale = max(MIN_ANIMATION_SPEED, abs(velocity.x) / WALK_SPEED * 2)
			move(GameManager.default_gravity, delta)
		State.JUMP:
			move(0.0 if is_first_tick else GameManager.default_gravity, delta)
		State.FALL:
			move(GameManager.default_gravity, delta)
	is_first_tick = false


func get_next_state(state: State) -> int:
	var should_enlarge := (can_enlarge or can_onfire) and curr_mode == Mode.SMALL
	if should_enlarge:
		return State.ENLARGE
	
	var should_onfire := can_onfire and curr_mode == Mode.LARGE
	if should_onfire:
		return State.ONFIRE
	
	var can_jump := is_on_floor() and state not in TRANSFORM_STATES
	var should_jump := can_jump and action_requested == RequestableAction.JUMP
	if should_jump:
		return State.JUMP
		
	if state in GROUND_STATES and not is_on_floor():
		return State.FALL
		
	var movement := Input.get_axis("move_left", "move_right")
	var is_still := is_zero_approx(movement) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if not is_still:
				return State.WALK
		State.WALK:
			if abs(velocity.x) > MIN_TURN_SPEED and velocity.x * direction > 0 and movement * direction < 0:
				return State.TURN
			if is_still:
				return State.IDLE
		State.TURN:
			if movement * direction_before_turn > 0 or is_zero_approx(velocity.x):
				return State.IDLE
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
		State.FALL:
			if is_on_floor():
				return State.WALK
		State.ENLARGE:
			if not small_animator.is_playing():
				return state_machine.last_state
		State.ONFIRE:
			if on_fire_timer.is_stopped():
				return state_machine.last_state
	return StateMachine.KEEP_CURRENT


func transition_state(from: State, to: State) -> void:
	print_debug(
		"State: [%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to]
	])
	
	match from:
		State.WALK:
			_get_animator().speed_scale = 1 # 恢复动画播放速度
		State.FALL:
			_get_animator().speed_scale = 1 # 恢复播放动画
		State.ENLARGE:
			curr_mode = Mode.LARGE
			small_animator.stop()
		State.ONFIRE:
			curr_mode = Mode.FIRE
			blink_animator.stop()
			big_animator.stop()
			if is_invincible:
				blink_animator.play("invincible")
			else:
				_set_shader_enabled(false)
			
	match to:
		State.IDLE:
			_get_animator().play("idle")
		State.WALK:
			_get_animator().play("walk")
		State.TURN:
			_get_animator().play("turn")
			if from not in TRANSFORM_STATES:
				direction_before_turn = direction
		State.JUMP:
			_get_animator().play("jump")
			if from not in TRANSFORM_STATES: # 变身结束后不用跳
				velocity.y = JUMP_VELOCITY
			action_requested = RequestableAction.NONE
		State.FALL:
			if from == State.TURN:
				_get_animator().play("walk") # 空中不能转身停顿
			_get_animator().speed_scale = 0 # 下落时暂停播放动画
		State.ENLARGE:
			can_enlarge = false
			can_onfire = false
			_reset_animator(big_animator)
			small_animator.play("enlarge")
		State.ONFIRE:
			can_onfire = false
			_reset_animator(fire_animator)
			big_animator.stop()
			_set_shader_enabled(true)
			blink_animator.play("onfire", -1, 1.0, false)
			on_fire_timer.start()
	is_first_tick = true
	
	
func move(gravity: float, delta: float) -> void:
	var movement := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(movement):
		direction = Direction.LEFT if movement < 0 else Direction.RIGHT
		
	var acceleration := WALK_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, movement * WALK_SPEED, acceleration * delta)
	velocity.y += gravity * delta
	
	move_and_slide()
	global_position.x = max(global_position.x, GameManager.max_left_x + 8)
	
	
func stand(gravity: float, delta:float) -> void:
	var acceleration := WALK_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += gravity * delta
	
	move_and_slide()
	global_position.x = max(global_position.x, GameManager.max_left_x + 8)

	
func _eat(item: Node) -> void:
	print_debug("Eatting: %s" % item.name)
	if item is Mushroom:
		if item.mushroom_type == GameManager.SPAWN_ITEM.UPGRADE:
			can_enlarge = true
		elif item.mushroom_type == GameManager.SPAWN_ITEM.LIFE:
			print_debug("Bonus Life!")
	elif item is Flower:
		can_onfire = true
	elif item is Star:
		_set_shader_enabled(true)
		blink_animator.play("invincible")
		is_invincible = true
		invincible_timer.start()

func _get_animator() -> AnimationPlayer:
	if curr_mode == Mode.SMALL:
		return small_animator
	elif curr_mode == Mode.LARGE:
		return big_animator
	elif curr_mode == Mode.FIRE:
		return fire_animator
	return null
	
func _set_shader_enabled(enabled: bool) -> void:
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("shader_enabled", enabled)

var color = Color(0.11372549086809, 0.13333334028721, 0.16078431904316)
const COLORS_CLASSIC := [
	Vector4(0.69, 0.20, 0.14, 1.0),
	Vector4(0.41, 0.41, 0.01, 1.0),
	Vector4(0.89, 0.61, 0.14, 1.0),
]

const COLORS_FIRE := [
	Vector4(0.96, 0.83, 0.64, 1.0),
	Vector4(0.70, 0.19, 0.12, 1.0),
	Vector4(0.90, 0.61, 0.12, 1.0),
]

const COLORS_GREEN := [
	Vector4(0.22, 0.51, 0.0, 1.0),
	Vector4(0.90, 0.61, 0.12, 1.0),
	Vector4(1.0, 1.0, 1.0, 1.0),
]

const COLORS_RED := [
	Vector4(0.69, 0.20, 0.14, 1.0),
	Vector4(0.90, 0.61, 0.12, 1.0),
	Vector4(1.0, 1.0, 1.0, 1.0),
]

const COLORS_BLACK := [
	Vector4(0.0, 0.0, 0.0, 1.0),
	Vector4(0.61, 0.29, 0.0, 1.0),
	Vector4(1.0, 0.80, 0.77, 1.0),
]

func _set_shader_colors(color: String) -> void:
	var origin_colors := COLORS_FIRE if curr_mode == Mode.FIRE else COLORS_CLASSIC
	var new_colors: Array = origin_colors if color == "ORIGIN" else self["COLORS_" + color]
	var sprite_material = sprite_2d.material as ShaderMaterial
	print_debug(origin_colors)
	sprite_material.set_shader_parameter("origin_colors", origin_colors)
	sprite_material.set_shader_parameter("new_colors", new_colors)

func _reset_animator(animator: AnimationPlayer) -> void:
	animator.speed_scale = 1
