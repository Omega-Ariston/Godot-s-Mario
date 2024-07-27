class_name Bumpable
extends Area2D

const BUMP_HEIGHT := 8.0
const BUMP_DURATION := 0.1

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
	

func do_spawn(node: Node, item: GameManager.SPAWN_ITEM, player: Player) -> void:
	# 生成被顶出的物品
	print_debug("Spawning %s" % GameManager.SPAWN_ITEM.keys()[item])
	var item_instance: Node2D
	
	match item:
		GameManager.SPAWN_ITEM.COIN:
			item_instance = load("res://scenes/items/coin_bumped.tscn").instantiate() as CoinBumped
		GameManager.SPAWN_ITEM.LIFE:
			item_instance = load("res://scenes/items/mushroom.tscn").instantiate() as Mushroom
			item_instance.mushroom_type = GameManager.SPAWN_ITEM.LIFE
		GameManager.SPAWN_ITEM.UPGRADE:
			if player.curr_mode == Player.Mode.LARGE or player.curr_mode == Player.Mode.FIRE:
				item_instance = load("res://scenes/items/flower.tscn").instantiate() as Flower
			else:
				item_instance = load("res://scenes/items/mushroom.tscn").instantiate() as Mushroom
				item_instance.mushroom_type = GameManager.SPAWN_ITEM.UPGRADE
		GameManager.SPAWN_ITEM.STAR:
			item_instance = load("res://scenes/items/star.tscn").instantiate() as Star
	node.call_deferred("add_child", item_instance)
