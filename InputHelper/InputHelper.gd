extends Resource
class_name InputHelper

enum InputState {
	NOT_PRESSED,
	PRESSED,
	JUST_PRESSED,
	JUST_RELEASED
}

var PossibleInputs = [
	"ui_left", "ui_right", "jump", "fire", "start_loop"
]
