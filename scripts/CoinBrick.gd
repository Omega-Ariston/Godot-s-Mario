extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var spawn_item: GameManager.SPAWN_ITEM
@onready var bumpable: Bumpable = $Bumpable

func _ready() -> void:
	animation_player.play("unbumped")


func on_bumped(player: Player) -> void:
	if bumpable.can_bump:
		if spawn_item == GameManager.SPAWN_ITEM.COIN:
			# 金币直接顶
			bumpable.do_bump()
		else:
			# 道具等顶完再生成
			await bumpable.do_bump()
		if spawn_item != GameManager.SPAWN_ITEM.EMPTY:
			animation_player.play("bumped")
			bumpable.do_spawn(self, spawn_item, player)
			bumpable.can_bump = false

