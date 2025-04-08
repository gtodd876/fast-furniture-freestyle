extends Control
@onready var time_label: Label = $Background/VBoxContainer/TimeLabel
@onready var teal_label: Label = $Background/VBoxContainer/HBoxContainer/Teal/TealLabel
@onready var pink_label: Label = $Background/VBoxContainer/HBoxContainer/Pink/PinkLabel
@onready var purple_label: Label = $Background/VBoxContainer/HBoxContainer/Purple/PurpleLabel
@onready var score_label: Label = $Background/VBoxContainer/HBoxContainer3/ScoreLabel
@onready var tally_sound: AudioStreamPlayer = $TallySound
@onready var grade_audio: AudioStreamPlayer = $GradeAudio
@onready var grade_label: Label = $Background/VBoxContainer/Control/CenterContainer/GradeLabel
@onready var toot_audio: AudioStreamPlayer = $TootAudio
@onready var piper_toot: AudioStreamPlayer = $PiperToot

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

# Beat and color animation variables
@export var beat_duration: float = 0.95238  # Duration of beat cycle
@export var max_scale: Vector2 = Vector2(1.2, 1.2)  # Maximum scale
@export var min_scale: Vector2 = Vector2(1.0, 1.0)  # Minimum scale
@export var transition_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT

# Color cycling variables
var color_cycle_tween: Tween
var color_cycle_duration: float = 2.0
var color_range: Array[Color] = [
	Color(1, 0.5, 0.5),   # Light Red
	Color(0.5, 1, 0.5),   # Light Green
	Color(0.5, 0.5, 1),   # Light Blue
	Color(1, 1, 0.5),     # Light Yellow
	Color(1, 0.5, 1)      # Light Magenta
]


func _ready():
	# Initialize anchors for grade_label (redundant but good practice)
	grade_label.anchor_left = 0.5
	grade_label.anchor_right = 0.5
	grade_label.anchor_top = 0.5
	grade_label.anchor_bottom = 0.5
	
	# Format time
	var minutes = int(level_time) / 60
	var seconds = int(level_time) % 60
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]
	
	# Initialize labels to zero
	teal_label.text = "x 0"
	pink_label.text = "x 0"
	purple_label.text = "x 0"
	score_label.text = "Score: 0"
	
	# Wait for the GradeLabel to be properly initialized with correct size
	await get_tree().process_frame
	
	# First, ensure the label has finished calculating its size
	# Use get_minimum_size() which is available on Control nodes
	var min_size = grade_label.get_minimum_size()
	
	# Calculate and set the correct pivot offset
	grade_label.pivot_offset = Vector2(min_size.x / 2, 0)
	print("Grade label size: ", grade_label.size)
	print("Set pivot offset to: ", grade_label.pivot_offset)
	
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
	
	# Ensure pivot offset is properly set when text changes
	await get_tree().process_frame
	var updated_size = grade_label.get_minimum_size()
	grade_label.pivot_offset = Vector2(updated_size.x / 2, 0)
	print("Updated grade label size after text change: ", updated_size)
	print("Updated pivot offset: ", grade_label.pivot_offset)

	if grade == "C" or grade == "D":
		toot_audio.play()
	elif grade == "F":
		piper_toot.play()
	else:
		grade_audio.play()
	
	# Animate the grade appearing
	var appear_tween = create_tween()
	appear_tween.tween_property(grade_label, "modulate:a", 1.0, 0.5)
	
	# Start beat animation and color cycling after the grade appears
	await appear_tween.finished
	start_color_cycling()
	
	is_animating = false

func start_color_cycling():
	# Stop any existing color cycle tween
	if color_cycle_tween:
		color_cycle_tween.kill()
	
	# Create a new color cycling tween
	color_cycle_tween = create_tween().set_loops()
	
	# Cycle through colors
	for color in color_range:
		color_cycle_tween.tween_method(
			func(c): 
				grade_label.add_theme_color_override("font_color", c), 
			Color.WHITE, 
			color, 
			color_cycle_duration / color_range.size()
		)
	
	# Optional: Add a reset to white at the end of each cycle
	color_cycle_tween.tween_method(
		func(c): 
			grade_label.add_theme_color_override("font_color", c), 
		color_range[-1], 
		Color.WHITE, 
		color_cycle_duration / color_range.size()
	)

func get_grade_for_score(score: int) -> String:
	print('final_score: ', score, "/100")
	
	if score >= 95:
		return "A+"
	elif score >= 90:
		return "A"
	elif score >= 80:
		return "B"
	elif score >= 70:
		return "C"
	elif score >= 60:
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
