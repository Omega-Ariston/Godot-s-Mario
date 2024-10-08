class_name Star
extends CharacterBody2D

const SPAWN_DURATION := 1.0
const SPEED := 60.0
const JUMP_VELOCITY := -240.0
const SCORE := 1000
const MAX_FALL_SPEED := 240.0 # 04000

const RECT_ORIGIN := Rect2(0, 48, 64, 16)
const RECT_CYAN := Rect2(144, 48, 64, 16)

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var direction := 1
var spawning := true

func _ready() -> void:
	match GameManager.current_world_type:
		GameManager.WorldType.GROUND:
			sprite_2d.region_rect = RECT_ORIGIN
		GameManager.WorldType.UNDER:
			sprite_2d.region_rect = RECT_CYAN
	animation_player.play("blink")
	# 让自身向上顶出一个砖的高度，并开始向右以固定速度跳跃移动
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - Variables.TILE_SIZE.y, SPAWN_DURATION)
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
		move(Variables.DEFAULT_GRAVITY / 2, delta)

func move(gravity: float, delta: float) -> void:
	velocity.x = SPEED * direction
	var velocity_y = velocity.y + gravity * delta
	velocity.y = min(velocity_y, MAX_FALL_SPEED)
	move_and_slide()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
