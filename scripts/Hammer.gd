class_name Hammer
extends CharacterBody2D

const SPEED := 80
const INITIAL_JUMP_SPEED := -230
const LAUNCH_DELAY := 0.2

var direction := -1
var has_thrown := false
var launcher : HammerLauncher

@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal thrown

func _ready() -> void:
	animation_player.play("idle")
	await get_tree().create_timer(LAUNCH_DELAY).timeout
	launch()
	has_thrown = true
	thrown.emit()
	
func _physics_process(delta: float) -> void:
	if has_thrown:
		velocity.x = direction * SPEED
		velocity.y += GameManager.default_gravity * delta
		move_and_slide()
	elif launcher:
		global_position = launcher.global_position

func launch() -> void:
	velocity.y = INITIAL_JUMP_SPEED
	match direction:
		-1:
			animation_player.play("spin")
		+1:
			animation_player.play_backwards("spin")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
