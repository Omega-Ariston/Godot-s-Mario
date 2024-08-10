extends Node2D

@onready var level: RichTextLabel = $Level
@onready var life: RichTextLabel = $Life

func _ready() -> void:
	level.text = "World " + str(StatusBar.world) + '-' + str(StatusBar.level)
	life.text = "*" + ("%3d" % GameManager.life)
	await get_tree().create_timer(2).timeout
	GameManager.change_scene(GameManager.get_level_scene_path(StatusBar.world, StatusBar.level))
