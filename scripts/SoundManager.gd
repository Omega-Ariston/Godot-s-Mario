extends Node

@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

var aboveGroundBGM := preload("res://assets/sounds/01. Above Ground BGM.mp3")
var courseClearBGM := preload("res://assets/sounds/02. Course Clear Fanfare.mp3")
var undergroundBGM := preload("res://assets/sounds/03. Underground BGM.mp3")
var underwaterBGM := preload("res://assets/sounds/04. Underwater BGM.mp3")
var castleBGM := preload("res://assets/sounds/05. Castle BGM.mp3")

func play_sfx(sfx_name: String) -> void:
	var audio_player := sfx.get_node(sfx_name) as AudioStreamPlayer
	if not audio_player:
		return
	audio_player.play()

func play_world_bgm(world_type: World.Type) -> void:
	match world_type:
		World.Type.GROUND:
			bgm_player.stream = aboveGroundBGM
		World.Type.UNDER:
			bgm_player.stream = undergroundBGM
		World.Type.WATER:
			bgm_player.stream = underwaterBGM
		World.Type.CASTLE:
			bgm_player.stream = castleBGM
	bgm_player.play()


func course_clear() -> void:
	bgm_player.stream = courseClearBGM
	bgm_player.play()	

func pause_bgm() -> void:
	bgm_player.playing = false
