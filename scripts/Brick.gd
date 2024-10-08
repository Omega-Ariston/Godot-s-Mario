class_name Brick
extends StaticBody2D

const SCORE := 50

const COLOR_ORIGIN := [
	Vector4(0.61, 0.29, 0.0, 1.0)
]

const COLOR_CYAN := [
	Vector4(0.0, 0.47, 0.54, 1.0)
]

const RECT_ORIGIN := Rect2(16, 0, 16, 16)
const RECT_BARE := Rect2(32, 0, 16, 16) # 不带亮面
const RECT_BUMPED := Rect2(48, 0, 16, 16)

@export var spawn_item: Bumpable.SpawnItem

@onready var bumpable: Bumpable = $Bumpable
@onready var bump_timer: Timer = $BumpTimer
@onready var sprite_2d: Sprite2D = $Sprite2D

var bumped := false

func _ready() -> void:
	await GameManager.world_ready
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == GameManager.WorldType.UNDER:
		sprite_2d.region_rect = RECT_BARE
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
	else:
		sprite_material.set_shader_parameter("shader_enabled", false)

func on_bumped(player: Player, broken: bool = false) -> void:
	if bumpable.can_bump:
		bumpable.can_bump = false
		bumpable.apply_bump_effect()
		if spawn_item == Bumpable.SpawnItem.EMPTY and (player.curr_mode != player.Mode.SMALL or broken):
			SoundManager.play_sfx("BrokenBrick")
			ScoreManager.add_score(SCORE, self, false)
			var instance := preload("res://scenes/bricks/broken_brick.tscn").instantiate() as BrokenBrick
			instance.global_position = global_position
			owner.add_child(instance)
			queue_free()
		elif spawn_item == Bumpable.SpawnItem.COIN:
			SoundManager.play_sfx("Coin")
			# 金币在第一次顶之后开始计时，时间到达之后只能顶最后一下
			if not bumped:
				bumped = true
				bump_timer.start()
			if bump_timer.is_stopped():
				sprite_2d.region_rect = RECT_BUMPED
			else:
				bumpable.do_bump(true)
				bumpable.do_spawn(self, spawn_item, player)
		else:
			# 道具要等顶完再生成
			if spawn_item != Bumpable.SpawnItem.EMPTY:
				SoundManager.play_sfx("Vine" if spawn_item == Bumpable.SpawnItem.VINE else "UpgradeAppear")
				sprite_2d.region_rect = RECT_BUMPED
			await bumpable.do_bump(true if player.curr_mode == Player.Mode.SMALL and spawn_item == Bumpable.SpawnItem.EMPTY else false)
			if spawn_item != Bumpable.SpawnItem.EMPTY:
				bumpable.do_spawn(self, spawn_item, player)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
