extends Node

const CHANGE_SCENE_DURATION := 0.4
const VINE_RISE_COUNT := 6
const TRANSITION_SCENE_PATH := "res://scenes/worlds/transition.tscn"
const LIFE_COUNT := 3
const INITIAL_CAMERA_OFFSET := Variables.TILE_SIZE.x * 4

enum WorldType {
	GROUND,
	UNDER,
	WATER,
	CASTLE
}

var current_level: String
var current_spawn_point: String
var current_world_type : WorldType
var player_current_mode: Player.Mode
var life := LIFE_COUNT
var is_time_up := false
var into_the_under := false

@onready var scene_changer: ColorRect = $CanvasLayer/SceneChanger
@onready var game_timer: Timer = $GameTimer
@onready var score_timer: Timer = $ScoreTimer

signal screen_ready
signal score_counted
signal world_ready
signal player_ready

func _ready() -> void:
	scene_changer.color.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		change_scene(StatusBar.level)
	if event.is_action_pressed("test"):
		var player := get_tree().get_first_node_in_group("Player") as Player
		if player.curr_mode == Player.Mode.SMALL:
			player.can_enlarge = true
		elif player.curr_mode == Player.Mode.LARGE:
			player.can_onfire = true

func restore_status() -> void:
	current_level = ""
	current_spawn_point = ""
	StatusBar.level = "1-1"
	player_current_mode = Player.Mode.SMALL
	life = LIFE_COUNT
	is_time_up = false

func add_life() -> void:
	SoundManager.play_sfx("ExtraLife")
	life += 1
	
func end_level_by_flag_pole() -> void:
	# 判断是否要放烟花
	var end_num := StatusBar.time % 10 as int
	# 计分
	score_timer.start()
	await score_counted
	# 升旗
	var white_flag = get_tree().get_first_node_in_group("WhiteFlag") as WhiteFlag
	await create_tween().tween_property(white_flag, "global_position:y", white_flag.global_position.y - Variables.TILE_SIZE.y * 1.5, 0.5).finished
	# 如果有烟花就放烟花
	if end_num in [1, 3, 6]:
		await white_flag.play_firework(end_num)
	# 等通关音乐结束
	if SoundManager.bgm_player.playing:
		await SoundManager.bgm_player.finished
	# 等两秒
	await get_tree().create_timer(2).timeout
	# 1-1和4-1有特殊开场动画
	if StatusBar.level in ["1-1", "4-1"]:
		GameManager.into_the_under = true
	var next_level
	# 特殊跳关
	if StatusBar.level == '1-2':
		# 1-2直接跳到4-1
		next_level = "4-1"
	elif StatusBar.level == '4-2':
		# 4-2直接跳到8-1
		next_level = "8-1"
	else:
		# 普通情况关卡数+1即可
		var level_array = StatusBar.level.split('-')
		next_level = level_array[0] + '-' + str(int(level_array[1]) + 1)
	transition_scene(next_level)

func get_level_scene_path(level: String) -> String:
		return "res://scenes/worlds/" + level + ".tscn"

func title_scene() -> void:
	# 黑幕设为不透明
	scene_changer.color.a = 1.0	
	# 切换标题场景
	var title_scene_path := "res://scenes/worlds/title.tscn"
	var tree = get_tree()
	tree.change_scene_to_file(title_scene_path)
	await tree.tree_changed
	# 恢复屏幕
	var scene_change_timer = tree.create_timer(CHANGE_SCENE_DURATION)
	await scene_change_timer.timeout
	scene_changer.color.a = 0.0

func transition_scene(level: String, black=true) -> void:
	if black:
		# 黑幕设为不透明
		scene_changer.color.a = 1.0	
	# 解除死亡造成的暂停
	PauseManager.unpause_normal()
	# 设置状态栏
	var tree := get_tree()
	StatusBar.level = level
	var scene_change_timer: SceneTreeTimer
	if black:
		# 切换场景
		scene_change_timer = tree.create_timer(CHANGE_SCENE_DURATION / 2)
	tree.change_scene_to_file(TRANSITION_SCENE_PATH)
	await tree.tree_changed
	if black:
		# 恢复屏幕
		await scene_change_timer.timeout
		scene_changer.color.a = 0.0
		screen_ready.emit()
	else:
		screen_ready.emit()

func change_scene(level: String, params: Dictionary = {}) -> void:
	# 黑幕设为不透明
	scene_changer.color.a = 1.0	
	# 解除死亡造成的暂停
	PauseManager.unpause_normal()
	# 切换场景
	var tree := get_tree()
	var scene_change_timer := tree.create_timer(CHANGE_SCENE_DURATION)
	# 进入地下的动画走单独的逻辑
	if into_the_under:
		into_the_under = false
		tree.change_scene_to_file("res://scenes/worlds/into_the_under.tscn")
		# 恢复屏幕
		await scene_change_timer.timeout
		scene_changer.color.a = 0.0
		screen_ready.emit()
		return
	# 初始化关卡
	tree.change_scene_to_file(get_level_scene_path(level))
	await world_ready
	# 设置时间
	if params.has("time"):
		StatusBar.time = params.get("time")
	# 初始化出生点
	var spawn_point: SpawnPoint
	var spawn_point_name = params.get("spawn_point") as String if params.has("spawn_point") else current_spawn_point
	for point: SpawnPoint in tree.get_nodes_in_group("SpawnPoints"):
		# 找到指定点
		if point.name == spawn_point_name:
			spawn_point = point
	# 初始化玩家
	var player := tree.get_first_node_in_group("Player") as Player
	player.direction = player.Direction.RIGHT
	uncontrol_player(player)
	player.global_position = spawn_point.global_position
	player_ready.emit()
	# 恢复屏幕
	await scene_change_timer.timeout
	scene_changer.color.a = 0.0
	# 如果有无敌，播放无敌动画
	var star_time_left = params.get("star_time_left", 0.0) as float
	if star_time_left > 0:
		player.is_under_star = true
		player.blink_animator.play("star", -1, 4.0, false)
	# 播放出场动画
	if spawn_point.direction != SpawnPoint.Spawn_Direction.NONE:
		player.is_spawning = true
		if spawn_point.type == SpawnPoint.Type.VINE:
			await _animate_vine(player, spawn_point)
		else:
			await _animate_pipe(player, spawn_point)
	# 恢复星星计时
	player.is_spawning = false
	if player.is_under_star:
		player.star_timer.start(star_time_left)
	screen_ready.emit()
						

func uncontrol_player(player: Player) -> void:
	player.state_machine.enabled = false
	player.velocity = Vector2.ZERO
	player.collision_shape_2d.set_deferred("disabled", true)
	player.controllable = false

func control_player(player: Player) -> void:
	player.state_machine.enabled = true
	player.collision_shape_2d.set_deferred("disabled", false)
	player.controllable = true

func _animate_pipe(player: Player, spawn_point: SpawnPoint) -> void:
	SoundManager.play_sfx("PipeHurt")
	# 如果需要从管道钻出来，则从指定点的反方向3个瓦片的距离出生，并且提前禁用物理碰撞和控制 TODO:这个应该是默认配置
	player.animation_player.play("idle") # 默认刚出来就是站立姿势
	player.global_position.y += Variables.TILE_SIZE.y * 3 * spawn_point.direction
	if current_world_type == WorldType.WATER:
		# 角色消失
		player.visible = false
	else:
		# 角色放到后面去
		player.z_index = -1
	var tween := create_tween()
	tween.tween_property(player, "global_position:y", spawn_point.global_position.y, 1.0)
	await tween.finished
	if current_world_type == WorldType.WATER:
		# 角色重新出现
		player.visible = true
	else:
		# 角色回到前面来
		player.z_index = 3

func _animate_vine(player: Player, spawn_point: SpawnPoint) -> void:
	SoundManager.play_sfx("Vine")
	# 如果从藤蔓爬出来，则从指定点下两个瓦片出生，并等藤蔓长完4个瓦片高度后爬上来落地
	player.global_position.y += Variables.TILE_SIZE.y * 2
	# 角色放到后面去
	player.z_index = -1
	var vine_instance = preload("res://scenes/climables/vine.tscn").instantiate() as Vine
	vine_instance.rise_count = VINE_RISE_COUNT
	vine_instance.position.y += Variables.TILE_SIZE.y / 2 # 中心点偏移量
	spawn_point.add_child(vine_instance)
	# 设置玩家的攀爬状态
	player.can_climb = true
	player.climbing_object = vine_instance
	player.state_machine.current_state = player.State.CLIMB
	player.animation_player.play("climb")
	# 把玩家吸上藤蔓
	vine_instance.climable.attach_player(player)
	await vine_instance.rise_completed
	# 等藤蔓长完之后让玩家上来
	var tween := create_tween()
	tween.tween_property(player, "global_position:y", spawn_point.global_position.y - (VINE_RISE_COUNT - 2) * Variables.TILE_SIZE.y, (VINE_RISE_COUNT - 2) * 0.5)
	await tween.finished
	# 爬到顶端后停止动作并换边
	player.animation_player.speed_scale = 0
	player._change_climb_side()
	await get_tree().create_timer(0.5).timeout
	player._unclimb()
	player.direction = player.Direction.RIGHT
	# 手动切换状态
	player.transition_state(player.State.CLIMB, player.State.FALL)
	# 角色回到前面来
	player.z_index = 3
	# 等一小会，角色碰撞还没恢复，容易出问题
	await get_tree().create_timer(0.1).timeout


func _on_game_timer_timeout() -> void:
	var new_time = StatusBar.time - 1
	if new_time < 0:
		GameManager.is_time_up = true
		game_timer.stop()
	else:
		StatusBar.time = new_time


func _on_score_timer_timeout() -> void:
	if StatusBar.time > 0:
		StatusBar.time -= 1
		StatusBar.score += 20
	else:
		score_timer.stop()
		score_counted.emit()

func is_stomp(player: Player, body: Node2D) -> bool:
	return true if player.state_machine.current_state == Player.State.FALL else player.global_position.y < (body.global_position.y - Variables.TILE_SIZE.y / 2)
