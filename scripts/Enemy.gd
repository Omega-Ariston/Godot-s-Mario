class_name Enemy
extends CharacterBody2D

enum Direction {
	LEFT = -1,
	RIGHT = +1,
}

@export var direction := Direction.LEFT:
	set(v):
		if not is_node_ready():
			await ready
		direction = v
		graphics.scale.x = -direction

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox

const DEAD_BOUNCE := Vector2(50, -150)
const DEAD_Z_INDEX := 4
const PLAYER_STOMPED_BOUNCE_HIGH := -4 * 60 # 04xxx
const PLAYER_STOMPED_BOUNCE_LOW := -3 * 60 # 03xxx
const MAX_FALL_SPEED := 120.0 # 02000
const SHOOT_CHAIN := [500, 800, 1000, 2000, 4000, 5000, 8000]

var curr_shoot_num := 0

var player: Player
var default_gravity := Variables.DEFAULT_GRAVITY as float

var stomped := false # 被踩
var hit := false # 被火焰打中
var charged := false # 被无敌星撞到
var bumped := false # 被下方的砖块顶到
var shot := false # 被壳撞到

var attack_direction := Direction.RIGHT # 受到攻击时攻击的指向

func _ready() -> void:
	GameManager.world_ready.connect(_on_world_ready)
	GameManager.player_ready.connect(_on_player_ready)

func move(speed_var: float, direction_var: int, delta: float, gravity: float = default_gravity, limit_speed := true) -> void:
	velocity.x = speed_var * direction_var
	var velocity_y = velocity.y + gravity * delta
	if limit_speed:
		velocity.y = min(velocity_y, MAX_FALL_SPEED)
	else:
		velocity.y = velocity_y
	move_and_slide()
	
# 被踩
func on_stomped() -> void:
	stomped = true
	SoundManager.play_sfx("Stomp")
	# 给玩家施加一个向上小跳的力，但只改变整数部分
	var bounce_height : float
	if self is Goomba or self is Beetle or self is Turtle:
		bounce_height = PLAYER_STOMPED_BOUNCE_HIGH
	else:
		bounce_height = PLAYER_STOMPED_BOUNCE_LOW
		
	player.velocity.y = bounce_height + player.velocity.y - int(player.velocity.y)
	# 取消对玩家的碰撞检测
	hurtbox.set_deferred("monitoring", false)
	set_collision_mask_value(2, false)
	
# 被无敌星撞
func on_charged(body: CharacterBody2D) -> void:
	charged = true
	SoundManager.play_sfx("Kill")
	attack_direction = Direction.LEFT if body.global_position.x > global_position.x else Direction.RIGHT

# 被壳撞
func on_shot(enemy: Enemy) -> void:
	shot = true
	SoundManager.play_sfx("Kill")
	attack_direction = Direction.LEFT if enemy.global_position.x > global_position.x else Direction.RIGHT
	# 使用撞击链来计分
	if enemy.curr_shoot_num >= SHOOT_CHAIN.size():
		ScoreManager.add_life(self)
	else:
		ScoreManager.add_score(SHOOT_CHAIN[enemy.curr_shoot_num], self)
	enemy.curr_shoot_num += 1

# 被火球打
func on_hit(body: Fireball) -> void:
	hit = true
	SoundManager.play_sfx("Kill")
	attack_direction = Direction.LEFT if body.global_position.x > global_position.x else Direction.RIGHT

# 被砖块从下面顶
func on_bumped(bumpable: Bumpable) -> void:
	bumped = true
	SoundManager.play_sfx("Kill")
	attack_direction = Direction.LEFT if bumpable.global_position.x > global_position.x else Direction.RIGHT

func die(pause := true) -> void:
	# 禁用碰撞
	collision_shape_2d.set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
	# 来到屏幕前面
	z_index = DEAD_Z_INDEX
	# 冻结动画并上下倒转
	if pause:
		animation_player.call_deferred("pause")
	graphics.scale.y = -1
	# 给一个小弹跳
	velocity.y = DEAD_BOUNCE.y

func start() -> void:
	set_process_mode(Node.PROCESS_MODE_INHERIT)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_player_ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _on_world_ready() -> void:
	# 由子类实现
	pass
