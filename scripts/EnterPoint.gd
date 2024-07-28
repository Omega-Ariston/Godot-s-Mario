class_name EnterPoint
extends Marker2D

@export_file("*.tscn") var new_scene : String
@export var spawn_point_name : String
@export var direction : ENTER_DIRECTION

const MIN_ENTER_DISTANCE := 6

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
		if player.is_on_floor() and global_position.distance_to(player.global_position) <= MIN_ENTER_DISTANCE:
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
	var enter_distance := GameManager.TILE_SIZE.y * 3
	var enter_duration := 1.0
	var tween = create_tween()
	match direction:
		ENTER_DIRECTION.RIGHT:
			tween.tween_property(player, "global_position:x", global_position.x + enter_distance, enter_duration)
		ENTER_DIRECTION.DOWN: 
			tween.tween_property(player, "global_position:y", global_position.y + enter_distance, enter_duration)
	await tween.finished
