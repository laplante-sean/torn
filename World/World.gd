extends Node

const Player = preload("res://Player/Player.tscn")

onready var currentLevel = $Level_00
onready var player = $Player

func _ready():
	# So the background defaults to black on every frame
	VisualServer.set_default_clear_color(Color.black)


func reload_level():
	player.respawn()
	
	if len(player.recorded_data) > 0:
		var other_self = Utils.instance_scene_on_main(Player, player.global_position)
		other_self.recorded_data = player.recorded_data
		other_self.start_playback()
