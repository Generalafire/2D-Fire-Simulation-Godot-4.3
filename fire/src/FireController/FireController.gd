extends Node2D
class_name FireController

@onready var tilemap = $TileMapLayer
@onready var fire = preload("res://Fire/fire.tscn")

@export var frames_per_tick = 4 #You can use a timer to simulate ticks as well
@export var starting_fire_value = 0.1 #How much fire your starting fire starts with
@export var maximum_fire_per_cell = 1 #How much "fire" you want.  Fire is increased by delta, higher the fire, the faster the fire spreads
@export var burned_cell = Vector2(1,1) #If you only have one burnt tile in your set, use this where the coords are the atlas_coords

var tiles = {
	#tile_coordinates = {
		#fire: float #starts at 0, goes to maximum_fire.  
		#fire_sprite: Node #When on fire, store the instantiated node here
		#burn_time: int #from 0 to however long you want it to burn in ticks 
		#heat: float #starts at 0, current heat, calculated from surrounding fire values and multiplied by conduction heat = fire*conduction
		#maximum_heat: float #How much heat it can take before being on fire, or breaking
		#conduction: float #from 0 to whatever.  More conduction equals more heat transfer, use this in conjunction with maximum_heat to simulate objects
		#is_flammable: bool #if it can catch on fire or not, true = flammable
		#is_destructible: bool #if it breaks when either maximum_heat is reached, or if it burn_time(if false, its replaced by burned_cell) reaches 0, true = destructible
		#},
}


var tiles_on_fire: Array = []
var tiles_destructible: Array = []
var tiles_burnt_out: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_tiles()
	call_deferred("setup_fire")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.get_frames_drawn() % frames_per_tick == 0:
		var tiles_on_fire_deletion_queue = []
		for tile_coords in tiles_on_fire:
			var tile_to_be_removed = decrement_burn_time(tile_coords)
			if tile_to_be_removed != Vector2i(1e6, 1e6): #An invalid return value. If you have 1e6 tiles and your computer is not frozen or busted, then it must be quantum or super.
				tiles_on_fire_deletion_queue.append(tile_to_be_removed)
			increment_fire(tile_coords, delta)
			transfer_heat(tile_coords, delta)

		for i in tiles_on_fire_deletion_queue:
			if tiles_on_fire.has(i):
				tiles_on_fire.erase(i)
		tiles_on_fire_deletion_queue.clear()

		

func decrement_burn_time(tile_coordinates: Vector2i) -> Vector2i:
	#Decrease burn time and replace when burned out or delete if is_destructible
	if tiles[tile_coordinates]["burn_time"] > 0:
		tiles[tile_coordinates]["burn_time"] -= 1
		return Vector2(1e6, 1e6) #If you have 1e6 tiles and your computer is not frozen or busted, then it must be quantum or super.
	else:
		tiles[tile_coordinates]["fire_sprite"].queue_free()
		if tiles[tile_coordinates]["is_destructible"]:
			tilemap.set_cell(tile_coordinates, -1)
			tiles_burnt_out.append(tile_coordinates)
			return tile_coordinates
		else:
			tilemap.set_cell(tile_coordinates, 0, burned_cell)
			tiles_burnt_out.append(tile_coordinates)
			return tile_coordinates

func increment_fire(tile_coordinates:Vector2i, delta:float) -> void:
	#Increase fire by delta, so the fire is slow growing.  Adjust by whatever you want
	if tiles[tile_coordinates]["fire"] < maximum_fire_per_cell:
		tiles[tile_coordinates]["fire"] += delta

func transfer_heat(tile_coordinates:Vector2i, delta:float) -> void:
	#Transfer heat to surrounding tiles and set on fire if threshold reached
	var surrounding_tiles = tilemap.get_surrounding_cells(tile_coordinates)
	for i in surrounding_tiles:
		#If the tile is a valid material, and not on fire, or burnt out, transfer heat to it
		if tiles.has(i) and !tiles_on_fire.has(i) and !tiles_burnt_out.has(i):
			tiles[i]["heat"] += tiles[tile_coordinates]["fire"] * tiles[tile_coordinates]["conduction"]
			
			#If block is destructible and not on fire, destroy the block.  ie something like glass that may melt/shatter in the heat
			if (tiles[i]["heat"] >= tiles[i]["maximum_heat"]) and tiles[i]["is_destructible"] and !tiles[i]["is_flammable"] and !tiles_on_fire.has(i):
				tilemap.set_cell(i, -1)
			
			#Sets on fire and spawns fire sprite
			if (tiles[i]["heat"] >= tiles[i]["maximum_heat"]) and tiles[i]["is_flammable"]:
				tiles[i]["fire"] += delta
				tiles_on_fire.append(i)
						
				var new_fire = fire.instantiate()
				tiles[i]["fire_sprite"] = new_fire
				new_fire.global_position = tilemap.map_to_local(i)
				call_deferred("add_child", new_fire)

func setup_fire() -> void:
	var starting_fires = get_tree().get_nodes_in_group("Fire")
	for i in starting_fires:
		var coords = tilemap.local_to_map(i.global_position)
		if tiles.has(coords):
			tiles[coords]["heat"] = tiles[coords]["maximum_heat"]
			tiles[coords]["fire"] = starting_fire_value
			tiles[coords]["fire_sprite"] = i
			if !tiles_on_fire.has(coords):
				tiles_on_fire.append(coords)

func setup_tiles() -> void:
	for x in tilemap.get_used_rect().size.x:
		for y in tilemap.get_used_rect().size.y:
			var coords = Vector2i(x + tilemap.get_used_rect().position.x,
			y + tilemap.get_used_rect().position.y)
			var tile_data = tilemap.get_cell_tile_data(coords)
			if tile_data == null:
				continue
			match tile_data.get_custom_data("Material"):
				"Wood": #This is your material name
					tiles[coords] = {
						fire = 0.0,
						fire_sprite = null,
						burn_time = 720.0,
						heat = 0.0,
						maximum_heat = 250.0,
						conduction = 0.5,
						is_flammable = true,
						is_destructible = false,
						}
				"Wood(Light)":
					tiles[coords] = {
						fire = 0.0,
						fire_sprite = null,
						burn_time = 300.0,
						heat = 0.0,
						maximum_heat = 180.0,
						conduction = 1.0,
						is_flammable = true,
						is_destructible = true,
						}
				"Burned":
					tiles[coords] = {
						fire = 0.0,
						fire_sprite = null,
						burn_time = 360.0,
						heat = 0.0,
						maximum_heat = 360.0,
						conduction = 0.5,
						is_flammable = false,
						is_destructible = false,
						}
				"Glass":
					tiles[coords] = {
						fire = 0.0,
						fire_sprite = null,
						burn_time = 0.0,
						heat = 0.0,
						maximum_heat = 360.0,
						conduction = 3.0,
						is_flammable = false,
						is_destructible = true,
						}
				#"Water":
					#tiles[coords] = {
						#fire = 0.0,
						#fire_sprite = null,
						#burn_time = 360.0,
						#heat = 0.0,
						#maximum_heat = 360.0,
						#conduction = 0.5,
						#is_flammable = false,
						#is_destructible = false,
						#}
				"Destructible":
					tiles[coords] = {
						fire = 0.0,
						fire_sprite = null,
						burn_time = 360.0,
						heat = 0.0,
						maximum_heat = 360.0,
						conduction = 3.0,
						is_flammable = true,
						is_destructible = true,
						}
				"Ground":
					tiles[coords] = {
						fire = 0.0,
						fire_sprite = null,
						burn_time = 360,
						heat = 0.0,
						maximum_heat = 360.0,
						conduction = 0.1,
						is_flammable = true,
						is_destructible = false,
						}
				"Steel":
					tiles[coords] = {
						fire = 0.0,
						fire_sprite = null,
						burn_time = 0.0,
						heat = 0.0,
						maximum_heat = 36000.0,
						conduction = 5.0,
						is_flammable = false,
						is_destructible = true,
						}
