extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var mouse_sense: float = 0.1
var aim_mouse_sense: float = 0.05
var is_aiming: bool = false

@onready var Head = $Head
@onready var camera = $Head/Camera3D
@onready var weapon = $Head/Camera3D/WeaponHolder/Weapon/fps_rig/Revolvernode/Revolver/RevolverArmature
@onready var weapon_holder = $Head/Camera3D/WeaponHolder

# Posições da arma: idle e mira
var idle_position: Vector3 = Vector3(0.3, -0.25, -0.1)
var aim_position: Vector3 = Vector3(0.1, -0.1, 0.2)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		var sens = mouse_sense
		if is_aiming:
			sens = aim_mouse_sense
		rotate_y(deg_to_rad(-event.relative.x * sens))
		Head.rotate_x(deg_to_rad(-event.relative.y * sens))
		Head.rotation.x = clamp(Head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			weapon.fire()

		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_aiming = event.pressed

	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		weapon.reload()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# Transição suave da arma entre posição idle e de mira
	var target_pos: Vector3
	if is_aiming:
		target_pos = aim_position
	else:
		target_pos = idle_position

	weapon_holder.transform.origin = weapon_holder.transform.origin.lerp(target_pos, delta * 10.0)
