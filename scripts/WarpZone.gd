extends Node2D

@export var level_a : int
@export var level_b : int
@export var level_c : int

@onready var text: Node2D = $Text
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var piranhas: Node2D = $Piranhas

var player: Player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta: float) -> void:
	if player.global_position.x >= global_position.x:
		piranhas.queue_free()
		text.visible = true
		set_physics_process(false)
