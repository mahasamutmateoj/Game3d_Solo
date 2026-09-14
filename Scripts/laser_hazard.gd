extends Area3D
@export var cycle: float = 5.0
@export var active_duration: float = 2.2
@export var phase: float = 0.0
@export var travel := Vector3.ZERO
var origin := Vector3.ZERO
var elapsed := 0.0
var active := false
var laser_material: StandardMaterial3D

func _ready():
	origin = position
	collision_layer = 0
	collision_mask = 1
	laser_material = $Beam.material_override.duplicate()
	$Beam.material_override = laser_material
	add_to_group("Hazards")

func _physics_process(delta):
	elapsed += delta
	position = origin + travel * sin(elapsed * TAU / cycle)
	var clock := fposmod(elapsed + phase, cycle)
	active = clock < active_duration
	var warning := clock >= cycle - 0.75
	var color := Color("#ff3c55") if active else (Color("#ffc45b") if warning else Color("#243b48"))
	laser_material.albedo_color = color
	laser_material.emission = color
	laser_material.emission_energy_multiplier = 2.0 if active else (0.7 if warning else 0.0)
	if active:
		for body in get_overlapping_bodies():
			if body.is_in_group("Player") and body.respawn_grace <= 0.0:
				body.respawn(get_tree().current_scene.get_node("Extras/SpawnPosition").global_position)
