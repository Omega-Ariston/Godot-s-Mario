class_name EnterPoint
extends Marker2D

@export_file("*.tscn") var new_scene : String
@export var spawn_point_name : String
@export var direction : ENTER_DIRECTION

enum ENTER_DIRECTION {
	DOWN,
	RIGHT,
}

var enter_requested = false

func _input(event: InputEvent) -> void:
	match direction:
		ENTER_DIRECTION.DOWN:
			if event.is_action_pressed("crouch"):
				enter_requested = true
			if event.is_action_released("crouch"):
				enter_requested = false
		ENTER_DIRECTION.RIGHT:
			if event.is_action_pressed("move_right"):
				enter_requested = true
			if event.is_action_released("move_right"):
				enter_requested = false

func _physics_process(_delta: float) -> void:
	if enter_requested:
		var player := get_tree().get_first_node_in_group("Player") as Player
		var min_enter_distance
		if direction == ENTER_DIRECTION.DOWN:
			min_enter_distance = 6
		else:
			# 角色碰撞体积的一半
			min_enter_distance = floori(player.collision_shape_2d.shape.get_rect().size.x / 2)
		if player.state_machine.current_state in player.GROUND_STATES and global_position.distance_to(player.global_position) <= min_enter_distance:
			enter_requested = false
			await enter_pipe(player)
			# 切换场景
			var params := { "player_mode": player.curr_mode }
			if spawn_point_name:
				params["spawn_point"] = spawn_point_name
			GameManager.change_scene(new_scene, params)

func enter_pipe(player: Player) -> void:
	# 禁用角色碰撞和输入事件
	GameManager.uncontrol_player(player)
	# 角色移动入口方向的三个瓦片长度
	var enter_distance := GameManager.TILE_SIZE.y * 3 if direction == ENTER_DIRECTION.DOWN else GameManager.TILE_SIZE.x
	var enter_duration := 1.0
	var tween = create_tween()
	match direction:
		ENTER_DIRECTION.RIGHT:
			tween.tween_property(player, "global_position:x", global_position.x + enter_distance, enter_duration)
		ENTER_DIRECTION.DOWN: 
			tween.tween_property(player, "global_position:y", global_position.y + enter_distance, enter_duration)
	await tween.finished
