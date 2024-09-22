class_name Lakitu
extends Enemy

enum State {
	APPROACH,
	WONDER_LEFT,
	WONDER_RIGHT,
	DASH,
	BRAKE,
	BYE,
	DYING,
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
const BYE_SPEED := 80.0
const MAX_SPINY_NUM := 4

const ACCELERATION := SPEED / 0.4
const DASH_ACCELERATION := DASH_SPEED / 0.4

const WONDER_RANGE := Variables.TILE_SIZE.x * 3.5
const SPAWN_DISTANCE := Variables.TILE_SIZE.x * 16 # 复活在一个屏幕以外
const MIN_THROW_DISTANCE := Variables.TILE_SIZE.x # 离玩家必须有最小距离才扔，免得扔玩家头上

var original_y : float
var can_throw := false

@onready var throw_timer: Timer = $ThrowTimer
@onready var respawn_timer: Timer = $RespawnTimer
@onready var bye_point: Marker2D = $ByePoint

func _ready() -> void:
	super()
	original_y = global_position.y
	animation_player.play("idle")

func _on_player_ready() -> void:
	super()
	if player.global_position.x > global_position.x:
		# 角色重生或从管道里出来时
		var spawn_x = player.global_position.x + Variables.TILE_SIZE.x * 16
		if spawn_x < bye_point.global_position.x:
			get_parent().global_position.x = spawn_x

func get_next_state(state: State) -> int:
	if hit or charged or stomped:
		return State.DYING if state != State.DYING else state_machine.KEEP_CURRENT
	if global_position.x >= bye_point.global_position.x  :
		return State.BYE if state != State.BYE else state_machine.KEEP_CURRENT
	
	var distance := global_position.x - player.global_position.x
	
	match state:
		State.APPROACH:
			if distance < WONDER_RANGE:
				return State.WONDER_LEFT
		State.WONDER_LEFT:
			if distance < 0 and abs(distance) >= WONDER_RANGE:
				return State.WONDER_RIGHT
		State.WONDER_RIGHT:
			if player.velocity.x >= player.MAX_WALK_SPEED / 2:
				return State.DASH
			if distance > 0 and abs(distance) >= WONDER_RANGE:
				return State.WONDER_LEFT
		State.DASH:
			if player.velocity.x < player.MAX_WALK_SPEED / 2:
				return State.BRAKE
		State.BRAKE:
			if player.velocity.x > player.MAX_WALK_SPEED / 2:
				if global_position.x < player.global_position.x + Variables.TILE_SIZE.x * 5:
					return State.DASH
			elif is_zero_approx(velocity.x):
				if distance < 0:
					return State.WONDER_RIGHT
				else:
					return State.APPROACH
			
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	
	if state != State.DYING:
		# 始终朝向玩家
		direction = Direction.LEFT if player.global_position.x < global_position.x else Direction.RIGHT
		# 丢刺怪
		if can_throw and get_tree().get_node_count_in_group("Spiny") < MAX_SPINY_NUM and abs(global_position.x - player.global_position.x) >= MIN_THROW_DISTANCE:
			can_throw = false
			var spiny_instance := preload("res://scenes/characters/spiny.tscn").instantiate() as Spiny
			var enemy_enabler := preload("res://scenes/characters/enemy_enabler.tscn").instantiate()
			animation_player.play("idle")
			var node2d := Node2D.new()
			node2d.global_position = global_position
			node2d.add_child(spiny_instance)
			node2d.add_child(enemy_enabler)
			owner.add_child(node2d)
			
	match state:
		State.APPROACH:
			move(SPEED, -1, delta)
		State.WONDER_LEFT:
			move(DASH_SPEED if direction == Direction.LEFT else SPEED, -1, delta)
		State.WONDER_RIGHT:
			move(DASH_SPEED if direction == Direction.RIGHT else SPEED, +1, delta)
		State.DASH:
			move(DASH_SPEED, +1, delta)
		State.DYING:
			move(0, 0, delta, default_gravity)
		State.BYE:
			move(BYE_SPEED, -1, delta)
		State.BRAKE:
			move(0, -1, delta)

func move(speed: float, dir: int, delta: float, gravity : float = 0, _limit_speed := false) -> void:
	var acceleration := DASH_ACCELERATION if state_machine.current_state in [State.DASH, State.BRAKE, State.BYE] else ACCELERATION
	velocity.x = move_toward(velocity.x, dir * speed, acceleration * delta)
	var velocity_y := velocity.y + gravity * delta
	velocity.y = min(velocity_y, MAX_FALL_SPEED)
	move_and_slide()
	if state_machine.current_state == State.DASH:
		global_position.x = min(global_position.x, player.global_position.x + Variables.TILE_SIZE.x * 5)

func transition_state(_from: State, to: State) -> void:
	match to:
		State.BYE:
			velocity.x = 0
			animation_player.pause()
			throw_timer.stop()
		State.DYING:
			animation_player.play("idle")
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
		State.DEAD:
			velocity = Vector2.ZERO
			
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
	await get_tree().create_timer(0.3).timeout
	can_throw = true


func _on_respawn_timer_timeout() -> void:
	# 没到ByePoint时才复活
	var spawn_x := player.global_position.x + SPAWN_DISTANCE
	if spawn_x < bye_point.global_position.x:
		# 恢复碰撞
		hurtbox.set_deferred("monitoring", true)
		# 恢复朝向
		graphics.scale.y = 1
		# 恢复位置
		z_index = 2
		position = Vector2.ZERO
		var parent := get_parent() as Node2D
		parent.global_position = Vector2(spawn_x, original_y)
		parent.add_child(preload("res://scenes/characters/enemy_enabler.tscn").instantiate())
		# 恢复状态
		animation_player.play("idle")
		state_machine.current_state = State.APPROACH
		# 恢复丢怪
		throw_timer.start()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# 在屏幕外面等着复活
	state_machine.current_state = State.DEAD
	set_process_mode(Node.PROCESS_MODE_DISABLED)
