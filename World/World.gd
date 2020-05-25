extends Node

const Player = preload("res://Player/Player.tscn")

export(float) var CAMERA_ZOOM_STEP = 0.05
export(float) var MIN_ZOOM = 1
export(float) var MAX_ZOOM = 2

onready var currentLevel = $Level_00
onready var player = $Player
onready var probPlayer = $ProbabilityPlayer
onready var camera = $Camera

var other_self = null  # If a loop is playing this holds the other self


func _ready():
	# So the background defaults to black on every frame
	VisualServer.set_default_clear_color(Color.black)
	player.connect("hit_door", self, "_on_Player_hit_door")
	set_player_spawn(currentLevel.get_spawn_point())
	probPlayer.set_is_probable_future()


func set_player_spawn(set_pos):
	player.global_position = set_pos
	player.spawn_point = player.global_position
	probPlayer.global_position = player.global_position
	probPlayer.spawn_point = player.global_position


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
		currentLevel.activate_portal()
	player.respawn(true)
	probPlayer.respawn()


func change_levels(level_portal):
	print("Change levels: ", level_portal)
	var NextLevel = load(level_portal.next_level_path)
	currentLevel.queue_free()
	var nextLevel = NextLevel.instance()
	add_child(nextLevel)
	set_player_spawn(nextLevel.get_spawn_point())
	player.respawn(true)
	probPlayer.respawn()


func _on_Player_died():
	print("Game over somehow? Did you shoot yourself?")


func _on_other_self_died():
	print("Loop broken!")
	other_self = null
	currentLevel.activate_portal()


func _on_Player_begin_loop():
	if player.has_recorded_data() and other_self == null:
		currentLevel.deactivate_portal()
		other_self = Utils.instance_scene_on_main(Player, player.spawn_point)
		other_self.set_is_clone()
		other_self.connect("died", self, "_on_other_self_died")
		other_self.recorded_data = player.take_recorded_data()
		other_self.start_playback(true)
		player.respawn(true)
		probPlayer.respawn()


func _on_Player_level_complete(level_portal):
	call_deferred("change_levels", level_portal)
