class_name Climable
extends Area2D

@onready var climb_area: CollisionShape2D = $ClimbArea

func _ready() -> void:
	body_entered.connect(_on_area_2d_body_entered)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		# 让玩家进入攀爬状态，并设置正确的朝向
		body.can_climb = true
		body.climbing_object = self
		if body.velocity.x < 0:
			body.direction = body.Direction.LEFT
		else:
			body.direction = body.Direction.RIGHT
		attach_player(body)
		
func attach_player(player: Player) -> void:
	# 把玩家固定到攀爬点
	player.global_position.x = climb_area.global_position.x - \
			player.direction * player.collision_shape_2d.shape.get_rect().size.x / 2
	player.velocity = Vector2.ZERO

