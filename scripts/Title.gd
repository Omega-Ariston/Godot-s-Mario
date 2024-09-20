extends Node2D

@onready var foreground: TileMapLayer = $TileMap/Foreground

@onready var camera_2d: MainCamera = $MainCamera
@onready var player: Player = $Player

func _ready() -> void:
	player.controllable = false
	setup_camera()

func _input(event: InputEvent) -> void:
		# TODO: 续关的逻辑
	if event.is_action_pressed("start"):
		get_viewport().set_input_as_handled()
		StatusBar.initialize()
		GameManager.transition_scene("1-1")

func setup_camera() -> void:
	var used := foreground.get_used_rect()
	var tile_size := Variables.TILE_SIZE
	
	camera_2d.limit_top = floori(1.5 * tile_size.y) # 最上面一个方块只显示一半
	camera_2d.limit_right = floori(used.end.x * tile_size.x)
	camera_2d.limit_bottom = ceili((used.end.y - 0.5) * tile_size.y) # 最下面一个方块只显示一半
	camera_2d.limit_left = 0
