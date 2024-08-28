class_name Lakitu
extends Enemy

enum State {
	APPROACH,
	WONDER_LEFT,
	WONDER_RIGHT,
	DASH,
	BRAKE,
	BYE,
	DEAD,
}

const SCORE := {
	"stomped" : 800,
	"hit": 200,
	"charged": 200,
}

const SPEED := 30.0
const WONDER_SPEED := 50.0
const DASH_SPEED := 200.0

const ACCELERATION := SPEED / 0.4
const DASH_ACCELERATION := DASH_SPEED / 0.4

const WONDER_RANGE := Variables.TILE_SIZE.x * 3.5
const BYE_RANGE := Variables.TILE_SIZE.x * 16

var player: Player
var flag_pole : FlagPole

var original_y : float

@onready var throw_timer: Timer = $ThrowTimer
@onready var respawn_timer: Timer = $RespawnTimer

func _ready() -> void:
	await GameManager.world_ready
	player = get_tree().get_first_node_in_group("Player")
	flag_pole = get_tree().get_first_node_in_group("FlagPole")
	original_y = global_position.y
	animation_player.play("idle")
	await GameManager.player_ready
	if player.global_position.x > global_position.x:
		# 角色重生或从管道里出来时
		global_position.x = player.global_position.x + Variables.TILE_SIZE.x * 16

func get_next_state(state: State) -> int:
	if hit or charged or stomped:
		return State.DEAD if state != State.DEAD else state_machine.KEEP_CURRENT
	
	if flag_pole.global_position.x - global_position.x <= BYE_RANGE:
		return State.BYE if state != State.BYE else state_machine.KEEP_CURRENT
	
	var distance := global_position.x - player.global_position.x
	
	match state:
		State.APPROACH:
			if distance < WONDER_RANGE:
				return State.WONDER_LEFT
		State.WONDER_LEFT:
			if (distance < 0 and abs(distance) >= WONDER_RANGE) or is_equal_approx(global_position.x, GameManager.max_left_x):
				return State.WONDER_RIGHT
		State.WONDER_RIGHT:
			if player.velocity.x >= player.WALK_SPEED / 2:
				return State.DASH
			if distance > 0 and abs(distance) >= WONDER_RANGE:
				return State.WONDER_LEFT
		State.DASH:
			if player.velocity.x < player.WALK_SPEED / 2:
				return State.BRAKE
		State.BRAKE:
			if player.velocity.x > player.WALK_SPEED / 2:
				return State.DASH
			if is_zero_approx(velocity.x):
				if distance < 0:
					return State.WONDER_RIGHT
				else:
					return State.APPROACH
			
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	
	# 始终朝向玩家
	if state != State.DEAD:
		direction = Direction.LEFT if player.global_position.x < global_position.x else Direction.RIGHT
	
	match state:
		State.APPROACH:
			move(SPEED, -1, delta)
		State.WONDER_LEFT:
			move(SPEED, -1, delta)
		State.WONDER_RIGHT:
			move(SPEED, +1, delta)
		State.DASH:
			move(DASH_SPEED, +1, delta)
		State.DEAD:
			move(0, attack_direction, delta, default_gravity)
		State.BYE:
			move(SPEED, -1, delta)
		State.BRAKE:
			move(0, -1, delta)

func move(speed: float, dir: int, delta: float, gravity : float = 0) -> void:
	var acceleration := DASH_ACCELERATION if state_machine.current_state in [State.DASH, State.BRAKE] else ACCELERATION
	velocity.x = move_toward(velocity.x, dir * speed, acceleration * delta)
	velocity.y += gravity * delta
	move_and_slide()
	if not state_machine.current_state in [State.BYE, State.DEAD]:
		global_position.x = max(global_position.x, GameManager.max_left_x)
	if state_machine.current_state == State.DASH:
		global_position.x = min(global_position.x, player.global_position.x + Variables.TILE_SIZE.x * 5)

func transition_state(from: State, to: State) -> void:
	print_debug(
		"State: [%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to]
	])
	match to:
		State.BYE:
			velocity.x = 0
			animation_player.pause()
			throw_timer.stop()
		State.DEAD:
			if charged:
				charged = false
				ScoreManager.add_score(SCORE["charged"], self)
			elif hit:
				hit = false
				ScoreManager.add_score(SCORE["hit"], self)
			elif stomped:
				stomped = false
				ScoreManager.add_score(SCORE["stomped"], self)
			die()
			
func die(_pause := false) -> void:
	# 别再丢怪了
	throw_timer.stop()
	# 禁用碰撞
	hurtbox.set_deferred("monitoring", false)
	# 上下倒转
	graphics.scale.y = -1
	# 来到屏幕前面
	z_index = DEAD_Z_INDEX
	# 给一个小弹跳
	velocity.y = DEAD_BOUNCE.y
	# 准备复活
	respawn_timer.start()

func _on_throw_timer_timeout() -> void:
	animation_player.play("throw")
	var spiny_instance := load("res://scenes/characters/spiny.tscn").instantiate() as Spiny
	await get_tree().create_timer(0.3).timeout
	animation_player.play("idle")
	spiny_instance.global_position = global_position
	owner.add_child(spiny_instance)


func _on_respawn_timer_timeout() -> void:
	# 玩家快到终点了就别复活了
	if flag_pole.global_position.x - player.global_position.x > BYE_RANGE * 2:
		# 恢复碰撞
		hurtbox.set_deferred("monitoring", true)
		# 恢复朝向
		graphics.scale.y = 1
		# 恢复位置
		z_index = 0
		velocity = Vector2(0, 0)
		global_position.y = original_y
		global_position.x = player.global_position.x + Variables.TILE_SIZE.x * 16 # 出生在一个屏幕以外
		# 恢复状态
		animation_player.play("idle")
		state_machine.current_state = State.APPROACH
		# 恢复丢怪
		throw_timer.start()
