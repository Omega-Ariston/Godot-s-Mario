class_name Cannon
extends Enemy

enum State {
	IDLE,
	FIRE,
}

const PLAYER_RANGE := Variables.TILE_SIZE.x * 3
const MAX_BULLET_NUM := 4
const MIN_WAIT_TIME := 0.5
const MAX_WAIT_TIME := 3.0

var can_fire := true
var is_player_nearby := false
var rng := RandomNumberGenerator.new()

@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D
@onready var fire_timer: Timer = $FireTimer

func get_next_state(state: State) -> int:
	
	match state:
		State.IDLE:
			var should_fire = can_fire \
				and not is_player_nearby \
				and get_tree().get_node_count_in_group("Bullet") < MAX_BULLET_NUM
			if should_fire:
				return State.FIRE
		State.FIRE:
			if not can_fire:
				return State.IDLE
	return state_machine.KEEP_CURRENT


func tick_physics(_state: State, _delta: float) -> void:
	if player:
		# 更新玩家位置
		is_player_nearby = abs(player.global_position.x - global_position.x) < PLAYER_RANGE
	
func transition_state(_from: State, to: State) -> void:
	match to:
		State.FIRE:
			# 发射炮弹
			var bullet_instance := preload("res://scenes/characters/bullet.tscn").instantiate() as Bullet
			bullet_instance.direction = Direction.LEFT if player.global_position.x < global_position.x else Direction.RIGHT
			var enemy_enabler := preload("res://scenes/characters/enemy_enabler.tscn").instantiate()
			var node2d := Node2D.new()
			node2d.global_position = global_position
			node2d.add_child(bullet_instance)
			node2d.add_child(enemy_enabler)
			owner.add_child(node2d)
			can_fire = false
			fire_timer.start(rng.randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME))
		
func _on_fire_timer_timeout() -> void:
	if rng.randf_range(0, 1) > 0.66:
		can_fire = true
	else:
		fire_timer.start(rng.randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME))
