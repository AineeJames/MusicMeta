extends Node

@export var Stream: AudioStreamMP3

func _ready():
	var metadata := MusicMeta.get_mp3_metadata(Stream)
	if metadata.error != OK:
		return

	metadata.print_info()
