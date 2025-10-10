#macro MARIO_SCALE 2.5
#macro TRIANGLE_WIDTH 16

///@param x1
///@param y1
///@param z1
///@param x2
///@param y2
///@param z2
///@param x3
///@param y3
///@param z3
function Triangle(_x1, _y1, _z1, _x2, _y2, _z2, _x3, _y3, _z3) constructor
{
	x1 = _x1
	y1 = _y1
	z1 = _z1
	
	x2 = _x2
	y2 = _y2
	z2 = _z2
	
	x3 = _x3
	y3 = _y3
	z3 = _z3
}

function mario_init()
{
	var marioInit = sm64_init()
	if (marioInit != 1)
	{
		print("[SM64] sm64.us.z64 not found, libsm64 will not be available during this session.")
		return false;
	}
	
	global.mariotexture = sprite_add("sm64_texture.png", 1, false, false, 0, 0)
	global.mariosolids = 0
	
	vertex_format_begin()
	vertex_format_add_position_3d()
	vertex_format_add_texcoord()
	vertex_format_add_color()
	global.triangleformat = vertex_format_end()
	global.trianglebuffer = vertex_create_buffer()
	
	return true;
}
global.marioinit = mario_init()

///@param triangleData
function mario_add_surface(_triangleData)
{
	sm64_add_static_surface(SM64_SURFACE_DEFAULT, 0, SM64_TERRAIN_STONE, _triangleData.x1, _triangleData.y1, _triangleData.z1, _triangleData.x2, _triangleData.y2, _triangleData.z2, _triangleData.x3, _triangleData.y3, _triangleData.z3)
}

function mario_reload_surfaces()
{
	print("[SM64] Previous solid amount: ", global.mariosolids)
	sm64_reset_surfaces()
	global.mariosolids = 0
	
	mario_create_bottomfloor()
	with (obj_solid)
		mario_create_solid()
	with (obj_platform)
		mario_create_platform()
	with (obj_slope)
		mario_create_slope()
	
	print("[SM64] New solid amount: ", global.mariosolids)
	sm64_load_static_surfaces()
}

function mario_create_solid()
{
	if !global.marioinit
		exit;
	
	// floor
	floorTriangle = new Triangle(x * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
							(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), 0,
							x * MARIO_SCALE, -(y * MARIO_SCALE), 0)
	mario_add_surface(floorTriangle)

	floorTriangle2 = new Triangle(x * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
							(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
							(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), 0)
	mario_add_surface(floorTriangle2)

	// ceiling
	ceilingTriangle = new Triangle(x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), 0,
							(x + sprite_width) * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), 0,
							x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), TRIANGLE_WIDTH)
	mario_add_surface(ceilingTriangle)

	ceilingTriangle2 = new Triangle((x + sprite_width) * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), 0,
							(x + sprite_width) * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), TRIANGLE_WIDTH,
							x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), TRIANGLE_WIDTH)
	mario_add_surface(ceilingTriangle2)

	// left side
	leftTriangle = new Triangle(x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), 0,
							x * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
							x * MARIO_SCALE, -(y * MARIO_SCALE), 0)
	mario_add_surface(leftTriangle)

	leftTriangle2 = new Triangle(x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), 0,
							x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), TRIANGLE_WIDTH,
							x * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH)
	mario_add_surface(leftTriangle2)

	// right side
	rightTriangle = new Triangle((x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), 0,
							(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
							(x + sprite_width) * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), 0)
	mario_add_surface(rightTriangle)

	rightTriangle2 = new Triangle((x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
							(x + sprite_width) * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), TRIANGLE_WIDTH,
							(x + sprite_width) * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), 0)
	mario_add_surface(rightTriangle2)
	
	global.mariosolids++
}

function mario_create_platform()
{
	if !global.marioinit
		exit;
	
	floorTriangle = new Triangle(x * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
							(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), 0,
							x * MARIO_SCALE, -(y * MARIO_SCALE), 0)
	mario_add_surface(floorTriangle)

	floorTriangle2 = new Triangle(x * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
							(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
							(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), 0)
	mario_add_surface(floorTriangle2)
	
	global.mariosolids++
}

function mario_create_slope()
{
	if !global.marioinit
		exit;
	
	if (image_xscale > 0)
	{
		floorTriangle = new Triangle(x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), TRIANGLE_WIDTH,
								(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), 0,
								x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), 0)
		mario_add_surface(floorTriangle)

		floorTriangle2 = new Triangle(x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), TRIANGLE_WIDTH,
								(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
								(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), 0)
		mario_add_surface(floorTriangle2)
	}
	else
	{
		floorTriangle = new Triangle((x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
								x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), 0,
								(x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), 0)
		mario_add_surface(floorTriangle)

		floorTriangle2 = new Triangle((x + sprite_width) * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH,
								x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), TRIANGLE_WIDTH,
								x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), 0)
		mario_add_surface(floorTriangle2)
	}
	
	global.mariosolids++
}

function mario_create_bottomfloor()
{
	if !global.marioinit
		exit;
	
	floorTriangle = new Triangle(0, -((room_height * 2) * MARIO_SCALE), TRIANGLE_WIDTH,
							room_width * MARIO_SCALE, -((room_height * 2) * MARIO_SCALE), 0,
							0, -((room_height * 2) * MARIO_SCALE), 0)
	mario_add_surface(floorTriangle)

	floorTriangle2 = new Triangle(0, -((room_height * 2) * MARIO_SCALE), TRIANGLE_WIDTH,
							room_width * MARIO_SCALE, -((room_height * 2) * MARIO_SCALE), TRIANGLE_WIDTH,
							room_width * MARIO_SCALE, -((room_height * 2) * MARIO_SCALE), 0)
	mario_add_surface(floorTriangle2)
}

function draw_3d_start()
{
	gpu_set_ztestenable(true)
}

function draw_3d_end()
{
	gpu_set_cullmode(cull_noculling)
	gpu_set_ztestenable(false)
}

///@param triangleData
///@param color
///@param cullmode
function draw_3d_triangle(_triangleData, _color, _cullmode)
{
	var whiteTexture = sprite_get_texture(spr_3dtriangle, 0)
	
	gpu_set_cullmode(_cullmode)
	draw_primitive_begin_texture(pr_trianglelist, whiteTexture)
	vertex_begin(global.trianglebuffer, global.triangleformat)
	
	vertex_position_3d(global.trianglebuffer, _triangleData.x1, _triangleData.z1, -_triangleData.y1)
	vertex_texcoord(global.trianglebuffer, 0, 0)
	vertex_color(global.trianglebuffer, _color, 1)
	
	vertex_position_3d(global.trianglebuffer, _triangleData.x2, _triangleData.z2, -_triangleData.y2)
	vertex_texcoord(global.trianglebuffer, 1, 0)
	vertex_color(global.trianglebuffer, _color, 1)
	
	vertex_position_3d(global.trianglebuffer, _triangleData.x3, _triangleData.z3, -_triangleData.y3)
	vertex_texcoord(global.trianglebuffer, 0, 1)
	vertex_color(global.trianglebuffer, _color, 1)
	
	vertex_end(global.trianglebuffer)
	vertex_submit(global.trianglebuffer, pr_trianglelist, whiteTexture)
	draw_primitive_end()
}