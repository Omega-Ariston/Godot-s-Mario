extends World

@onready var a: Marker2D = $Portals/A
@onready var b: Marker2D = $Portals/B
@onready var c: Marker2D = $Portals/C
@onready var d: Marker2D = $Portals/D
@onready var e: Marker2D = $Portals/E

@onready var enemies: Node2D = $Enemies

@onready var enemies_a: Node2D = $Enemies/A
@onready var enemies_b: Node2D = $Enemies/B
@onready var enemies_d: Node2D = $Enemies/D

@onready var special_pipes: Node2D = $Enemies/SpecialPipes
@onready var special_turtles: Node2D = $Enemies/B/SpecialTurtles
@onready var bridge_switch: BridgeSwitch = $BridgeSwitch
@onready var foreground: TileMapLayer = $TileMap/Foreground
@onready var bowser: Bowser = $Enemies/Node2D20/Bowser
@onready var endpoint: Marker2D = $EndScreen/Endpoint
@onready var thank_you: RichTextLabel = $EndScreen/ThankYou
@onready var lines: Node2D = $EndScreen/Lines


const SPECIAL_PIPE_E1_POSITION := [3136, 4160]
const SPECIAL_PIPE_E2_POSITION := [3280, 4304]

const CAPTURE_RANGE := Variables.TILE_SIZE.x * 8
const CHAIN_COORD := Vector2(316, 10)
const BRIDGE_COORD_Y := 11
const BRIDGE_COORD_X_RANGE := [304, 316]

var enemies_a_copy : Node2D
var enemies_b_copy : Node2D
var enemies_d_copy : Node2D
var b_enabled := true

func _ready() -> void:
	super()
	bridge_switch.switch_triggered.connect(_on_bridge_switch_triggered)
	enemies_a_copy = enemies_a.duplicate()
	enemies_b_copy = enemies_b.duplicate()
	enemies_d_copy = enemies_d.duplicate()

func _physics_process(_delta: float) -> void:
	if b_enabled and detect_portal('b'):
		teleportPlayerAndRespawnEnemies('b', 'a')
		return
	if detect_portal('c'):
		# 禁用B传回A的机制
		b_enabled = false
		var new_enemies := teleportPlayerAndRespawnEnemies('c', 'b')
		# 把两只乌龟也传过去
		teleport_special_turtles()
		# 更新两只乌龟的指针
		special_turtles = new_enemies.get_node('SpecialTurtles')
		return
	if detect_portal('e'):
		teleportPlayerAndRespawnEnemies('e', 'd')
		return

func detect_portal(from: String) -> bool:
	return player.global_position.x > self[from].global_position.x and player.global_position.x - self[from].global_position.x < CAPTURE_RANGE

func get_enemies_ready(node: Node2D) -> void:
	if node is Enemy:
		node._on_world_ready()
		node._on_player_ready()
	elif node.get_child_count() > 0:
		for child in node.get_children():
			if child is Node2D:
				get_enemies_ready(child)

func teleportPlayerAndRespawnEnemies(from: String, to: String) -> Node2D:
	# 传送主角和相机
	camera_2d.limit_left = 0
	player.global_position.x = self[to].global_position.x + (player.global_position.x - self[from].global_position.x)
	camera_2d.global_position.x = self[to].global_position.x + (camera_2d.global_position.x - self[from].global_position.x)
	# 传送火球
	var fire_balls := get_tree().get_nodes_in_group("Fireballs")
	for fire_ball : Fireball in fire_balls:
		fire_ball.global_position.x = self[to].global_position.x + (fire_ball.global_position.x - self[from].global_position.x)
	# 更新敌人
	var new_enemies := self['enemies_' + to + '_copy'].duplicate() as Node2D
	enemies.add_child(new_enemies)
	# 手动调用敌人们的world_ready和player_ready方法
	get_enemies_ready(new_enemies)
	return new_enemies

func _on_bridge_switch_triggered() -> void:
	# 停止游戏时间和状态栏动画
	GameManager.game_timer.stop()
	StatusBar.coin_animation.pause()
	# 冻住主角
	player.controllable = false
	player.state_machine.enabled = false
	player.velocity = Vector2.ZERO
	# 选择性冻住库巴
	var bowser_alive := is_instance_valid(bowser) and bowser.state_machine.current_state != Bowser.State.DEAD
	if bowser_alive:
		bowser.freeze()
	# 消除所有锤子、火球、喷射火焰
	get_tree().call_group("Hammers", "queue_free")
	get_tree().call_group("Hadoukens", "queue_free")
	get_tree().call_group("Fireballs", "queue_free")
	if bowser_alive:
		# 断锁链
		foreground.set_cell(CHAIN_COORD)
		# 断桥
		var x := BRIDGE_COORD_X_RANGE[1]
		while x >= BRIDGE_COORD_X_RANGE[0]:
			# 等0.05秒
			await get_tree().create_timer(0.08).timeout
			foreground.set_cell(Vector2i(x, BRIDGE_COORD_Y))
			SoundManager.play_sfx("BrokenBrick")
			x -= 1
		# 等待Bowser摔下
		bowser.fall()
		await bowser.dead
	elif is_instance_valid(bowser):
		bowser.queue_free()
	# 播放通关动画
	animate_finale()

func animate_finale() -> void:
	# 放歌
	var bgm:= SoundManager.world_clear()
	# 重置相机，并移除摄像机和右边界限制
	camera_2d.reset_camera_center()
	right_wall.global_position.x = foreground.get_used_rect().end.x * Variables.TILE_SIZE.x
	camera_2d.limit_right = ceili(right_wall.global_position.x)
	# 主角和相机一起往右走
	camera_2d.smooth_move_right(Player.MAX_WALK_SPEED)
	player.state_machine.enabled = true
	player.target_x = roundi(endpoint.global_position.x)
	player.input_x = 1
	player.arrived.connect(end.bind(bgm))

func _on_special_pipe_screen_exited() -> void:
	# 将两个特殊管道传送到新地点
	special_pipes.global_position = e.global_position if special_pipes.global_position == d.global_position else d.global_position

func teleport_special_turtles() -> void:
	special_turtles.global_position.x = b.global_position.x - (c.global_position.x - special_turtles.global_position.x)

func end(bgm: AudioStreamPlayer) -> void:
	player.input_x = 0
	await get_tree().create_timer(1).timeout
	# 出现谢谢
	thank_you.visible = true
	# 等bgm放完
	if bgm.playing:
		await bgm.finished
	# 开始放结尾曲
	SoundManager.meet_princess()
	# 依次出现其它文字
	for line in lines.get_children():
		line.visible = true
		await get_tree().create_timer(1.5).timeout
