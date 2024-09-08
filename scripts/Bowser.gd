class_name Bowser
extends Enemy

enum State {
	WONDER_LEFT,
	WONDER_RIGHT,
	LAUNCH,
	CHASING,
	DEAD,
}

const SPEED := 15.0
const SCORE := {
	"hit": 5000,
	"charged": 5000,
}

const MIN_JUMP_INTERVAL := 1.5
const MAX_JUMP_INTERVAL := 2.5
const JUMP_VELOCITY := -200

const HAMMER_COUNT_RANGE := [3, 8] # 单次一口气扔出的锤子数范围
const HAMMER_INTERVAL_SINGLE_RANGE := [0.1, 0.2]
const HAMMER_INTERVAL_GROUP := 1.0

var rng := RandomNumberGenerator.new()
var hammer_to_throw := 0
var life_point := 4 # 需要打四下才死
var can_change_direction := false
var can_launch := false
var throwing := false

@onready var jump_timer: Timer = $JumpTimer
@onready var direction_timer: Timer = $DirectionTimer
@onready var hadouken_timer: Timer = $HadoukenTimer
@onready var hammer_timer: Timer = $HammerTimer
@onready var hadouken_launcher: HadoukenLauncher = $Graphics/HadoukenLauncher
@onready var hammer_launcher: HammerLauncher = $Graphics/HammerLauncher

func _ready() -> void:
	super()
	throw_hammer()
	throwing = true

func get_next_state(state: State) -> int:
	
	if charged or life_point == 0:
		return State.DEAD if state != State.DEAD else state_machine.KEEP_CURRENT
	
	match state:
		State.WONDER_LEFT, State.WONDER_RIGHT:
			if direction == Direction.RIGHT:
				return State.CHASING
			if can_launch:
				return State.LAUNCH
			if can_change_direction or is_on_wall():
				return State.WONDER_RIGHT if state == State.WONDER_LEFT else State.WONDER_LEFT
		State.LAUNCH:
			if not animation_player.is_playing():
				return state_machine.get_last_safe_state()
		State.CHASING:
			if direction == Direction.LEFT:
				# 后退一步
				return State.WONDER_RIGHT
				
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	# 始终面朝玩家
	if state_machine.current_state != State.DEAD:
		direction = Direction.LEFT if player.global_position.x < global_position.x else Direction.RIGHT
	
	match state:
		State.WONDER_LEFT:
			move(SPEED, -1, delta, default_gravity / 2)
		State.WONDER_RIGHT:
			move(SPEED, +1, delta, default_gravity / 2)
		State.LAUNCH:
			var move_direction := -1 if state_machine.get_last_safe_state() == State.WONDER_LEFT else +1
			move(SPEED, move_direction, delta, default_gravity / 2)
		State.CHASING:
			move(SPEED, direction, delta, default_gravity / 2)
		State.DEAD:
			move(DEAD_BOUNCE.x, attack_direction, delta)


func transition_state(_from: State, to: State) -> void:
	
	match to:
		State.WONDER_LEFT, State.WONDER_RIGHT:
			if not throwing:
				throw_hammer()
			can_change_direction = false
			animation_player.play("wonder")
			direction_timer.start()
			hadouken_timer.start()
			jump_timer.start(rng.randf_range(MIN_JUMP_INTERVAL, MAX_JUMP_INTERVAL))
		State.LAUNCH:
			can_launch = false
			animation_player.play("launch")
		State.CHASING:
			direction_timer.stop()
			jump_timer.stop()
			hadouken_timer.stop()
		State.DEAD:
			direction_timer.stop()
			jump_timer.stop()
			hadouken_timer.stop()
			SoundManager.play_sfx("Kill")
			if life_point == 0:
				ScoreManager.add_score(SCORE["hit"], self)
			elif charged:
				ScoreManager.add_score(SCORE["charged"], self)
			die()

# 被火球打
func on_hit(_body: CharacterBody2D) -> void:
	life_point -= 1

# 被踩
func on_stomped() -> void:
	player.hurt(self)

func throw_hammer() -> void:
	throwing = true
	while state_machine.current_state not in [State.CHASING, State.DEAD]:
		while hammer_to_throw > 0:	
			if not get_tree().paused:
				hammer_launcher.launch()
				hammer_to_throw -= 1
			# 等待一小会扔下一个锤子
			await get_tree().create_timer(rng.randf_range(HAMMER_INTERVAL_SINGLE_RANGE[0], HAMMER_INTERVAL_SINGLE_RANGE[1])).timeout
		# 休息一会儿生成新一批锤子
		await get_tree().create_timer(HAMMER_INTERVAL_GROUP).timeout
		hammer_to_throw = rng.randi_range(HAMMER_COUNT_RANGE[0], HAMMER_COUNT_RANGE[1])
	throwing = false

func _on_direction_timer_timeout() -> void:
	# 1/2的概率转换方向
	if rng.randf() >= 0.5:
		can_change_direction = true


func _on_jump_timer_timeout() -> void:
	# 起跳吧！
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
	jump_timer.start(rng.randf_range(MIN_JUMP_INTERVAL, MAX_JUMP_INTERVAL))


func _on_hadouken_timer_timeout() -> void:
	# 1/2的概率喷火
	if rng.randf() >= 0.5:
		can_launch = true
