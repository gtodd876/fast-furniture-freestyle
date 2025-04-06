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

func _ready() -> void:
	# Wait one frame to ensure all nodes are ready
	await get_tree().process_frame
	# Start the timer
	start_time = Time.get_time_dict_from_system().second + Time.get_time_dict_from_system().minute * 60.0
	# Connect player's score_changed signal to score UI
	player.score_changed.connect(score_ui.update_score)
	connect_collectables()
	# Calculate max score
	setup_collectables()
	
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
	elif points == 20:
		collected_pink += 1
	elif points == 30:
		collected_purple += 1
	
	print("Current collected counts - Teal: %d, Pink: %d, Purple: %d" % [collected_teal, collected_pink, collected_purple])

# Call this when setting up the level to track collectables
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
	if player.global_position.y > 1000:
		get_tree().reload_current_scene()

func _on_level_completed(score: Variant, time: Variant, perfect_score: Variant) -> void:
	print('Level Completed - Score: ', score, ' Time: ', elapsed_time, ' Perfect Score: ', perfect_score)
	# Stop player input
	player.stop_input()
	audio_stream_player.stop()
	
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
