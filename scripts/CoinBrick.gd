extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bump_area: BumpArea = $BumpArea

@export var spawn_item: GameManager.SPAWNABLE

var bumpable := true

func _ready() -> void:
	animation_player.play("unbumped")
	bump_area.bump.connect(on_bumped)

func on_bumped(bumper: Bumper) -> void:
	if bumpable:
		GameManager.do_bump(self)
		if spawn_item != GameManager.SPAWNABLE.EMPTY:
			animation_player.play("bumped")
			GameManager.do_spawn(self, spawn_item, bumper.owner)
			bumpable = false
