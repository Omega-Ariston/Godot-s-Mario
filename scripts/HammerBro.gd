class_name HammerBro
extends Enemy

enum State {
	WONDER,
	JUMP_UP_ONE,
	JUMP_UP_TWO,
	JUMP_DOWN_ONE, # 向下跳一层
	JUMP_DOWN_TWO, # 向下跳两层
	LANDING,
	CHASING,
	DEAD,
}

const SPEED := 15.0
const SCORE := {
	"stomped" : 1000,
	"hit": 1000,
	"charged": 1000,
	"bumped": 1000,
}
const WONDER_RANGE := Variables.TILE_SIZE.x / 2
const MIN_JUMP_INTERVAL := 2.0
const MAX_JUMP_INTERVAL := 3.0
const JUMP_UP_VELOCITY := -280
const JUMP_DOWN_VELOCITY := -100
const LEVEL_TWO_BOUND := 7 # 双层砖块中上层的下界，单位为瓦片高度
const LEVEL_ONE_BOUND := 11 # 双层砖块中下层的下界，单位为瓦片高度
const CHARACTER_HEIGHT := 1.5 # 角色高度，单位为瓦片高度
const HAMMER_COUNT_RANGE := [1, 4] # 单次一口气扔出的锤子数范围
const HAMMER_INTERVAL_SINGLE := 0.3
const HAMMER_INTERVAL_GROUP := 1.0

# 原始颜色，顺序为壳、肉、壳边缘
const COLOR_ORIGIN := [
	Vector4(0.12, 0.52, 0.0, 1.0),
	Vector4(0.84, 0.55, 0.13, 1.0),
	Vector4(1.0, 1.0, 1.0, 1.0),
]

const COLOR_CYAN := [
	Vector4(0.11, 0.40, 0.46, 1.0),
	Vector4(0.51, 0.22, 0.06, 1.0),
	Vector4(0.98, 0.73, 0.67, 1.0)
]

var origin_x : float
var rng := RandomNumberGenerator.new()
var can_jump := false
var is_chasing := false
var level_before_jump : int
var move_direction := Direction.LEFT
var hammer_to_throw := 0

@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D
@onready var jump_timer: Timer = $JumpTimer
@onready var floor_checker: Node2D = $FloorChecker
@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var hammer_launcher: HammerLauncher = $Graphics/HammerLauncher

func _ready() -> void:
	super()
	origin_x = global_position.x
	throw_hammer()

func _on_world_ready() -> void:
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == GameManager.WorldType.UNDER:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
	else:
		sprite_material.set_shader_parameter("shader_enabled", false)
		

func throw_hammer() -> void:
	while true:
		while hammer_to_throw > 0:	
			await hammer_launcher.launch()
			hammer_to_throw -= 1
			await get_tree().create_timer(HAMMER_INTERVAL_SINGLE).timeout
		# 休息一会儿生成新一批锤子
		await get_tree().create_timer(HAMMER_INTERVAL_GROUP).timeout
		hammer_to_throw = rng.randi_range(HAMMER_COUNT_RANGE[0], HAMMER_COUNT_RANGE[1])

func get_next_state(state: State) -> int:
	
	if charged or hit or bumped or stomped:
		return State.DEAD if state != State.DEAD else state_machine.KEEP_CURRENT
	
	match state:
		State.WONDER:
			if not on_floor_raycast():
				return State.LANDING
			if is_chasing and direction == Direction.LEFT:
				return State.CHASING
			if can_jump:
				can_jump = false
				# 1/2的机率向上向下跳或向下跳一层跳两层
				var first_jump_type := rng.randf_range(0, 1) > 0.5
				level_before_jump = current_level()
				match level_before_jump:
					2:
						return State.JUMP_DOWN_ONE if first_jump_type else State.JUMP_DOWN_TWO
					1:
						return State.JUMP_UP_ONE if first_jump_type else State.JUMP_DOWN_ONE
					0:
						return State.JUMP_UP_ONE if first_jump_type else State.JUMP_UP_TWO
		State.JUMP_UP_ONE, State.JUMP_UP_TWO:
			if velocity.y >= 0:
				return State.LANDING
		State.JUMP_DOWN_ONE:
			if on_floor_raycast() and current_tile_unit_y() > LEVEL_ONE_BOUND:
				# 从追击返回到巡航模式并站在管道上时会进入这个状态，需要防止它往管道下面跳
				return State.JUMP_UP_ONE
			if current_level() == level_before_jump - 1:
				return State.LANDING
		State.JUMP_DOWN_TWO:
			if current_level() == 0:
				return State.LANDING
		State.LANDING:
			if is_on_floor():
				if state_machine.get_last_safe_state() == State.JUMP_UP_TWO:
					return State.JUMP_UP_ONE
				return State.WONDER
		State.CHASING:
			if not on_floor_raycast():
				return State.LANDING
			if direction == Direction.RIGHT:
				return State.WONDER
			if wall_checker.is_colliding():
				return State.JUMP_UP_ONE
				
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	var direction_old := direction
	# 始终面朝玩家
	direction = Direction.LEFT if player.global_position.x < global_position.x else Direction.RIGHT
	
	if is_chasing and direction_old == Direction.LEFT and direction == Direction.RIGHT:
		# 追逐状态下玩家从左边到右边时更新原地位置
		origin_x = global_position.x
	if is_chasing and direction == Direction.LEFT:
		move_direction = Direction.LEFT
	elif global_position.x <= origin_x - WONDER_RANGE:
		move_direction = Direction.RIGHT
	elif global_position.x >= origin_x + WONDER_RANGE:
		move_direction = Direction.LEFT
	
	match state:
		State.WONDER, State.CHASING:
			move(SPEED, move_direction, delta, 0)
		State.DEAD:
			move(DEAD_BOUNCE.x, attack_direction, delta)
		_:
			move(SPEED, move_direction, delta, default_gravity / 2)


func transition_state(from: State, to: State) -> void:
	
	print_debug(
		"State: [%s] %s => %s, position: %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to],
		global_position.y / Variables.TILE_SIZE.y
	])
	
	match to:
		State.WONDER:
			# 禁用碰撞
			collision_shape_2d.disabled = true
		State.JUMP_UP_ONE:
			if from == State.LANDING:
				# 说明是二段跳的第二段，需要禁用碰撞
				collision_shape_2d.disabled = true
			velocity.y = JUMP_UP_VELOCITY
		State.JUMP_UP_TWO:
			velocity.y = JUMP_UP_VELOCITY
		State.JUMP_DOWN_ONE, State.JUMP_DOWN_TWO:
			velocity.y = JUMP_DOWN_VELOCITY
		State.LANDING:
			# 恢复碰撞以站立
			collision_shape_2d.disabled = false
		State.DEAD:
			if charged:
				ScoreManager.add_score(SCORE["charged"], self)
			elif hit:
				ScoreManager.add_score(SCORE["hit"], self)
			elif bumped:
				ScoreManager.add_score(SCORE["bumped"], self)
			elif stomped:
				ScoreManager.add_score(SCORE["stomped"], self)
			die()

func current_level() -> int:
	# 当前所在的层数（锤子兄弟可以在最多三层的场景中生成），地面为0，中间为1，顶上为2
	if current_tile_unit_y() < LEVEL_TWO_BOUND + CHARACTER_HEIGHT:
		return 2
	elif current_tile_unit_y() < LEVEL_ONE_BOUND + CHARACTER_HEIGHT:
		return 1
	else:
		return 0

func current_tile_unit_y() -> int:
	return ceili(global_position.y / Variables.TILE_SIZE.y)

func _on_chase_timer_timeout() -> void:
	is_chasing = true

func _on_jump_timer_timeout() -> void:
	# 非追击状态下2/3的机率跳
	if state_machine.current_state != State.CHASING and rng.randf_range(0, 1) > 0.33:
		can_jump = true
	jump_timer.start(rng.randf_range(MIN_JUMP_INTERVAL, MAX_JUMP_INTERVAL))

func on_floor_raycast() -> bool:
	for ray_cast: RayCast2D in floor_checker.get_children():
		if ray_cast.is_colliding():
			return true
	return false
