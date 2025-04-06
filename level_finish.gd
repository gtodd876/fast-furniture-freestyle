# Modified level_finish.gd with better integration for your player

extends Area2D
class_name LevelFinish
signal level_completed(score, time, perfect_score)

# Celebration effect variables
var celebration_active = false
var celebration_duration = 2.0
var celebration_timer = 0.0
var confetti_particles
var celebration_sounds = []
var sound_index = 0
var player_ref = null  # Reference to the player
var original_player_position = Vector2.ZERO
var victory_animation_active = false
var original_camera_zoom = Vector2.ONE
var original_camera_offset = Vector2.ZERO

func _ready():
	# Connect body entered signal
	body_entered.connect(_on_body_entered)
	
	# Set up celebration effects
	setup_celebration_effects()

func setup_celebration_effects():
	# Add particles for the celebration
	confetti_particles = CPUParticles2D.new()
	confetti_particles.emitting = false
	confetti_particles.amount = 100
	confetti_particles.lifetime = 2.0
	confetti_particles.explosiveness = 0.8
	confetti_particles.direction = Vector2(0, -1)
	confetti_particles.gravity = Vector2(0, 98)
	confetti_particles.initial_velocity_min = 50
	confetti_particles.initial_velocity_max = 100
	confetti_particles.scale_amount_min = 4.0
	confetti_particles.scale_amount_max = 4.0
	
	# Particle colors (confetti-like)
	var colors = [Color(1, 0.5, 0.5), Color(0.5, 1, 0.5), Color(0.5, 0.5, 1), 
				 Color(1, 1, 0.5), Color(0.5, 1, 1), Color(1, 0.5, 1)]
	confetti_particles.color_ramp = create_color_gradient(colors)
	
	add_child(confetti_particles)
	
	# Load celebration sounds (you'll need to add these to your project)
	var sound1 = preload("res://assets/sounds/bandura.wav") if ResourceLoader.exists("res://assets/sounds/bandura.wav") else null
	var sound2 = preload("res://assets/sounds/intro-music.wav") if ResourceLoader.exists("res://assets/sounds/intro-music.wav") else null
	
	if sound1:
		celebration_sounds.append(sound1)
	if sound2:
		celebration_sounds.append(sound2)

# Helper to create a color gradient for the particles
func create_color_gradient(colors):
	var gradient = Gradient.new()
	var num_colors = colors.size()
	
	for i in range(num_colors):
		gradient.add_point(float(i) / float(num_colors - 1), colors[i])
	
	return gradient

func _on_body_entered(body):
	if body is CharacterBody2D and body.name == "Player" and not celebration_active:
		# Store player reference and position
		player_ref = body
		original_player_position = body.global_position
		
		# Add dramatic time slow-down effect
		Engine.time_scale = 0.3  # Slow down time
		
		# Store original camera settings if available
		if body.has_node("Camera2D"):
			var camera = body.get_node("Camera2D")
			original_camera_zoom = camera.zoom
			original_camera_offset = camera.offset
		
		# Play a celebration sound
		if celebration_sounds.size() > 0:
			var audio_player = AudioStreamPlayer.new()
			add_child(audio_player)
			audio_player.stream = celebration_sounds[sound_index]
			audio_player.play()
			sound_index = (sound_index + 1) % celebration_sounds.size()
		
		# Start the victory animation - use player's existing animation system
		start_victory_animation()
		
		# Start the celebration
		celebration_active = true
		celebration_timer = 0.0
		
		# Position particles at player position
		confetti_particles.global_position = body.global_position + Vector2(0, -30)
		confetti_particles.emitting = true
		
		# Get score info for later use
		var score = body.score
		var world = get_tree().get_current_scene()
		var perfect_score = score >= world.score_ui.max_score
		
		# Disable player controls during celebration
		body.stop_input()
		
		# Gradually return time to normal
		var time_tween = create_tween()
		time_tween.tween_property(Engine, "time_scale", 1.0, 1.0).set_delay(0.5)

func start_victory_animation():
	if player_ref:
		victory_animation_active = true
		
		# Use the player's animation player if available
		if player_ref.has_node("AnimationPlayer"):
			var anim_player = player_ref.get_node("AnimationPlayer")
			
			# If there's a victory/celebration animation, play it
			# Otherwise we'll make the player do a cartwheel if that function exists
			if anim_player.has_animation("victory"):
				anim_player.play("victory")
			elif player_ref.has_method("do_cartwheel"):
				# Use the player's built-in cartwheel animation
				player_ref.do_cartwheel()
		
		# Camera celebration effect
		if player_ref.has_node("Camera2D"):
			var camera = player_ref.get_node("Camera2D")
			
			# Create a camera zoom effect
			var zoom_tween = create_tween()
			zoom_tween.tween_property(camera, "zoom", original_camera_zoom * 1.2, 0.5).set_ease(Tween.EASE_OUT)
			zoom_tween.tween_property(camera, "zoom", original_camera_zoom, 0.5).set_ease(Tween.EASE_IN)
			
			# Also create a small camera shake effect
			shake_camera(camera, 5, 0.5)

# Camera shake function
func shake_camera(camera, intensity, duration):
	var shake_timer = 0.0
	var original_pos = camera.offset
	
	# Create a timer for the shake effect
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.02  # Shake frequency
	timer.autostart = true
	
	# Connect the timer to a function that updates the camera position
	timer.timeout.connect(func():
		shake_timer += timer.wait_time
		
		if shake_timer < duration:
			# Apply random offset based on intensity
			var offset = Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
			camera.offset = original_pos + offset
		else:
			# Reset camera position and stop the timer
			camera.offset = original_pos
			timer.queue_free()
	)

func _process(delta):
	if celebration_active:
		celebration_timer += delta
		
		# Make the player jump slightly every 0.5s during celebration
		if victory_animation_active and player_ref and player_ref.is_on_floor():
			if fmod(celebration_timer, 0.7) < 0.1 and not player_ref.animation_player.current_animation == "jump_up":
				player_ref.velocity.y = player_ref.jump_speed * 0.7  # Smaller celebration jumps
		
		# Flash score UI or other visual effects
		var world = get_tree().get_current_scene()
		if world.has_node("ScoreUI") and world.score_ui:
			var score_ui = world.score_ui
			score_ui.bg_rect.color = Color(
				0.1 + 0.4 * sin(celebration_timer * 10),
				0.1 + 0.4 * sin(celebration_timer * 10 + 2),
				0.1 + 0.4 * sin(celebration_timer * 10 + 4),
				0.7
			)
		
		# When celebration is over, proceed to level complete screen
		if celebration_timer >= celebration_duration:
			celebration_active = false
			victory_animation_active = false
			
			# If we modified the camera zoom, reset it
			if player_ref and player_ref.has_node("Camera2D"):
				var camera = player_ref.get_node("Camera2D")
				camera.zoom = original_camera_zoom
				camera.offset = original_camera_offset
			
			# Now proceed with the level completion
			complete_level()

func complete_level():
	if player_ref:
		# Get the score directly from the player
		var score = player_ref.score
		
		# Get the world node
		var world = get_tree().get_current_scene()
		
		# Get level time from world
		var elapsed_time = world.elapsed_time
		
		# Check if perfect score was achieved
		var perfect_score = score >= world.score_ui.max_score
		
		print("Level completed! Score: ", score, " Time: ", elapsed_time, " Perfect: ", perfect_score)
		
		# Emit signal with level stats
		level_completed.emit(score, elapsed_time, perfect_score)
		
		# Call the level completion method in the world if it exists
		if world.has_method("on_level_completed"):
			world.on_level_completed(score, elapsed_time, perfect_score)
