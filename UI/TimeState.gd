extends Control

onready var play = $Play
onready var record = $Record
onready var rewind = $Rewind
onready var recordBarFull = $RecordBarFull
onready var recordBarDisabled = $RecordBarDisabled


func _ready():
	set_play_state()
	recordBarDisabled.visible = false
	Events.connect("player_recording_complete", self, "set_rewind_state")
	Events.connect("player_rewind_complete", self, "set_play_state")
	Events.connect("player_started_recording", self, "set_record_state")
	Events.connect("set_record_percent", self, "set_record_percent")
	Events.connect("player_recording_disabled", self, "set_recording_disabled")
	Events.connect("player_recording_enabled", self, "set_recording_enabled")
	Events.connect("level_reloaded", self, "level_reloaded")


func set_play_state():
	recordBarFull.set_scale(Vector2.ONE)
	play.visible = true
	record.visible = false
	rewind.visible = false


func set_record_state():
	play.visible = false
	record.visible = true
	rewind.visible = false


func set_rewind_state():
	recordBarFull.set_scale(Vector2.ZERO)
	play.visible = false
	record.visible = false
	rewind.visible = true


func set_record_percent(value):
	recordBarFull.set_scale(Vector2(value, 1))


func set_recording_disabled():
	recordBarFull.set_scale(Vector2.ONE)
	recordBarDisabled.visible = true


func level_reloaded():
	set_play_state()
	set_recording_enabled()


func set_recording_enabled():
	recordBarFull.set_scale(Vector2.ONE)
	recordBarDisabled.visible = false
