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
	bg_rect.size = Vector2(get_viewport().size.x, 40)  # Full width, 40px height
	bg_rect.position = Vector2(0, 0)
	add_child(bg_rect)
	
	# Create the score label
	score_label = Label.new()
	score_label.text = "SCORE: 0"
	score_label.position = Vector2(20, 8)  # Positioned within the bar
	
		# Create the time label
	time_label = Label.new()
	time_label.text = "TIME: 0.00"
	time_label.position = Vector2(180, 8)  # Positioned to the right of score
	
	# Set up the font
	var font = load("res://assets/fonts/Baumans-Regular.ttf")  # Adjust path as needed
	if font:
		var font_variation = FontVariation.new()
		font_variation.base_font = font
		score_label.add_theme_font_override("font", font_variation)
		score_label.add_theme_font_size_override("font_size", 24)
		score_label.add_theme_color_override("font_color", Color.WHITE)
		
		time_label.add_theme_font_override("font", font_variation)
		time_label.add_theme_font_size_override("font_size", 24)
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

func show_perfect_score():
		# Set the flag to indicate perfect screen is active
	perfect_screen_active = true
	
	print("Loading perfect score scene...")
	
	# Create the celebration scene
	#var perfect_scene = load("res://perfect_score.tscn")
	#if perfect_scene:
		#var instance = perfect_scene.instantiate()
		## Make sure it's added to the viewport
		#get_tree().root.add_child(instance)
		#print("Perfect scene added to root")
		#
		## Store reference
		#instance.set_meta("perfect_root", true)
	#else:
		#print("Failed to load perfect score scene!")

func spawn_victory_particles(parent_node):
	# Create several particle systems at different positions
	var viewport_size = get_viewport().size
	
	for i in range(5):
		var particles = CPUParticles2D.new()
		particles.position = Vector2(viewport_size.x * (0.1 + 0.2 * i), 100)
		particles.z_index = 10000  # Above everything else
		particles.emitting = true
		particles.one_shot = true
		particles.explosiveness = 1.0
		particles.amount = 30
		particles.lifetime = 2.0
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
		particles.direction = Vector2(0, 1)  # Downward direction
		particles.spread = 60.0
		particles.gravity = Vector2(0, 50)
		particles.initial_velocity_min = 100.0
		particles.initial_velocity_max = 200.0
		particles.scale_amount_min = 2.0
		particles.scale_amount_max = 4.0
		
		# Rainbow colors
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(1, 0, 0))   # Red
		gradient.add_point(0.2, Color(1, 0.5, 0)) # Orange  
		gradient.add_point(0.4, Color(1, 1, 0))   # Yellow
		gradient.add_point(0.6, Color(0, 1, 0))   # Green
		gradient.add_point(0.8, Color(0, 0.5, 1)) # Blue
		gradient.add_point(1.0, Color(0.5, 0, 1)) # Purple
		particles.color_ramp = gradient
		
		parent_node.add_child(particles)

func spawn_celebration_particles(position: Vector2):
	var particles = CPUParticles2D.new()
	particles.position = position
	particles.z_index = 10000
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 50
	particles.lifetime = 2.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 100)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	
	# Rainbow colors
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0, 0))   # Red
	gradient.add_point(0.2, Color(1, 0.5, 0)) # Orange  
	gradient.add_point(0.4, Color(1, 1, 0))   # Yellow
	gradient.add_point(0.6, Color(0, 1, 0))   # Green
	gradient.add_point(0.8, Color(0, 0.5, 1)) # Blue
	gradient.add_point(1.0, Color(0.5, 0, 1)) # Purple
	particles.color_ramp = gradient
	
	add_child(particles)
	
	# Auto-remove when done
	await get_tree().create_timer(3.0).timeout
	particles.queue_free()

func _input(event):
	if perfect_screen_active and event is InputEventKey and event.pressed:
		dismiss_perfect_screen()
		get_viewport().set_input_as_handled()

func dismiss_perfect_screen():
	# Find and remove the perfect score root node
	for child in get_tree().root.get_children():
		if child.has_meta("perfect_root"):
			child.queue_free()
	
	perfect_screen_active = false
	set_process_input(false)
