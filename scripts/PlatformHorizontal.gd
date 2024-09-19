extends StaticBody2D

@export var direction := -1 # -1表示向左，1表示向右

@onready var left_end: Marker2D = $LeftEnd
@onready var right_end: Marker2D = $RightEnd

const SPEED := 25

func _ready() -> void:
	while true:
		var duration : float
		var target_x : float
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		match direction:
			-1:
				duration = (global_position.x - left_end.global_position.x) / SPEED
				target_x = left_end.global_position.x
				direction = +1
			+1:
				duration = (right_end.global_position.x - global_position.x) / SPEED
				target_x = right_end.global_position.x
				direction = -1
		tween.tween_property(self, "global_position:x", target_x, duration)
		await tween.finished
				
