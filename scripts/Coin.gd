class_name Coin
extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const SCORE := 200

const COLOR_ORIGIN := [
	Vector4(0.0, 0.0, 0.0, 1.0)
]

const COLOR_CYAN := [
	Vector4(0.0, 0.47, 0.54, 1.0)
]

func _ready() -> void:
	await GameManager.world_ready
	var sprite_material = animated_sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == GameManager.WorldType.UNDER:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
	else:
		sprite_material.set_shader_parameter("shader_enabled", false)

func on_bumped(_body=null) -> void:
	var item_instance = load("res://scenes/items/coin_bumped.tscn").instantiate() as CoinBumped
	item_instance.global_position = global_position
	get_tree().root.call_deferred("add_child", item_instance)
	on_eaten(false)

func on_eaten(add_score := true) -> void:
	SoundManager.play_sfx("Coin")
	if add_score:
		ScoreManager.add_score(SCORE, self, false)
	StatusBar.coin += 1
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		on_eaten()
