class_name FlagPole
extends Node2D

@export var door_distance := 6 as int

@onready var flag: Sprite2D = $Flag
@onready var climable: Climable = $Climable

const DOWN_SPEED := 130.0

var player_slipping := false
var player: Player
var player_destination_y: float

signal player_entered

func _on_climable_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body
		SoundManager.pause_bgm()
		SoundManager.play_sfx("FlagPole")
		# 降落旗子
		var flag_tween := create_tween()
		var flag_destination_y = global_position.y - Variables.TILE_SIZE.y * 1.5
		var flag_duration := abs(flag_destination_y - flag.global_position.y) / DOWN_SPEED as float
		flag_tween.tween_property(flag, "global_position:y", flag_destination_y, flag_duration)
		flag_tween.finished.connect(_on_flag_down_finished)
		# 控制玩家下降
		body.controllable = false
		player_destination_y = global_position.y - Variables.TILE_SIZE.y
		# 开始角色的滑行
		player_slipping = true
		

func _physics_process(_delta: float) -> void:
	if player_slipping:
		# 控制角色匀速滑行，直到滑到底
		if is_equal_approx(player.global_position.y, player_destination_y):
			player_slipping = false
		else:
			player.constant_speed_y = DOWN_SPEED
	else:
		# 检查角色是否已经走到了终止点，如果是就把角色杀掉并发出通知
		if player and player.global_position.x >= global_position.x + Variables.TILE_SIZE.x * door_distance:
			player.input_x = 0
			player.velocity = Vector2.ZERO
			player.visible = false
			player_entered.emit()

func _on_flag_down_finished() -> void:
	# 旗子落完角色就要停了
	if player_slipping:
		player_slipping = false
		player.velocity.y = 0
		player.constant_speed_y = 0
	# 下旗
	player._change_climb_side()
	await get_tree().create_timer(0.5).timeout
	player._unclimb()
	SoundManager.course_clear()
	# 往门的方向走
	player.input_x = 1.0
