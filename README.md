![fire1](https://github.com/user-attachments/assets/ec106442-08e4-4122-be81-ec25cf216406)

![fire2](https://github.com/user-attachments/assets/0ab51f62-f872-4582-9706-34811763eeac)

To Use:
	SceneOrder:
		World:
			FireController:
				TileMapLayer
			Fire
			
	1. Use the FireController scene with a tilemap as its child. (Currently only supports one layer)

	2. In TileMapLayer, add a custom layer called Material with a type of String.  Paint your tiles with whatever materials you want.  Make sure you have a "Burned" material for burnt out tiles.  If you don't want tiles to interact with fire, just don't add a material to them.
	3. In FireController, set the following values:
		frames_per_tick = 4 #You can use a timer to simulate ticks as well, higher the value, the faster slower the simulation
		starting_fire_value = 0.1 #How much fire your starting fire starts with
		maximum_fire_per_cell = 1 #How much "fire" you want.  Fire is increased by delta, higher the maximum fire, the faster the fire spreads by a rate of heat = fire*conduction
		burned_cell = Vector2(1,1) #If you only have one burnt tile in your set, use this where the coords are the atlas_coords
	4. In the FireController script under setup_tiles(), add your materials to the match case with the following format.  You will also find a description of the properties at the top of the script.
			"Wood(Light)": #This is your material name
				tiles[coords] = { 
					fire = 0.0, #Do not change unless you want it to be partially on fire
					fire_sprite = null, #Do not change, this is where the scene can be accessed
					burn_time = 300.0,
					heat = 0.0, #Do not change unless you want it to be closer to being on fire
					maximum_heat = 180.0,
					conduction = 1.0,
					is_flammable = true,
					is_destructible = true,
					}
	5. Add the Fire scene to whatever valid tile you want it to start on.  Please note, graphical glitches will occur if it overlaps other tiles
	
