extends StaticBody2D

enum {
	NOT_PRESSED,
	PRESSED
}

signal button_pressed
signal button_released

var pressers = 0
var state = NOT_PRESSED setget set_state

onready var sprite = $Sprite


func is_pressed():
	return state == PRESSED


func set_state(value):
	state = value
	if state == PRESSED:
		sprite.frame = 1
	else:
		sprite.frame = 0


func _on_Area2D_body_entered(body):
	pressers += 1

	if self.state == PRESSED:
		return  #Already pressed

	self.state = PRESSED
	emit_signal("button_pressed")


func _on_Area2D_body_exited(body):
	pressers -= 1

	if pressers <= 0:
		pressers = 0
		self.state = NOT_PRESSED
		emit_signal("button_released")
