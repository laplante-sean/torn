extends Node

const Player = preload("res://Player/Player.tscn")

onready var currentLevel = $Level_00
onready var player = $Player

var other_self = null  # If a loop is playing this holds the other self


func _ready():
	# So the background defaults to black on every frame
	VisualServer.set_default_clear_color(Color.black)


func reload_level():
	if player.has_recorded_data() and other_self == null:
		other_self = Utils.instance_scene_on_main(Player, player.spawn_point)
		other_self.recorded_data = player.take_recorded_data()
		other_self.start_playback(true)
		player.respawn(true)


func kill_other_self():
	if other_self != null:
		other_self.queue_free()
		other_self = null
