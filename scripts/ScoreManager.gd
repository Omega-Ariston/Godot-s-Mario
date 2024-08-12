extends Node

func add_score(pos: Vector2, score: int, speed: ScoreText.Speed) -> void:
	StatusBar.score += score
	var instance := load("res://scenes/text/score_text.tscn").instantiate() as ScoreText
	instance.initialize(pos, str(score), speed)
	get_tree().root.add_child(instance)
