class_name Bumpable
extends Node2D


@onready var bump_area: Area2D = $BumpArea
@onready var effect_area: Area2D = $EffectArea

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

		
func do_bump() -> void:
	# 先往上顶一小段距离，然后下落回来
	var tween := create_tween()
	var originalY := owner.position.y as float
	# 上顶的过程中对上方物体应用上顶效果
	effect_area.set_deferred("monitoring", true)
	tween.tween_property(owner, "position:y", originalY - BUMP_HEIGHT, BUMP_DURATION)
	await tween.finished
	# 下落的过程就不用应用上顶效果了
	effect_area.set_deferred("monitoring", false)
	tween = create_tween()
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


# 被玩家顶
func _on_bump_area_body_entered(body: Node2D) -> void:
	if body is Player:
		print_debug("[Bumped] %s" % [ owner.name])
		owner.on_bumped(body)

# 把顶的效果应用到上方的物体
func _on_effect_area_body_entered(body: Node2D) -> void:
	if body is Enemy and body.is_on_floor():
		body.on_bumped(self)
	elif body is Mushroom and body.is_on_floor():
		body.on_bumped(self)
