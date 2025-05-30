extends InteractableObject

# --- Exported Properties ---
@export var anim:AnimatedSprite2D 
var choice
var anim_str: String
var door2: InteractableObject
# --- Built-in Callbacks ---
func _ready() -> void:
	super()
	gui_focus.closed.connect(end_interact)
	await get_tree().process_frame
	if get_terrain_at_tile(0, -1):
		anim_str = "open-up"
		door2 = get_object_in_coords(0, 1)
	elif get_terrain_at_tile(0, 1): 
		anim_str = "open-down"
		door2 = get_object_in_coords(0, -1)
	elif get_terrain_at_tile(-1): 
		anim_str = "open-left"
		door2 = get_object_in_coords(1)
	elif get_terrain_at_tile(1): 
		anim_str = "open-right"
		door2 = get_object_in_coords(-1)
	anim.animation = anim_str
	

func interact() -> void:
	super()

func end_interact() -> void:
	super()
	if WorldPathfinder.map.local_to_map(WorldTurnBase.players[0].position) == map_position:
		gui_focus.close()
		return
	choice = gui_focus.close()
	
	var p = WorldPathfinder.calculate_free_path(WorldTurnBase.players[0].position, position)
	WorldTurnBase.players[0].all_actions.append(PlayerNode.Move.new(p[p.size()-2], WorldTurnBase.players[0]))
	WorldTurnBase.players[0].all_actions.append(PlayerNode.Press.new(done))
	if choice == 1:
		WorldPathfinder.pathfinder.set_point_solid(map_position, false)
		WorldTurnBase.players[0].all_actions.append(PlayerNode.Move.new(Vector2((-1*(p[p.size()-2].x-map_position.x))+map_position.x, p[p.size()-2].y), WorldTurnBase.players[0]))
	elif choice == 0:
		WorldPathfinder.pathfinder.set_point_solid(map_position, true)
func done(off: bool = true):
	if door2 and off:
		door2.choice = choice
		door2.done(false)
	match choice:
		-1:
			return
		0:
			if anim.frame != 0:
				anim.play_backwards(anim_str)
				await anim.animation_finished
		1:
			if anim.frame == 0:
				anim.play(anim_str)
				await anim.animation_finished
func get_terrain_at_tile(x: int = 0, y: int = 0) -> int:
	var cell := WorldPathfinder.map.get_cell_tile_data(Vector2i(map_position.x+x, map_position.y+y))
	if cell == null:
		return 0
	return cell.terrain

	return 0
func get_object_in_coords(x: int = 0, y: int = 0) -> InteractableObject:
	for i in WorldPathfinder.map.get_parent().get_child(1).get_children():
		if i is InteractableObject:
			if i.map_position == map_position+Vector2i(x,y):
				return i
	return null
