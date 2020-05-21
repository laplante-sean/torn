extends KinematicBody2D
class_name RecordablePlayer

signal playback_complete

enum {
	NOT_PRESSED,
	PRESSED,
	JUST_PRESSED,
	JUST_RELEASED
}

var inputs = [
	"ui_left", "ui_right", "jump", "fire", "test_playback"
]

var current_inputs = {}  # Keeps track of what inputs are being pressed/released
var frame_count = 0  # Keeps count of the physics frames while we're recording/playing-back
var recorded_data = []  # The recorded data for a session
var recording = true  # Whether or not we're recording
var playback = false  # Whether or not we're playing back
var record_idx = 0  # The current record index we're working on during playback
var playback_loop = false  # Whether or not to loop playback
var spawn_point = Vector2.ZERO  # The orignal spawn point
var motion = Vector2.ZERO  # The player's motion

onready var sprite = $Sprite
onready var gun = $Sprite/PlayerGun


func _ready():
	spawn_point = global_position
	
	# Build our dict
	for input in inputs:
		current_inputs[input] = {
			"action": NOT_PRESSED
		}


func respawn(start_recording=false):
	"""
	Respawn the player. Optionally start recording on respawn.
	
	:param start_recording: Whether or not to start recording on respawn
	"""
	print("Respawn: ", spawn_point)
	global_position = spawn_point
	motion = Vector2.ZERO
	if start_recording:
		start_recording()


func has_recorded_data():
	"""
	:returns: True if there is data recorded, false otherwise.
	"""
	return len(recorded_data) > 0


func take_recorded_data():
	"""
	This will return the recorded data and clear it
	for this instance.
	
	:returns: The recorded data
	"""
	var ret = recorded_data
	clear_recording()
	return ret


func start_recording():
	"""
	Start recording actions. Will clear any previous recording
	and will stop any playback.
	"""
	clear_recording()
	recording = true


func start_playback(loop=false):
	"""
	Start playing back actions if there are any. Will stop
	recording if one is in progress.
	
	:param loop: If true, this playback will loop otherwise it will stop at the end
	"""
	stop_recording()
	playback = true
	frame_count = 0
	record_idx = 0
	playback_loop = loop


func stop_recording():
	"""
	Stop recording actions
	"""
	recording = false


func stop_playback():
	"""
	Stop playing back
	"""
	playback = false
	playback_loop = false


func clear_recording():
	"""
	Stops and clears the recorded data
	"""
	stop_recording()  # Make sure we're stopped
	stop_playback()  # Can't clear if we're playing back
	frame_count = 0
	recorded_data = []
	record_idx = 0


func parse_inputs():
	"""
	Called on each frame from an inherited player's
	_physics_process to parse the input. Ignores user
	input if playback is true.
	"""
	if not playback:
		# If we're not playing back, parse the real input
		for input in inputs:
			if Input.is_action_just_pressed(input):
				set_input(input, JUST_PRESSED)
			elif Input.is_action_pressed(input):
				set_input(input, PRESSED)
			elif Input.is_action_just_released(input):
				set_input(input, JUST_RELEASED)
			else:
				set_input(input, NOT_PRESSED)
	else:
		# If we're playing back we need to make sure to switch
		# JUST_PRESSED to PRESSED and JUST_RELEASED to NOT_PRESSED
		# since actions will be getting set directly by calls to
		# action_press() and action_release()
		for input in inputs:
			var prev_action = get_input_action(input)
			if prev_action == JUST_PRESSED:
				set_input(input, PRESSED)
			elif prev_action == JUST_RELEASED:
				set_input(input, NOT_PRESSED)

	if recording:
		record()  # Record the input if we're recording

	if playback:
		playback()  # Playback actions

	frame_count += 1  # Always increment the frame count


func set_input(input, action):
	"""
	Used to set the current inputs.
	"""
	current_inputs[input].action = action


func clear_inputs():
	for input in inputs:
		current_inputs[input].action = NOT_PRESSED


func playback_set_input(input, action):
	"""
	Helper to set the input during playback
	"""
	if input == "test_playback":
		return  # Don't playback this one
	
	# During playback, action will only be JUST_PRESSED or JUST_RELEASED
	if action == JUST_PRESSED:
		playback_action_press(input)
	else:
		playback_action_release(input)


func playback_action_press(input):
	"""
	Called during playback to set an action
	"""
	var action = get_input_action(input)
	if action == NOT_PRESSED or action == JUST_RELEASED:
		set_input(input, JUST_PRESSED)


func playback_action_release(input):
	"""
	Called during playback to release an action
	"""
	var action = get_input_action(input)
	if action == JUST_PRESSED or action == PRESSED:
		set_input(input, JUST_RELEASED)


func get_input_action(input):
	return current_inputs[input].action


func record():
	var current_record = {
		"frame": frame_count,        # Current physics frame for playback
		"inputs": [],                # The current inputs
		"position": global_position, # Global position for sanity checking
		"facing": sprite.scale.x,    # The direction we're facing
		"gun_rotation": gun.rotation  # The player's gun rotation
	}

	# Gather up all the inputs that are in some state other than NOT_PRESSED
	for input in inputs:
		var action = get_input_action(input)
		if action == JUST_PRESSED or action == JUST_RELEASED:
			# We don't need to track PRESSED that will happen
			# during playback.
			current_record.inputs.push_back({
				"input": input,
				"action": action
			})

	# Save to our global recorded_data struct if there were any inputs
	if len(current_record.inputs) > 0:
		recorded_data.push_back(current_record)


func playback():
	if record_idx == len(recorded_data):
		var start_again = false
		if playback_loop:
			start_again = true
		
		stop_playback()
		clear_inputs()  # Don't want to leave anything pressed
		emit_signal("playback_complete")
		
		if start_again:
			start_playback(true)
			respawn()
		return  # Done

	if frame_count != recorded_data[record_idx].frame:
		return  # We're not at the physics frame for the next record yet

	var data = recorded_data[record_idx]
	global_position = data.position
	sprite.scale.x = data.facing
	gun.rotation = data.gun_rotation
	
	for input_record in data.inputs:
		playback_set_input(input_record.input, input_record.action)
	
	record_idx += 1


func get_action_strength(input):
	var action = get_input_action(input)
	if action == PRESSED or action == JUST_PRESSED:
		return 1
	return 0


func is_action_just_pressed(input):
	return get_input_action(input) == JUST_PRESSED


func is_action_just_released(input):
	return get_input_action(input) == JUST_RELEASED


func is_action_pressed(input):
	var action = get_input_action(input)
	if action == PRESSED or action == JUST_PRESSED:
		return true
	return false
