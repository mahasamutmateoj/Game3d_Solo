extends Area3D
@onready var spawn_position = %SpawnPosition
func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.respawn(spawn_position.global_position)
