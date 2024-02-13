extends Node3D
class_name Chunk

var mesh_instance
var noise
var x
var z
var chunk_size
var should_remove = true


func _init(noise,x,z,chunk_size):
	self.noise = noise
	self.x = x
	self.z = z
	self.chunk_size = chunk_size

func _ready():
	generate_chunk()

func generate_chunk():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size,chunk_size)
	plane_mesh.subdivide_depth = chunk_size * 0.5
	plane_mesh.subdivide_width = chunk_size * 0.5
	
	#give a material
	plane_mesh.material = preload("res://assets/materials/terrain.material")
	
	var surface_tool = SurfaceTool.new()
	var data_tool = MeshDataTool.new()
	surface_tool.create_from(plane_mesh,0)
	var array_plane = surface_tool.commit()
	var error = data_tool.create_from_surface(array_plane,0)
	
	var water_exists = false
	
	for i in range(data_tool.get_vertex_count()):
		var vertex = data_tool.get_vertex(i)
		vertex.y = noise.get_noise_3d(vertex.x + x,vertex.y,vertex.z + z) * 80
		
		# check for water placement
		if vertex.y <= 0.2:
			water_exists = true
		data_tool.set_vertex(i,vertex)
	
	array_plane.clear_surfaces()
	
	data_tool.commit_to_surface(array_plane)
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(array_plane,0)
	surface_tool.generate_normals()
	
	#instansiate terrain mesh
	var terrain_mesh = MeshInstance3D.new()
	terrain_mesh.mesh = surface_tool.commit()
	terrain_mesh.create_trimesh_collision()
	terrain_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(terrain_mesh)
	
	# create water for level under 0.2 (inclusive)
	if water_exists:
		# water mesh
		var water_mesh_instance = preload("res://scenes/water.tscn").instantiate()
		water_mesh_instance.mesh.size = Vector2(chunk_size,chunk_size);
		add_child(water_mesh_instance)
		

