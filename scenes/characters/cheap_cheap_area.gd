extends Area2D

const MAX_CHEAP_CHEAP_NUM := 3

var can_spawn := false

func _process(_delta: float) -> void:
	if can_spawn and get_tree().get_node_count_in_group("CheapCheaps") < MAX_CHEAP_CHEAP_NUM:
		var cheap_cheap := preload("res://scenes/characters/cheap_cheap.tscn").instantiate() as CheapCheap
		var node2d := Node2D.new()
		var center := get_viewport().get_camera_2d().get_screen_center_position().x
		var half_screen := get_viewport_rect().size.x / 2
		var left_bound := center - half_screen
		var right_bound := center + half_screen
		node2d.global_position.x = GameManager.rng.randf_range(left_bound, right_bound)
		node2d.global_position.y = Variables.BOTTOM_BOUNDARY
		node2d.add_child(cheap_cheap)
		var enemy_enabler := preload("res://scenes/characters/enemy_enabler.tscn").instantiate()
		node2d.add_child(enemy_enabler)
		owner.add_child(node2d)

func _on_body_entered(_body: Player) -> void:
	can_spawn = true

func _on_body_exited(_body: Player) -> void:
	can_spawn = false
