extends Area2D
class_name LevelFinish

signal level_completed(score, time, perfect_score)

func _ready():
	# Connect body entered signal
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body is CharacterBody2D and body.name == "Player":
		# Get the score directly from the player
		var score = body.score
		
		# Get the world node
		var world = get_tree().get_current_scene()
		
		# Get level time from world (if you have a timer implemented)
		var elapsed_time = 0.0
		
		# Check if perfect score was achieved
		var perfect_score = score >= world.score_ui.max_score
		
		print("Level completed! Score: ", score, " Time: ", elapsed_time, " Perfect: ", perfect_score)
		
		# Emit signal with level stats
		level_completed.emit(score, elapsed_time, perfect_score)
		
		# Call the level completion method in the world if it exists
		if world.has_method("on_level_completed"):
			world.on_level_completed(score, elapsed_time, perfect_score)
