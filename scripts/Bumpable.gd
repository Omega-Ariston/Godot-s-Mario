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

func do_bump(reset := false) -> void:
	# 先往上顶一小段距离，然后下落回来
	var tween := create_tween()
	var originalY := owner.position.y as float
	tween.tween_property(owner, "position:y", originalY - BUMP_HEIGHT, BUMP_DURATION)
	await tween.finished
	tween = create_tween()
	tween.tween_property(owner, "position:y", originalY + 1, BUMP_DURATION)
	tween.tween_property(owner, "position:y", originalY, BUMP_DURATION)
	await tween.finished
	if reset:
		can_bump = true
	

func do_spawn(node: Node2D, item: SpawnItem, player: Player) -> void:
	# 生成被顶出的物品
	var item_instance: Node2D
	
	match item:
		SpawnItem.COIN:
			item_instance = preload("res://scenes/items/coin_bumped.tscn").instantiate() as CoinBumped
		SpawnItem.LIFE:
			item_instance = preload("res://scenes/items/mushroom.tscn").instantiate() as Mushroom
			item_instance.mushroom_type = SpawnItem.LIFE
		SpawnItem.UPGRADE:
			if player.curr_mode == Player.Mode.LARGE or player.curr_mode == Player.Mode.FIRE:
				item_instance = preload("res://scenes/items/flower.tscn").instantiate() as Flower
			else:
				item_instance = preload("res://scenes/items/mushroom.tscn").instantiate() as Mushroom
				item_instance.mushroom_type = SpawnItem.UPGRADE
		SpawnItem.STAR:
			item_instance = preload("res://scenes/items/star.tscn").instantiate() as Star
		SpawnItem.VINE:
			item_instance = preload("res://scenes/climables/vine.tscn").instantiate() as Vine
	item_instance.global_position = node.global_position
	get_tree().root.call_deferred("add_child", item_instance)

# 被玩家顶
func _on_bump_area_body_entered(body: Node2D) -> void:
	if body is Player and body.is_bumping(owner):
		if owner is CoinBrick and owner.is_hidden and can_bump:
			# 隐藏砖不能从上面往下触发
			if body.velocity.y >= 0:
				return
		body.on_bumping(true)
		owner.on_bumped(body)

# 把顶的效果应用到上方的物体
func apply_bump_effect() -> void:
	for area in effect_area.get_overlapping_areas():
		if area.owner.has_method("on_bumped"):
			area.owner.on_bumped(self)
	for body in effect_area.get_overlapping_bodies():
		print_debug(body.name)
		if body.has_method("on_bumped"):
			body.on_bumped(self)
