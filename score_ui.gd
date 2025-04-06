extends CanvasLayer
class_name ScoreUI

@onready var score_label: Label
@onready var time_label: Label
@onready var bg_rect: ColorRect
var current_score: int = 0
var max_score: int = 100
var perfect_screen_active = false

func _ready():
	# Create a background bar at the top
	bg_rect = ColorRect.new()
	bg_rect.color = Color(0.1, 0.1, 0.1, 0.7)  # Semi-transparent dark background
	bg_rect.size = Vector2(get_viewport().size.x, 25)  # Full width, 40px height
	bg_rect.position = Vector2(0, 0)
	add_child(bg_rect)
	
	# Create the score label
	score_label = Label.new()
	score_label.text = "SCORE: 0"
	score_label.position = Vector2(50, 1)  # Positioned within the bar
	
		# Create the time label
	time_label = Label.new()
	time_label.text = "TIME: 0.00"
	time_label.position = Vector2(190, 1)  # Positioned to the right of score
	
	# Set up the font
	var font = load("res://assets/fonts/Baumans-Regular.ttf")  # Adjust path as needed
	if font:
		var font_variation = FontVariation.new()
		font_variation.base_font = font
		score_label.add_theme_font_override("font", font_variation)
		score_label.add_theme_font_size_override("font_size", 16)
		score_label.add_theme_color_override("font_color", Color.WHITE)
		
		time_label.add_theme_font_override("font", font_variation)
		time_label.add_theme_font_size_override("font_size", 16)
		time_label.add_theme_color_override("font_color", Color.WHITE)
	
	add_child(score_label)
	add_child(time_label)
	
	# Initialize score to 0
	update_score(0)
	update_time(0.0)
	
func update_score(new_score: int):
	current_score = new_score
	score_label.text = "SCORE: %d" % current_score

func update_time(elapsed_time: float):
	# Format time to display minutes:seconds.milliseconds
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	var milliseconds = int((elapsed_time - int(elapsed_time)) * 100)
	
	time_label.text = "TIME: %02d:%02d" % [minutes, seconds]
