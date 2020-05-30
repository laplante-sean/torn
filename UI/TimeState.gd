extends Control

onready var play = $Play
onready var record = $Record
onready var rewind = $Rewind


func _ready():
	set_play_state()
	Events.connect("player_recording_complete", self, "set_rewind_state")
	Events.connect("player_rewind_complete", self, "set_play_state")
	Events.connect("player_started_recording", self, "set_record_state")


func set_play_state():
	play.visible = true
	record.visible = false
	rewind.visible = false


func set_record_state():
	play.visible = false
	record.visible = true
	rewind.visible = false


func set_rewind_state():
	play.visible = false
	record.visible = false
	rewind.visible = true

