extends Node

func add_score(pos: Vector2, score: int, speed: ScoreText.Speed) -> void:
	StatusBar.score += score
	var instance := load("res://scenes/text/score_text.tscn").instantiate() as ScoreText
	# 分数生成在物体上方一个格子
	var new_pos = pos - Vector2(0, Variables.TILE_SIZE.y)
	instance.initialize(new_pos, str(score), speed)
	get_tree().root.add_child(instance)
