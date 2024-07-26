class_name Star
extends CharacterBody2D

const SPAWN_DURATION := 1.0
const SPEED := 60.0
const JUMP_VELOCITY := -230.0

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var direction := 1
var spawning := true

func _ready() -> void:
	animation_player.play("blink")
	# 让自身向上顶出一个砖的高度，并开始向右以固定速度跳跃移动
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - GameManager.TILE_SIZE.y, SPAWN_DURATION)
	await tween.finished
	spawning = false
	collision_shape_2d.disabled = false

func _physics_process(delta: float) -> void:
	if is_on_wall():
		# 撞到墙就反向跑
		direction = -direction
	if not spawning:
		if is_on_floor():
			# 碰到地就跳
			velocity.y = JUMP_VELOCITY
		move(GameManager.default_gravity / 2, delta)

func move(gravity: float, delta: float) -> void:
	velocity.x = SPEED * direction
	velocity.y += gravity * delta
	move_and_slide()
