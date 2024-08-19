class_name BrokenBrick
extends Node2D

@onready var sprite_1: AnimatedSprite2D = $RigidBody2D/AnimatedSprite2D
@onready var sprite_2: AnimatedSprite2D = $RigidBody2D2/AnimatedSprite2D
@onready var sprite_3: AnimatedSprite2D = $RigidBody2D3/AnimatedSprite2D
@onready var sprite_4: AnimatedSprite2D = $RigidBody2D4/AnimatedSprite2D

@onready var brick_1: RigidBody2D = $RigidBody2D
@onready var brick_2: RigidBody2D = $RigidBody2D2
@onready var brick_3: RigidBody2D = $RigidBody2D3
@onready var brick_4: RigidBody2D = $RigidBody2D4

const HIGHER_IMPULSE := Vector2(60, 350)
const LOWER_IMPULSE := Vector2(60, 250)

const COLOR_ORIGIN := [
	Vector4(0.61, 0.29, 0.0, 1.0)
, ]
const COLOR_CYAN := [
	Vector4(0.0, 0.47, 0.54, 1.0)
]

func _ready() -> void:
	for i in range(4):
		var sprite_material = self['sprite_' + str(i + 1)].material as ShaderMaterial
		sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN)
		if GameManager.current_world_type == World.Type.UNDER:
			sprite_material.set_shader_parameter("shader_enabled", true)
			sprite_material.set_shader_parameter("new_colors", COLOR_CYAN)
			
	brick_1.apply_central_impulse(Vector2(-HIGHER_IMPULSE.x, -HIGHER_IMPULSE.y))
	brick_2.apply_central_impulse(Vector2(HIGHER_IMPULSE.x, -HIGHER_IMPULSE.y))
	brick_3.apply_central_impulse(Vector2(-LOWER_IMPULSE.x, -LOWER_IMPULSE.y))
	brick_4.apply_central_impulse(Vector2(LOWER_IMPULSE.x, -LOWER_IMPULSE.y))
	await get_tree().create_timer(1, false).timeout
	queue_free()
