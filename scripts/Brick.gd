class_name Brick
extends StaticBody2D

const SCORE := 50

const COLOR_ORIGIN := [
	Vector4(0.61, 0.29, 0.0, 1.0)
]

const COLOR_CYAN := [
	Vector4(0.0, 0.47, 0.54, 1.0)
]

@export var spawn_item: Bumpable.SpawnItem

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bumpable: Bumpable = $Bumpable
@onready var bump_timer: Timer = $BumpTimer
@onready var sprite_2d: Sprite2D = $Sprite2D

var bumped := false

func _ready() -> void:
	await GameManager.world_ready
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN)
	if GameManager.current_world_type == World.Type.UNDER:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN)
	animation_player.play("unbumped")

func on_bumped(player: Player, broken: bool = false) -> void:
	if bumpable.can_bump:
		bumpable.apply_bump_effect()
		if spawn_item == Bumpable.SpawnItem.EMPTY and (player.curr_mode != player.Mode.SMALL or broken):
			bumpable.can_bump = false
			SoundManager.play_sfx("BrokenBrick")
			ScoreManager.add_score(SCORE, self, false)
			var instance := load("res://scenes/bricks/broken_brick.tscn").instantiate() as BrokenBrick
			instance.global_position = global_position
			get_tree().root.add_child(instance)
			queue_free()
		elif spawn_item == Bumpable.SpawnItem.COIN:
			SoundManager.play_sfx("Coin")
			# 金币在第一次顶之后开始计时，时间到达之后只能顶最后一下
			if not bumped:
				bumped = true
				bump_timer.start()
			elif bump_timer.time_left == 0:
					animation_player.play("bumped")
					bumpable.can_bump = false
			bumpable.do_bump()
			bumpable.do_spawn(self, spawn_item, player)
		else:
			# 道具要等顶完再生成
			if spawn_item != Bumpable.SpawnItem.EMPTY:
				bumpable.can_bump = false
				SoundManager.play_sfx("Vine" if spawn_item == Bumpable.SpawnItem.VINE else "UpgradeAppear")
				animation_player.play("bumped")
			await bumpable.do_bump()
			if spawn_item != Bumpable.SpawnItem.EMPTY:
				bumpable.do_spawn(self, spawn_item, player)
