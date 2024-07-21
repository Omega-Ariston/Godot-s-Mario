class_name Player
extends CharacterBody2D

const WALK_SPEED := 90.0
const WALK_ACCELERATION := WALK_SPEED / 0.2
const AIR_ACCELERATION := WALK_SPEED / 0.3
const JUMP_VELOCITY := -320.0

enum State {
	IDLE_SMALL,
	WALK_SMALL,
	RUN_SMALL,
	JUMP_SMALL,
	FALL_SMALL,
	ENLARGE,
	IDLE_LARGE,
	WALK_LARGE,
	RUN_LARGE,
	JUMP_LARGE,
	FALL_LARGE,
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
	State.IDLE_SMALL, State.WALK_SMALL, State.RUN_SMALL
]

const SMALL_STATES := [
	State.IDLE_SMALL, State.WALK_SMALL, State.RUN_SMALL, State.JUMP_SMALL, State.FALL_SMALL
]

const LARGE_STATES := [
	State.IDLE_LARGE, State.WALK_LARGE, State.RUN_LARGE, State.JUMP_LARGE, State.FALL_LARGE
]

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
@onready var animation_player: AnimationPlayer = $AnimationPlayer

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
		State.IDLE_SMALL, State.IDLE_LARGE:
			move(default_gravity, delta)
		State.WALK_SMALL, State.WALK_LARGE:
			move(default_gravity, delta)
		State.RUN_SMALL, State.RUN_LARGE:
			move(default_gravity, delta)
		State.JUMP_SMALL, State.JUMP_LARGE:
			move(0.0 if is_first_tick else default_gravity, delta)
		State.FALL_SMALL, State.FALL_LARGE:
			move(default_gravity, delta)
	is_first_tick = false

func get_next_state(state: State) -> int:
	var should_enlarge := can_enlarge and state in SMALL_STATES
	if should_enlarge:
		return State.ENLARGE
	
	var can_jump := is_on_floor()
	var should_jump := can_jump and action_requested == RequestableAction.JUMP
	if should_jump:
		if state in SMALL_STATES:
			return State.JUMP_SMALL
		elif state in LARGE_STATES:
			return State.JUMP_LARGE
		
	if state in GROUND_STATES and not is_on_floor():
		return State.FALL_SMALL
		
	var movement := Input.get_axis("move_left", "move_right")
	var is_still := is_zero_approx(movement) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE_SMALL:
			if not is_still:
				return State.WALK_SMALL
		State.WALK_SMALL:
			if is_still:
				return State.IDLE_SMALL
		State.JUMP_SMALL:
			if velocity.y >= 0:
				return State.FALL_SMALL
		State.FALL_SMALL:
			if is_on_floor():
				return State.WALK_SMALL
		State.ENLARGE:
			if not animation_player.is_playing():
				return State.IDLE_LARGE
		State.IDLE_LARGE:
			if not is_still:
				return State.WALK_LARGE
		State.WALK_LARGE:
			if is_still:
				return State.IDLE_LARGE
		State.JUMP_LARGE:
			if velocity.y >= 0:
				return State.FALL_LARGE
		State.FALL_LARGE:
			if is_on_floor():
				return State.WALK_LARGE
	return StateMachine.KEEP_CURRENT

func transition_state(from: State, to: State) -> void:
	print_debug(
		"[%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to]
	])
	match to:
		State.IDLE_SMALL:
			animation_player.play("idle_small")
		State.WALK_SMALL:
			animation_player.play("walk_small")
		State.JUMP_SMALL:
			animation_player.play("jump_small")
			velocity.y = JUMP_VELOCITY
			action_requested = RequestableAction.NONE
		State.FALL_SMALL:
			animation_player.play("jump_small")
		State.ENLARGE:
			can_enlarge = false
			animation_player.play("enlarge")
		State.IDLE_LARGE:
			animation_player.play("idle_large")
		State.WALK_LARGE:
			animation_player.play("walk_large")
		State.JUMP_LARGE:
			animation_player.play("jump_large")
			velocity.y = JUMP_VELOCITY
			action_requested = RequestableAction.NONE
		State.FALL_LARGE:
			animation_player.play("jump_large")
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

func _freeze_character() -> void:
	print_debug("stop")
	can_control = false
	
func _unfreeze_character() -> void:
	print_debug("continue")
	can_control = true
