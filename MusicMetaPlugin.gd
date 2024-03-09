@tool
extends EditorPlugin

const AUTOLOAD_NAME = "MusicMeta"

func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/MusicMeta/MusicMeta.gd")

func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
