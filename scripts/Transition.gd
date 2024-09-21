extends Node2D

@onready var level_label: RichTextLabel = $LevelStart/Level
@onready var life_label: RichTextLabel = $LevelStart/Life
@onready var level_start: Node2D = $LevelStart
@onready var time_up: Node2D = $TimeUp
@onready var game_over: Node2D = $GameOver

func _ready() -> void:
	# 停止播放状态栏动画
	StatusBar.transition_screen()
	# 先显示TimeUp，再显示GameOver，最后是普通切关
	if GameManager.is_time_up:
		GameManager.is_time_up = false
		time_up.visible = true
		await get_tree().create_timer(2).timeout
		GameManager.transition_scene(StatusBar.level, false)
	elif GameManager.life == 0:
		game_over.visible = true
		await SoundManager.play_sfx("GameOver").finished
		GameManager.restore_status()
		GameManager.title_scene()
	else:
		# 普通切关卡
		level_label.text = "World " + str(StatusBar.level)
		life_label.text = ("%3d" % GameManager.life)
		level_start.visible = true
		# 等两秒进入正式关
		await get_tree().create_timer(2).timeout
		GameManager.change_scene(StatusBar.level)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		get_viewport().set_input_as_handled()
