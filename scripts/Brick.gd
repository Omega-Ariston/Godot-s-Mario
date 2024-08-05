extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var spawn_item: Bumpable.SpawnItem
@onready var bumpable: Bumpable = $Bumpable
@onready var bump_timer: Timer = $BumpTimer

var bumped := false

func _ready() -> void:
	animation_player.play("unbumped")


func on_bumped(player: Player) -> void:
	if bumpable.can_bump:
		if spawn_item == Bumpable.SpawnItem.EMPTY and player.curr_mode != player.Mode.SMALL:
			bumpable.can_bump = false
			SoundManager.play_sfx("BrokenBrick")
			var instance := load("res://scenes/bumpables/broken_brick.tscn").instantiate() as BrokenBrick
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

