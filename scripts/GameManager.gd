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

func init_contact(node: RigidBody2D):
	node.contact_monitor = true
	node.max_contacts_reported = MAX_ITEM_CONTACT


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		change_scene(get_tree().current_scene.scene_file_path)
	if event.is_action_pressed("test"):
		get_tree().get_first_node_in_group("Player").can_onfire = true

func change_scene(path: String):
	get_tree().change_scene_to_file(path)
	# 重置相机镜头
	max_left_x = 0
