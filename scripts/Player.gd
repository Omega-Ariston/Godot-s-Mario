class_name Player
extends CharacterBody2D

const WALK_SPEED := 80.0
const DASH_SPEED := WALK_SPEED * 2
const CLIMB_SPEED := 40.0
const WALK_ACCELERATION := WALK_SPEED / 0.4
const DASH_ACCELERATION := WALK_ACCELERATION * 2
const CLIMB_ACCELERATION := CLIMB_SPEED / 0.2
const AIR_ACCELERATION := WALK_SPEED / 0.2
const JUMP_VELOCITY := -350.0
const MIN_ANIMATION_SPEED := 0.8
const MIN_TURN_SPEED := WALK_SPEED / 1.5
const FIREBALL_LIMIT := 2
const CLIFF_LIMIT := Variables.TILE_SIZE.y * 18

enum State {
	IDLE,
	WALK,
	TURN,
	CROUCH,
	CROUCH_JUMP,
	LAUNCH,
	JUMP,
	FALL,
	CLIMB,
	ENLARGE,
	ONFIRE,
	HURT,
	DEAD,
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


const GROUND_STATES := [
	State.IDLE, State.WALK, State.TURN, State.CROUCH
]

const CROUCH_STATES := [
	State.CROUCH, State.CROUCH_JUMP
]

const UNSAFE_STATES := [
	State.ENLARGE, State.ONFIRE, State.HURT, State.LAUNCH
]

@export var curr_mode := Mode.SMALL as Mode:
	set(v):
		if curr_mode != v:
			print_debug(
				"Mode: [%s] %s => %s" % [
				Engine.get_physics_frames(),
				Mode.find_key(curr_mode),
				Mode.find_key(v)
			])
			curr_mode = v
			if not is_node_ready():
				await ready
			match curr_mode:
				Mode.SMALL:
					_reset_animator(big_animator)
					_reset_animator(fire_animator)
				Mode.LARGE:
					_reset_animator(small_animator)
					_reset_animator(fire_animator)
				Mode.FIRE:
					_reset_animator(small_animator)
					_reset_animator(big_animator)
		
@export var direction := Direction.RIGHT:
	set(v):
		if direction != v:
			print_debug(
				"Direction: [%s] %s => %s" % [
				Engine.get_physics_frames(),
				Direction.find_key(direction),
				Direction.find_key(v)
			])
			direction = v
			if not is_node_ready():
				await ready
			# 翻转图像
			graphics.scale.x = direction

var is_first_tick := false
var can_enlarge := false
var can_onfire := false
var can_climb := false
var climbing_object # 可能是藤蔓或旗杆
var crouch_requested := false
var jump_requested := false
var launch_requested := false
var dash_requested := false
var direction_before_turn := Direction.RIGHT
var is_under_star := false # 是否在无敌星作用下
var is_invincible := false # 是否处于受伤后无敌状态
var is_hurt := false # 是否处于受伤状态
var last_animation : String
var controllable := true
var is_spawning := false

# 用于模拟玩家移动
var input_x := 0.0
var input_y := 0.0
var constant_speed_x: float
var constant_speed_y: float

@onready var graphics: Node = $Graphics
@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var small_animator: AnimationPlayer = $SmallAnimator
@onready var big_animator: AnimationPlayer = $BigAnimator
@onready var fire_animator: AnimationPlayer = $FireAnimator
@onready var blink_animator: AnimationPlayer = $BlinkAnimator
@onready var state_machine: StateMachine = $StateMachine
@onready var on_fire_timer: Timer = $OnFireTimer
@onready var star_timer: Timer = $StarTimer
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var dying_timer: Timer = $DyingTimer
@onready var fireball_launcher: ItemLauncher = $Graphics/FireballLauncher

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and is_on_floor(): #防止在空中保存跳跃指令
		jump_requested = true
	if event.is_action_released("jump"):
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2 # 最小跳跃高度
		jump_requested = false
	if event.is_action_pressed("action"):
		launch_requested = true
	if event.is_action_released("action"):
		launch_requested = false
	if event.is_action_pressed("move_down"):
		crouch_requested = true
	if event.is_action_released("move_down"):
		crouch_requested = false


func tick_physics(state: State, delta: float) -> void:
	if is_on_floor():
		# 开始和结束加速都要在地面上判断
		if Input.is_action_pressed("action"):
				dash_requested = true
		else:
			if is_on_floor():
				dash_requested = false
	
	if is_invincible:
		if invincible_timer.time_left == 0:
			is_invincible = false
			graphics.modulate.a = 1
		else:
			# 闪烁角色
			_blink_character()

	if is_under_star:
		if star_timer.time_left == 0:
			is_under_star = false
			if state != State.ONFIRE:
				blink_animator.stop()
				_set_shader_enabled(false)
		elif (SoundManager.bgm_player.stream == SoundManager.starBGM and not SoundManager.bgm_player.playing):
			SoundManager.play_world_bgm()
			if state != State.ONFIRE:
				blink_animator.play("star", -1, 0.25, false)
	
	match state:
		State.IDLE:
			move(GameManager.default_gravity, delta)
		State.WALK, State.TURN:
			# 动画播放速度与走路速度正相关
			_get_animator().speed_scale = max(MIN_ANIMATION_SPEED, abs(velocity.x) / WALK_SPEED * 1.5)
			move(GameManager.default_gravity, delta)
		State.CROUCH:
			stand(GameManager.default_gravity, delta)
		State.JUMP, State.CROUCH_JUMP:
			move(0.0 if is_first_tick else GameManager.default_gravity, delta)
		State.DEAD:
			if dying_timer.time_left == 0:
				move(0.0 if is_first_tick else GameManager.default_gravity, delta)
		State.FALL:
			move(GameManager.default_gravity, delta)
		State.CLIMB:
			if (controllable and Input.is_action_just_pressed("move_right")) \
					or (not controllable and input_x > 0):
				if direction == Direction.LEFT:
					_unclimb()
				if direction == Direction.RIGHT:
					_change_climb_side()
			elif (controllable and Input.is_action_just_pressed("move_left")) \
					or (not controllable and input_x < 0):
				if direction == Direction.RIGHT:
					_unclimb()
				if direction == Direction.LEFT:
					_change_climb_side()
			else:
				# 没爬的时候不动
				_get_animator().speed_scale = min(abs(velocity.y / CLIMB_SPEED), 2.0)
				climb(delta)
		State.LAUNCH:
			move(GameManager.default_gravity, delta)
		State.HURT:
			# 闪烁角色
			_blink_character()
			
	is_first_tick = false


func get_next_state(state: State) -> int:
	if is_spawning:
		return State.IDLE if state != State.IDLE else state_machine.KEEP_CURRENT
	
	if global_position.y > CLIFF_LIMIT or GameManager.is_time_up:
		return State.DEAD if state != State.DEAD else state_machine.KEEP_CURRENT
	
	if is_hurt:
		return State.DEAD if curr_mode == Mode.SMALL else State.HURT
	
	var should_climb := can_climb and state != State.CLIMB
	if should_climb:
		return State.CLIMB
	
	var should_enlarge := (can_enlarge or can_onfire) and curr_mode == Mode.SMALL
	if should_enlarge:
		return State.ENLARGE
	
	var should_onfire := can_onfire and curr_mode == Mode.LARGE
	if should_onfire:
		return State.ONFIRE
	
	var can_crouch := state in GROUND_STATES and state not in UNSAFE_STATES and curr_mode != Mode.SMALL
	var should_crouch := can_crouch and crouch_requested and state not in CROUCH_STATES
	if should_crouch:
		return State.CROUCH
	
	var can_jump := state in GROUND_STATES and state not in UNSAFE_STATES
	var should_jump := can_jump and jump_requested
	if should_jump:
		return State.CROUCH_JUMP if state == State.CROUCH else State.JUMP
		
	if state in GROUND_STATES and not is_on_floor():
		return State.FALL
	
	var can_launch_fireball :=  curr_mode == Mode.FIRE and state not in CROUCH_STATES and state not in UNSAFE_STATES
	var should_launch_fireball := can_launch_fireball and launch_requested and get_tree().get_nodes_in_group("Fireballs").size() < FIREBALL_LIMIT
	if should_launch_fireball:
		return State.LAUNCH
		
	var movement := Input.get_axis("move_left", "move_right") if controllable else input_x
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
			if not _get_animator().is_playing() or movement * direction_before_turn > 0 or is_zero_approx(velocity.x):
				return State.IDLE if is_still else State.WALK
		State.CROUCH:
			if is_on_floor() and crouch_requested == false:
				return State.IDLE
		State.JUMP, State.CROUCH_JUMP:
			if velocity.y >= 0:
				return State.FALL
		State.FALL:
			if is_on_floor():
				return State.IDLE if is_still else State.WALK
		State.CLIMB:
			if can_climb == false:
				return State.FALL if not is_on_floor() else State.WALK
		State.LAUNCH:
			if not fire_animator.is_playing():
				return state_machine.get_last_safe_state(_is_safe_state)
		State.ENLARGE:
			if not small_animator.is_playing():
				return state_machine.get_last_safe_state(_is_safe_state)
		State.ONFIRE:
			if on_fire_timer.is_stopped():
				return state_machine.get_last_safe_state(_is_safe_state)
		State.HURT:
			if not _get_animator().is_playing():
				return state_machine.get_last_safe_state(_is_safe_state)
	return StateMachine.KEEP_CURRENT


func transition_state(from: State, to: State) -> void:
	print_debug(
		"State: [%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to]
	])
	
	match from:
		State.WALK, State.FALL, State.CLIMB:
			_get_animator().speed_scale = 1 # 恢复动画播放速度
		State.ENLARGE:
			# 恢复时间
			get_tree().paused = false
			curr_mode = Mode.LARGE
		State.TURN:
			if not _get_animator().is_playing():
				# 只有刹车状态需要重置速度，其余状态维持原有速度
				velocity.x = 0
		State.ONFIRE:
			# 恢复时间
			get_tree().paused = false
			curr_mode = Mode.FIRE
			blink_animator.stop()
			if is_under_star:
				blink_animator.play("star")
			else:
				_set_shader_enabled(false)
		State.HURT:
			# 恢复时间
			get_tree().paused = false
			curr_mode = Mode.SMALL
			# 进入无敌时间
			is_invincible = true
			invincible_timer.start()
			
	match to:
		State.IDLE:
			_get_animator().play("idle")
		State.WALK:
			_get_animator().play("walk")
		State.TURN:
			# 水平速度越大，转身需要的时间越长，转身速度越慢
			var turn_speed :float = abs(DASH_SPEED / velocity.x)
			_get_animator().play("turn", -1, turn_speed, false)
			if from not in UNSAFE_STATES:
				direction_before_turn = direction
		State.CROUCH:
			_get_animator().play("crouch")
		State.JUMP:
			_get_animator().play("jump")
			if from not in UNSAFE_STATES: # 变身结束或发完炮后不用跳
				velocity.y = JUMP_VELOCITY
				SoundManager.play_sfx("JumpSmall" if curr_mode == Mode.SMALL else "JumpLarge")
			jump_requested = false
		State.CROUCH_JUMP:
			_get_animator().play("crouch")
			SoundManager.play_sfx("JumpSmall" if curr_mode == Mode.SMALL else "JumpLarge")
			if from not in UNSAFE_STATES: # 变身结束后不用跳
				velocity.y = JUMP_VELOCITY
			jump_requested = false
		State.FALL:
			if from in [State.TURN, State.CLIMB]:
				_get_animator().play("walk")
			elif from == State.LAUNCH:
				_get_animator().play(last_animation)
			_get_animator().speed_scale = 0 # 下落时暂停播放动画
		State.CLIMB:
			_get_animator().play("climb")
		State.HURT:
			is_hurt = false
			get_tree().paused = true # 静止游戏场景
			_reset_animator(small_animator)
			_get_animator().play("hurt")
			SoundManager.play_sfx("PipeHurt")
		State.LAUNCH:
			last_animation = fire_animator.current_animation
			launch_requested = false
			fire_animator.play("launch")
			fireball_launcher.launch()
		State.ENLARGE:
			can_enlarge = false
			can_onfire = false
			# 暂停时间
			get_tree().paused = true
			_reset_animator(big_animator)
			small_animator.play("enlarge")
			SoundManager.play_sfx("Upgrade")
		State.ONFIRE:
			can_onfire = false
			# 暂停时间
			get_tree().paused = true
			_reset_animator(fire_animator)
			big_animator.stop()
			_set_shader_enabled(true)
			blink_animator.play("onfire", -1, 1.0, false)
			SoundManager.play_sfx("Upgrade")
			on_fire_timer.start()
		State.DEAD:
			is_hurt = false
			if global_position.y > CLIFF_LIMIT:
				sprite_2d.visible = false # 摔死的时候不让死亡动画被看见
			else:
				# 非摔死的情况下才会冻结屏幕
				get_tree().paused = true # 静止游戏场景
			velocity = Vector2.ZERO
			GameManager.game_timer.stop() # 停止计时
			collision_shape_2d.set_deferred("disabled", true)
			set_process_input(false)
			controllable = false
			big_animator.stop()
			fire_animator.stop()
			small_animator.play("dead")
			SoundManager.pause_bgm()
			SoundManager.play_sfx("MarioDie")
			GameManager.life -= 1
			GameManager.player_current_mode = Mode.SMALL
			# 到前面来
			z_index = 5
			dying_timer.start()
	is_first_tick = true
	
	
func move(gravity: float, delta: float) -> void:
	var movement := Input.get_axis("move_left", "move_right") if controllable else input_x
	if not is_zero_approx(movement) and not is_first_tick and is_on_floor():
		direction = Direction.LEFT if movement < 0 else Direction.RIGHT
	var speed = DASH_SPEED if dash_requested else WALK_SPEED
	var acceleration := AIR_ACCELERATION if not is_on_floor() else DASH_ACCELERATION if dash_requested else WALK_ACCELERATION
	velocity.x = constant_speed_x if constant_speed_x != 0 else move_toward(velocity.x, movement * speed, acceleration * delta)
	velocity.y += gravity * delta
	
	move_and_slide()
	global_position.x = max(global_position.x, GameManager.max_left_x + Variables.TILE_SIZE.x / 2)
	
	
func stand(gravity: float, delta: float) -> void:
	var acceleration := WALK_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += gravity * delta
	
	move_and_slide()
	global_position.x = max(global_position.x, GameManager.max_left_x + 8)
		

func climb(delta:float) -> void:
	var movement := Input.get_axis("move_up", "move_down") if controllable else input_y
	velocity.y = constant_speed_y if constant_speed_y != 0 else move_toward(velocity.y, movement * CLIMB_SPEED, CLIMB_ACCELERATION * delta)
	move_and_slide()


func hurt(enemy: Enemy) -> void:
	print_debug("HURT BY:", enemy.name)
	if not is_invincible:
		is_hurt = true

func dead() -> void:
	GameManager.transition_scene(GameManager.current_level)


func _is_safe_state(state: State) -> bool:
	return state not in UNSAFE_STATES


func _change_climb_side() -> void:
	var distance := abs(global_position.x - climbing_object.climb_area.global_position.x) * 2 as float
	global_position.x += distance * direction
	direction = Direction.LEFT if direction == Direction.RIGHT else Direction.RIGHT

func _unclimb() -> void:
	if can_climb:
		can_climb = false
		climbing_object = null
		global_position.x -= direction * Variables.TILE_SIZE.x / 2 # 给一点初速度，避免直接掉到藤下面

func _eat(item: Node) -> void:
	print_debug("Eatting: %s" % item.name)
	if item is Mushroom:
		if item.mushroom_type == Bumpable.SpawnItem.UPGRADE:
			can_enlarge = true
			ScoreManager.add_score(Mushroom.SCORE, item)
		elif item.mushroom_type == Bumpable.SpawnItem.LIFE:
			ScoreManager.add_life(item.get_global_transform_with_canvas().origin)
	elif item is Flower:
		can_onfire = true
		ScoreManager.add_score(Flower.SCORE, item)
	elif item is Star:
		_set_shader_enabled(true)
		blink_animator.play("star")
		is_under_star = true
		ScoreManager.add_score(Star.SCORE, item)
		SoundManager.go_star()
		star_timer.start()

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


func _blink_character() -> void:
	graphics.modulate.a = 0 if (Time.get_ticks_msec() / 10) % 2 == 0 else 1


func _set_shader_colors(color: String) -> void:
	var origin_colors := COLORS_FIRE if curr_mode == Mode.FIRE else COLORS_CLASSIC
	var new_colors: Array = origin_colors if color == "ORIGIN" else self["COLORS_" + color]
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", origin_colors.duplicate())
	sprite_material.set_shader_parameter("new_colors", new_colors.duplicate())


func _reset_animator(animator: AnimationPlayer) -> void:
	animator.speed_scale = 1
	animator.stop(true)


func _on_dying_timer_timeout() -> void:
	velocity.y = JUMP_VELOCITY
