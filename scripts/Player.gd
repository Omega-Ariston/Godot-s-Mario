class_name Player
extends CharacterBody2D

const WALK_SPEED := 80.0
const JUMP_VELOCITY := -320.0

var gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var can_control := true

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	if can_control:
		var direction := Input.get_axis("move_left", "move_right")
		velocity.x = direction * WALK_SPEED
		velocity.y += gravity * delta

		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
		
		if is_on_floor():
			if is_zero_approx(direction):
				animation_player.play("idle")
			else:
				animation_player.play("walk")
		else:
			animation_player.play("jump")
			
		if not is_zero_approx(direction):
			sprite_2d.flip_h = direction < 0

		move_and_slide()
		global_position.x = max(global_position.x, GameManager.max_left_x + 8)
	
func _eat(item: Eatable) -> void:
	print_debug("Eatting: %s" % item.name)
	if item is Mushroom:
		if item.mushroom_type == GameManager.SPAWNABLE.MUSHROOM_BIG:
			# 如果当前很小，就变大，否则只加分
			print_debug("I am getting big!")
			animation_player.play("enlarge")
		elif item.mushroom_type == GameManager.SPAWNABLE.MUSHROOM_LIFE:
			# 奖命
			print_debug("Bonus Life!")

func _freeze_character() -> void:
	print_debug("stop")
	can_control = false
	
func _unfreeze_character() -> void:
	print_debug("continue")
	can_control = true
