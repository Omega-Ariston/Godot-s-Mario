extends Marker2D

@export_file("*.tscn") var new_scene : String

const MIN_ENTER_DISTANCE := 6

var enter_requested = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("crouch"):
		enter_requested = true
	if event.is_action_released("crouch"):
		enter_requested = false

func _physics_process(delta: float) -> void:
	if enter_requested:
		var player := get_tree().get_first_node_in_group("Player") as Player
		if global_position.distance_to(player.global_position) <= MIN_ENTER_DISTANCE:
			enter_requested = false
			await player.dive_into_pipe()
			# 切换场景
			GameManager.change_scene(new_scene)
