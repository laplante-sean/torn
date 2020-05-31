extends Sprite

signal destroyed(target)

onready var animationPlayer = $AnimationPlayer


func _on_Hurtbox_hit(damage):
	animationPlayer.play("Destroy")


func _on_AnimationPlayer_animation_finished(anim_name):
	emit_signal("destroyed", self)
	Events.emit_signal("item_destroyed", "res://World/Target.tscn", global_position)
	queue_free()
