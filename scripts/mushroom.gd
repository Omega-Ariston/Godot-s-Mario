class_name Mushroom
extends CharacterBody2D

@export var mushroom_type: Bumpable.SPAWN_ITEM

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const SPAWN_DURATION := 1.0
const MOVE_DELAY := 0.1
const SPEED := 60.0

var direction := 1
var spawning := true

func _ready() -> void:
	if mushroom_type == Bumpable.SPAWN_ITEM.UPGRADE:
		animation_player.play("big")
	elif mushroom_type == Bumpable.SPAWN_ITEM.LIFE:
		animation_player.play("life")
	
	# 让自身向上顶出一个砖的高度，并开始向右以固定速度移动
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - Variables.TILE_SIZE.y, SPAWN_DURATION)
	await tween.finished
	# 延迟一会
	await get_tree().create_timer(MOVE_DELAY).timeout
	spawning = false
	collision_shape_2d.disabled = false

func _physics_process(delta: float) -> void:
	if is_on_wall():
		# 撞到墙就反向跑
		direction = -direction
	if not spawning:
		move(GameManager.default_gravity, delta)

func move(gravity: float, delta: float) -> void:
	velocity.x = SPEED * direction
	velocity.y += gravity * delta
	move_and_slide()
