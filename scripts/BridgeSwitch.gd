class_name BridgeSwitch
extends Node2D

signal switch_triggered

func _on_player_entered(_body: Node2D) -> void:
	switch_triggered.emit()
	queue_free()
