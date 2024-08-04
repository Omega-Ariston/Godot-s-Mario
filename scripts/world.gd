class_name World
extends Node2D

@export var world_type: Type

@onready var tile_map: TileMap = $TileMap
@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var player: Player = $Player

var viewport_size: Vector2

enum Type {
	GROUND,
	UNDER,
	WATER,
	CASTLE
}

func _ready() -> void:
	setup_bgm()
	setup_camera()
	GameManager.control_player(player)

func _process(_delta: float) -> void:
	var center_position := camera_2d.get_screen_center_position()
	var left_coord := center_position.x - viewport_size.x / 2
	GameManager.max_left_x = max(left_coord, GameManager.max_left_x)
	camera_2d.limit_left = ceili(GameManager.max_left_x)

func setup_bgm() -> void:
	SoundManager.play_world_bgm(world_type)

func setup_camera() -> void:
	viewport_size = get_viewport_rect().size
	var used := tile_map.get_used_rect()
	var tile_size := Variables.TILE_SIZE
	
	camera_2d.limit_top = floori(used.position.y + 0.5 * tile_size.y)
	camera_2d.limit_right = floori(used.end.x * tile_size.x)
	camera_2d.limit_bottom = ceili((used.end.y - 0.5) * tile_size.y) # 最下面一个方块只显示一半
	camera_2d.limit_left = ceili((used.position.x + 1) * tile_size.x) # 不显示最左的一行墙壁
