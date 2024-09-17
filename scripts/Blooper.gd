class_name Blooper
extends Enemy

enum State {
	SINK,
	PUSH,
	DEAD,
}

const SCORE := {
	"hit": 200,
	"charged": 200,
}

const SINK_SPEED := 20.0
const PUSH_SPEED := Vector2(75.0, -80.0)

const MIN_SINK_DISTANCE := Variables.TILE_SIZE.y
const MIN_PLAYER_DISTANCE_Y := Variables.TILE_SIZE.y
const PUSH_DISTANCE := Variables.TILE_SIZE.y * 2

const THROTTLE_DISTANCE_X := Variables.TILE_SIZE.x * 4 # 决定倾向于靠近玩家还是远离玩家的临时水平距离
var APPROXIMITY := 0.7 # 倾向程度，即倾向事件发生的概率

var rng := RandomNumberGenerator.new()
var should_leave := false # 是否应该远离玩家
var original_y : float # 记录下潜或上推前的原始位置

func get_next_state(state: State) -> int:
	if hit or charged:
		return State.DEAD if state != State.DEAD else state_machine.KEEP_CURRENT
	
	var player_distance_y := global_position.y - player.global_position.y
	var travel_distance_y := global_position.y - original_y as float
	
	match state:
		State.SINK:
			if travel_distance_y > MIN_SINK_DISTANCE \
				and ((player_distance_y < 0 and abs(player_distance_y) <= MIN_PLAYER_DISTANCE_Y) \
					or player_distance_y >= 0):
				# 在玩家上方时一直下沉到玩家头上一格，在玩家下方时至少下沉一个高度
				return State.PUSH
		State.PUSH:
			# 推的距离固定，但不能超过水面
			if abs(travel_distance_y) >= PUSH_DISTANCE or global_position.y <= Variables.WATER_SURFACE_Y_OFFSET:
				return State.SINK
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	# 面朝玩家
	direction = Direction.LEFT if player.global_position.x < global_position.x else Direction.RIGHT
	if should_leave:
		direction = Direction.LEFT if direction == Direction.RIGHT else Direction.RIGHT
	
	match state:
		State.SINK:
			swim(0.0, direction, SINK_SPEED)
		State.PUSH:
			swim(PUSH_SPEED.x, direction, PUSH_SPEED.y)
		State.DEAD:
			move(DEAD_BOUNCE.x, attack_direction, delta)

func swim(speed_x: float, dir: int, speed_y: float) -> void:
	velocity.x = speed_x * dir
	velocity.y = speed_y
	move_and_slide()

func transition_state(_from: State, to: State) -> void:
	match to:
		State.SINK:
			animation_player.play("sink")
			original_y = global_position.y
		State.PUSH:
			# 离玩家近时更倾向于远离玩家，离玩家远时更倾向于靠近玩家
			var player_distance_x := abs(global_position.x - player.global_position.x) as float
			var triggered := rng.randf_range(0, 1) <= APPROXIMITY
			should_leave = (player_distance_x <= THROTTLE_DISTANCE_X and triggered) \
				or (player_distance_x > THROTTLE_DISTANCE_X and not triggered)
			animation_player.play("push")
			original_y = global_position.y
		State.DEAD:
			animation_player.play("dead")
			die(false)

# 被踩
func on_stomped() -> void:
	# 伤害玩家
	player.hurt(self)

# 被砖块从下面顶
func on_bumped(_bumpable: Bumpable) -> void:
	pass
