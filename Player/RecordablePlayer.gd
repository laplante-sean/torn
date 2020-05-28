extends Player
class_name RecordablePlayer

const TimeMarker = preload("res://World/TimeMarker.tscn")

signal begin_loop
signal exit_level(level_portal)

var frame_count = 0  # Keeps count of the physics frames while we're recording/playing-back
var recorded_data = []  # The recorded data for a session
var is_recording = true  # Whether or not we're recording  TODO - Default to false
var record_point = Vector2.ZERO  # Point we hit the record button


func _ready():
	MainInstances.player = self
	record_point = global_position


func _physics_process(delta):
	process_input(delta)  # Actually move the player, update animations, etc.
	
	if is_action_just_pressed("start_recording"):
		if is_on_floor():
			print("Begin recording")
			start_recording()
		else:
			print("Can only begin recordings on floor")
	
	if is_recording:
		record()

	if is_action_just_pressed("start_loop"):
		emit_signal("begin_loop")

	frame_count += 1


func respawn():
	"""
	Respawn the player. (overrides base Player class respawn())
	"""
	clear_recording()
	.respawn()  # Call base Player class respawn()


func loop_respawn():
	"""
	Respawn the player at the previously set record point.
	"""
	global_position = record_point
	motion = Vector2.ZERO
	state = PlayerState.MOVE


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


func get_record_start_point():
	"""
	Helper that gets the global position set when the recording started
	"""
	return record_point


func start_recording():
	"""
	Start recording actions. Will clear any previous recording
	and will stop any playback.
	"""
	clear_recording()
	record_point = global_position
	is_recording = true
	var marker = Utils.instance_scene_on_main(TimeMarker, record_point)
	MainInstances.timeMarker = marker


func stop_recording():
	"""
	Stop recording actions
	"""
	is_recording = false


func clear_recording():
	"""
	Stops and clears the recorded data
	"""
	stop_recording()  # Make sure we're stopped
	frame_count = 0
	recorded_data = []
	record_point = spawn_point  # Fallback to spawn point


func record():
	"""
	Used to record inputs while recording is running
	"""
	var current_record = {
		"frame": frame_count,              # Current physics frame for playback
		"inputs": [],                      # The current inputs
		"position": global_position,       # Global position for sanity checking
		"facing": sprite.scale.x,          # The direction we're facing
		"gun_rotation": gun.rotation       # The player's gun rotation
	}

	# We only parse out JUST_PRESSED and JUST_RELEASED actions (all we need)
	for input in InputHelper.PossibleInputs:
		var obj = {
			"input": input,
			"action": InputHelper.InputState.NOT_PRESSED
		}
		
		if is_action_just_pressed(input):
			obj.action = InputHelper.InputState.JUST_PRESSED
		elif is_action_just_released(input):
			obj.action = InputHelper.InputState.JUST_RELEASED
		elif len(recorded_data) == 0 and is_action_pressed(input):
			# If we just started recording while actions were held,
			# set them as JUST_PRESSED
			obj.action = InputHelper.InputState.JUST_PRESSED
		else:
			continue  # Skip all NOT_PRESSED/PRESSED actions

		current_record.inputs.push_back(obj)

	# Save to our global recorded_data struct if there were any inputs
	if len(current_record.inputs) > 0:
		recorded_data.push_back(current_record)
