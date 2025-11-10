extends Node3D

@export var damage: int = 20
@export var speed: float = 100.0
@export var gravity: Vector3 = Vector3(0, -9.8, 0)
@export var max_distance: float = 1000.0

var velocity: Vector3
var traveled_distance: float = 0.0
var last_position: Vector3

func initialize(direction: Vector3, speed_: float, damage_: int) -> void:
	damage = damage_
	speed = speed_
	velocity = direction.normalized() * speed
	last_position = global_transform.origin
	look_at(global_transform.origin + velocity, Vector3.UP)

func _process(delta: float) -> void:
	# Aplica gravidade na velocidade
	velocity += gravity * delta
	
	# Calcula o deslocamento e próxima posição
	var displacement = velocity * delta
	var next_position = global_transform.origin + displacement
	
	# Raycast para detectar colisões entre a posição atual e a próxima
	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = last_position
	params.to = next_position
	params.exclude = [self]
	params.collision_mask = 0xFFFFFFFF  # Detecta todos os corpos por padrão

	var ray_result = space_state.intersect_ray(params)

	if ray_result and ray_result.collider:
		# Colidiu com algo real
		print("Acertou:", ray_result.collider.name)
		if ray_result.collider.has_method("take_damage"):
			ray_result.collider.take_damage(damage)
		queue_free()
		return
	
	# Atualiza a posição da bala
	global_transform.origin = next_position
	last_position = next_position
	traveled_distance += displacement.length()
	
	# Destrói a bala se ultrapassar a distância máxima
	if traveled_distance > max_distance:
		queue_free()
