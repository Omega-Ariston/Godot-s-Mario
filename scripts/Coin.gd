class_name Coin
extends Node2D

func on_bumped(_body=null) -> void:
	var item_instance = load("res://scenes/items/coin_bumped.tscn").instantiate() as CoinBumped
	item_instance.global_position = global_position
	get_tree().root.call_deferred("add_child", item_instance)
	on_eaten()

func on_eaten() -> void:
	SoundManager.play_sfx("Coin")
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		on_eaten()
