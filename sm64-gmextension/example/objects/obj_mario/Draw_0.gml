if (global.mario < 0)
	exit;

if !surface_exists(surface)
	surface = surface_create(room_width, room_height)

var drawMario = true
if !(frameskip mod 2)
	drawMario = false

if drawMario
{
	//var oldCamView = camera_get_view_mat(view_camera[0])
	//var oldCamProjection = camera_get_proj_mat(view_camera[0])
	//var oldViewMatrix = matrix_get(matrix_view)
	//var oldProjectionMatrix = matrix_get(matrix_projection)
	//var oldWorldMatrix = matrix_get(matrix_world)
	
	//var viewMatrix = matrix_build_lookat((room_width * MARIO_SCALE) / 2, room_width * MARIO_SCALE, (room_height * MARIO_SCALE) / 2, (room_width * MARIO_SCALE) / 2, 0, (room_height * MARIO_SCALE) / 2, 0, 0, 1)
	//var viewMatrix = matrix_build_lookat((room_width * MARIO_SCALE) / 2, 1000 + room_width * MARIO_SCALE, -2000, (room_width * MARIO_SCALE) / 2, 540 * MARIO_SCALE, 0, 0, 0, 1)
	//var projectionMatrix = matrix_build_projection_perspective_fov(45, 16 / 9, 100, 20000)
	//camera_set_view_mat(view_camera[0], viewMatrix)
	//camera_set_proj_mat(view_camera[0], projectionMatrix)
	
	surface_set_target(surface)
	draw_clear_alpha(c_black, 0)
	draw_set_color(c_white)
	
	gpu_set_cullmode(cull_counterclockwise)
	gpu_set_ztestenable(true)

	var whiteTexture = sprite_get_texture(spr_3dtriangle, 0)
	draw_primitive_begin_texture(pr_trianglelist, whiteTexture)

	var texturedInds = []
	var texturedCount = 0
	for (var i = 0; i < sm64_mario_get_triangles_used(global.mario) * 3; i++)
	{
		if (sm64_mario_get_geometry_uvX(global.mario, i * 2) != 1 || sm64_mario_get_geometry_uvY(global.mario, i * 2) != 1)
	    {
	        texturedInds[texturedCount] = i
	        texturedCount++
	    }
	
		vertex_begin(marioTexturedBuffer, marioTexturedFormat)

//		vertex_position_3d(marioTexturedBuffer, sm64_mario_get_geometry_posX(global.mario, i * 3), sm64_mario_get_geometry_posZ(global.mario, i * 3), -sm64_mario_get_geometry_posY(global.mario, i * 3))
		vertex_position_3d(marioTexturedBuffer, sm64_mario_get_geometry_posX(global.mario, i * 3) / MARIO_SCALE, -sm64_mario_get_geometry_posY(global.mario, i * 3) / MARIO_SCALE, sm64_mario_get_geometry_posZ(global.mario, i * 3) / MARIO_SCALE)
		vertex_normal(marioTexturedBuffer, sm64_mario_get_geometry_normalX(global.mario, i * 3), -sm64_mario_get_geometry_normalY(global.mario, i * 3), sm64_mario_get_geometry_normalZ(global.mario, i * 3))
		vertex_texcoord(marioTexturedBuffer, 0, 0)
		vertex_color(marioTexturedBuffer, make_color_rgb(sm64_mario_get_geometry_colorRed(global.mario, i * 3), sm64_mario_get_geometry_colorGreen(global.mario, i * 3), sm64_mario_get_geometry_colorBlue(global.mario, i * 3)), 1)
	
		vertex_end(marioTexturedBuffer)
		vertex_submit(marioTexturedBuffer, pr_trianglelist, whiteTexture)
	}

	draw_primitive_end()

	var marioTexture = sprite_get_texture(global.mariotexture, 0)
	draw_primitive_begin_texture(pr_trianglelist, marioTexture)

	for (var i = 0; i < texturedCount; i++)
	{
		var ind = texturedInds[i]
		vertex_begin(marioTexturedBuffer, marioTexturedFormat)
//		vertex_position_3d(marioTexturedBuffer, sm64_mario_get_geometry_posX(global.mario, ind * 3), sm64_mario_get_geometry_posZ(global.mario, ind * 3), -sm64_mario_get_geometry_posY(global.mario, ind * 3))
		vertex_position_3d(marioTexturedBuffer, sm64_mario_get_geometry_posX(global.mario, ind * 3) / MARIO_SCALE, -sm64_mario_get_geometry_posY(global.mario, ind * 3) / MARIO_SCALE, sm64_mario_get_geometry_posZ(global.mario, ind * 3) / MARIO_SCALE)
		vertex_normal(marioTexturedBuffer, sm64_mario_get_geometry_normalX(global.mario, ind * 3), -sm64_mario_get_geometry_normalY(global.mario, ind * 3), sm64_mario_get_geometry_normalZ(global.mario, ind * 3))
		vertex_texcoord(marioTexturedBuffer, sm64_mario_get_geometry_uvX(global.mario, ind * 2), sm64_mario_get_geometry_uvY(global.mario, ind * 2))
		vertex_color(marioTexturedBuffer, c_white, 1)
	
		vertex_end(marioTexturedBuffer)
		vertex_submit(marioTexturedBuffer, pr_trianglelist, marioTexture)
	}

	draw_primitive_end()
	surface_reset_target()

	gpu_set_cullmode(cull_noculling)
	gpu_set_ztestenable(false)
}

draw_surface_ext(surface, 0, 0, 1, 1, 0, c_white, 1)