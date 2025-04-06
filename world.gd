# Modified world.gd to integrate the new juice effects

extends Node2D
@onready var player: CharacterBody2D = $Player
@onready var score_ui: ScoreUI = $ScoreUI
@onready var level_finish: LevelFinish = $LevelFinish
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
var start_time: float = 0.0
var elapsed_time: float = 0.0
# Add these variables to your world.gd file at the top
var collected_teal = 0
var collected_pink = 0 
var collected_purple = 0

# For screen shake effect
var shake_active = false
var shake_intensity = 0
var shake_duration = 0
var shake_timer = 0
var original_camera_position = Vector2.ZERO
var camera = null

func _ready() -> void:
	# Wait one frame to ensure all nodes are ready
	await get_tree().process_frame
	if player:
		player.add_to_group("player")
	# Start the timer
	start_time = Time.get_time_dict_from_system().second + Time.get_time_dict_from_system().minute * 60.0
	# Connect player's score_changed signal to score UI
	player.score_changed.connect(score_ui.update_score)
	connect_collectables()
	# Calculate max score
	setup_collectables()
	
	# Connect level finish signal
	level_finish.level_completed.connect(on_level_completed)
	
	# Find camera if it exists
	if has_node("Camera2D"):
		camera = get_node("Camera2D")
		original_camera_position = camera.position

func connect_collectables() -> void:
	# Find all collectables in the scene
	var collectables = get_tree().get_nodes_in_group("collectables")
	print("Found %d collectables to connect" % collectables.size())
	
	# Connect their collected signals to the player
	for collectable in collectables:
		if collectable is Collectable:
			print("Connecting collectable: ", collectable.name)
			# Connect the collected signal to our own handler
			if !collectable.collected.is_connected(_on_collectable_collected):
				collectable.collected.connect(_on_collectable_collected)

func _on_collectable_collected(points):
	print("Collectable collected, adding %d points" % points)
	player.add_score(points)
	# Track collectables as they're collected
	if points == 10:
		collected_teal += 1
		play_collect_effects("teal")
	elif points == 20:
		collected_pink += 1
		play_collect_effects("pink")
	elif points == 30:
		collected_purple += 1
		play_collect_effects("purple")
	
	print("Current collected counts - Teal: %d, Pink: %d, Purple: %d" % [collected_teal, collected_pink, collected_purple])

# Modified play_collect_effects function for world.gd
func play_collect_effects(color_type):
	# Create a separate audio player for collectible sounds
	var collect_sfx = AudioStreamPlayer.new()
	add_child(collect_sfx)
	
	# Load the correct sound effect
	var sound = load("res://assets/sounds/Analog Bubbles_bip_1bubbles.wav")
	if sound:
		collect_sfx.stream = sound
		
		# Set pitch based on collectible type
		var pitch = 1.0
		if color_type == "teal":
			pitch = 0.8
		elif color_type == "pink":
			pitch = 1.0
		elif color_type == "purple":
			pitch = 1.2
		
		collect_sfx.pitch_scale = pitch
		collect_sfx.play()
		
		# Remove the audio player once the sound is done
		collect_sfx.finished.connect(func(): collect_sfx.queue_free())
	
	# Add a small camera shake based on value
	var intensity = 0
	if color_type == "teal":
		intensity = 1
	elif color_type == "pink":
		intensity = 2
	elif color_type == "purple":
		intensity = 3
	
	if intensity > 0:
		shake_screen(intensity, 0.2)
	
	# Apply a small bounce to the player
	if player:
		# Find the player sprite
		var player_sprite = player.get_node("Sprite2D") if player.has_node("Sprite2D") else null
		if player_sprite:
			# Create a quick squash and stretch animation
			var squash_tween = create_tween()
			squash_tween.tween_property(player_sprite, "scale", Vector2(1.2, 0.8), 0.1)
			squash_tween.tween_property(player_sprite, "scale", Vector2(0.9, 1.1), 0.1)
			squash_tween.tween_property(player_sprite, "scale", Vector2(1.0, 1.0), 0.1)
			
			# Assuming there's gravity in your game, apply a small upward velocity for bounce
			if intensity > 1:  # Only apply for more valuable collectibles
				player.velocity.y = -50  # Apply a small jump velocity

# Add a screen shake function
func shake_screen(intensity, duration):
	if camera:
		shake_active = true
		shake_intensity = intensity
		shake_duration = duration
		shake_timer = 0

# Setup collectables function
func setup_collectables():
	# Get all collectables and add them to a group
	var collectables = get_tree().get_nodes_in_group("collectables")
	print("Found %d collectables in the level" % collectables.size())
	
	# You can also count by type if needed
	var teal_count = 0
	var pink_count = 0
	var purple_count = 0
	
	for collectable in collectables:
		if collectable is Collectable:
			if collectable.points == 10:
				teal_count += 1
			elif collectable.points == 20:
				pink_count += 1
			elif collectable.points == 30:
				purple_count += 1
	
	print("Collectables: %d Teal, %d Pink, %d Purple" % [teal_count, pink_count, purple_count])
	
	# Set max score on UI
	var max_score = (teal_count * 10) + (pink_count * 20) + (purple_count * 30)
	print('max_score: ', max_score)
	if score_ui:
		score_ui.max_score = max_score

func _process(delta: float) -> void:
	if not player.level_finished:
		elapsed_time += delta
		
	score_ui.update_time(elapsed_time)
	
	# Handle screen shake effect
	if shake_active and camera:
		shake_timer += delta
		
		if shake_timer < shake_duration:
			# Apply random offset based on intensity
			var offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
			camera.position = original_camera_position + offset
		else:
			# Reset camera position and stop shaking
			camera.position = original_camera_position
			shake_active = false
	
	if player.global_position.y > 1000:
		get_tree().reload_current_scene()

func on_level_completed(score: Variant, time: Variant, perfect_score: Variant) -> void:
	print('Level Completed - Score: ', score, ' Time: ', elapsed_time, ' Perfect Score: ', perfect_score)
	
	# Add a bigger screen shake for level completion
	shake_screen(5, 0.5)
	
	# Create screen flash effect - even more subtle and faster
	var flash_color = Color(1, 1, 1, 0.2)  # White flash with very low opacity
	if perfect_score:
		flash_color = Color(1, 0.8, 0.2, 0.2)  # Golden flash with very low opacity
	
	# Use an extremely short duration for the flash
	var flash = load("res://screen_flash.gd").flash(self, flash_color, 0.3)
	
	# Start level complete popup immediately so particles are visible from the start
	var popup_creator = load("res://level_complete_popup.tscn").instantiate()
	add_child(popup_creator)
	
	# Connect to the animation completed signal
	popup_creator.animation_completed.connect(func():
		# Add a small delay before transitioning to the level complete screen
		await get_tree().create_timer(0.5).timeout
		show_level_complete_screen(score, elapsed_time)
	)

func show_level_complete_screen(score, elapsed_time):
	# Use the tracked counts instead of trying to check collectable nodes
	var collectable_counts = {
		"teal": collected_teal,
		"pink": collected_pink,
		"purple": collected_purple
	}
	
	# Debug print the counts
	print("Collected Counts: ", collectable_counts)
	
	# Load and transition to level complete scene
	var level_complete_scene = load("res://level_complete.tscn")
	var level_complete_instance = level_complete_scene.instantiate()
	
	# Set level data in the new scene
	level_complete_instance.set_level_data(score, elapsed_time, collectable_counts)
	
	# Change to the level complete scene
	get_tree().root.add_child(level_complete_instance)
	queue_free()  # Remove the current world scene
