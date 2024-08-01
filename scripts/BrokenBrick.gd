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

func _ready() -> void:
	sprite_1.play("idle")
	sprite_2.play("idle")
	sprite_3.play("idle")
	sprite_4.play("idle")
	brick_1.apply_central_impulse(Vector2(-HIGHER_IMPULSE.x, -HIGHER_IMPULSE.y))
	brick_2.apply_central_impulse(Vector2(HIGHER_IMPULSE.x, -HIGHER_IMPULSE.y))
	brick_3.apply_central_impulse(Vector2(-LOWER_IMPULSE.x, -LOWER_IMPULSE.y))
	brick_4.apply_central_impulse(Vector2(LOWER_IMPULSE.x, -LOWER_IMPULSE.y))
	await get_tree().create_timer(1).timeout
	queue_free()

