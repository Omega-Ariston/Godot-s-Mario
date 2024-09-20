class_name Hammer
extends CharacterBody2D

const SPEED := 80
const INITIAL_JUMP_SPEED := -230
const LAUNCH_DELAY := 0.2
const GRAVITY := 562.5 # 00280
const MAX_FALL_SPEED := 240.0 # 04000

# 原始颜色，顺序为锤头、锤柄、连接处
const COLOR_ORIGIN := [
	Vector4(0.0, 0.0, 0.0, 1.0),
	Vector4(1.0, 0.80, 0.77, 1.0),
	Vector4(0.61, 0.29, 0, 1.0),
]

const COLOR_GREY := [
	Vector4(0.41, 0.41, 0.41, 1.0),
	Vector4(1.0, 1.0, 1.0, 1.0),
	Vector4(0.67, 0.67, 0.67, 1.0)
]

var direction := -1
var has_thrown := false
var launcher : HammerLauncher

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D

signal thrown

func _ready() -> void:
	var sprite_material = sprite_2d.material as ShaderMaterial
	sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
	if GameManager.current_world_type == GameManager.WorldType.CASTLE:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("new_colors", COLOR_GREY.duplicate())
	else:
		sprite_material.set_shader_parameter("shader_enabled", false)
	animation_player.play("idle")
	await get_tree().create_timer(LAUNCH_DELAY).timeout
	launch()
	has_thrown = true
	thrown.emit()
	
func _physics_process(delta: float) -> void:
	if has_thrown:
		velocity.x = direction * SPEED
		var velocity_y = velocity.y + GRAVITY * delta
		velocity.y = min(velocity_y, MAX_FALL_SPEED)
		move_and_slide()
	elif is_instance_valid(launcher):
		global_position = launcher.global_position

func launch() -> void:
	velocity.y = INITIAL_JUMP_SPEED
	if launcher.can_throw:
		area_2d.monitoring = true
	else:
		queue_free()
	match direction:
		-1:
			animation_player.play("spin")
		+1:
			animation_player.play_backwards("spin")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_2d_body_entered(body: Player) -> void:
	body.hurt(self)
