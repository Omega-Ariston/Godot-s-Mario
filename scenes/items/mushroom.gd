extends RigidBody2D

@export var mushroom_type: GameManager.MUSHROOM_TYPE

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const SPEED := 80.0
const SPAWN_DURATION := 0.5
const MOVE_DELAY := 0.1

func _ready() -> void:
	if mushroom_type == GameManager.MUSHROOM_TYPE.BIG:
		animation_player.play("big")
	elif mushroom_type == GameManager.MUSHROOM_TYPE.LIFE:
		animation_player.play("life")
	
	# 让自身向上顶出一个砖的高度，并开始向右以固定速度移动
	freeze = true
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - GameManager.TILE_SIZE.y, SPAWN_DURATION)
	await tween.finished
	# 延迟一会
	await get_tree().create_timer(MOVE_DELAY).timeout
	freeze = false

func _physics_process(delta: float) -> void:
	linear_velocity.x = SPEED
