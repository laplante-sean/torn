extends Node2D

onready var sprite = $Sprite


func _process(_delta):
	var playerSprite = get_parent()
	var player = playerSprite.get_parent()
	if player.is_playback:
		return  # If this is a playback player don't use mouse.
	rotation = playerSprite.get_local_mouse_position().angle()
