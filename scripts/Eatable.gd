class_name Eatable
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_area_2d_body_entered)
	set_collision_layer_value(5, true)
	set_collision_mask_value(2, true)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		owner.queue_free()
		body._eat(owner)
