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

enum Size {
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

@export var curr_size := Size.SMALL as Size:
	set(v):
		print_debug(
		"Size: [%s] %s => %s" % [
		Engine.get_physics_frames(),
		Size.keys()[curr_size],
		Size.keys()[v]
	])
		curr_size = v
		
@export var direction := Direction.RIGHT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		sprite_2d.scale.x = direction

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick := false
var action_requested := RequestableAction.NONE
var can_enlarge := false
var can_onfire := false
var transforming_fire := false
var direction_before_turn := Direction.RIGHT

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var small_animator: AnimationPlayer = $SmallAnimator
@onready var big_animator: AnimationPlayer = $BigAnimator
@onready var fire_animator: AnimationPlayer = $FireAnimator
@onready var state_machine: StateMachine = $StateMachine

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		action_requested = RequestableAction.JUMP
	if event.is_action_released("jump"):
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2
		if action_requested == RequestableAction.JUMP:
			action_requested = RequestableAction.NONE


func tick_physics(state: State, delta: float) -> void:
		
	match state:
		State.IDLE:
			move(default_gravity, delta)
		State.WALK, State.TURN:
			# 动画播放速度与走路速度正相关
			_get_animator().speed_scale = max(MIN_ANIMATION_SPEED, abs(velocity.x) / WALK_SPEED * 2)
			move(default_gravity, delta)
		State.JUMP:
			move(0.0 if is_first_tick else default_gravity, delta)
		State.FALL:
			move(default_gravity, delta)
	is_first_tick = false


func get_next_state(state: State) -> int:
	var should_enlarge := can_enlarge and curr_size == Size.SMALL
	if should_enlarge:
		return State.ENLARGE
	
	var should_onfire := can_onfire and curr_size == Size.LARGE
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
			if not transforming_fire:
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
			curr_size = Size.LARGE
			can_enlarge = false
			_reset_animator(big_animator)
			small_animator.play("enlarge")
		State.ONFIRE:
			curr_size = Size.FIRE
			can_onfire = false
			_reset_animator(fire_animator)
			_onfire()
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

func _onfire() -> void:
	transforming_fire = true
	big_animator.stop()
	var yValues = [48, 192, 240, 144, 48] # 四个不同颜色的马里奥y值
	var currRect := sprite_2d.get_region_rect()
	# 循环播放四次
	for i in range(4):
		for yValue in yValues:
			currRect.position.y = yValue
			sprite_2d.set_region_rect(currRect)
			# 等0.07秒
			await get_tree().create_timer(0.07).timeout
	transforming_fire = false
	
func _eat(item: Node) -> void:
	print_debug("Eatting: %s" % item.name)
	if item is Mushroom:
		if item.mushroom_type == GameManager.SPAWN_ITEM.UPGRADE:
			can_enlarge = true
		elif item.mushroom_type == GameManager.SPAWN_ITEM.LIFE:
			# 奖命
			print_debug("Bonus Life!")
	if item is Flower:
		if curr_size == Size.LARGE:
			can_onfire = true
		else :
			can_enlarge = true

func _get_animator() -> AnimationPlayer:
	if curr_size == Size.SMALL:
		return small_animator
	elif curr_size == Size.LARGE:
		return big_animator
	elif curr_size == Size.FIRE:
		return fire_animator
	return null


func _reset_animator(animator: AnimationPlayer) -> void:
	animator.speed_scale = 1
