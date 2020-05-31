extends CanvasLayer

onready var controlsMenu = $ControlsMenu


func _on_PauseMenu_display_controls():
	controlsMenu.visible = true


func _on_PauseMenu_hide_controls():
	controlsMenu.visible = false
