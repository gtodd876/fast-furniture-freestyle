extends Control

@onready var call_to_action: Label = $ColorRect/MarginContainer/VBoxContainer/SubViewport/Control/CallToAction
@export var beat_duration: float = 0.95238  # 476.19ms in seconds is quarter note of the song tempo
@export var max_scale: = Vector2(1.2, 1.2)  # Maximum scale
@export var min_scale: = Vector2(1.0, 1.0)  # Minimum scale
@export var transition_type: = Tween.TRANS_SINE
@export var ease_type: = Tween.EASE_IN_OUT
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var tween: Tween

func _ready():
	start_beat_animation()
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://world.tscn")
	
func start_beat_animation():
	if tween:
		tween.kill()
		
	tween = create_tween().set_loops()
	
	tween.tween_property(call_to_action, "scale", max_scale, beat_duration / 2).set_trans(transition_type).set_ease(ease_type)
	tween.tween_property(call_to_action, "scale", min_scale, beat_duration /2).set_trans(transition_type).set_ease(ease_type)
