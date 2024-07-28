extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var spawn_item: GameManager.SPAWN_ITEM
@onready var bumpable: Bumpable = $Bumpable
@onready var bump_timer: Timer = $BumpTimer

var bumped := false

func _ready() -> void:
	animation_player.play("unbumped")


func on_bumped(player: Player) -> void:
	if bumpable.can_bump:
		if spawn_item == GameManager.SPAWN_ITEM.COIN:
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
			animation_player.play("bumped")
			await bumpable.do_bump()
			if spawn_item != GameManager.SPAWN_ITEM.EMPTY:
				bumpable.do_spawn(self, spawn_item, player)
				bumpable.can_bump = false

