extends Node2D

@onready var foreground: TileMapLayer = $TileMap/Foreground

@onready var camera_2d: MainCamera = $MainCamera
@onready var player: Player = $Player
@onready var top: RichTextLabel = $TOP

func _ready() -> void:
	StatusBar.coin_animation.play("origin")
	top.text = 'TOP- ' + ("%06d" % GameManager.current_highest_score)
	player.controllable = false
	setup_camera()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		get_viewport().set_input_as_handled()
		StatusBar.initialize()
		if Input.is_action_pressed("A"):
			# 续关
			GameManager.transition_scene(GameManager.current_world + "-1")
		else:
			GameManager.transition_scene("1-1")

func setup_camera() -> void:
	var used := foreground.get_used_rect()
	var tile_size := Variables.TILE_SIZE
	
	camera_2d.limit_top = Variables.TOP_BOUNDARY # 最上面一个方块只显示一半
	camera_2d.limit_right = floori(used.end.x * tile_size.x)
	camera_2d.limit_bottom = Variables.BOTTOM_BOUNDARY # 最下面一个方块只显示一半
	camera_2d.limit_left = 0
