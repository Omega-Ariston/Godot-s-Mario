class_name Mushroom
extends CharacterBody2D

@export var mushroom_type: Bumpable.SpawnItem

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D

const SPAWN_DURATION := 1.0
const MOVE_DELAY := 0.1
const SPEED := 60.0
const BOUNCE_SPEED := -200
const SCORE := 1000
const MAX_FALL_SPEED := 240.0 # 04000

# 顺序为蘑菇伞、蘑菇斑点、蘑菇柄
const COLOR_ORIGIN := [
	Vector4(0.90, 0.61, 0.12, 1.0),
	Vector4(0.70, 0.19, 0.12, 1.0),
	Vector4(0.98, 0.98, 0.98, 1.0)
]
const COLOR_GREEN := [
	Vector4(0.90, 0.61, 0.12, 1.0),
	Vector4(0.06, 0.58, 0, 1.0),
	Vector4(0.98, 0.98, 0.98, 1.0)
]
const COLOR_CYAN := [
	Vector4(0.51, 0.22, 0.06, 1.0),
	Vector4(0.0, 0.48, 0.54, 1.0),
	Vector4(0.98, 0.73, 0.67, 1.0)
]

var direction := 1
var spawning := true

func _ready() -> void:
	var sprite_material = sprite_2d.material as ShaderMaterial
	if mushroom_type == Bumpable.SpawnItem.LIFE:
		sprite_material.set_shader_parameter("shader_enabled", true)
		sprite_material.set_shader_parameter("origin_colors", COLOR_ORIGIN.duplicate())
		if GameManager.current_world_type == GameManager.WorldType.UNDER:
			sprite_material.set_shader_parameter("new_colors", COLOR_CYAN.duplicate())
		else:
			sprite_material.set_shader_parameter("new_colors", COLOR_GREEN.duplicate())
			
	
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
		move(Variables.DEFAULT_GRAVITY, delta)

func move(gravity: float, delta: float) -> void:
	velocity.x = SPEED * direction
	var velocity_y = velocity.y + gravity * delta
	velocity.y = min(velocity_y, MAX_FALL_SPEED)
	move_and_slide()

func on_bumped(bumpable: Bumpable) -> void:
	# 根据顶砖的位置确定蘑菇的新前进方向，并给予一个小跳的速度
	if not spawning:
		direction = -1 if bumpable.global_position.x > global_position.x else 1
		velocity.y = BOUNCE_SPEED
