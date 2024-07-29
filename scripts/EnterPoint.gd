class_name EnterPoint
extends Marker2D

@export_file("*.tscn") var new_scene : String
@export var spawn_point_name : String
@export var direction : ENTER_DIRECTION

enum ENTER_DIRECTION {
	DOWN,
	RIGHT,
}

var player: Player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta: float) -> void:
	var enter_requested: bool
	var min_enter_distance: int
	if direction == ENTER_DIRECTION.DOWN:
		enter_requested = Input.is_action_pressed("crouch")
		min_enter_distance = 6
	else:
		enter_requested = Input.is_action_pressed("move_right")
		# 角色碰撞体积的一半
		min_enter_distance = floori(player.collision_shape_2d.shape.get_rect().size.x / 2)
	if enter_requested \
			and player.state_machine.current_state in player.GROUND_STATES \
			and global_position.distance_to(player.global_position) <= min_enter_distance:
		await enter_pipe()
		# 切换场景
		var params := { "player_mode": player.curr_mode }
		if spawn_point_name:
			params["spawn_point"] = spawn_point_name
		GameManager.change_scene(new_scene, params)

func enter_pipe() -> void:
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
