extends Node2D
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	connect_collectables()
	
func connect_collectables() -> void:
		# Find all collectables in the scene
	var collectables = get_tree().get_nodes_in_group("collectables")
	
	# Connect their collected signals to the player
	for collectable in collectables:
		if collectable is Collectable:
			collectable.collected.connect(_on_collectable_collected)

func _on_collectable_collected(points):
	player.add_score(points)

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

func _process(delta: float) -> void:
	if player.global_position.y > 1000:
		get_tree().reload_current_scene()
