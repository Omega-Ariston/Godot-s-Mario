extends StaticBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bump_area: BumpArea = $BumpArea

@export_enum("Empty", "Coin", "Mushroom_Big") var spawn_item: String
var bumpable := true

func _ready() -> void:
	animation_player.play("unbumped")
	bump_area.bump.connect(on_bumped)

func on_bumped(bumper) -> void:
	if spawn_item != "Empty":
		print_debug("Spawning %s" % spawn_item)
		if spawn_item == "Coin":
			var coin := load("res://scenes/items/coin.tscn").instantiate() as Node2D
			add_child(coin)
		animation_player.play("bumped")
		bumpable = false
