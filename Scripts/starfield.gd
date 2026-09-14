@tool
extends MultiMeshInstance3D
# Always configure a fresh, empty resource before allocating instances.
func _ready():
	var star := SphereMesh.new()
	star.radius = 0.45
	star.height = 0.9
	star.radial_segments = 4
	star.rings = 2
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("#c9e6ff")
	star.material = mat
	var field := MultiMesh.new()
	field.transform_format = MultiMesh.TRANSFORM_3D
	field.mesh = star
	field.instance_count = 900
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260914
	for i in field.instance_count:
		var direction := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		var size := rng.randf_range(0.5, 1.6)
		field.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), direction * rng.randf_range(220.0, 350.0)))
	multimesh = field
