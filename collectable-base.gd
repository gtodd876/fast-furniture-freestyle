extends Area2D
class_name Collectable
@export var points: int = 10
@export var collect_sound: AudioStream
@export var texture: Texture2D
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var audio_player = $AudioStreamPlayer

signal collected(points)

var is_collected: bool = false
func _ready():
	if texture and sprite:
		sprite.texture = texture
	
	# Connect the body_entered signal
	if !body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	print("Collectable ready: ", name, " with ", points, " points")

func _on_body_entered(body):
	print("Body entered: ", body.name)
	if body is CharacterBody2D:
		collect()
		
func collect():
	print("Collecting: ", name, " with ", points, " points")
	# Set collected flag
	is_collected = true
	# Emit signal with points
	collected.emit(points)
	
	# Play collection sound
	if collect_sound and audio_player:
		audio_player.stream = collect_sound
		audio_player.play()
	
	# Spawn particles
	spawn_collect_effect()
	
	# Disable collision and hide sprite
	collision_shape.set_deferred("disabled", true)
	sprite.visible = false
	
	# Wait for audio/particles to finish before removing
	await get_tree().create_timer(1.0).timeout
	queue_free()
	
func spawn_collect_effect():
	# Create particle effect
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 16
	particles.lifetime = 0.8
	
	# In Godot 4, these properties have been renamed
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	particles.direction = Vector2(0, -1)
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 80.0
	particles.spread = 180.0
	
	# In Godot 4, scale_amount is now a property you set directly
	particles.scale_amount_min = 1.5  # Base scale
	particles.scale_amount_max = 2.5  # With randomness
	
	# Colorful particles
	var color = Color(1.0, 1.0, 0.5)  # Yellow/gold base
	if points == 10:
		color = Color(0.5, 1.0, 0.8)  # Teal-ish
	elif points == 20:
		color = Color(1.0, 0.5, 0.7)  # Pink-ish
	elif points == 30:
		color = Color(0.8, 0.5, 1.0)  # Purple-ish
		
	particles.color = color
	particles.color_ramp = create_color_gradient(color)
	
	add_child(particles)
	particles.top_level = true  # Make sure particles stay in place when parent moves
	particles.global_position = global_position  # Position particles at collectable's location
	
func create_color_gradient(base_color: Color) -> Gradient:
	var gradient = Gradient.new()
	var bright_color = base_color.lightened(0.3)
	bright_color.a = 1.0
	var fade_color = base_color
	fade_color.a = 0.0
	
	gradient.colors = [bright_color, fade_color]
	gradient.offsets = [0.0, 1.0]
	
	return gradient
