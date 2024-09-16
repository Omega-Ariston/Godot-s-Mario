class_name Hadouken
extends CharacterBody2D

const SPEED := Vector2(60, 30)

var target_y : float


func _ready() -> void:
	# 生成后对齐到瓦片网络的垂直中心线上
	target_y = ceili(global_position.y / (Variables.TILE_SIZE.y / 2)) * (Variables.TILE_SIZE.y / 2)
	SoundManager.play_sfx("Hadouken")

func _physics_process(_delta: float) -> void:
	if not is_node_ready():
		await ready
	velocity.x = -SPEED.x
	if is_equal_approx(global_position.y, target_y):
		velocity.y = 0
	else:
		velocity.y = SPEED.y if target_y > global_position.y else -SPEED.y
	move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.hurt(self)
	elif body is Fireball:
		body.on_hit_enemy()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
