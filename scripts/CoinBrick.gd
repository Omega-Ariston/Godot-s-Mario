class_name CoinBrick
extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bumpable: Bumpable = $Bumpable
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D


@export var spawn_item: Bumpable.SpawnItem
@export var is_hidden := false

func _ready() -> void:
	if is_hidden:
		# 隐藏砖没有碰撞体积，并且图片透明
		collision_shape_2d.disabled = true
		sprite_2d.visible = false
	animation_player.play("unbumped")


func on_bumped(player: Player) -> void:
	if bumpable.can_bump:
		if is_hidden:
			if player.velocity.y < 0:
				# 判断是否是来自下方的撞击，如果是，则砖显形并恢复碰撞体积
				bumpable.can_bump = false
				sprite_2d.visible = true
				# 重置玩家速度，防止玩家从斜下方蹭着飞上去
				player.velocity.y = 0
				collision_shape_2d.set_deferred("disabled", false)
			else:
				return
		else:
			bumpable.can_bump = false
		animation_player.play("bumped")
		if spawn_item == Bumpable.SpawnItem.COIN:
			# 金币直接顶
			SoundManager.play_sfx("Coin")
			bumpable.do_bump()
		else:
			# 道具等顶完再生成
			SoundManager.play_sfx("Vine" if spawn_item == Bumpable.SpawnItem.VINE else "UpgradeAppear")
			await bumpable.do_bump()
		if spawn_item != Bumpable.SpawnItem.EMPTY:
			bumpable.do_spawn(self, spawn_item, player)


func on_charged(player: Player) -> void:
	if bumpable.can_bump:
		bumpable.can_bump = false
		if is_hidden:
			# 砖显形并恢复碰撞体积
			sprite_2d.visible = true
			collision_shape_2d.set_deferred("disabled", false)
		animation_player.play("bumped")
		if spawn_item == Bumpable.SpawnItem.COIN:
			# 金币直接顶
			SoundManager.play_sfx("Coin")
			bumpable.do_bump()
		else:
			# 道具等顶完再生成
			SoundManager.play_sfx("Vine" if spawn_item == Bumpable.SpawnItem.VINE else "UpgradeAppear")
			await bumpable.do_bump()
		if spawn_item != Bumpable.SpawnItem.EMPTY:
			bumpable.do_spawn(self, spawn_item, player)
