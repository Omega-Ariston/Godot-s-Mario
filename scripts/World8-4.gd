extends World

@onready var a: Marker2D = $Portals/A
@onready var b: Marker2D = $Portals/B
@onready var c: Marker2D = $Portals/C
@onready var d: Marker2D = $Portals/D
@onready var e: Marker2D = $Portals/E

const CAPTURE_RANGE := Variables.TILE_SIZE.x * 8

func _physics_process(_delta: float) -> void:
	if player.global_position.x > b.global_position.x and player.global_position.x - b.global_position.x < CAPTURE_RANGE:
		camera_2d.limit_left = 0
		player.global_position.x = a.global_position.x + (player.global_position.x - b.global_position.x)
	elif player.global_position.x > c.global_position.x and player.global_position.x - c.global_position.x < CAPTURE_RANGE:
		camera_2d.limit_left = 0
		player.global_position.x = b.global_position.x + (player.global_position.x - c.global_position.x)
	elif player.global_position.x > e.global_position.x and player.global_position.x - e.global_position.x < CAPTURE_RANGE:
		camera_2d.limit_left = 0
		player.global_position.x = d.global_position.x + (player.global_position.x - e.global_position.x)
