extends Node3D

func _on_area_3d_body_entered(body: Node):
	if body.is_in_group("player"):
		body.nearby_weapon = self
		print("Player está perto da arma")

func _on_area_3d_body_exited(body: Node):
	if body.is_in_group("player"):
		if body.nearby_weapon == self:
			body.nearby_weapon = null
		print("Player saiu de perto da arma")
