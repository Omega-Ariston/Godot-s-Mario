extends Node

var max_left_x: float
const TILE_SIZE := Vector2(16, 16)


enum SPAWN_ITEM {
	EMPTY,
	COIN,
	UPGRADE,
	LIFE,
}

const MAX_ITEM_CONTACT := 3

func init_contact(node: RigidBody2D):
	node.contact_monitor = true
	node.max_contacts_reported = MAX_ITEM_CONTACT


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		change_scene(get_tree().current_scene.scene_file_path)
	if event.is_action_pressed("fire"):
		var player = get_tree().get_first_node_in_group("Player") as Player
		player._set_shader_enabled(true)
		player._set_shader_colors("GREEN")
		var material = player.sprite_2d.material as ShaderMaterial
		print_debug(material.get_shader_parameter("origin_colors"))
		print_debug(material.get_shader_parameter("new_colors"))
		#get_tree().get_first_node_in_group("Player").can_onfire = true

func change_scene(path: String):
	get_tree().change_scene_to_file(path)
	# 重置相机镜头
	max_left_x = 0
