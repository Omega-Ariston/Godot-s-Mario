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
@onready var visible_on_screen_enabler_2d: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox

const DEAD_BOUNCE := Vector2(50, -250)
const DEAD_Z_INDEX := 5
const PLAYER_STOMPED_BOUNCE := -200.0

var gravity := GameManager.default_gravity as float

var stomped := false # 被踩
var hit := false # 被火焰打中
var charged := false # 被无敌星撞到
var bumped := false # 被下方的砖块顶到

var attack_direction := Direction.RIGHT # 受到攻击时攻击的指向

func _ready() -> void:
	z_index = -1 # 不能站主角前面

func move(speed_var: float, direction_var: int, delta: float) -> void:
	velocity.x = speed_var * direction_var
	velocity.y += gravity * delta
	move_and_slide()
	
# 被踩
func on_stomped(player: Player) -> void:
	stomped = true
	SoundManager.play_sfx("Stomp")
	# 给玩家施加一个向上小跳的力
	player.velocity.y = PLAYER_STOMPED_BOUNCE
	# 取消对玩家的碰撞检测
	hurtbox.set_deferred("monitoring", false)
	set_collision_mask_value(2, false)
	
# 被无敌星撞或被龟壳撞
func on_charged(body: CharacterBody2D) -> void:
	charged = true
	SoundManager.play_sfx("Kill")
	attack_direction = Direction.LEFT if body.global_position.x > global_position.x else Direction.RIGHT

# 被火球打
func on_hit(body: CharacterBody2D) -> void:
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
