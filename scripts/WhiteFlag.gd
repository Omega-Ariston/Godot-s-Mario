class_name WhiteFlag
extends Node2D

@onready var firework_1: Marker2D = $Firework1
@onready var firework_2: Marker2D = $Firework2
@onready var firework_3: Marker2D = $Firework3
@onready var firework_4: Marker2D = $Firework4
@onready var firework_5: Marker2D = $Firework5
@onready var firework_6: Marker2D = $Firework6

func play_firework(num: int) -> void:
	for i in range(num):
		var firework_instance := preload("res://scenes/items/firework.tscn").instantiate() as Node2D
		firework_instance.global_position = self["firework_" + str(i + 1)].global_position
		get_tree().root.add_child(firework_instance)
		await firework_instance.vanished
