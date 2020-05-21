extends "res://Player/RecordablePlayer.gd"
class_name Player

const PlayerBullet = preload("res://Player/PlayerBullet.tscn")

export(int) var ACCELERATION = 500
export(int) var MAX_SPEED = 65
export(float) var FRICTION = 0.25
export(int) var BULLET_SPEED = 350
export(int) var GRAVITY = 200
export(int) var JUMP_FORCE = 120
export(int) var MAX_SLOPE_ANGLE = 46

enum PlayerState {
	MOVE
}

var MainInstances = Utils.get_MainInstances()

var state = PlayerState.MOVE
var time_scale = 1.0
var snap_vector = Vector2.ZERO
var just_jumped = false

onready var animationPlayer = $AnimationPlayer
onready var coyoteJumpTimer = $CoyoteJumpTimer
onready var muzzle = $Sprite/PlayerGun/Sprite/Muzzle
onready var fireBulletTimer = $FireBulletTimer


func _ready():
	MainInstances.player = self  # So we can access the player everywhere


func _physics_process(delta):
	parse_inputs() # Need to call this first. Implemented in RecordablePlayer

	if is_action_just_pressed("test_playback"):
		get_tree().current_scene.reload_level()
	if Input.is_action_just_pressed("test_kill_other_self"):
		get_tree().current_scene.kill_other_self()

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

	if Input.is_action_pressed("fire") and fireBulletTimer.time_left == 0:
		fire_bullet()


func fire_bullet():
	var bullet = Utils.instance_scene_on_main(PlayerBullet, muzzle.global_position)
	bullet.velocity = Vector2.RIGHT.rotated(gun.rotation) * BULLET_SPEED
	bullet.velocity.x *= sprite.scale.x
	bullet.rotation = bullet.velocity.angle()
	fireBulletTimer.start()


func get_input_vector():
	var input_vector = Vector2.ZERO
	input_vector.x = get_action_strength("ui_right") - get_action_strength("ui_left")
	return input_vector


func apply_horizontal_force(input_vector, delta):
	if input_vector.x != 0:
		motion.x += input_vector.x * ACCELERATION * delta
		motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)


func apply_friction(input_vector):
	if input_vector.x == 0 and is_on_floor():
		motion.x = lerp(motion.x, 0, FRICTION)


func update_snap_vector():
	if is_on_floor():
		snap_vector = Vector2.DOWN


func jump_check():
	if is_on_floor() or coyoteJumpTimer.time_left > 0:
		if is_action_just_pressed("jump"):
			jump(JUMP_FORCE)
			just_jumped = true
	elif is_action_just_released("jump") and motion.y < -JUMP_FORCE / 2:
			motion.y = -JUMP_FORCE / 2


func jump(force):
	motion.y = -force
	snap_vector = Vector2.ZERO


func apply_gravity(delta):
	if not is_on_floor():
		motion.y += GRAVITY * delta
		motion.y = min(motion.y, JUMP_FORCE)


func update_animations(input_vector):
	if not playback:
		var facing = sign(get_local_mouse_position().x)
		if facing != 0:
			sprite.scale.x = facing

	if input_vector.x != 0:
		animationPlayer.play("Run")
		# Play animation in reverse when player runs backwards
		animationPlayer.playback_speed = input_vector.x * sprite.scale.x
	else:
		# Idle animation should never play in reverse
		animationPlayer.playback_speed = 1
		animationPlayer.play("Idle")

	# Override run/idle if we're in the air
	if not is_on_floor():
		animationPlayer.play("Jump")


func move():
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


func _on_Player_playback_complete():
	print("Playback complete!")
