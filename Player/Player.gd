extends KinematicBody2D
class_name Player

signal died
signal rewind_complete

const PlayerBullet = preload("res://Player/PlayerBullet.tscn")

export(int) var ACCELERATION = 500
export(int) var MAX_SPEED = 65
export(float) var FRICTION = 0.25
export(int) var BULLET_SPEED = 250
export(int) var GRAVITY = 200
export(int) var JUMP_FORCE = 120
export(int) var MAX_SLOPE_ANGLE = 46
export(bool) var follow_mouse = true

enum PlayerState {
	MOVE,
	REWIND,
	DIE
}

var InputHelper = Utils.get_InputHelper()
var state = PlayerState.MOVE
var snap_vector = Vector2.ZERO
var just_jumped = false
var motion = Vector2.ZERO
var spawn_point = Vector2.ZERO
var time_marker = null  # The current time marker
var rewind_data = []   # Stores a list of positions and animation states for rewinding
var rewind_idx = 0     # When rewinding, stores the index
var current_animation = "Idle"

onready var sprite = $PlayerSprite/Sprite
onready var animationPlayer = $PlayerSprite/AnimationPlayer
onready var coyoteJumpTimer = $CoyoteJumpTimer
onready var muzzle = $PlayerSprite/Sprite/PlayerGun/Sprite/Muzzle
onready var gun = $PlayerSprite/Sprite/PlayerGun
onready var fireBulletTimer = $FireBulletTimer
onready var hurtbox = $Hurtbox


func _ready():
	spawn_point = global_position


func process_input(delta):
	"""
	Called from the _physics_process callbacks of inherited scenes
	to update player position, and physics based on input.
	"""
	match state:
		PlayerState.MOVE:
			var input_vector = get_input_vector()
			apply_horizontal_force(input_vector, delta)
			apply_friction(input_vector)
			update_snap_vector()
			jump_check()
			apply_gravity(delta)
			update_animations(input_vector)
			move()

			if is_action_pressed("fire") and fireBulletTimer.time_left == 0:
				fire_bullet()
		PlayerState.REWIND:
			rewind()
		PlayerState.DIE:
			pass  # Do nothing, we're dying


func spawn(loc):
	"""
	Called to spawn the player. Sets the spawn point
	and moves the player to it. If this method is not
	called, the spawn point will be set to the player's
	position in the _ready() callback.
	
	:param loc: The location to spawn the player
	"""
	spawn_point = loc
	respawn()


func respawn():
	"""
	Respawn the player.
	"""
	global_position = spawn_point
	motion = Vector2.ZERO
	state = PlayerState.MOVE
	gun.follow_mouse = true


func fire_bullet():
	"""
	Instance a bullet and fire it
	"""
	var bullet = Utils.instance_scene_on_main(PlayerBullet, muzzle.global_position)
	bullet.velocity = Vector2.RIGHT.rotated(gun.rotation) * BULLET_SPEED
	bullet.velocity.x *= sprite.scale.x
	bullet.rotation = bullet.velocity.angle()
	fireBulletTimer.start()


func get_input_vector():
	"""
	Get the current input vector (left or right) for movement
	
	:returns: The input vector
	"""
	var input_vector = Vector2.ZERO
	input_vector.x = get_action_strength("ui_right") - get_action_strength("ui_left")
	return input_vector


func get_current_animation():
	"""
	Returns the currently active animation by name
	
	:returns: Current animation name
	"""
	return current_animation


func apply_horizontal_force(input_vector, delta):
	"""
	Based on the input vector and delta, apply horizontal motion
	
	:param input_vector: The current input_vector returned from get_input_vector
	:param delta: The current delta from _physics_process
	"""
	if input_vector.x != 0:
		motion.x += input_vector.x * ACCELERATION * delta
		motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)


func apply_friction(input_vector):
	"""
	Apply friction to the motion if we're on the floor and we're not moving
	
	:param input_vector: The current input_vector returned from get_input_vector
	"""
	if input_vector.x == 0 and is_on_floor():
		motion.x = lerp(motion.x, 0, FRICTION)


func is_moving():
	"""
	Helper that returns True if the player is moving and False if not.
	
	:returns: True if moving. False if stationary
	"""
	if get_input_vector() != Vector2.ZERO:
		return true
	if not is_on_floor():
		return true
	return false


func update_snap_vector():
	"""
	Update our snap vector if we're on the floor
	"""
	if is_on_floor():
		snap_vector = Vector2.DOWN


func jump_check():
	"""
	Check if we're jumping or not.
	"""
	if is_on_floor() or coyoteJumpTimer.time_left > 0:
		if is_action_just_pressed("jump"):
			jump(JUMP_FORCE)
			just_jumped = true
	elif is_action_just_released("jump") and motion.y < -JUMP_FORCE / 2:
			motion.y = -JUMP_FORCE / 2


func jump(force):
	"""
	Apply a force in the upward direction to make the player jump
	
	:param force: The jump force to apply
	"""
	motion.y = -force
	snap_vector = Vector2.ZERO


func apply_gravity(delta):
	"""
	Apply gravity to the player if we're in the air
	
	:param delta: The current delta from _physics_process
	"""
	if not is_on_floor():
		motion.y += GRAVITY * delta
		motion.y = min(motion.y, JUMP_FORCE)


func update_animations(input_vector):
	"""
	Update our animations based on the input_vector
	
	:param input_vector: The current input_vector returned from get_input_vector
	"""
	var facing = 1
	if follow_mouse:
		facing = sign(get_local_mouse_position().x)
	else:
		facing = input_vector.x

	if facing != 0:
		sprite.scale.x = facing

	if input_vector.x != 0:
		current_animation = "Run"
		# Play animation in reverse when player runs backwards
		animationPlayer.playback_speed = input_vector.x * sprite.scale.x
	else:
		current_animation = "Idle"
		# Idle animation should never play in reverse
		animationPlayer.playback_speed = 1

	# Override run/idle if we're in the air
	if not is_on_floor():
		current_animation = "Jump"

	animationPlayer.play(current_animation)


func move():
	"""
	Final step: Actually move the player
	"""
	# Capture properties of motion prior to moving
	# We use them after moving to fix some
	# move_and_slide_with_snap issues
	var was_in_air = not is_on_floor()
	var was_on_floor = is_on_floor()
	var last_motion = motion
	var last_position = position
	
	motion = move_and_slide_with_snap(motion, snap_vector * 4, Vector2.UP, true, 4, deg2rad(MAX_SLOPE_ANGLE))

	# Happens on landing
	if was_in_air and is_on_floor():
		# Fix for move_and_slide_with_snap causing us to 
		# lose momentum when landing on a slope
		motion.x = last_motion.x

	# Just left the ground
	if was_on_floor and not is_on_floor() and not just_jumped:
		# Fix for little hop if you fall off a ledge after
		# climbing a slope
		motion.y = 0
		position.y = last_position.y
		coyoteJumpTimer.start()

	# Prevent sliding on slope when idle (hack)
	if is_on_floor() and get_floor_velocity().length() == 0 and abs(motion.x) < 1:
		# If we're on the floor, not on a moving platform, and our motion is super tiny...don't move
		position.x = last_position.x


func start_rewind():
	"""
	Set the rewind_idx to start
	"""
	rewind_idx = len(rewind_data)
	state = PlayerState.REWIND
	gun.follow_mouse = false


func rewind():
	"""
	Visually rewind a player
	"""
	rewind_idx -= 2

	if rewind_idx < 0:
		rewind_idx = 0
		emit_signal("rewind_complete")
		state = PlayerState.MOVE
		animationPlayer.playback_speed = 1
		gun.follow_mouse = true
		return

	var frame = rewind_data[rewind_idx]
	global_position = frame.position
	sprite.scale.x = frame.facing
	gun.rotation = frame.gun_rotation
	animationPlayer.playback_speed = sprite.scale.x * -1  # Flip it
	animationPlayer.play(frame.animation)


func _on_Hurtbox_hit(damage):
	"""
	Called if our hurtbox is hit with an amount of damage to apply
	
	:param damage: The amount of damage done to the player
	"""
	motion = Vector2.ZERO
	state = PlayerState.DIE
	animationPlayer.play("Die")
	clear_time_marker()


func clear_time_marker():
	"""
	Used to clear an existing time marker
	"""
	if time_marker != null:
		time_marker.queue_free()
		time_marker = null


func _on_PlayerSprite_death_animation_complete():
	"""
	When we run our 'Die' animation it triggers the nested 'Die' animation
	of the player's gun as well. When both those are done playing, this method
	will be called. Now we can free the player sprite.
	"""
	queue_free()
	emit_signal("died")


func get_action_strength(input):
	"""
	Method that can be overridden by spcialized 'Player' classes to change
	where we get the input from. By default we get it from the human
	
	:param input: The current input
	"""
	return Input.get_action_strength(input)


func is_action_just_pressed(input):
	"""
	Method that can be overridden by spcialized 'Player' classes to change
	where we get the input from. By default we get it from the human
	
	:param input: The current input
	"""
	return Input.is_action_just_pressed(input)


func is_action_just_released(input):
	"""
	Method that can be overridden by spcialized 'Player' classes to change
	where we get the input from. By default we get it from the human
	
	:param input: The current input
	"""
	return Input.is_action_just_released(input)


func is_action_pressed(input):
	"""
	Method that can be overridden by spcialized 'Player' classes to change
	where we get the input from. By default we get it from the human
	
	:param input: The current input
	"""
	return Input.is_action_pressed(input)
