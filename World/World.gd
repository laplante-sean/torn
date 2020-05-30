extends Node

const RecordablePlayer = preload("res://Player/RecordablePlayer.tscn")
const PlaybackPlayer = preload("res://Player/PlaybackPlayer.tscn")
const Level_00 = preload("res://Levels/Level_00.tscn")

export(String, FILE, "*.tscn") var start_level_path = ""
export(float) var CAMERA_ZOOM_STEP = 0.05
export(float) var MIN_ZOOM = 1
export(float) var MAX_ZOOM = 2

onready var player = $RecordablePlayer
onready var camera = $Camera

var MainInstances = Utils.get_MainInstances()
var currentLevel = null
var currentLevelPath = "res://Levels/Level_00.tscn"
var other_self = null  # If a loop is playing this holds the other self


func _ready():
	if MainInstances.is_load_game:
		var save_data = SaveAndLoad.load_data_from_file()
		currentLevelPath = save_data.level
		currentLevel = Utils.instance_scene_on_main(load(save_data.level))
	elif start_level_path:
		# If this is set, use it.
		currentLevelPath = start_level_path
		currentLevel = Utils.instance_scene_on_main(load(start_level_path))
	else:
		# If not we default to Level_00
		currentLevel = Utils.instance_scene_on_main(Level_00)
	
	# So the background defaults to black on every frame
	VisualServer.set_default_clear_color(Color.black)
	player.spawn(currentLevel.get_spawn_point())


func update_save_data():
	var save_data = SaveAndLoad.load_data_from_file()
	save_data.level = currentLevelPath
	SaveAndLoad.save_data_to_file(save_data)


func _physics_process(_delta):
	if Input.is_action_just_pressed("redo_level"):
		print("Resetting level")
		reload_level()
	if Input.is_action_just_released("zoom_in"):
		zoom_in()
	if Input.is_action_just_released("zoom_out"):
		zoom_out()
	if Input.is_action_just_pressed("reset_camera"):
		print("Reset camera")
		reset_zoom()


func zoom_in():
	zoom(-CAMERA_ZOOM_STEP)


func zoom_out():
	zoom(CAMERA_ZOOM_STEP)


func zoom(step):
	camera.zoom.x = clamp(camera.zoom.x + step, MIN_ZOOM, MAX_ZOOM)
	camera.zoom.y = clamp(camera.zoom.y + step, MIN_ZOOM, MAX_ZOOM)


func reset_zoom():
	camera.zoom = Vector2(1, 1)


func reload_level():
	if other_self:
		other_self.queue_free()
		other_self = null
		currentLevel.activate_portal()
	
	if player == null:
		reconstruct_player(currentLevel.get_spawn_point())
	
	# Respawn the player (recording will be cleared)
	player.respawn()


func change_levels(level_portal):
	currentLevel.queue_free()
	currentLevelPath = level_portal.next_level_path
	currentLevel = Utils.instance_scene_on_main(load(level_portal.next_level_path))
	update_save_data()
	player.clear_time_marker()
	player.spawn(currentLevel.get_spawn_point())


func _on_other_self_died():
	print("Loop broken!")
	other_self = null
	currentLevel.activate_portal()


func reconstruct_player(at_position):
	"""
	Remake the player at a certain position
	
	:at_position: Where to place the player
	"""
	player = Utils.instance_scene_on_main(RecordablePlayer, currentLevel.get_spawn_point())
	player.global_position = at_position
	player.cameraFollow.set_remote_node("../../Camera")
	
	# Reconnect all the signals
	player.connect("died", self, "_on_RecordablePlayer_died")
	player.connect("begin_loop", self, "_on_RecordablePlayer_begin_loop")
	player.connect("exit_level", self, "_on_RecordablePlayer_exit_level")
	player.connect("rewind_complete", self, "_on_RecordablePlayer_rewind_complete")
	player.connect("begin_recording", self, "_on_RecordablePlayer_begin_recording")


func _on_RecordablePlayer_died():
	player = null
	
	if other_self != null:
		reconstruct_player(other_self.global_position)
		other_self.clear_time_marker()
		other_self.queue_free()
		other_self = null
		currentLevel.activate_portal()


func _on_RecordablePlayer_begin_loop():
	if player.has_recorded_data() and other_self == null:
		# First, stop recording
		player.stop_recording()

		# Then, start the rewind. When it's done we'll get a signal. Then
		# we'll start the loop...
		player.start_rewind()
		
		Events.emit_signal("player_recording_complete")


func _on_RecordablePlayer_exit_level(level_portal):
	call_deferred("change_levels", level_portal)


func _on_RecordablePlayer_rewind_complete():
	# Then, respawn to the beginning of the loop
	player.loop_respawn()
	
	# Next, Deactivate the portal level portal since you cannot move on
	# with an active loop.
	currentLevel.deactivate_portal()
	
	# Finally, create the looping clone and start playback
	other_self = Utils.instance_scene_on_main(PlaybackPlayer, player.get_record_start_point())
	other_self.connect("died", self, "_on_other_self_died")
	other_self.set_playback_data(player.take_recorded_data(), player.take_time_marker())
	other_self.start_playback()
	
	Events.emit_signal("player_rewind_complete")


func _on_RecordablePlayer_begin_recording():
	Events.emit_signal("player_started_recording")
