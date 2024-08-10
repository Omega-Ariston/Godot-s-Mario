extends Node2D

@onready var level_label: RichTextLabel = $Level
@onready var life_label: RichTextLabel = $Life



func _ready() -> void:
	level_label.text = "World " + str(StatusBar.level)
	life_label.text = "*" + ("%3d" % GameManager.life)
	await get_tree().create_timer(2).timeout
	GameManager.change_scene(GameManager.get_level_scene_path(StatusBar.level))
