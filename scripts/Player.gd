class_name Player
extends CharacterBody2D

const WALK_SPEED := 90.0
const WALK_ACCELERATION := WALK_SPEED / 0.2
const AIR_ACCELERATION := WALK_SPEED / 0.3
const JUMP_VELOCITY := -320.0

enum State {
	IDLE,
	WALK,
	RUN,
	JUMP,
	FALL,
	ENLARGE,
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
	State.IDLE, State.WALK, State.RUN
]

@export var curr_size := Size.SMALL as Size
@export var direction := Direction.RIGHT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		sprite_2d.scale.x = direction

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var can_control := true
var is_first_tick := false
var action_requested := RequestableAction.NONE
var can_enlarge := false

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var small_animator: AnimationPlayer = $SmallAnimator
@onready var big_animator: AnimationPlayer = $BigAnimator

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
		State.WALK:
			move(default_gravity, delta)
		State.RUN:
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
	
	var can_jump := is_on_floor()
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
			if is_still:
				return State.IDLE
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
		State.FALL:
			if is_on_floor():
				return State.WALK
		State.ENLARGE:
			curr_size = Size.LARGE
			if not small_animator.is_playing():
				return State.IDLE
	return StateMachine.KEEP_CURRENT

func transition_state(from: State, to: State) -> void:
	print_debug(
		"[%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to]
	])
	match to:
		State.IDLE:
			_get_animator().play("idle")
		State.WALK:
			_get_animator().play("walk")
		State.JUMP:
			_get_animator().play("jump")
			velocity.y = JUMP_VELOCITY
			action_requested = RequestableAction.NONE
		State.FALL:
			_get_animator().play("jump")
		State.ENLARGE:
			can_enlarge = false
			_get_animator().play("enlarge")
	is_first_tick = true
	
func move(gravity: float, delta: float) -> void:
	var movement := Input.get_axis("move_left", "move_right")
	var acceleration := WALK_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, movement * WALK_SPEED, acceleration * delta)
	velocity.y += gravity * delta
		
	if not is_zero_approx(movement):
		direction = Direction.LEFT if movement < 0 else Direction.RIGHT
	
	move_and_slide()
	global_position.x = max(global_position.x, GameManager.max_left_x + 8)
	
func stand(gravity: float, delta:float) -> void:
	var acceleration := WALK_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += gravity * delta
	
	move_and_slide()
	global_position.x = max(global_position.x, GameManager.max_left_x + 8)
	
func _eat(item: Eatable) -> void:
	print_debug("Eatting: %s" % item.name)
	if item is Mushroom:
		if item.mushroom_type == GameManager.SPAWNABLE.MUSHROOM_BIG:
			can_enlarge = true
		elif item.mushroom_type == GameManager.SPAWNABLE.MUSHROOM_LIFE:
			# 奖命
			print_debug("Bonus Life!")

func _get_animator() -> AnimationPlayer:
	if curr_size == Size.SMALL:
		return small_animator
	elif curr_size == Size.LARGE:
		return big_animator
	return null
