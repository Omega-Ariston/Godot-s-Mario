class_name Cannon
extends Enemy

enum State {
	IDLE,
	FIRE,
}

const PLAYER_RANGE := Variables.TILE_SIZE.x * 3
const MAX_BULLET_NUM := 4

var can_fire := true
var is_player_nearby := false

@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D
@onready var fire_timer: Timer = $FireTimer

func get_next_state(state: State) -> int:
	
	match state:
		State.IDLE:
			var should_fire = can_fire and not is_player_nearby and get_tree().get_node_count_in_group("Bullet") <= MAX_BULLET_NUM
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
			bullet_instance.global_position = global_position
			owner.add_child(bullet_instance)
			can_fire = false
			fire_timer.start()
		
func _on_fire_timer_timeout() -> void:
	can_fire = true
