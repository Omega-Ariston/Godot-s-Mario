class_name Mushroom
extends RigidBody2D

@export var mushroom_type: GameManager.SPAWN_ITEM

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var wall_checker: RayCast2D = $WallChecker

const ACCELERATION := 60.0
const SPAWN_DURATION := 1.0
const MOVE_DELAY := 0.1

var direction := 1

var spawning := true

func _ready() -> void:
	if mushroom_type == GameManager.SPAWN_ITEM.UPGRADE:
		animation_player.play("big")
	elif mushroom_type == GameManager.SPAWN_ITEM.LIFE:
		animation_player.play("life")
	
	# 让自身向上顶出一个砖的高度，并开始向右以固定速度移动
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - GameManager.TILE_SIZE.y, SPAWN_DURATION)
	await tween.finished
	# 延迟一会
	await get_tree().create_timer(MOVE_DELAY).timeout
	spawning = false
	collision_shape_2d.disabled = false
	freeze = false
	GameManager.init_contact(self)
	wall_checker.enabled = true

func _physics_process(delta: float) -> void:
	if wall_checker.is_colliding():
		direction = -direction
	wall_checker.scale.x = direction
	if not spawning:
		move_and_collide(Vector2(ACCELERATION * delta * direction, 0))
