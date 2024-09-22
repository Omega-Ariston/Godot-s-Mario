extends Node

func add_score(score: int, item: Node2D = null, showText = true) -> void:
	StatusBar.score += score
	if showText:
		var instance := preload("res://scenes/text/score_text.tscn").instantiate() as ScoreText
		# 分数生成在物体上方一个格子
		var new_pos = item.get_global_transform_with_canvas().origin - Vector2(0, Variables.TILE_SIZE.y)
		instance.initialize(new_pos, str(score), ScoreText.Speed.SLOW if item is CoinBumped else ScoreText.Speed.FAST)
		get_tree().root.add_child(instance)

func add_life(item: Node2D) -> void:
	GameManager.add_life()
	var instance := preload("res://scenes/text/score_text.tscn").instantiate() as ScoreText
	# 命数生成在物体上方一个格子
	var new_pos = item.get_global_transform_with_canvas().origin - Vector2(0, Variables.TILE_SIZE.y)
	instance.initialize(new_pos, "1UP", ScoreText.Speed.FAST)
	get_tree().root.add_child(instance)
