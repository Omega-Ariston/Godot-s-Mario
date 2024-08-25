class_name Fireball
extends CharacterBody2D

const HORIZONTAL_SPEED := 300
const JUMP_VELOCITY := -250.0
const LAUNCH_FALL_SPEED := 200

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var direction := 1
var has_grouded := false
var hit_enemy := false
var blasted := false

func _init() -> void:
	add_to_group("Fireballs")

func _ready() -> void:
	animation_player.play("fire")
	# 随机出一个火球形态
	var offset := randf() * animation_player.get_animation("fire").length
	animation_player.advance(offset)

func _physics_process(delta: float) -> void:
	if not hit_enemy:
		if is_on_wall():
			if not blasted:
				# 撞到墙就爆炸
				blasted = true
				SoundManager.play_sfx("Bump")
				animation_player.play("blast", -1, 3.0, false)
			return
		if is_on_floor():
			has_grouded = true
			# 碰到地就跳
			velocity.y = JUMP_VELOCITY
		move(GameManager.default_gravity * 2, delta)
			
func move(gravity: float, delta: float) -> void:
	velocity.x = HORIZONTAL_SPEED * direction
	if not has_grouded:
		velocity.y = LAUNCH_FALL_SPEED
	else:
		velocity.y += gravity * delta
	move_and_slide()

func _on_visible_on_screen_notifier_2d_screen_exited():
	# 离开屏幕时销毁
	queue_free()

func on_hit_enemy(enemy: Node2D) -> void:
	hit_enemy = true
	velocity = Vector2.ZERO
	if enemy is Enemy:
		animation_player.play("blast", -1, 3.0, false)
