extends Node

var max_left_x: float
const TILE_SIZE := Vector2(16, 16)


enum SPAWN_ITEM {
	EMPTY,
	COIN,
	UPGRADE,
	LIFE,
	STAR,
}

const MAX_ITEM_CONTACT := 3
var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		change_scene(get_tree().current_scene.scene_file_path)
	if event.is_action_pressed("test"):
		var player := get_tree().get_first_node_in_group("Player") as Player
		player.can_onfire = true
		print_debug(player.small_animator.is_playing(), player.big_animator.is_playing(), player.fire_animator.is_playing())

func change_scene(path: String, params: Dictionary = {}):
	var tree := get_tree()
	tree.change_scene_to_file(path)
	await tree.tree_changed
	
	var player := tree.get_first_node_in_group("Player") as Player
	
	if params.has("player_mode"):
		player.curr_mode = params.get("player_mode")
	
	if params.has("spawn_point"):
		var spawn_point = params.get("spawn_point") as String
		for point: SpawnPoint in tree.get_nodes_in_group("SpawnPoints"):
			# 找到指定点
			if point.name == spawn_point:
				player.global_position = point.global_position
				# 如果需要从管道钻出来，则从指定点的反方向3个瓦片的距离出生，并且提前禁用物理碰撞和控制 TODO:这个应该是默认配置
				if point.direction != point.SPAWN_DIRECTION.NONE:
					uncontrol_player(player)
					player.is_spawning = true
					player._get_animator().play("idle") # 默认刚出来就是站立姿势
					player.global_position.y += TILE_SIZE.y * 3 * point.direction
					var tween := create_tween()
					tween.tween_property(player, "global_position:y", point.global_position.y, 1.0)
					await tween.finished
					player.is_spawning = false
					control_player(player)
					
	# 重置相机镜头
	max_left_x = 0

func uncontrol_player(player: Player) -> void:
	player.velocity = Vector2.ZERO
	player.collision_shape_2d.set_deferred("disabled", true)
	player.set_process_input(false)
	player.controllable = false

func control_player(player: Player) -> void:
	player.collision_shape_2d.set_deferred("disabled", false)
	player.set_process_input(true)
	player.controllable = true
