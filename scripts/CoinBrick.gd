class_name CoinBrick
extends StaticBody2D

const COLOR_ORIGIN := [
	Vector4(0.0, 0.0, 0.0, 1.0)
]

const COLOR_CYAN := [
	Vector4(0.0, 0.47, 0.54, 1.0)
]

const COLOR_GREY := [
	Vector4(0.38, 0.38, 0.38, 1.0)
]

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bumpable: Bumpable = $Bumpable
@onready var sprite_2d: Sprite2D = $Sprite2D


@export var spawn_item: Bumpable.SpawnItem
@export var is_hidden := false

func _ready() -> void:
	await GameManager.world_ready
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == GameManager.WorldType.UNDER:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
	elif GameManager.current_world_type == GameManager.WorldType.CASTLE:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_GREY.duplicate())
	else:
		sprite_material.set_shader_parameter("shader_enabled", false)
	if is_hidden:
		# 隐藏砖没有碰撞体积，并且图片透明
		set_collision_layer_value(1, false)
		sprite_2d.visible = false
	animation_player.play("unbumped")


func on_bumped(player: Player) -> void:
	if bumpable.can_bump:
		if is_hidden:
			# 隐藏砖显形并恢复碰撞体积
			set_collision_layer_value(1, true)
			sprite_2d.visible = true
		bumpable.can_bump = false
		bumpable.apply_bump_effect()
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
			set_collision_layer_value(1, true)
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

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
