class_name Bumpable
extends Area2D

const BUMP_HEIGHT := 8.0
const BUMP_DURATION := 0.1

enum SpawnItem {
	EMPTY,
	COIN,
	UPGRADE,
	LIFE,
	STAR,
	VINE,
}

var can_bump := true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_collision_mask_value(2, true)
	
func _on_body_entered(node: Node2D) -> void:
	if node is Player:
		print_debug("[Bumped] %s" % [ owner.name])
		owner.on_bumped(node)
		
		
func do_bump() -> void:
	# 先往上顶一小段距离，然后下落回来
	var tween:= create_tween()
	var originalY := owner.position.y as float
	tween.tween_property(owner, "position:y", originalY - BUMP_HEIGHT, BUMP_DURATION)
	tween.tween_property(owner, "position:y", originalY, BUMP_DURATION)
	await tween.finished
	

func do_spawn(node: Node, item: SpawnItem, player: Player) -> void:
	# 生成被顶出的物品
	print_debug("Spawning %s" % SpawnItem.keys()[item])
	var item_instance: Node2D
	
	match item:
		SpawnItem.COIN:
			item_instance = load("res://scenes/items/coin_bumped.tscn").instantiate() as CoinBumped
		SpawnItem.LIFE:
			item_instance = load("res://scenes/items/mushroom.tscn").instantiate() as Mushroom
			item_instance.mushroom_type = SpawnItem.LIFE
		SpawnItem.UPGRADE:
			if player.curr_mode == Player.Mode.LARGE or player.curr_mode == Player.Mode.FIRE:
				item_instance = load("res://scenes/items/flower.tscn").instantiate() as Flower
			else:
				item_instance = load("res://scenes/items/mushroom.tscn").instantiate() as Mushroom
				item_instance.mushroom_type = SpawnItem.UPGRADE
		SpawnItem.STAR:
			item_instance = load("res://scenes/items/star.tscn").instantiate() as Star
		SpawnItem.VINE:
			item_instance = load("res://scenes/climables/vine.tscn").instantiate() as Vine
	node.call_deferred("add_child", item_instance)
