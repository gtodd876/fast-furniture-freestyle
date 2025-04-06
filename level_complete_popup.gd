# Simplified level_complete_popup.gd - focusing on particles and text only

extends CanvasLayer

signal animation_completed

@onready var label = $CenterContainer/LevelCompleteLabel
@onready var particles = $CPUParticles2D
var camera = null
var original_camera_position = Vector2.ZERO
var original_camera_zoom = Vector2.ONE

func _ready():
	# Start with everything invisible
	label.modulate.a = 0
	
	# Enhance particles
	enhance_particles()
	
	# Find the player's camera
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera2D"):
		camera = player.get_node("Camera2D")
		original_camera_position = camera.offset
		original_camera_zoom = camera.zoom
	
	# Start the appear animation after a short delay
	await get_tree().create_timer(0.2).timeout
	play_appear_animation()

func enhance_particles():
	if particles:
		# Make particles larger
		particles.scale_amount_min = 8.0
		particles.scale_amount_max = 12.0
		
		# Increase particle count
		particles.amount = 150
		
		# Add more variety to initial velocities for a bigger burst
		particles.initial_velocity_min = 100
		particles.initial_velocity_max = 200
		
		# Add some gravity for a more natural fall
		particles.gravity = Vector2(0, 50)
		
		# Use stronger, saturated colors
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(1, 0.2, 0.2, 1))  # Bright red
		gradient.add_point(0.2, Color(1, 0.8, 0.2, 1))  # Bright yellow
		gradient.add_point(0.4, Color(0.2, 1, 0.2, 1))  # Bright green
		gradient.add_point(0.6, Color(0.2, 0.8, 1, 1))  # Bright blue
		gradient.add_point(0.8, Color(0.8, 0.2, 1, 1))  # Bright purple
		gradient.add_point(1.0, Color(1, 0.5, 0.0, 1))  # Bright orange
		particles.color_ramp = gradient
		
		# Add some hue variation for more color diversity
		particles.hue_variation_min = -0.2
		particles.hue_variation_max = 0.2
		
		# Enhance shape
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 10
		
		# Make the particles last longer
		particles.lifetime = 3.0

func play_appear_animation():
	# Start particles
	particles.emitting = true
	
	# Camera zoom effect if we found a camera
	if camera:
		var zoom_tween = create_tween()
		zoom_tween.tween_property(camera, "zoom", original_camera_zoom * 1.1, 0.5)
		zoom_tween.tween_property(camera, "zoom", original_camera_zoom, 0.5)
	
	# Scale animation with a bounce effect for the text
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(label, "scale", Vector2(1, 1), 0.7).from(Vector2(0.1, 0.1))
	
	# Fade in the label
	var fade_tween = create_tween()
	fade_tween.tween_property(label, "modulate:a", 1.0, 0.4)
	
	# Add a pulsating effect to the text to make it more visible
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(label, "self_modulate", Color(1.3, 1.3, 1.3), 0.6)
	pulse_tween.tween_property(label, "self_modulate", Color(1.0, 1.0, 1.0), 0.6)
	
	# Wait before playing exit animation
	await get_tree().create_timer(3.0).timeout
	
	# Kill the pulsing effect
	pulse_tween.kill()
	
	play_exit_animation()

func play_exit_animation():
	# Return camera to original state if found
	if camera:
		var zoom_tween = create_tween()
		zoom_tween.tween_property(camera, "zoom", original_camera_zoom, 0.5)
	
	# Fade out all elements
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_property(particles, "modulate:a", 0.0, 0.5)
	
	# When animation is done, emit signal
	await tween.finished
	animation_completed.emit()
	queue_free()
