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
	if b_enabled and detect_portal('b', 'a'):
		return
	if detect_portal('c', 'b'):
		b_enabled = false
		return
	if detect_portal('e', 'd'):
		return

func detect_portal(from: String, to: String) -> bool:
	if player.global_position.x > self[from].global_position.x and player.global_position.x - self[from].global_position.x < CAPTURE_RANGE:
		camera_2d.limit_left = 0
		player.global_position.x = self[to].global_position.x + (player.global_position.x - self[from].global_position.x)
		var new_enemies := self['enemies_' + to + '_copy'].duplicate() as Node2D
		enemies.add_child(new_enemies)
		# 手动调用敌人们的world_ready和player_ready方法
		get_enemies_ready(new_enemies)
		return true
	else:
		return false

func get_enemies_ready(node: Node2D) -> void:
	if node is Enemy:
		node._on_world_ready()
		node._on_player_ready()
	elif node.get_child_count() > 0:
		for child in node.get_children():
			get_enemies_ready(child)
