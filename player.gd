
extends CharacterBody2D
enum PlayerState { IDLE, RUN, JUMP, CARTWHEEL }
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
var air_jump = true
var jump_buffer: bool = false
var player_state = PlayerState.IDLE

func calc_gravity(v: Vector2) -> float:
	return gravity if (v.y < 0) else fall_gravity
	
func do_jump() -> void:
	change_state(PlayerState.JUMP)
	velocity.y = jump_speed
	
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
	var tween = create_tween()
	var full_spin: int = 360
	if $Sprite2D.flip_h == false:
		tween.tween_property(sprite_2d, "rotation_degrees", 0, 0.4).from(full_spin - sprite_2d.rotation_degrees)
	else:
		tween.tween_property(sprite_2d, "rotation_degrees", 0, 0.4).from(full_spin - sprite_2d.rotation_degrees)

func _ready() -> void:
	camera_2d.zoom = Vector2(max_zoom_amount, max_zoom_amount)
	change_state(PlayerState.IDLE)
	var result: Rect2 = $Sprite2D.get_rect()
	print("player", result.size)
	
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
			animation_player.play("cartwheel")

func get_input(delta: float) -> void:
	var x_input = Input.get_axis("left", "right")
	var right = x_input == 1
	var left = x_input == -1
	var jump_pressed = Input.is_action_just_pressed("jump")
	var jump_released = Input.is_action_just_released("jump")
	var cartwheel_pressed = Input.is_action_just_pressed("cartwheel")
	velocity.x = 0
	if right:
		velocity.x += x_input * run_speed
		$Sprite2D.flip_h = false
	if left:
		velocity.x += x_input * run_speed
		$Sprite2D.flip_h = true

	if is_on_floor():
		if jump_pressed:
			do_jump()
		if jump_buffer:
			do_jump()
			jump_buffer = false
		if cartwheel_pressed:
			do_cartwheel()
			change_state(PlayerState.RUN)
	else:
		if jump_pressed:
			jump_buffer = true
			get_tree().create_timer(jump_buffer_time).timeout.connect(on_jump_buffer_timeout)
			do_double_jump(delta)
		
	if player_state == PlayerState.IDLE and velocity.x != 0:
		change_state(PlayerState.RUN)
	if player_state == PlayerState.RUN and velocity.x == 0:
		change_state(PlayerState.IDLE)
	if player_state in [PlayerState.IDLE, PlayerState.RUN] and !is_on_floor():
		change_state(PlayerState.JUMP)
	
	if jump_released:
		if velocity.y < 0:
			velocity.y = jump_speed / 4.0
			
func on_jump_buffer_timeout() -> void:
	jump_buffer = false

func _physics_process(delta: float) -> void:
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
	var y_offset_target: float = clamp(ray_cast_2d.get_collision_point().y - global_position.y - 30, -59, 112)
	print('ray y', ray_cast_2d.get_collision_point().y, 'global y', global_position.y, 'cam offset y', camera_2d.offset.y, 'y offset target', y_offset_target)
	camera_2d.offset.y = lerp(camera_2d.offset.y, y_offset_target, 0.02)
	var zoom_target = Vector2.ONE
	
	move_and_slide()
	camera_2d.zoom = camera_2d.zoom.lerp(zoom_target, 0.02)
