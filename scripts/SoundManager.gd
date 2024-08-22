extends Node

@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

var aboveGroundBGM := preload("res://assets/sounds/01. Above Ground BGM.mp3")
var courseClearBGM := preload("res://assets/sounds/02. Course Clear Fanfare.mp3")
var undergroundBGM := preload("res://assets/sounds/03. Underground BGM.mp3")
var underwaterBGM := preload("res://assets/sounds/04. Underwater BGM.mp3")
var castleBGM := preload("res://assets/sounds/05. Castle BGM.mp3")
var starBGM := preload("res://assets/sounds/Super_Star_theme.ogg")

func play_sfx(sfx_name: String) -> AudioStreamPlayer:
	var audio_player := sfx.get_node(sfx_name) as AudioStreamPlayer
	if not audio_player:
		return
	audio_player.play()
	return audio_player

func play_world_bgm() -> void:
	var stream: AudioStream
	match GameManager.current_world_type:
		GameManager.WorldType.GROUND:
			stream = aboveGroundBGM
		GameManager.WorldType.UNDER:
			stream = undergroundBGM
		GameManager.WorldType.WATER:
			stream = underwaterBGM
		GameManager.WorldType.CASTLE:
			stream = castleBGM
	bgm_player.stream = stream
	bgm_player.play()


func course_clear() -> void:
	bgm_player.stream = courseClearBGM
	bgm_player.play()

func go_star() -> void:
	bgm_player.stream = starBGM
	bgm_player.play()

func pause_bgm() -> void:
	bgm_player.playing = false
