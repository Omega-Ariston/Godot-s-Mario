extends Node

@onready var sfx: Node = $SFX
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

var aboveGroundBGM := preload("res://assets/sounds/01. Above Ground BGM.mp3")
var courseClearBGM := preload("res://assets/sounds/02. Course Clear Fanfare.mp3")
var undergroundBGM := preload("res://assets/sounds/03. Underground BGM.mp3")
var underwaterBGM := preload("res://assets/sounds/04. Underwater BGM.mp3")
var castleBGM := preload("res://assets/sounds/05. Castle BGM.mp3")
var starBGM := preload("res://assets/sounds/Super_Star_theme.ogg")

func play_sfx(sfx_name: String) -> void:
	var audio_player := sfx.get_node(sfx_name) as AudioStreamPlayer
	if not audio_player:
		return
	if not audio_player.playing:
		audio_player.play()

func play_world_bgm() -> void:
	var world := get_tree().root.get_node("World") as World
	var world_type := world.world_type
	var stream: AudioStream
	match world_type:
		World.Type.GROUND:
			stream = aboveGroundBGM
		World.Type.UNDER:
			stream = undergroundBGM
		World.Type.WATER:
			stream = underwaterBGM
		World.Type.CASTLE:
			stream = castleBGM
	if stream != bgm_player.stream or not bgm_player.playing:
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
