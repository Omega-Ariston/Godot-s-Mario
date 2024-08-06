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
@onready var hurtbox: Area2D = $Hurtbox

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
	
# 被无敌星撞
func on_charged(body: Player) -> void:
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

func _on_hurtbox_area_entered(area: Area2D) -> void:
	print_debug("%s hit %s" % [area.owner.name, name])
	if area.owner is Player:
		# 优先处理无敌星，然后才是被踩
		var player := area.owner as Player
		print_debug(player.global_position.y, global_position.y)
		if player.is_under_star:
			# 碰到无敌星了
			on_charged(player)
		elif player.global_position.y < (global_position.y - Variables.TILE_SIZE.y / 2):
			# 如果来自上方就自己被踩
			on_stomped(player)
		elif self is Turtle and state_machine.current_state == Turtle.State.STOMPED:
			# 龟壳被玩家撞跑
			on_stomped(player)
	if area.owner is Fireball:
		on_hit(area.owner)
		area.owner.on_hit_enemy(self)
	if area.owner is Turtle and area.owner.state_machine.current_state == Turtle.State.SHOOT:
		on_hit(area.owner)
