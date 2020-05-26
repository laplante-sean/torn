extends Node

const PlaybackPlayer = preload("res://Player/PlaybackPlayer.tscn")
const Level_00 = preload("res://Levels/Level_00.tscn")

export(String, FILE, "*.tscn") var start_level_path = ""
export(float) var CAMERA_ZOOM_STEP = 0.05
export(float) var MIN_ZOOM = 1
export(float) var MAX_ZOOM = 2

onready var currentLevel = null
onready var player = $RecordablePlayer
onready var camera = $Camera

var other_self = null  # If a loop is playing this holds the other self


func _ready():
	if start_level_path:
		# If this is set, use it.
		currentLevel = Utils.instance_scene_on_main(load(start_level_path))
	else:
		# If not we default to Level_00
		currentLevel = Utils.instance_scene_on_main(Level_00)
	
	# So the background defaults to black on every frame
	VisualServer.set_default_clear_color(Color.black)
	player.spawn(currentLevel.get_spawn_point())


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
	
	# Respawn the player (recording will be cleared)
	player.respawn()


func change_levels(level_portal):
	currentLevel.queue_free()
	currentLevel = Utils.instance_scene_on_main(load(level_portal.next_level_path))
	player.spawn(currentLevel.get_spawn_point())


func _on_other_self_died():
	print("Loop broken!")
	other_self = null
	currentLevel.activate_portal()


func _on_RecordablePlayer_died():
	print("Game over somehow? Did you shoot yourself?")


func _on_RecordablePlayer_begin_loop():
	if player.has_recorded_data() and other_self == null:
		player.stop_recording()  # Stop recording then...
		
		# Deactivate the portal
		currentLevel.deactivate_portal()
		
		# And create the clone
		other_self = Utils.instance_scene_on_main(PlaybackPlayer, player.get_record_start_point())
		other_self.connect("died", self, "_on_other_self_died")
		other_self.set_playback_data(player.take_recorded_data())
		other_self.start_playback()


func _on_RecordablePlayer_exit_level(level_portal):
	call_deferred("change_levels", level_portal)
