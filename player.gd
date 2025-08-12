# Snappy 2D Platformer Controller (Celeste-Style + Dash + Hazards)

extends CharacterBody2D

# --- Movement ---
@export var speed: float = 280.0
@export var acceleration: float = 0.08
@export var friction: float = 0.12     
@export var air_acceleration: float = 0.06 

# --- Jump ---
@export var jump_velocity: float = -420.0
@export var jump_cut_multiplier: float = 0.4 
@export var coyote_time: float = 0.1    
@export var jump_buffer_time: float = 0.1

# --- Wall Jump ---
@export var wall_jump_velocity: Vector2 = Vector2(450.0, -380.0) 
@export var wall_slide_gravity: float = 120.0
@export var wall_jump_time: float = 0.15

# --- Gravity ---
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed: float = 600.0

# --- Dash ---
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.4
var dash_timer: float = 0.0
var dash_cd_timer: float = 0.0
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO

# --- Timers ---
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var wall_jump_timer: float = 0.0
var can_wall_jump: bool = false

func _physics_process(delta: float):
	update_timers(delta)

	# Jump buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	
	# Dash input
	if Input.is_action_just_pressed("dash") and dash_cd_timer <= 0:
		start_dash()
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer > 0:
			velocity = dash_direction * dash_speed
			move_and_slide()
			return
		else:
			is_dashing = false
			dash_cd_timer = dash_cooldown

	# Gravity + wall slide
	if not is_on_floor():
		if is_on_wall() and velocity.y > 0 and Input.is_action_pressed("left" if get_wall_normal().x > 0 else "right"):
			velocity.y += wall_slide_gravity * delta
			can_wall_jump = true
		else:
			velocity.y += gravity * delta
			can_wall_jump = false
		velocity.y = min(velocity.y, max_fall_speed)
	else:
		can_wall_jump = false

	# Coyote time
	if is_on_floor():
		coyote_timer = coyote_time
		was_on_floor = true
	elif was_on_floor and not is_on_floor():
		was_on_floor = false

	# Movement
	handle_horizontal_movement(delta)
	handle_jumping()

	# Jump cut
	if velocity.y < 0 and not Input.is_action_pressed("jump"):
		velocity.y *= jump_cut_multiplier
	
	move_and_slide()

func update_timers(delta: float):
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
	if dash_cd_timer > 0:
		dash_cd_timer -= delta

func handle_horizontal_movement(delta: float):
	var input_axis = Input.get_axis("left", "right")
	var target_velocity = input_axis * speed
	var accel = acceleration if is_on_floor() else air_acceleration
	if wall_jump_timer > 0:
		accel *= 0.3
	if input_axis != 0:
		velocity.x = lerp(velocity.x, target_velocity, accel)
	else:
		var fric = friction if is_on_floor() else friction * 0.8
		velocity.x = lerp(velocity.x, 0.0, fric)

func handle_jumping():
	var can_jump = (is_on_floor() or coyote_timer > 0) and jump_buffer_timer > 0
	var can_wall_jump_now = can_wall_jump and is_on_wall() and jump_buffer_timer > 0
	if can_jump:
		velocity.y = jump_velocity
		jump_buffer_timer = 0
		coyote_timer = 0
	elif can_wall_jump_now:
		var wall_normal = get_wall_normal()
		velocity.x = wall_normal.x * wall_jump_velocity.x
		velocity.y = wall_jump_velocity.y
		wall_jump_timer = wall_jump_time
		jump_buffer_timer = 0
		can_wall_jump = false

func start_dash():
	var input_dir = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)
	if input_dir == Vector2.ZERO:
		input_dir = Vector2(1 if not $Sprite2D.flip_h else -1, 0)
	dash_direction = input_dir.normalized()
	is_dashing = true
	dash_timer = dash_duration
	velocity = dash_direction * dash_speed

func _process(_delta):
	if wall_jump_timer <= 0:
		if velocity.x > 10:
			$Sprite2D.flip_h = false
		elif velocity.x < -10:
			$Sprite2D.flip_h = true

# --- Hazard & Trampoline Handling ---
func _on_spike_area_body_entered(body):
	if body == self:
		die()

func _on_trampoline_area_body_entered(body):
	if body == self:
		velocity.y = -600  # trampoline launch velocity

func die():
	print("Player died")
	# Reset player position or trigger death animation
	position = Vector2.ZERO
