class_name EnterPoint
extends Marker2D

@export var new_level : String
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
				# 距离小于角色碰撞体积的3/5
				var min_enter_distance := ceilf(player.collision_shape_2d.shape.size.x * 3 / 5)
				should_enter = player.state_machine.current_state == player.State.WALK \
							and global_position.distance_to(player.global_position) <= min_enter_distance
			ENTER_DIRECTION.UP:
				can_enter = true
				# 玩家位置比进入点高就行，并且x轴在当前进入点的左右两边
				should_enter = player.state_machine.current_state == player.State.CLIMB \
						and player.global_position.y <= global_position.y \
						and abs(player.global_position.x - global_position.x) < Variables.TILE_SIZE.x
		if can_enter and should_enter:
			await enter()
			# 切换场景
			var params := { "player_mode": player.curr_mode }
			params["spawn_point"] = spawn_point_name
			# 四种情况：
			if not new_level:
				# 子->主 或 关卡内切换（迷宫关）
				params["time"] = StatusBar.time
				GameManager.change_scene(StatusBar.level, params)
			elif new_level.begins_with('sub'):
				# 主->子
				if player.is_under_star:
					params["star_time_left"] = player.star_timer.time_left
				params["time"] = StatusBar.time
				GameManager.change_scene(new_level, params)
			else:
				# 主->主
				GameManager.transition_scene(new_level)

func enter() -> void:
	entered = true
	# 暂停游戏时间
	GameManager.game_timer.stop()
	# 禁用角色碰撞和输入事件
	GameManager.uncontrol_player(player)
	var tween = create_tween()
	match direction:
		ENTER_DIRECTION.RIGHT:
			var sound := SoundManager.play_sfx("PipeHurt")
			player.direction = Player.Direction.RIGHT
			if GameManager.current_world_type == GameManager.WorldType.WATER:
				# 角色直接消失
				player.visible = false
			else:
				# 角色放到后面去
				player.z_index = -1
			# 播放走路动画
			player.animation_player.speed_scale = 1
			tween.tween_property(player, "global_position:x", global_position.x + Variables.TILE_SIZE.x / 2, 0.5)
			await sound.finished
			SoundManager.pause_bgm()
		ENTER_DIRECTION.DOWN: 
			var sound := SoundManager.play_sfx("PipeHurt")
			# 角色放到后面去
			player.z_index = -1
			tween.tween_property(player, "global_position:y", global_position.y + Variables.TILE_SIZE.y * 2, 0.8)
			await sound.finished
			SoundManager.pause_bgm()
		ENTER_DIRECTION.UP:
			# 播放动画攀爬动画
			player.animation_player.speed_scale = 1
			var duration := abs((player.global_position.y + Variables.TILE_SIZE.y) / player.CLIMB_UP_SPEED) as float
			tween.tween_property(player, "global_position:y", -Variables.TILE_SIZE.y, duration)
			await tween.finished
