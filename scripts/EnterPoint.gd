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
	var min_enter_distance: float
	if direction == ENTER_DIRECTION.DOWN:
		enter_requested = Input.is_action_pressed("move_down")
		min_enter_distance = 6.0
	else:
		enter_requested = Input.is_action_pressed("move_right")
		# 角色碰撞体积的一半
		min_enter_distance = ceilf(player.collision_shape_2d.shape.get_rect().size.x / 2)
	if enter_requested \
			and player.state_machine.current_state in player.GROUND_STATES \
			and global_position.distance_to(player.global_position) <= min_enter_distance:
		await enter_pipe()
		# 切换场景
		var params := { "player_mode": player.curr_mode }
		if spawn_point_name:
			params["spawn_point"] = spawn_point_name
		if player.is_invincible:
			params["invincible_time_left"] = player.invincible_timer.time_left
		GameManager.change_scene(new_scene, params)

func enter_pipe() -> void:
	var player_width := player.sprite_2d.get_rect().size.x
	var player_height := player.sprite_2d.get_rect().size.y
	# 禁用角色碰撞和输入事件
	GameManager.uncontrol_player(player)
	var enter_distance := player_height if direction == ENTER_DIRECTION.DOWN else player_width
	var enter_duration := 0.8 
	var tween = create_tween()
	match direction:
		ENTER_DIRECTION.RIGHT:
			tween.tween_property(player, "global_position:x", global_position.x + enter_distance, enter_duration)
		ENTER_DIRECTION.DOWN: 
			tween.tween_property(player, "global_position:y", global_position.y + enter_distance, enter_duration)
	await tween.finished
