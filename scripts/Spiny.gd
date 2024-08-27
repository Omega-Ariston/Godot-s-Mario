class_name Spiny
extends Enemy

enum State {
	SPAWN,
	WALK,
	DEAD,
}

const SPEED := 30.0
const BOUNCE_SPEED := -200
const SPAWN_BOUNCE := -200
const SCORE := {
	"hit": 200,
	"charged": 200,
}

@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D

var player: Player


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func get_next_state(state: State) -> int:
	if hit or charged:
		return State.DEAD if state != State.DEAD else state_machine.KEEP_CURRENT
		
	match state:
		State.SPAWN:
			if is_on_floor():
				return State.WALK
				
	return state_machine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	if is_on_wall():
		direction = Direction.LEFT if direction == Direction.RIGHT else Direction.RIGHT
	
	match state:
		State.SPAWN:
			# 自由落体
			move(0, direction, delta)
		State.WALK:
			move(SPEED, direction, delta)
		State.DEAD:
			move(DEAD_BOUNCE.x, attack_direction, delta)


func transition_state(_from: State, to: State) -> void:
	match to:
		State.SPAWN:
			animation_player.play("spawn")
			velocity.y = SPAWN_BOUNCE
		State.WALK:
			animation_player.play("walk")
			# 往玩家方向移动
			direction = Direction.LEFT if global_position.x > player.global_position.x else Direction.RIGHT
		State.DEAD:
			animation_player.play("walk", -1, 0, false)
			if charged:
				ScoreManager.add_score(SCORE["charged"], self)
			elif hit:
				ScoreManager.add_score(SCORE["hit"], self)
			die(false)

# 被踩
func on_stomped(_player: Player) -> void:
	# 伤害玩家
	player.hurt(self)

# 被砖块从下面顶
func on_bumped(bumpable: Bumpable) -> void:
	direction = Direction.LEFT if bumpable.global_position.x > global_position.x else Direction.RIGHT
	velocity.y = BOUNCE_SPEED
