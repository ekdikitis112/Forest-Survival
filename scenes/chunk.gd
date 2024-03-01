extends MeshInstance3D
class_name TerrainChunk

@export_range(20,400,1) var Terrain_Size := 200
@export_range(1,100,1) var resolution := 20
@export var Terrain_Max_Height = 5
var chunk_lods = [5,20,50,80]
var position_coord = Vector2()
const CENTER_OFFSET = 0.5

var set_collision = false

func generate_terrain(noise:FastNoiseLite,coords:Vector2,size:float,initially_visible:bool):
	Terrain_Size = size
	position_coord = coords * size
	var a_mesh: ArrayMesh
	var surftool = SurfaceTool.new()
	surftool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in resolution+1:
		for x in resolution+1:
			# get percentage of current point
			var percent = Vector2(x,z)/resolution
			# create the point on the mesh
			# offset it by -0.5 to make origin centered
			var pointOnMesh = Vector3((percent.x-CENTER_OFFSET),0,(percent.y-CENTER_OFFSET))
			# multiply it by the terrain size to get vertex position
			var vertex = pointOnMesh * Terrain_Size
			# set the height of the vertex by noise
			# pass position to make noise continueous
			vertex.y = noise.get_noise_2d(vertex.x+position.x,vertex.z+position.z) * Terrain_Max_Height
			# create UVs using percentage
			var uv = Vector2()
			uv.x = percent.x
			uv.y = percent.y
			# set UV and add vertex
			surftool.set_uv(uv)
			surftool.add_vertex(vertex)
	var vert = 0
	for z in resolution:
		for x in resolution:
			surftool.add_index(vert+0)
			surftool.add_index(vert+1)
			surftool.add_index(vert+resolution+1)
			surftool.add_index(vert+resolution+1)
			surftool.add_index(vert+1)
			surftool.add_index(vert+resolution+2)
			vert += 1
		vert += 1
	# generate Normal Map
	surftool.generate_normals()
	# create Array Mesh from Data
	a_mesh = surftool.commit()
	# assign Array Mesh to mesh
	mesh = a_mesh
	
	if set_collision == true:
		create_collision()
	
	# set to invisible on start
	setChunkVisible(initially_visible)

func update_lod(view_pos:Vector2):
	var viewer_distance = position_coord.distance_to(view_pos)
	var update_terrain = false
	var new_lod = 0
	if viewer_distance > 1000:
		new_lod = chunk_lods[0]
	if viewer_distance <= 1000:
		new_lod = chunk_lods[1]
	if viewer_distance < 900:
		new_lod = chunk_lods[2]
	if viewer_distance < 500 :
		new_lod = chunk_lods[3]
		set_collision = true
	
	if resolution != new_lod:
		resolution = new_lod
		update_terrain = true
	return update_terrain

func update_chunk(view_pos:Vector2,max_view_dis):
	var viewer_distance = position_coord.distance_to(view_pos)
	var _is_visible = viewer_distance <= max_view_dis
	setChunkVisible(_is_visible)

func setChunkVisible(_is_visible):
	visible = _is_visible

func getChunkVisible():
	return visible

func create_collision():
	if get_child_count() > 0:
		for i in get_children():
			i.free()
	create_trimesh_collision()
