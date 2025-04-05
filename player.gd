
extends CharacterBody2D
enum PlayerState { IDLE, RUN, JUMP, CARTWHEEL }
var score: int = 0
signal score_changed(new_score)
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_2d: Camera2D = $Camera2D
@onready var jump_sfx: AudioStreamPlayer = $jump_sfx
@onready var sprite_2d: Sprite2D = $Sprite2D
@export var gravity: float = 750
@export var fall_gravity: float = 1500
@export var run_speed: int = 150
@export var jump_speed: int = -300
@export var min_zoom_amount: float = 0.9
@export var max_zoom_amount: float = 1.5
@onready var ray_cast_2d: RayCast2D = $Sprite2D/RayCast2D
@export var landing_acceleration: float = 200.0
@export var air_jump_speed_reduction: float = 1500.0
@export var jump_buffer_time: float = 0.15
@export var max_speed: float = 290.0
@export var friction: float = 1600.0
@export var acceleration: float = 150.0
@export var air_friction: float = 60.0
var air_jump = true
var jump_buffer: bool = false
var player_state = PlayerState.IDLE
var was_in_air = false

func calc_gravity(v: Vector2) -> float:
	return gravity if (v.y < 0) else fall_gravity
	
func do_jump(is_bouncer = false) -> void:
	change_state(PlayerState.JUMP)
	velocity.y = jump_speed * 1.25 if is_bouncer else jump_speed
	
func do_double_jump(delta: float) -> void:
	if  air_jump == true and PlayerState.JUMP:
				velocity.y = jump_speed
				velocity.x -= air_jump_speed_reduction * delta
				air_jump = false
				var tween = create_tween()
				if $Sprite2D.flip_h == false:
					tween.tween_property(sprite_2d, "rotation_degrees", 0, 0.4).from(-360 + sprite_2d.rotation_degrees)
				else:
					tween.tween_property(sprite_2d, "rotation_degrees", 0, 0.4).from(360 + sprite_2d.rotation_degrees)
						

func do_cartwheel() -> void:
	change_state(PlayerState.CARTWHEEL)
	var tween = create_tween()
	var full_spin: int = 360
	if $Sprite2D.flip_h == false:
		tween.tween_property(sprite_2d, "rotation_degrees", 360, 0.4).from(0)
		tween.tween_property(sprite_2d, "rotation_degrees", 0, 0.0)
	else:
		tween.tween_property(sprite_2d, "rotation_degrees", -360, 0.4).from(0)
		tween.tween_property(sprite_2d, "rotation_degrees", 0, 0.0)
	tween.tween_callback(func():
		if is_on_floor():
			if abs(velocity.x) > 0:
				change_state(PlayerState.RUN)
			else:
				change_state(PlayerState.IDLE)
		else:
			change_state(PlayerState.JUMP)
	)
		
func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)
	print("Score: ", score)

func _ready() -> void:
	camera_2d.zoom = Vector2(max_zoom_amount, max_zoom_amount)
	change_state(PlayerState.IDLE)
	var result: Rect2 = $Sprite2D.get_rect()
	
func change_state(new_state: PlayerState) -> void:
	player_state = new_state
	match player_state:
		PlayerState.IDLE:
			animation_player.play("idle")
		PlayerState.RUN:
			animation_player.play("run")
		PlayerState.JUMP:
			jump_sfx.stop()
			jump_sfx.play()
			animation_player.play("jump_up")
		PlayerState.CARTWHEEL:
			print("play animationd")
			animation_player.play("cartwheel")

func get_input(delta: float) -> void:
	var x_input = Input.get_axis("left", "right")
	var right = x_input == 1
	var left = x_input == -1
	var jump_pressed = Input.is_action_just_pressed("jump")
	var jump_released = Input.is_action_just_released("jump")
	var cartwheel_pressed = Input.is_action_just_pressed("cartwheel")
	var direction = x_input
	if right:
		$Sprite2D.flip_h = false
	if left:
		$Sprite2D.flip_h = true

	if is_on_floor():
		if jump_pressed:
			do_jump()
		if jump_buffer:
			do_jump()
			jump_buffer = false
		if cartwheel_pressed:
			do_cartwheel()
	else:
		if jump_pressed:
			jump_buffer = true
			get_tree().create_timer(jump_buffer_time).timeout.connect(on_jump_buffer_timeout)
			do_double_jump(delta)
			
	if player_state != PlayerState.CARTWHEEL:
		if player_state == PlayerState.IDLE and velocity.x != 0:
			change_state(PlayerState.RUN)
		if player_state == PlayerState.RUN and velocity.x == 0:
			change_state(PlayerState.IDLE)
		if player_state in [PlayerState.IDLE, PlayerState.RUN] and !is_on_floor():
			change_state(PlayerState.JUMP)
	
	if jump_released:
		if velocity.y < 0:
			velocity.y = jump_speed / 4.0
		# Apply acceleration or friction based on input direction
	if is_on_floor():
		if direction != 0:
			# Accelerate towards max_speed in the input direction
			velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
		else:
			# Apply friction to slow down when no input
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		# Correct version - gradually reduce velocity in air when no input
		if direction == 0:
			velocity.x = move_toward(velocity.x, 0, air_friction * delta)
		# Optional: You could also allow some air control
		else:
			velocity.x = move_toward(velocity.x, direction * max_speed * 0.8, air_friction * delta)
			
func on_jump_buffer_timeout() -> void:
	jump_buffer = false

func _physics_process(delta: float) -> void:
	var was_in_air_this_frame = !is_on_floor()
	velocity.y += calc_gravity(velocity) * delta
	get_input(delta)
	if is_on_floor():
		air_jump = true
		
	if player_state == PlayerState.JUMP:
		if is_on_floor():
			change_state(PlayerState.IDLE)
		else: # is not on floor
			if  velocity.y > 0:
				$AnimationPlayer.play("jump_down")
	var y_offset_target: float = clamp(ray_cast_2d.get_collision_point().y - $Sprite2D.global_position.y - 30, -59, -20)
	camera_2d.offset.y = lerp(camera_2d.offset.y, y_offset_target, 0.02)
	var zoom_target = Vector2.ONE
	
	move_and_slide()
	# Detect if we just landed this frame
	var just_landed = was_in_air_this_frame and is_on_floor()
	# Check if there was a collision
	if get_slide_collision_count() > 0:		
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			var normal = collision.get_normal()
			
			if collider.name == "Bouncers" and normal.y < 0:
				if just_landed:
					print("Bouncing landed from above")
					do_jump(true)
			elif collider.name != "Bouncers":
				match collider.name:
					"Collectables":
						print("Collectables")
					"Obstacles":
						print("Obstacles")
					"FloorTiles":
						print("FloorTiles")
					"Sliders":
						print("Sliders")
					_:
						print("Unknown collision name: ", collider.name)
					
	camera_2d.zoom = camera_2d.zoom.lerp(zoom_target, 0.02)
