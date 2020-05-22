extends Node

const Player = preload("res://Player/Player.tscn")

export(float) var CAMERA_ZOOM_STEP = 0.05
export(float) var MIN_ZOOM = 1
export(float) var MAX_ZOOM = 2

onready var currentLevel = $Level_00
onready var player = $Player
onready var camera = $Camera

var other_self = null  # If a loop is playing this holds the other self


func _ready():
	# So the background defaults to black on every frame
	VisualServer.set_default_clear_color(Color.black)
	player.connect("hit_door", self, "_on_Player_hit_door")


func _process(delta):
	if Input.is_action_just_pressed("redo_level"):
		reload_level()
	if Input.is_action_just_released("zoom_in"):
		zoom_in()
	if Input.is_action_just_released("zoom_out"):
		zoom_out()
	if Input.is_action_just_pressed("reset_camera"):
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
	player.respawn(true)


func change_levels(portal):
	print("Change levels: ", portal)
	var offset = portal.get_next_level_spawn_loc()
	var NextLevel = load(portal.next_level_path)
	var nextLevel = NextLevel.instance()
	add_child(nextLevel)
	
	#
	# TODO: Make sure this is good!
	#
	var next_offset = nextLevel.position - nextLevel.spawnPoint.position
	nextLevel.position = next_offset + offset
	# TODO: Unload the prev. level
	# TODO: Restart recording
	# TODO: Disable loop in elevator


func _on_Player_died():
	print("Game over somehow? Did you shoot yourself?")


func _on_other_self_died():
	print("Loop broken!")
	other_self = null


func _on_Player_begin_loop():
	if player.has_recorded_data() and other_self == null:
		other_self = Utils.instance_scene_on_main(Player, player.spawn_point)
		other_self.connect("died", self, "_on_other_self_died")
		other_self.recorded_data = player.take_recorded_data()
		other_self.start_playback(true)


func _on_Player_hit_door(door):
	call_deferred("change_levels", door)
