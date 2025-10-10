if (object_index != obj_player2 || global.coop)
{
	mario_create_bottomfloor()
	with (obj_solid)
		mario_create_solid()
	with (obj_platform)
		mario_create_platform()
	with (obj_slope)
		mario_create_slope()
	
	var _doorObj = -4
	if (targetDoor == "A")
		_doorObj = obj_doorA
	else if (targetDoor == "B")
		_doorObj = obj_doorB
	else if (targetDoor == "C")
		_doorObj = obj_doorC
	else if (targetDoor == "D")
		_doorObj = obj_doorD
	else if (targetDoor == "E")
		_doorObj = obj_doorE
	else if (targetDoor == "F")
		_doorObj = obj_doorF
	else if (targetDoor == "G")
		_doorObj = obj_doorG
	
	if (_doorObj != -4 && instance_exists(_doorObj) && !dooroverride)
	{
		if hallway
			x = _doorObj.x + (hallwaydirection * 100)
		else if box
			x = _doorObj.x + 32
		else
			x = _doorObj.x + 16
		y = _doorObj.y - 14
	}
	
	with (obj_mario)
	{
		surface_free(surface)
		sm64_mario_set_position(global.mario, other.x * MARIO_SCALE, -(other.bbox_bottom * MARIO_SCALE), TRIANGLE_WIDTH / 2)
		sm64_load_static_surfaces()
	}
}