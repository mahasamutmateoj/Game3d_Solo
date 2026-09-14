extends Area3D
@export var spawn_at := Vector3.ZERO
var activated := false
func _ready():
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
func _on_body_entered(body):
	if activated or not body.is_in_group("Player"):
		return
	activated = true
	get_tree().current_scene.get_node("Extras/SpawnPosition").global_position = spawn_at
