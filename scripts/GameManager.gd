extends Node

var max_left_x: float
const TILE_SIZE := Vector2(16, 16)

const BUMP_HEIGHT := 8.0
const BUMP_DURATION := 0.1

const MAX_ITEM_CONTACT := 3

enum SPAWNABLE {
	EMPTY,
	COIN,
	MUSHROOM_BIG,
	MUSHROOM_LIFE
}

func init_contact(node: RigidBody2D):
	node.contact_monitor = true
	node.max_contacts_reported = MAX_ITEM_CONTACT

func do_bump(node: Node) -> void:
	# 先往上顶一小段距离，然后下落回来
	var tween:= create_tween()
	var originalY := node.position.y as float
	tween.tween_property(node, "position:y", originalY - BUMP_HEIGHT, BUMP_DURATION)
	await tween.finished
	tween = create_tween()
	tween.tween_property(node, "position:y", originalY, BUMP_DURATION)

func do_spawn(node: Node, item: SPAWNABLE) -> void:
	# 生成被顶出的物品
	print_debug("Spawning %s" % SPAWNABLE.keys()[item])
	var item_instance: Node2D
	if item == SPAWNABLE.COIN:
		item_instance = load("res://scenes/items/coin.tscn").instantiate() as Node2D
	elif item == SPAWNABLE.MUSHROOM_BIG || item == SPAWNABLE.MUSHROOM_LIFE:
		item_instance = load("res://scenes/items/mushroom.tscn").instantiate() as Mushroom
		item_instance.mushroom_type = item
	if item_instance != null:
		node.call_deferred("add_child", item_instance)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		change_scene(get_tree().current_scene.scene_file_path)

func change_scene(path: String):
	get_tree().change_scene_to_file(path)
	# 重置相机镜头
	max_left_x = 0
