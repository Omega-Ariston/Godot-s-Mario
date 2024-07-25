extends Node

var max_left_x: float
const TILE_SIZE := Vector2(16, 16)

const BUMP_HEIGHT := 8.0
const BUMP_DURATION := 0.1

const MAX_ITEM_CONTACT := 3

enum SPAWNABLE {
	EMPTY,
	COIN,
	UPGRADE,
	LIFE,
}

func init_contact(node: RigidBody2D):
	node.contact_monitor = true
	node.max_contacts_reported = MAX_ITEM_CONTACT

func do_bump(node: Node) -> void:
	# 先往上顶一小段距离，然后下落回来
	var tween:= create_tween()
	var originalY := node.position.y as float
	tween.tween_property(node, "position:y", originalY - BUMP_HEIGHT, BUMP_DURATION)
	tween.tween_property(node, "position:y", originalY, BUMP_DURATION)

func do_spawn(node: Node, item: SPAWNABLE, player: Player) -> void:
	# 生成被顶出的物品
	print_debug("Spawning %s" % SPAWNABLE.keys()[item])
	var item_instance: Node2D
	if item == SPAWNABLE.COIN:
		item_instance = load("res://scenes/items/coin_bumped.tscn").instantiate() as CoinBumped
	elif item == SPAWNABLE.LIFE:
		item_instance = load("res://scenes/items/mushroom.tscn").instantiate() as Mushroom
		item_instance.mushroom_type = SPAWNABLE.LIFE
	elif item == SPAWNABLE.UPGRADE:
		if player.curr_size == player.Size.LARGE:
			item_instance = load("res://scenes/items/flower.tscn").instantiate() as Flower
		else:
			item_instance = load("res://scenes/items/mushroom.tscn").instantiate() as Mushroom
			item_instance.mushroom_type = SPAWNABLE.UPGRADE
	if item_instance != null:
		node.call_deferred("add_child", item_instance)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		change_scene(get_tree().current_scene.scene_file_path)
	if event.is_action_pressed("fire"):
		get_tree().get_first_node_in_group("Player").can_onfire = true

func change_scene(path: String):
	get_tree().change_scene_to_file(path)
	# 重置相机镜头
	max_left_x = 0
