extends Control
@onready var time_label: Label = $Background/VBoxContainer/TimeLabel
@onready var teal_label: Label = $Background/VBoxContainer/HBoxContainer/Teal/TealLabel
@onready var pink_label: Label = $Background/VBoxContainer/HBoxContainer/Pink/PinkLabel
@onready var purple_label: Label = $Background/VBoxContainer/HBoxContainer/Purple/PurpleLabel
@onready var score_label: Label = $Background/VBoxContainer/HBoxContainer3/ScoreLabel

var level_score: int = 0
var level_time: float = 0.0
var collectable_counts: Dictionary = {
	"teal": 0,
	"pink": 0,
	"purple": 0
}

func _ready():
		# Debug prints
	print("Collectables in _ready: ", collectable_counts)
	# Format time
	var minutes = int(level_time) / 60
	var seconds = int(level_time) % 60
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]
	
	# Update collectable count labels
	teal_label.text = "x %d" % collectable_counts["teal"]
	pink_label.text = "x %d" % collectable_counts["pink"]
	purple_label.text = "x %d" % collectable_counts["purple"]
	score_label.text = "Score: " + str(level_score)
	
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://world.tscn")
		queue_free()
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

# Method to set level completion data from the previous scene
func set_level_data(score: int, time: float, collectables: Dictionary):
		# Debug prints
	print("Received score: ", score)
	print("Received time: ", time)
	print("Received collectables: ", collectables)
	level_score = score
	level_time = time
	collectable_counts = collectables

	# Force update labels
	_ready()
