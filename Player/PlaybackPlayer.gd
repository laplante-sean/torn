extends Player
class_name PlaybackPlayer

var current_inputs = {}    # Keeps track of current inputs for the frame
var frame_count = 0        # Keeps count of the physics frames while we're recording/playing-back
var playback_data = []     # The recorded data to playback
var is_playback = false    # Whether or not we're playing back
var record_idx = 0         # The current record index we're working on during playback
var playback_loop = false  # Whether or not to loop playback
var out_of_sync = false    # Set to true if a playback gets FUBAR


func _ready():
	clear_inputs()


func _physics_process(delta):
	if is_playback:
		# If we're playing back we need to make sure to switch
		# JUST_PRESSED to PRESSED and JUST_RELEASED to NOT_PRESSED
		# since actions will be getting set directly by calls to
		# action_press() and action_release()
		for input in InputHelper.PossibleInputs:
			var prev_action = get_input_action(input)
			if prev_action == InputHelper.InputState.JUST_PRESSED:
				set_input(input, InputHelper.InputState.PRESSED)
			elif prev_action == InputHelper.InputState.JUST_RELEASED:
				set_input(input, InputHelper.InputState.NOT_PRESSED)

		playback()  # Playback actions

	process_input(delta)  # Actually move the player, update animations, etc.

	frame_count += 1  # Always increment the frame count


func set_playback_data(recorded_data, tm):
	"""
	Used to set the playback data for this playback player. If not called
	the playback player won't do anything.
	
	:param recorded_data: Data recorded by a recorable player to playback
	:param time_marker: Once playback starts the playback player takes control
		of the time marker and clears it when dead.
	"""
	playback_data = recorded_data
	time_marker = tm


func start_playback():
	"""
	Start playing back actions if there are any. Will stop
	recording if one is in progress.
	
	:param loop: If true, this playback will loop otherwise it will stop at the end
	"""
	is_playback = true
	frame_count = 0
	record_idx = 0


func stop_playback():
	"""
	Stop playing back
	"""
	is_playback = false
	out_of_sync = false


func set_input(input, action):
	"""
	Used to set the current inputs.
	
	:param input: The input string to set
	:param action: The input action to set it to
	"""
	if input == "start_loop":
		return  # Don't playback this one

	current_inputs[input] = action


func clear_inputs():
	"""
	Clear or initialize our current_inputs variable
	"""
	for input in InputHelper.PossibleInputs:
		current_inputs[input] = InputHelper.InputState.NOT_PRESSED


func get_input_action(input):
	"""
	Get the current input action
	
	:param input: Get action for this input
	:returns: One of the InputHelper.InputState values for this input
	"""
	return current_inputs[input]


func playback():
	if state == PlayerState.DIE:
		return  # We're dying just let it happen
	
	if record_idx == len(playback_data):
		stop_playback()
		clear_inputs()  # Don't want to leave anything pressed
		start_playback()
		respawn()
		gun.follow_mouse = false
		return

	if frame_count != playback_data[record_idx].frame:
		return  # We're not at the physics frame for the next record yet

	var data = playback_data[record_idx]
	
	# Error correction
	if global_position != data.position and !out_of_sync:
		# Something is out of sync. See if we can fix it.
		var direction = global_position.direction_to(data.position)  # Get normalized vector pointing at destination
		var distance = global_position.distance_to(data.position)  # Get how far we would be jumped
		if not test_move(transform, direction * distance):
			# No collision would occur so let's fix the position
			global_position = data.position
		else:
			# At this point we kindof just have to throw the data.position out
			out_of_sync = true
	elif global_position == data.position and out_of_sync:
		# We've come back into sync (maybe they were running into a wall or whatever)
		out_of_sync = false

	sprite.scale.x = data.facing
	gun.rotation = data.gun_rotation
	
	for input_record in data.inputs:
		set_input(input_record.input, input_record.action)
	
	record_idx += 1


func get_action_strength(input):
	var action = get_input_action(input)
	if action == InputHelper.InputState.PRESSED or action == InputHelper.InputState.JUST_PRESSED:
		return 1
	return 0


func is_action_just_pressed(input):
	return get_input_action(input) == InputHelper.InputState.JUST_PRESSED


func is_action_just_released(input):
	return get_input_action(input) == InputHelper.InputState.JUST_RELEASED


func is_action_pressed(input):
	var action = get_input_action(input)
	if action == InputHelper.InputState.PRESSED or action == InputHelper.InputState.JUST_PRESSED:
		return true
	return false
