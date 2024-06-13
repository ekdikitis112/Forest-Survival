class_name TerrainChunkMT extends MeshInstance3D

# Exports
@export_range(20, 400, 1) var Terrain_Size := 200
@export_range(1, 100, 1) var resolution := 20
@export var Terrain_Max_Height = 40
@export var chunk_lods : Array[int] = [2, 4, 8, 15, 20, 50]
@export var LOD_distances : Array[int] = [2000, 1500, 1050, 900, 790, 550]
@export var noise_scale : float = 0.1
@export var tree_density : float = 0.5
var tree_scene = load("res://scenes/full_tree.tscn")

# Member variables
var position_coord = Vector2()
var grid_coord = Vector2()
var min_height = 0
var max_height = 0

const CENTER_OFFSET = 0.5
var set_collision = false

@export var noise: FastNoiseLite = FastNoiseLite.new()

func set_forest_noise_parameters():
	noise.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	noise.set_frequency(0.01)
	noise.set_fractal_type(FastNoiseLite.FRACTAL_FBM)
	noise.set_fractal_octaves(6)
	noise.set_fractal_gain(0.5)
	noise.set_fractal_lacunarity(2.0)

func set_plains_noise_parameters():
	noise.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	noise.set_frequency(0.005)
	noise.set_fractal_type(FastNoiseLite.FRACTAL_FBM)
	noise.set_fractal_octaves(4)
	noise.set_fractal_gain(0.6)
	noise.set_fractal_lacunarity(1.5)

func generate_terrain(coords: Vector2, size: float, initially_visible: bool, thread=null):
	Terrain_Size = size
	grid_coord = coords
	position_coord = coords * size
	
	noise.seed = Globals.game_seed.seed
	
	# decide biome
	set_forest_noise_parameters()
	
	var a_mesh : ArrayMesh
	var surftool = SurfaceTool.new()
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var percent = Vector2(x, z) / resolution
			var pointOnMesh = Vector3((percent.x - CENTER_OFFSET), 0, (percent.y - CENTER_OFFSET))
			var vertex = pointOnMesh * Terrain_Size
			vertex.y = set_noise_position(vertex, noise)
			
			if vertex.y <= min_height:
				min_height = vertex.y
			if vertex.y >= max_height:
				max_height = vertex.y
			
			var uv = percent
			surftool.set_uv(uv)
			surftool.add_vertex(vertex)
	
	var vert = 0
	for z in range(resolution):
		for x in range(resolution):
			surftool.add_index(vert + 0)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + resolution + 1)
			surftool.add_index(vert + resolution + 1)
			surftool.add_index(vert + 1)
			surftool.add_index(vert + resolution + 2)
			vert += 1
		vert += 1
	
	surftool.generate_normals()
	a_mesh = surftool.commit()
	mesh = a_mesh
	
	var mat: Material = material_override
	mat.set_shader_parameter("min_grasss_height", min_height)
	mat.set_shader_parameter("max_rock_height", max_height)
	setChunkVisible(initially_visible)
	
	var water = MeshInstance3D.new()
	water.mesh = PlaneMesh.new()
	water.mesh.material = load("res://assets/materials/water.tres")
	water.position = Vector3(position_coord.x, -2, position_coord.y)
	water.mesh.size = Vector2(Terrain_Size * 2, Terrain_Size * 2)
	add_child(water)
	
	place_trees_with_noise(noise)
	
	call_deferred("thread_complete", thread)

func place_trees_with_noise(noise: FastNoiseLite):
	for vertex in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		var noise_value = abs(noise.get_noise_2d(vertex.x * noise_scale, vertex.z * noise_scale))*4
		print(noise_value)
		
		if noise_value > tree_density:
			if tree_scene:
				var tree_instance = tree_scene.instantiate()
				if tree_instance:
					tree_instance.global_transform.origin = vertex
					add_child(tree_instance)
				else:
					print("Failed to instance full_tree.tscn")
			else:
				print("Failed to load res://scenes/full_tree.tscn")

func set_noise_position(vertex: Vector3, noise: FastNoiseLite):
	return noise.get_noise_2d(position_coord.x + vertex.x, position_coord.y + vertex.z) * Terrain_Max_Height

func thread_complete(thread):
	if thread:
		thread.wait_to_finish()
	if set_collision:
		generate_collision()

func generate_collision():
	if get_child_count() > 0:
		get_child(0).queue_free()
	create_trimesh_collision()

func update_chunk(view_pos: Vector2, max_view_dis):
	var viewer_distance = position_coord.distance_to(view_pos)
	setChunkVisible(viewer_distance <= max_view_dis)

func should_remove(view_pos: Vector2, max_view_dis):
	return position_coord.distance_to(view_pos) > max_view_dis

func update_lod(view_pos: Vector2):
	var viewer_distance = position_coord.distance_to(view_pos)
	var new_lod = chunk_lods[0]
	
	for i in range(chunk_lods.size()):
		if viewer_distance < LOD_distances[i]:
			new_lod = chunk_lods[i]
	
	set_collision = new_lod >= chunk_lods[chunk_lods.size() - 1]
	
	if resolution != new_lod:
		resolution = new_lod
		return true
	
	return false

func free_chunk():
	free()

func setChunkVisible(_is_visible):
	visible = _is_visible

func getChunkVisible():
	return visible
