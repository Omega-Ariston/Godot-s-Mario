extends Node

const BRICK_SCORE := 50
const GOOMBA_SCORE := 100
const TURTLE_SCORE := 100
const COIN_BUMPED_SCORE := 200


func add_score(item: Node2D, showText = true) -> void:
	var score := _get_score(item)
	StatusBar.score += score
	if showText:
		var instance := load("res://scenes/text/score_text.tscn").instantiate() as ScoreText
		# 分数生成在物体上方一个格子
		var new_pos = item.get_global_transform_with_canvas().origin - Vector2(0, Variables.TILE_SIZE.y)
		instance.initialize(new_pos, str(score), ScoreText.Speed.SLOW if item is CoinBumped else ScoreText.Speed.FAST)
		get_tree().root.add_child(instance)

func add_life(pos: Vector2) -> void:
	GameManager.add_life()
	var instance := load("res://scenes/text/score_text.tscn").instantiate() as ScoreText
	# 命数生成在物体上方一个格子
	var new_pos = pos - Vector2(0, Variables.TILE_SIZE.y)
	instance.initialize(new_pos, "1 UP", ScoreText.Speed.FAST)
	get_tree().root.add_child(instance)

func _get_score(item: Node2D) -> int:
	if item is Brick:
		return BRICK_SCORE
	if item is Goomba:
		return GOOMBA_SCORE
	if item is Turtle:
		return TURTLE_SCORE
	if item is CoinBumped:
		return COIN_BUMPED_SCORE
	return 0
