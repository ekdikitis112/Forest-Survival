extends Node3D


const chunk_size = 64

# the amount increases in multiples of 16 at the same time the sub surfaces increase in multiples of 4
const chunk_amount = 16
const chunk_sub_surfaces = 4

var noise
var chunks = {}
var unready_chunks = {}
var thread

func  _ready():
	noise = FastNoiseLite.new()
	noise.set_noise_type(FastNoiseLite.TYPE_SIMPLEX_SMOOTH)
	noise.set_seed(Globals.seed)
	noise.set_fractal_octaves(6)
	noise.set_frequency(0.001)
	
	thread = Thread.new()

func add_chunk(x,z):
	var key = str(x)+","+str(z)
	if chunks.has(key) or unready_chunks.has(key):
		return
	
	if not thread.is_alive():
		#thread.start(self,"load_chunk",[thread,x,z])
		thread.start(load_chunk.bind([thread,x,z]))
		unready_chunks[key] = 1


func load_chunk(arr):
	thread = arr[0]
	var x = arr[1]  * chunk_size 
	var z = arr[2]  * chunk_size 
	#print("pos: X: "+str(x)+" Z: "+str(z))
	var chunk = Chunk.new(noise,x,z,chunk_size)
	
	chunk.transform.origin = Vector3(x,0,z)
	#print("chunk: X: "+str(chunk.x)+" Z: "+str(chunk.z)+"\n")
	call_deferred("load_done",chunk,thread)

func load_done(chunk,thread):
	add_child(chunk)
	var key = str(chunk.x / chunk_size) + "," + str(chunk.z / chunk_size) 
	chunks[key] = chunk
	unready_chunks.erase(key)
	thread.wait_to_finish()

func get_chunk(x,z):
	var key = str(x)+","+str(z)
	if chunks.has(key):
		return chunks.get(key)
	return null

func _process(_delta):
	update_chunks()
	clean_up_chunks()
	reset_chunks()

func update_chunks():
	var player_translation = $player.transform.origin
	var p_x = int(player_translation.x) / chunk_size
	var p_z = int(player_translation.z) / chunk_size
	add_chunk(p_x,p_z)
	for x in range(p_x-(chunk_amount/chunk_sub_surfaces),p_x+(chunk_amount/chunk_sub_surfaces)):
		for z in range(p_z-(chunk_amount/chunk_sub_surfaces),p_z+(chunk_amount/chunk_sub_surfaces)):
			#print("player position: X: "+str(p_x)+" Z: "+str(p_z))
			#print("chunk: X: "+str(x)+" Z: "+str(z)+"\n")
			add_chunk(x,z)
			var chunk = get_chunk(x,z)
			if chunk != null:
				chunk.should_remove = false
	

func clean_up_chunks():
	for key in chunks:
		var chunk = chunks[key]
		if chunk.should_remove:
			chunk.queue_free()
			chunks.erase(key)

func reset_chunks():
	for key in chunks:
		chunks[key].should_remove = true
