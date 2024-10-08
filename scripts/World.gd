class_name World
extends Node2D

@export var world_type: GameManager.WorldType
@export var level_time: int  # 8-1和8-3只有300秒，其余关是400秒
@export var level_name: String

@onready var camera_2d: MainCamera = $MainCamera
@onready var player: Player = $Player
@onready var spawn_points: Node = $SpawnPoints
@onready var spawn_point: SpawnPoint = $SpawnPoints/SpawnPoint
@onready var left_wall: StaticBody2D = $Boundaries/LeftWall
@onready var right_wall: StaticBody2D = $Boundaries/RightWall

var has_warned := false

func _ready() -> void:
	GameManager.screen_ready.connect(_on_screen_ready)
	GameManager.player_ready.connect(_on_player_ready)
	GameManager.player_started.connect(_on_player_started)
	var flag_pole := find_child("FlagPole") as FlagPole
	if flag_pole:
		flag_pole.flag_pulled.connect(func() -> void:
			has_warned = true)
	# sub-Flag和sub-Warp不会设置level_name
	if not level_name:
		GameManager.current_spawn_point = spawn_point.name
	elif GameManager.current_level != level_name:
		GameManager.current_level = level_name
		StatusBar.level = level_name
		GameManager.current_spawn_point = spawn_point.name
	StatusBar.time = level_time
	GameManager.current_world_type = world_type
	setup_camera()
	GameManager.world_ready.emit()

func _process(_delta: float) -> void:
	left_wall.global_position.x = camera_2d.get_screen_center_position().x - (get_viewport_rect().size.x / 2)
	camera_2d.limit_left = ceili(left_wall.global_position.x)
	
	if not has_warned and StatusBar.time <= Variables.WARNING_TIME:
		has_warned = true
		SoundManager.warn()

func setup_camera() -> void:
	camera_2d.limit_top = Variables.TOP_BOUNDARY # 最上面一个方块只显示一半
	camera_2d.limit_bottom = Variables.BOTTOM_BOUNDARY # 最下面一个方块只显示一半
	camera_2d.limit_left = 0
	camera_2d.limit_right = ceili(right_wall.global_position.x)

func _on_player_ready() -> void:
	camera_2d.limit_left = max(0, player.global_position.x - GameManager.INITIAL_CAMERA_OFFSET)
	
func _on_screen_ready() -> void:
	SoundManager.play_world_bgm()

func _on_player_started() -> void:
	GameManager.control_player(player)
	GameManager.game_timer.start()
