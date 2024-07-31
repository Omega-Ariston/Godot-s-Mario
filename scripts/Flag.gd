class_name FlagPole
extends Node2D

@onready var flag: Sprite2D = $Flag
const DOWN_SPEED := 130.0

func _on_climable_body_entered(body: Node2D) -> void:
	if body is Player:
		# 降落旗子，并控制玩家下降
		body.controllable = false
		body.collision_shape_2d.disabled = true
		# 爬的动作快点
		body._get_animator().speed_scale = 2.0
		body._get_animator().play("climb")
		var player_tween := create_tween()
		var flag_tween := create_tween()
		var player_destination_y = global_position.y - Variables.TILE_SIZE.y
		var flag_destination_y = global_position.y - Variables.TILE_SIZE.y * 1.5
		var player_duration := abs(player_destination_y - body.global_position.y) / DOWN_SPEED as float
		var flag_duration := abs(flag_destination_y - flag.global_position.y) / DOWN_SPEED as float
		player_tween.tween_property(body, "global_position:y", player_destination_y, player_duration)
		flag_tween.tween_property(flag, "global_position:y", flag_destination_y, flag_duration)
		player_tween.finished.connect(_on_player_down_finished.bind(body))
		flag_tween.finished.connect(_on_flag_down_finished.bind(body, player_tween))

func _on_flag_down_finished(player: Player, player_tween: Tween) -> void:
	# 旗子落完角色就要停了
	player_tween.kill()
	player._change_climb_side()
	await get_tree().create_timer(0.5).timeout
	player._unclimb()
	player.direction = player.Direction.RIGHT
	# 往门的方向走
	player._get_animator().speed_scale = 1
	player.velocity.x = player.WALK_SPEED
	# 等角色落地后立刻接管
	await get_tree().create_timer(0.3).timeout
	player.state_machine.enabled = false
	player._get_animator().play("walk")
	var tween := create_tween()
	var distance := Variables.TILE_SIZE.x * 6
	tween.tween_property(player, "global_position:x", player.global_position.x + distance, distance / player.WALK_SPEED)
	
	
func _on_player_down_finished(player: Player) -> void:
	# 角色先落完就别动了
	player._get_animator().speed_scale = 0
