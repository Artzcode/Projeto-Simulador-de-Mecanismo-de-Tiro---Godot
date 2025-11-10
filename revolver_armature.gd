extends Node3D

@export var damage: int = 20
@export var fire_rate: float = 0.8  # Cadência mais lenta para revolver Magnum
@export var bullet_scene: PackedScene

@export var max_ammo: int = 8  # Capacidade ajustada para 8 balas
@export var reserve_ammo: int = 24
var current_ammo: int = max_ammo
var is_reloading: bool = false
var can_fire: bool = true

@onready var muzzle = $Skeleton3D/Bullets2
@onready var animation_player = $Skeleton3D/AnimationPlayer
@onready var audio_fire = $Audio_Fire
@onready var audio_empty = $Audio_Empty
@onready var audio_reload = $Audio_Reload

var fire_timer: Timer

var base_recoil_amount = Vector3(0, 0, -0.03)
var recoil_variation = 0.015
var recoil_return_speed = 5.0
var current_recoil_offset = Vector3.ZERO

func _ready():
	fire_timer = Timer.new()
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true
	fire_timer.connect("timeout", Callable(self, "_on_FireTimer_timeout"))
	add_child(fire_timer)

func _process(delta):
	current_recoil_offset = current_recoil_offset.lerp(Vector3.ZERO, recoil_return_speed * delta)
	muzzle.transform.origin = muzzle.transform.origin.lerp(current_recoil_offset, 0.3)

func get_aim_direction() -> Vector3:
	var origin = muzzle.global_transform.origin
	var direction = -muzzle.global_transform.basis.z.normalized()
	var space_state = get_world_3d().direct_space_state
	
	var ray_length = 1000.0
	var to = origin + direction * ray_length

	var query = PhysicsRayQueryParameters3D.new()
	query.from = origin
	query.to = to
	query.exclude = [self]

	var result = space_state.intersect_ray(query)

	if result:
		return (result.position - origin).normalized()
	else:
		return direction

func fire() -> void:
	if not can_fire or is_reloading:
		return

	if current_ammo <= 0:
		if audio_empty:
			audio_empty.play()
		print("Sem munição! Precisa recarregar.")
		return

	current_ammo -= 1

	if animation_player:
		animation_player.play("RevolverArmature|Fire")
	if audio_fire:
		audio_fire.play()
		

	# Recuo com variação aleatória
	var random_recoil = base_recoil_amount + Vector3(
		randf_range(-recoil_variation, recoil_variation),
		randf_range(-recoil_variation, recoil_variation),
		randf_range(-recoil_variation, recoil_variation)
	)
	current_recoil_offset += random_recoil

	# Usa a direção da mira calculada com raycast
	var direction = get_aim_direction()

	# Dispersão do tiro
	var spread_angle = 2.0  # Spread menor para revólver, tiro mais preciso
	var spread_rad = deg_to_rad(spread_angle)
	direction = direction.rotated(Vector3.UP, randf_range(-spread_rad, spread_rad))
	direction = direction.rotated(Vector3.RIGHT, randf_range(-spread_rad, spread_rad))

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform.origin = muzzle.global_transform.origin
	if bullet.has_method("initialize"):
		bullet.initialize(direction, 100.0, damage)

	can_fire = false
	fire_timer.start()

func _on_FireTimer_timeout():
	can_fire = true

func reload():
	if is_reloading or current_ammo == max_ammo or reserve_ammo <= 0:
		return

	is_reloading = true
	can_fire = false

	if animation_player:
		animation_player.play("RevolverArmature|Reload")
	if audio_reload:
		audio_reload.play()

	var reload_time = animation_player and animation_player.current_animation_length or 1.5
	await get_tree().create_timer(reload_time).timeout

	var needed = max_ammo - current_ammo
	var to_reload = min(needed, reserve_ammo)
	current_ammo += to_reload
	reserve_ammo -= to_reload

	print("Recarregado: ", current_ammo, "/", reserve_ammo)

	is_reloading = false
	can_fire = true
