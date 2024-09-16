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

const SPECIAL_PIPE_E1_POSITION := [3136, 4160]
const SPECIAL_PIPE_E2_POSITION := [3280, 4304]

const CAPTURE_RANGE := Variables.TILE_SIZE.x * 8

var enemies_a_copy : Node2D
var enemies_b_copy : Node2D
var enemies_d_copy : Node2D

var b_enabled := true

func _ready() -> void:
	super()
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
	# 传送主角
	camera_2d.limit_left = 0
	player.global_position.x = self[to].global_position.x + (player.global_position.x - self[from].global_position.x)
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
	

func _on_special_pipe_screen_exited() -> void:
	# 将两个特殊管道传送到新地点
	special_pipes.global_position = e.global_position if special_pipes.global_position == d.global_position else d.global_position

func teleport_special_turtles() -> void:
	special_turtles.global_position.x = b.global_position.x - (c.global_position.x - special_turtles.global_position.x)
