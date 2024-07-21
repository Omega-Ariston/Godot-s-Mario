class_name Mushroom
extends Eatable

@export var mushroom_type: GameManager.SPAWNABLE

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var wall_checker: RayCast2D = $WallChecker
@onready var eatbox: CollisionShape2D = $Area2D/Eatbox

const ACCELERATION := 70.0
const SPAWN_DURATION := 0.5
const MOVE_DELAY := 0.1

var direction := 1

func _ready() -> void:
	if mushroom_type == GameManager.SPAWNABLE.MUSHROOM_BIG:
		animation_player.play("big")
	elif mushroom_type == GameManager.SPAWNABLE.MUSHROOM_LIFE:
		animation_player.play("life")
	
	# 让自身向上顶出一个砖的高度，并开始向右以固定速度移动
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - GameManager.TILE_SIZE.y, SPAWN_DURATION)
	await tween.finished
	# 延迟一会
	await get_tree().create_timer(MOVE_DELAY).timeout
	freeze = false
	GameManager.init_contact(self)
	wall_checker.enabled = true

func _physics_process(delta: float) -> void:
	if wall_checker.is_colliding():
		direction = -direction
	wall_checker.scale.x = direction
	move_and_collide(Vector2(ACCELERATION * delta * direction, 0))

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		print_debug("%s got eaten!" % name)
		_on_eaten(body)
		queue_free()
