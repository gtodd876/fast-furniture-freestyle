extends Node2D
@onready var player: CharacterBody2D = $Player

func _process(delta: float) -> void:
	if player.global_position.y > 1000:
		get_tree().reload_current_scene()
