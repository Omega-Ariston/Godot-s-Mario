extends Node

var max_left_x: float
const CHANGE_SCENE_DURATION := 0.5
const VINE_RISE_COUNT := 4

var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float

@onready var scene_changer: ColorRect = $CanvasLayer/SceneChanger

func _ready() -> void:
	scene_changer.color.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		change_scene(get_tree().current_scene.scene_file_path)
	if event.is_action_pressed("test"):
		var player := get_tree().get_first_node_in_group("Player") as Player
		player.can_onfire = true

func change_scene(path: String, params: Dictionary = {}):
	# 黑幕设为不透明
	scene_changer.color.a = 1.0	
	# 重置相机镜头
	max_left_x = 0
	var timer := get_tree().create_timer(CHANGE_SCENE_DURATION)
	var tree := get_tree()
	tree.change_scene_to_file(path)
	await tree.tree_changed
	await timer.timeout
	# 恢复屏幕
	scene_changer.color.a = 0.0
	
	var player := tree.get_first_node_in_group("Player") as Player
	player.direction = player.Direction.RIGHT
	if params.has("player_mode"):
		player.curr_mode = params.get("player_mode")
	
	if params.has("spawn_point"):
		var spawn_point = params.get("spawn_point") as String
		for point: SpawnPoint in tree.get_nodes_in_group("SpawnPoints"):
			# 找到指定点
			if point.name == spawn_point:
				player.global_position = point.global_position
				
				if point.direction != SpawnPoint.Spawn_Direction.NONE:
					uncontrol_player(player)
					player.is_spawning = true
					
					# 如果有无敌，播放无敌动画
					var invincible_time_left = params.get("invincible_time_left", 0.0) as float
					if invincible_time_left > 0:
						player.is_invincible = true
						player.blink_animator.play("invincible")
						
					if point.type == SpawnPoint.Type.VINE:
						# 如果从藤蔓爬出来，则从指定点下一个瓦片出生，并等藤蔓长完4个瓦片高度后爬上来落地
						player._get_animator().play("climb")
						player.can_climb = true
						player.state_machine.current_state = player.State.CLIMB
						player.global_position.y += Variables.TILE_SIZE.y * 2
						var vine_instance = load("res://scenes/climables/vine.tscn").instantiate() as Vine
						vine_instance.rise_count = VINE_RISE_COUNT
						vine_instance.position.y += Variables.TILE_SIZE.y / 2 # 中心点偏移量
						point.add_child(vine_instance)
						vine_instance.attach_player(player)
						player.climbing_vine = vine_instance
						await vine_instance.rise_completed
						var tween := create_tween()
						tween.tween_property(player, "global_position:y", point.global_position.y - (VINE_RISE_COUNT - 1) * Variables.TILE_SIZE.y, (VINE_RISE_COUNT - 1) * 0.5)
						await tween.finished
						player._get_animator().speed_scale = 0
						player._change_climb_side()
						await get_tree().create_timer(0.5).timeout
						player._unclimb()
						player.transition_state(player.State.CLIMB, player.State.FALL)
						await get_tree().create_timer(0.1).timeout
					else:
						# 如果需要从管道钻出来，则从指定点的反方向3个瓦片的距离出生，并且提前禁用物理碰撞和控制 TODO:这个应该是默认配置
						player._get_animator().play("idle") # 默认刚出来就是站立姿势
						player.global_position.y += Variables.TILE_SIZE.y * 3 * point.direction
						var tween := create_tween()
						tween.tween_property(player, "global_position:y", point.global_position.y, 1.0)
						await tween.finished
					
					# 恢复角色控制和无敌计时
					player.is_spawning = false
					control_player(player)
					if player.is_invincible:
						player.invincible_timer.start(invincible_time_left)
						

func uncontrol_player(player: Player) -> void:
	player.state_machine.enabled = false
	player.velocity = Vector2.ZERO
	player.collision_shape_2d.set_deferred("disabled", true)
	player.set_process_input(false)
	player.controllable = false

func control_player(player: Player) -> void:
	player.state_machine.enabled = true
	player.collision_shape_2d.set_deferred("disabled", false)
	player.set_process_input(true)
	player.controllable = true
