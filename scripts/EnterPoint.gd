class_name EnterPoint
extends Marker2D

@export_file("*.tscn") var new_scene : String
@export var spawn_point_name : String
@export var direction : ENTER_DIRECTION

enum ENTER_DIRECTION {
	DOWN, # 水管
	RIGHT, # 水管
	UP, # 藤蔓
}

var player: Player
var entered := false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta: float) -> void:
	if not entered:
		var can_enter: bool
		var should_enter: bool
		var min_enter_distance: float
		match direction:
			ENTER_DIRECTION.DOWN:
				can_enter = Input.is_action_pressed("move_down")
				should_enter = player.state_machine.current_state in player.GROUND_STATES
				min_enter_distance = 6.0
			ENTER_DIRECTION.RIGHT:
				can_enter = Input.is_action_pressed("move_right")
				should_enter = player.state_machine.current_state in player.GROUND_STATES
				# 角色碰撞体积的一半
				min_enter_distance = ceilf(player.collision_shape_2d.shape.get_rect().size.x / 2)
			ENTER_DIRECTION.UP:
				can_enter = true
				should_enter = player.state_machine.current_state == player.State.CLIMB
				min_enter_distance = Variables.TILE_SIZE.y
		should_enter = should_enter and global_position.distance_to(player.global_position) <= min_enter_distance 
		if can_enter and should_enter:
			await enter()
			# 切换场景
			var params := { "player_mode": player.curr_mode }
			if spawn_point_name:
				params["spawn_point"] = spawn_point_name
			if player.is_invincible:
				params["invincible_time_left"] = player.invincible_timer.time_left
			GameManager.change_scene(new_scene, params)

func enter() -> void:
	entered = true
	var curr_velocity = Vector2(player.velocity)
	var player_width := player.sprite_2d.get_rect().size.x
	var player_height := player.sprite_2d.get_rect().size.y
	# 禁用角色碰撞和输入事件
	GameManager.uncontrol_player(player)
	var tween = create_tween()
	match direction:
		ENTER_DIRECTION.RIGHT:
			tween.tween_property(player, "global_position:x", global_position.x + player_width, 0.8)
		ENTER_DIRECTION.DOWN: 
			tween.tween_property(player, "global_position:y", global_position.y + player_height, 0.8)
		ENTER_DIRECTION.UP:
			var duration := abs(player.global_position.y / curr_velocity.y) as float
			tween.tween_property(player, "global_position:y", -Variables.TILE_SIZE.y, duration)
	await tween.finished
