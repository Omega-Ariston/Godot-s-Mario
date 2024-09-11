class_name Player
extends CharacterBody2D

const WALK_SPEED := 1.5625 * 60 # 01900
const WALK_SPEED_WATER := 1.0625 * 60 # 01100
const DASH_SPEED := 2.5625 * 60 # 02900
const AIR_SPEED_SLOW := WALK_SPEED # 01900
const AIR_SPEED_FAST := DASH_SPEED # 02900

const CLIMB_UP_SPEED := -0.875 * 60 # 00E00
const CLIMB_DOWN_SPEED := 2 * 60 # 02000

const WALK_ACCELERATION := 0.037109375 * 60 * 60 # 00098
const DASH_ACCELERATION := 0.0556640625 * 60 * 60 # 000E4

const AIR_ACCELERATION_SLOW := WALK_ACCELERATION # 00098
const AIR_ACCELERATION_FAST := DASH_ACCELERATION # 000E4

const RELEASE_DECELERATION := 0.05078125 * 60 * 60 # 000D0
const SKIDDING_DECELERATION := 0.1015625 * 60 * 60 # 001A0

const AIR_SPEED_THROTTLE_AIR := WALK_SPEED # 01900
const AIR_SPEED_THROTTLE_GROUND := 1.8125 * 60 # 01D00

const AIR_DECELERATION_SLOW := WALK_ACCELERATION # 00098
const AIR_DECELERATION_MID := RELEASE_DECELERATION # 000D0
const AIR_DECELERATION_FAST := DASH_ACCELERATION # 000E4

const JUMP_VELOCITY_SLOW := -4 * 60 # 04000
const JUMP_VELOCITY_FAST := -5 * 60 # 05000
const JUMP_VELOCITY_THROTTLE_MID := 1 * 60 # 01000
const JUMP_VELOCITY_THROTTLE_FAST := 2.3125 * 60 # 02500

const SWIM_VELOCITY := -1.5 * 60 # 01800
const MIN_ANIMATION_SPEED := 0.8

const FIREBALL_LIMIT := 2
const CLIFF_LIMIT := Variables.TILE_SIZE.y * 18 # 世界底部

const GRAVITY_JUMP_SLOW := 0.125 * 60 * 60 # 00200
const GRAVITY_JUMP_MID := 0.11328125 * 60 * 60 # 001E0
const GRAVITY_JUMP_FAST := 0.15625 * 60 * 60 # 00280
const GRAVITY_SWIM := 0.046875 * 60 * 60 # 000D0
const GRAVITY_SWIM_FALL := 0.0390625 * 60 * 60# 000A0

const GRAVITY_FALL_SLOW := 0.4375 * 60 * 60 # 00700
const GRAVITY_FALL_MID := 0.375 * 60 * 60 # 00600
const GRAVITY_FALL_FAST := 0.5625 * 60 * 60 # 00900

const VELOCITY_Y_MAX := 4.5 * 60 # 04800
const VELOCITY_Y_CUT_OFF := 4.0 * 60 # 04000

enum State {
	IDLE,
	WALK,
	TURN,
	CROUCH,
	CROUCH_JUMP,
	LAUNCH,
	JUMP,
	SWIM,
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

const RECT_MAP := {
	Mode.SMALL: Rect2(96, 32, 272, 16),
	Mode.LARGE: Rect2(96, 0, 272, 32),
	Mode.FIRE: Rect2(96, 48, 272, 32),
}

const GRAPHIC_Y_MAP := {
	Mode.SMALL: -8,
	Mode.LARGE: -16,
	Mode.FIRE: -16,
}

const COLLISION_ATTR_MAP := {
	# 碰撞箱的y偏移量，宽度与高度
	Mode.SMALL: Vector3(-7, 10, 13),
	Mode.LARGE: Vector3(-13, 12, 26.75),
	Mode.FIRE: Vector3(-13, 12, 26.75),
}

const COLLISION_ATTR_CROUCH := Vector3(-7, 12, 13)

@export var curr_mode := Mode.SMALL as Mode:
	set(v):
		if curr_mode != v:
			curr_mode = v
			GameManager.player_current_mode = curr_mode
			initialize_mode()
		
@export var direction := Direction.RIGHT:
	set(v):
		if direction != v:
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
var swim_requested := false
var launch_requested := false
var dash_requested := false
var direction_before_turn : float
var is_under_star := false # 是否在无敌星作用下
var is_invincible := false # 是否处于受伤后无敌状态
var is_hurt := false # 是否处于受伤状态
var last_animation : String
var controllable := true
var is_spawning := false
var is_under_water := false
var velocity_x_before_jump : float
var direction_before_jump : float

# 用于模拟玩家移动
var input_x := 0.0
var input_y := 0.0
var constant_speed_x: float
var constant_speed_y: float

@onready var graphics: Node2D = $Graphics
@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var blink_animator: AnimationPlayer = $BlinkAnimator
@onready var state_machine: StateMachine = $StateMachine
@onready var on_fire_timer: Timer = $OnFireTimer
@onready var star_timer: Timer = $StarTimer
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var dying_timer: Timer = $DyingTimer
@onready var fireball_launcher: FireballLauncher = $Graphics/FireballLauncher
@onready var floor_checker: Node2D = $FloorChecker

func _unhandled_input(event: InputEvent) -> void:
	if controllable:
		if event.is_action_pressed("jump"):
			if is_under_water:
				swim_requested = true
			elif on_jumpable_floor(): #防止在空中保存跳跃指令
				jump_requested = true
		if event.is_action_released("jump"):
			jump_requested = false
			swim_requested = false
		if event.is_action_pressed("action") and curr_mode == Mode.FIRE:
			launch_requested = true
		if event.is_action_released("action"):
			launch_requested = false
		if event.is_action_pressed("move_down"):
			crouch_requested = true
		if event.is_action_released("move_down"):
			crouch_requested = false

func _ready() -> void:
	GameManager.world_ready.connect(_on_world_ready)
	curr_mode = GameManager.player_current_mode
	initialize_mode()

func tick_physics(state: State, delta: float) -> void:
	if not is_under_water and on_jumpable_floor():
		# 开始和结束加速都要在地面上判断
		if controllable and Input.is_action_pressed("action"):
				dash_requested = true
		else:
			if on_jumpable_floor():
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
				set_shader_enabled(false)
		elif (SoundManager.bgm_player.stream == SoundManager.starBGM and not SoundManager.bgm_player.playing):
			SoundManager.play_world_bgm()
			if state != State.ONFIRE:
				# 星星的最后几秒放慢闪烁速度
				blink_animator.play("star", -1, 1.0, false)
	
	match state:
		State.IDLE:
			move(0, delta)
		State.WALK:
			# 动画播放速度与走路速度正相关
			animation_player.speed_scale = max(MIN_ANIMATION_SPEED, abs(velocity.x) / WALK_SPEED * 1.5)
			move(0, delta)
		State.TURN:
			move(0, delta)
		State.CROUCH:
			stand(0, delta)
		State.JUMP, State.CROUCH_JUMP:
			var gravity: float
			if is_first_tick:
				gravity = 0.0
			else:
				if jump_requested:
					if velocity_x_before_jump < JUMP_VELOCITY_THROTTLE_MID:
						gravity = GRAVITY_JUMP_SLOW
					elif velocity_x_before_jump < JUMP_VELOCITY_THROTTLE_FAST:
						gravity = GRAVITY_JUMP_MID
					else:
						gravity = GRAVITY_JUMP_FAST
				else:
					if velocity_x_before_jump < JUMP_VELOCITY_THROTTLE_MID:
						gravity = GRAVITY_FALL_SLOW
					elif velocity_x_before_jump < JUMP_VELOCITY_THROTTLE_FAST:
						gravity = GRAVITY_FALL_MID
					else:
						gravity = GRAVITY_FALL_FAST
					
			move(gravity, delta)
		State.SWIM:
			move(GRAVITY_SWIM if swim_requested else GRAVITY_SWIM_FALL, delta)
		State.DEAD:
			if dying_timer.time_left == 0:
				move(GRAVITY_FALL_SLOW, delta)
		State.FALL:
			var gravity : float
			if is_first_tick:
				gravity = 0.0
			elif is_under_water:
				gravity = GRAVITY_SWIM_FALL
			else:
				if velocity_x_before_jump < JUMP_VELOCITY_THROTTLE_MID:
					gravity = GRAVITY_FALL_SLOW
				elif velocity_x_before_jump < JUMP_VELOCITY_THROTTLE_FAST:
					gravity = GRAVITY_FALL_MID
				else:
					gravity = GRAVITY_FALL_FAST
			move(gravity, delta)
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
				animation_player.speed_scale = min(abs(velocity.y / CLIMB_UP_SPEED), 2.0)
				climb(delta)
		State.LAUNCH:
			move(GRAVITY_FALL_SLOW, delta)
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
	
	if can_enlarge:
		return State.ENLARGE
	
	if can_onfire:
		return State.ONFIRE
	
	var can_crouch := state in GROUND_STATES and state not in UNSAFE_STATES and curr_mode != Mode.SMALL
	var should_crouch := can_crouch and crouch_requested and state not in CROUCH_STATES
	if should_crouch:
		return State.CROUCH
	
	var can_jump := state in GROUND_STATES and state not in UNSAFE_STATES
	var should_jump := can_jump and jump_requested
	if should_jump:
		return State.CROUCH_JUMP if state == State.CROUCH else State.JUMP
	
	var can_swim := is_under_water and swim_requested
	if can_swim:
		return State.SWIM
		
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
			if velocity.x * direction > 0 and movement * direction < 0:
				return State.TURN
			if is_still:
				return State.IDLE
		State.TURN:
			if movement * direction_before_turn > 0 or is_zero_approx(velocity.x):
				return State.IDLE if is_still else State.WALK
		State.CROUCH:
			if is_on_floor() and crouch_requested == false:
				return State.IDLE
		State.JUMP, State.CROUCH_JUMP, State.SWIM:
			if velocity.y >= 0 or is_on_ceiling():
				return State.FALL
		State.FALL:
			if is_on_floor():
				return State.IDLE if is_still else State.WALK
		State.CLIMB:
			if can_climb == false:
				return State.FALL if not is_on_floor() else State.WALK
		State.LAUNCH:
			if not animation_player.is_playing():
				return state_machine.get_last_safe_state(_is_safe_state)
		State.ENLARGE:
			if not animation_player.is_playing():
				return state_machine.get_last_safe_state(_is_safe_state)
		State.ONFIRE:
			if on_fire_timer.is_stopped():
				return state_machine.get_last_safe_state(_is_safe_state)
		State.HURT:
			if not animation_player.is_playing():
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
		State.WALK:
			animation_player.speed_scale = 1 # 恢复动画播放速度
		State.JUMP, State.CROUCH_JUMP:
			jump_requested = false
		State.SWIM:
			swim_requested = false
		State.FALL:
			animation_player.speed_scale = 1 # 恢复动画播放速度
			initialize_mode() # 恢复碰撞体积，针对CROUCH_JUMP的情况
		State.CLIMB:
			animation_player.speed_scale = 1 # 恢复动画播放速度
			initialize_mode() # 恢复角色位置
		State.ENLARGE:
			# 恢复时间
			get_tree().paused = false
			curr_mode = Mode.LARGE
		State.ONFIRE:
			# 恢复时间
			get_tree().paused = false
			curr_mode = Mode.FIRE
			blink_animator.stop()
			if is_under_star:
				blink_animator.play("star", -1, 4.0, false)
			else:
				set_shader_enabled(false)
		State.HURT:
			# 恢复时间
			get_tree().paused = false
			curr_mode = Mode.SMALL
			# 进入无敌时间
			is_invincible = true
			invincible_timer.start()
		State.CROUCH:
			if to != State.CROUCH_JUMP:
				initialize_mode() # 恢复碰撞体积
			
	match to:
		State.IDLE:
			animation_player.play("idle")
		State.WALK:
			animation_player.play("walk")
		State.TURN:
			animation_player.play("turn")
			if from not in UNSAFE_STATES:
				direction_before_turn = direction
		State.CROUCH:
			animation_player.play("crouch")
			# 修改碰撞体积
			collision_shape_2d.position.y = COLLISION_ATTR_CROUCH.x
			collision_shape_2d.shape.size.x = COLLISION_ATTR_CROUCH.y
			collision_shape_2d.shape.size.y = COLLISION_ATTR_CROUCH.z
		State.JUMP, State.CROUCH_JUMP:
			direction_before_jump = direction
			velocity_x_before_jump = abs(velocity.x)
			animation_player.play("jump" if to == State.JUMP else "crouch")
			if from not in UNSAFE_STATES: # 变身结束或发完炮后不用跳
				velocity.y = JUMP_VELOCITY_FAST if velocity_x_before_jump > JUMP_VELOCITY_THROTTLE_FAST else JUMP_VELOCITY_SLOW
				SoundManager.play_sfx("JumpSmall" if curr_mode == Mode.SMALL else "JumpLarge")
		State.SWIM:
			animation_player.play("swim_up", -1, 2.0, false)
			SoundManager.play_sfx("Stomp")
			if from not in UNSAFE_STATES:
				velocity.y = SWIM_VELOCITY
		State.FALL:
			velocity_x_before_jump = abs(velocity.x)
			if is_under_water:
				animation_player.play("swim_down")
			else:
				if from in [State.IDLE, State.TURN, State.CLIMB]:
					animation_player.play("walk")
				elif from == State.LAUNCH:
					animation_player.play(last_animation)
				animation_player.speed_scale = 0 # 下落时暂停播放动画
		State.CLIMB:
			animation_player.play("climb")
		State.HURT:
			is_hurt = false
			get_tree().paused = true # 静止游戏场景
			animation_player.play("hurt")
			SoundManager.play_sfx("PipeHurt")
		State.LAUNCH:
			last_animation = animation_player.current_animation
			launch_requested = false
			if is_under_water:
				animation_player.play("launch_swim")
			else:
				animation_player.play("launch")
			fireball_launcher.launch()
		State.ENLARGE:
			can_enlarge = false
			# 暂停时间
			get_tree().paused = true
			animation_player.play("enlarge")
			SoundManager.play_sfx("Upgrade")
		State.ONFIRE:
			can_onfire = false
			# 暂停时间
			get_tree().paused = true
			animation_player.stop()
			set_shader_enabled(true)
			blink_animator.play("onfire", -1, 2.0, false)
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
			controllable = false
			curr_mode = Mode.SMALL
			animation_player.play("dead")
			SoundManager.pause_bgm()
			SoundManager.play_sfx("MarioDie")
			GameManager.life -= 1
			# 到前面来
			z_index = 5
			dying_timer.start()
	is_first_tick = true
	
	
func move(gravity: float, delta: float) -> void:
	var movement := Input.get_axis("move_left", "move_right") if controllable else input_x
	if not is_zero_approx(movement) and not is_first_tick and (is_under_water or is_on_floor()):
		direction = Direction.LEFT if movement < 0 else Direction.RIGHT
	var target_speed : float
	var acceleration : float
	if state_machine.current_state == State.TURN:
		target_speed = 0
		acceleration = SKIDDING_DECELERATION
	elif is_zero_approx(movement):
		if is_on_floor():
			target_speed = 0.0
			acceleration = RELEASE_DECELERATION
		else:
			# 空中松开按键时维持当前速度
			target_speed = velocity.x
			acceleration = 0.0
	elif not is_on_floor():
		target_speed = AIR_SPEED_FAST if velocity_x_before_jump > AIR_SPEED_THROTTLE_AIR else AIR_SPEED_SLOW
		if movement * direction_before_jump > 0:
			# 空中同向移动
			acceleration = AIR_ACCELERATION_FAST if abs(velocity.x) > AIR_SPEED_THROTTLE_AIR else AIR_ACCELERATION_SLOW
		else:
			# 空中反向移动
			if abs(velocity.x) >= AIR_SPEED_THROTTLE_AIR:
				acceleration = AIR_DECELERATION_FAST
			elif velocity_x_before_jump >= AIR_SPEED_THROTTLE_GROUND:
				acceleration = AIR_DECELERATION_MID
			else:
				acceleration = AIR_DECELERATION_SLOW
	elif is_under_water:
		target_speed = WALK_SPEED_WATER
		acceleration = WALK_ACCELERATION
	elif dash_requested:
		target_speed = DASH_SPEED
		acceleration = DASH_ACCELERATION
	else:
		target_speed = WALK_SPEED
		acceleration = WALK_ACCELERATION
	
	velocity.x = constant_speed_x if constant_speed_x != 0 else move_toward(velocity.x, movement * target_speed, acceleration * delta)
	
	var velocity_y = velocity.y + gravity * delta
	# 限制最大下落速度
	if velocity_y > VELOCITY_Y_MAX:
		velocity_y = VELOCITY_Y_CUT_OFF
	velocity.y = velocity_y
	
	move_and_slide()
	
	
func stand(gravity: float, delta: float) -> void:
	var acceleration := SKIDDING_DECELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += gravity * delta
	
	move_and_slide()

func climb(_delta:float) -> void:
	var movement := Input.get_axis("move_up", "move_down") if controllable else input_y
	var velocity_y : float
	if constant_speed_y != 0:
		velocity_y = constant_speed_y
	elif movement < 0:
		velocity_y = CLIMB_UP_SPEED
	elif movement > 0:
		velocity_y = CLIMB_DOWN_SPEED
	velocity.y = velocity_y
	move_and_slide()


func hurt(_enemy: Node2D) -> void:
	if not is_invincible:
		is_hurt = true
		# 清除所有空中的火球
		get_tree().call_group("Fireballs", "queue_free")

func dead() -> void:
	GameManager.transition_scene(GameManager.current_level)

func initialize_mode() -> void:
	# 初始化角色外观以及碰撞体积和图形偏移
	sprite_2d.region_rect = RECT_MAP.get(curr_mode)
	graphics.position.y = GRAPHIC_Y_MAP.get(curr_mode)
	var collision_attr := COLLISION_ATTR_MAP.get(curr_mode) as Vector3
	var shape := collision_shape_2d.shape as RectangleShape2D
	collision_shape_2d.position.y = collision_attr.x
	shape.size.x = collision_attr.y
	shape.size.y = collision_attr.z

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
	if item is Mushroom:
		if item.mushroom_type == Bumpable.SpawnItem.UPGRADE:
			if curr_mode == Mode.SMALL:
				can_enlarge = true
			ScoreManager.add_score(Mushroom.SCORE, item)
		elif item.mushroom_type == Bumpable.SpawnItem.LIFE:
			ScoreManager.add_life(item.get_global_transform_with_canvas().origin)
	elif item is Flower:
		if curr_mode == Mode.SMALL:
			can_enlarge = true
		elif curr_mode == Mode.LARGE:
			can_onfire = true
		ScoreManager.add_score(Flower.SCORE, item)
	elif item is Star:
		set_shader_enabled(true)
		blink_animator.play("star", -1, 4.0, false)
		is_under_star = true
		ScoreManager.add_score(Star.SCORE, item)
		SoundManager.go_star()
		star_timer.start()

func _blink_character() -> void:
	graphics.modulate.a = 0 if (Time.get_ticks_msec() / 10) % 2 == 0 else 1

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

const COLORS_BLUE := [
	Vector4(0.0, 0.48, 0.54, 1.0),
	Vector4(0.61, 0.29, 0.0, 1.0),
	Vector4(1.0, 0.80, 0.77, 1.0),
]

const COLORS_CYAN := [
	Vector4(0.0, 0.25, 0.29, 1.0),
	Vector4(0.0, 0.48, 0.54, 1.0),
	Vector4(0.70, 0.93, 0.93, 1.0),
]

func set_shader_enabled(enabled: bool) -> void:
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("shader_enabled", enabled)

func set_onfire_colors(index: int) -> void:
	var origin_colors := COLORS_CLASSIC
	var new_colors: Array
	match index:
		0:
			new_colors = COLORS_FIRE
		1:
			match GameManager.current_world_type:
				GameManager.WorldType.GROUND:
					new_colors = COLORS_GREEN
				GameManager.WorldType.UNDER:
					new_colors = COLORS_BLUE
		2:
			new_colors = COLORS_RED
		3:
			match GameManager.current_world_type:
				GameManager.WorldType.GROUND:
					new_colors = COLORS_BLACK
				GameManager.WorldType.UNDER:
					new_colors = COLORS_CYAN
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", origin_colors.duplicate())
	sprite_material.set_shader_parameter("new_colors", new_colors.duplicate())

func set_star_colors(index: int) -> void:
	var origin_colors := COLORS_FIRE if curr_mode == Mode.FIRE else COLORS_CLASSIC
	var new_colors: Array
	match index:
		0:
			new_colors = origin_colors
		1:
			match GameManager.current_world_type:
				GameManager.WorldType.GROUND:
					new_colors = COLORS_GREEN
				GameManager.WorldType.UNDER:
					new_colors = COLORS_BLUE
		2:
			new_colors = COLORS_RED
		3:
			match GameManager.current_world_type:
				GameManager.WorldType.GROUND:
					new_colors = COLORS_BLACK
				GameManager.WorldType.UNDER:
					new_colors = COLORS_CYAN
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", origin_colors.duplicate())
	sprite_material.set_shader_parameter("new_colors", new_colors.duplicate())

func _on_dying_timer_timeout() -> void:
	velocity.y = JUMP_VELOCITY_FAST

func on_jumpable_floor() -> bool:
	for ray_cast: RayCast2D in floor_checker.get_children():
		if ray_cast.is_colliding():
			return true
	return false

func register_unjumpable_node(node: CollisionObject2D) -> void:
	for ray_cast: RayCast2D in floor_checker.get_children():
		ray_cast.add_exception(node)

func _on_world_ready() -> void:
	is_under_water = GameManager.current_world_type == GameManager.WorldType.WATER
