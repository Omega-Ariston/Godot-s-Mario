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
		match direction:
			ENTER_DIRECTION.DOWN:
				can_enter = Input.is_action_pressed("move_down")
				# 距离小于一个比较小的值
				should_enter = player.state_machine.current_state in player.GROUND_STATES \
						and global_position.distance_to(player.global_position) <= 6.0 # 一个相对小的值
			ENTER_DIRECTION.RIGHT:
				can_enter = Input.is_action_pressed("move_right")
				# 距离小于角色碰撞体积的一半
				var min_enter_distance := ceilf(player.collision_shape_2d.shape.get_rect().size.x / 2)
				should_enter = player.state_machine.current_state in player.GROUND_STATES \
						and global_position.distance_to(player.global_position) <= min_enter_distance
			ENTER_DIRECTION.UP:
				can_enter = true
				# 玩家位置比进入点高就行
				should_enter = player.state_machine.current_state == player.State.CLIMB \
						and player.global_position.y <= global_position.y
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
	var player_width := player.sprite_2d.get_rect().size.x
	var player_height := player.sprite_2d.get_rect().size.y
	# 禁用角色碰撞和输入事件
	GameManager.uncontrol_player(player)
	var tween = create_tween()
	match direction:
		ENTER_DIRECTION.RIGHT:
			# 播放走路动画
			player._get_animator().speed_scale = 1
			tween.tween_property(player, "global_position:x", global_position.x + player_width, 0.8)
		ENTER_DIRECTION.DOWN: 
			tween.tween_property(player, "global_position:y", global_position.y + player_height, 0.8)
		ENTER_DIRECTION.UP:
			# 播放动画攀爬动画
			player._get_animator().speed_scale = 1
			var duration := abs(player.global_position.y / player.CLIMB_SPEED) as float
			tween.tween_property(player, "global_position:y", -Variables.TILE_SIZE.y, duration)
	await tween.finished
