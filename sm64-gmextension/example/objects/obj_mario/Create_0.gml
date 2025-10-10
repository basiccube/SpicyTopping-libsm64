sm64_load_static_surfaces()

global.mario = sm64_mario_create(x * MARIO_SCALE, -(y * MARIO_SCALE), TRIANGLE_WIDTH / 2)
if (global.mario < 0)
{
	print("Failed to spawn Mario")
	instance_destroy()
	exit;
}

draw_set_lighting(true)
draw_light_enable(0, true)

vertex_format_begin()
vertex_format_add_position_3d()
vertex_format_add_normal()
vertex_format_add_texcoord()
vertex_format_add_color()
marioTexturedFormat = vertex_format_end()
marioTexturedBuffer = vertex_create_buffer()

surface = -4
depth = -7
facingDirection = 1
centerY = y

frameskip = 0
noclip = false