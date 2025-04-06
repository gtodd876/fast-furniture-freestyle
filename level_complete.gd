extends Control
@onready var time_label: Label = $Background/VBoxContainer/TimeLabel
@onready var teal_label: Label = $Background/VBoxContainer/HBoxContainer/Teal/TealLabel
@onready var pink_label: Label = $Background/VBoxContainer/HBoxContainer/Pink/PinkLabel
@onready var purple_label: Label = $Background/VBoxContainer/HBoxContainer/Purple/PurpleLabel
@onready var score_label: Label = $Background/VBoxContainer/HBoxContainer3/ScoreLabel
@onready var grade_label: Label = $Background/VBoxContainer/HBoxContainer3/GradeLabel
@onready var tally_sound: AudioStreamPlayer = $TallySound
@onready var grade_audio: AudioStreamPlayer = $GradeAudio

var level_score: int = 0
var level_time: float = 0.0
var collectable_counts: Dictionary = {
	"teal": 0,
	"pink": 0,
	"purple": 0
}
# Animation control variables
var is_animating: bool = false
var teal_count: int = 0
var pink_count: int = 0
var purple_count: int = 0
var current_score: int = 0
var animation_speed: float = 0.05  # Time between each count increment

func _ready():
		# Debug prints
	print("Collectables in _ready: ", collectable_counts)
	# Format time
	var minutes = int(level_time) / 60
	var seconds = int(level_time) % 60
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]
	   # Initialize labels to zero
	teal_label.text = "x 0"
	pink_label.text = "x 0"
	purple_label.text = "x 0"
	score_label.text = "Score: 0"
	
	# Add the grade label if it doesn't exist
	if not has_node("Background/VBoxContainer/GradeLabel"):
		var grade_container = $Background/VBoxContainer
		grade_label = Label.new()
		grade_label.name = "GradeLabel"
		grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grade_label.custom_minimum_size = Vector2(0, 40)  # Give it some height
		grade_container.add_child(grade_label)
	
	# Start the animated counting after a short delay
	await get_tree().create_timer(0.5).timeout
	start_animated_counting()

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		# Skip animation if it's still running
		if is_animating:
			skip_animation()
		else:
			get_tree().change_scene_to_file("res://world.tscn")
			queue_free()
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()



func set_level_data(score: int, time: float, collectables: Dictionary):
	print("Received score: ", score)
	print("Received time: ", time)
	print("Received collectables: ", collectables)
	level_score = score
	level_time = time
	collectable_counts = collectables

func start_animated_counting():
	is_animating = true
	
	# Reset counters
	teal_count = 0
	pink_count = 0
	purple_count = 0
	current_score = 0
	
	# Start counting teal collectibles
	count_teal_collectibles()

func count_teal_collectibles():
	if teal_count < collectable_counts["teal"]:
		teal_count += 1
		teal_label.text = "x %d" % teal_count
		current_score += 10
		score_label.text = "Score: %d" % current_score
		
		tally_sound.play()
		tally_sound.pitch_scale += 0.2
		
		# Wait a moment before next increment
		await get_tree().create_timer(animation_speed).timeout
		count_teal_collectibles()
	else:
		# Move to pink collectibles
		await get_tree().create_timer(0.3).timeout  # Slight pause between categories
		count_pink_collectibles()

func count_pink_collectibles():
	if pink_count < collectable_counts["pink"]:
		pink_count += 1
		pink_label.text = "x %d" % pink_count
		current_score += 20
		score_label.text = "Score: %d" % current_score
		
		tally_sound.play()
		tally_sound.pitch_scale += 0.2
		
		# Wait a moment before next increment
		await get_tree().create_timer(animation_speed).timeout
		count_pink_collectibles()
	else:
		# Move to purple collectibles
		await get_tree().create_timer(0.3).timeout  # Slight pause between categories
		count_purple_collectibles()

func count_purple_collectibles():
	if purple_count < collectable_counts["purple"]:
		purple_count += 1
		purple_label.text = "x %d" % purple_count
		current_score += 30
		score_label.text = "Score: %d" % current_score
		
		tally_sound.play()
		tally_sound.pitch_scale += 0.2
		
		# Wait a moment before next increment
		await get_tree().create_timer(animation_speed).timeout
		count_purple_collectibles()
	else:
		# Finish with assigning a grade
		await get_tree().create_timer(0.5).timeout  # Pause before showing grade
		show_final_grade()

func show_final_grade():
	var grade = get_grade_for_score(current_score)
	var max_score = (collectable_counts["teal"] * 10) + (collectable_counts["pink"] * 20) + (collectable_counts["purple"] * 30)
	
	var normalized_score = 0
	if max_score > 0:
		normalized_score = int((float(current_score) / float(max_score)) * 100)
	
	# Format the grade display
	var grade_text = "Grade: %s" % [grade]
	
	# Create a dramatic reveal for the grade
	grade_label.modulate.a = 0
	grade_label.text = grade_text
	
	# Style the grade based on result
	var grade_color = Color.WHITE
	var font_size = 24
	grade_audio.play()
	match grade:
		"A+":
			grade_color = Color(1, 0.8, 0.2)  # Gold
			font_size = 32
		"A":
			grade_color = Color(0.2, 1, 0.2)  # Green
			font_size = 28
		"B":
			grade_color = Color(0.2, 0.8, 1)  # Light Blue
		"C":
			grade_color = Color(1, 1, 0.2)  # Yellow
		"D":
			grade_color = Color(1, 0.6, 0.2)  # Orange
		"F":
			grade_color = Color(1, 0.2, 0.2)  # Red
	
	grade_label.add_theme_color_override("font_color", grade_color)
	grade_label.add_theme_font_size_override("font_size", font_size)
	
	# Animate the grade appearing
	var tween = create_tween()
	tween.tween_property(grade_label, "modulate:a", 1.0, 0.5)
	
	# For A+ grade, add some extra celebration
	if grade == "A+":
		# Play a special sound
		# If you have a sound player: $VictorySound.play()
		
		# Add a pulsing animation to the text
		await tween.finished
		var pulse_tween = create_tween().set_loops()
		pulse_tween.tween_property(grade_label, "self_modulate", Color(1.2, 1.2, 1.2), 0.5)
		pulse_tween.tween_property(grade_label, "self_modulate", Color(1, 1, 1), 0.5)
	
	is_animating = false

func get_grade_for_score(score: int) -> String:
	var max_score = (collectable_counts["teal"] * 10) + (collectable_counts["pink"] * 20) + (collectable_counts["purple"] * 30)
	
	if max_score == 100:
		return "A+"
	elif max_score >= 90:
		return "A"
	elif max_score >= 80:
		return "B"
	elif max_score >= 70:
		return "C"
	elif max_score >= 60:
		return "D"
	else:
		return "F"

func skip_animation():
	# Stop all running tweens
	var tweens = get_tree().get_nodes_in_group("tweens")
	for tween in tweens:
		tween.kill()
	
	# Set final values
	teal_count = collectable_counts["teal"]
	pink_count = collectable_counts["pink"]
	purple_count = collectable_counts["purple"]
	current_score = level_score
	
	# Update labels
	teal_label.text = "x %d" % teal_count
	pink_label.text = "x %d" % pink_count
	purple_label.text = "x %d" % purple_count
	score_label.text = "Score: %d" % current_score
	
	# Show the grade immediately
	show_final_grade()
