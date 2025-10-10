scr_getinput()
if noclip
{
	with (obj_player1)
	{
		hsp = (key_left + key_right) * 6
		vsp = -(key_up - key_down) * 6
		visible = true
		
		x += hsp
		y += vsp
		
		if key_jump
		{
			other.noclip = false
			print("[SM64] Noclip disabled")
			sm64_mario_set_position(global.mario, x * MARIO_SCALE, -(bbox_bottom * MARIO_SCALE), TRIANGLE_WIDTH / 2)
		}
	}
	exit;
}

var dir = 0
var spd = 0
var move = (key_left + key_right)
if (move != 0)
{
	dir = (-pi * move) * 0.5
	spd = 1
}

sm64_mario_set_input(global.mario,
	key_jump2,
	key_attack,
	key_down,
	0,
	0,
	cos(dir) * spd,
	sin(dir) * spd)

if (frameskip mod 2)
	sm64_mario_tick(global.mario)
sm64_mario_set_posZ(global.mario, TRIANGLE_WIDTH / 2)
draw_light_define_point(0, sm64_mario_get_posX(global.mario) - 192, -sm64_mario_get_posY(global.mario) - 192, sm64_mario_get_posZ(global.mario) - 4096, 16384, c_white)

x = sm64_mario_get_posX(global.mario) / MARIO_SCALE
y = -sm64_mario_get_posY(global.mario) / MARIO_SCALE
centerY = y - ((bbox_bottom - bbox_top) / 2)
facingDirection = sign(sm64_mario_get_faceangle(global.mario))
frameskip++

var destroyDestructibles = false
var marioFlags = sm64_mario_get_flags(global.mario)
if ((marioFlags & SM64_MARIO_PUNCHING) == SM64_MARIO_PUNCHING)
	destroyDestructibles = true
if ((marioFlags & SM64_ACT_FLAG_SHORT_HITBOX) == SM64_ACT_FLAG_SHORT_HITBOX)
	print("has short hit box")

var marioAction = sm64_mario_get_action(global.mario)
if (marioAction == SM64_ACT_DIVE || marioAction == SM64_ACT_DIVE_SLIDE)
	destroyDestructibles = true

//if (marioAction == SM64_ACT_CRAWLING || marioAction == SM64_ACT_CROUCHING)
//{
//	print("crouching")
//	sm64_mario_set_state(global.mario, marioFlags | SM64_ACT_FLAG_SHORT_HITBOX)
//}
//print(marioFlags)

if (marioAction == SM64_ACT_GROUNDPOUND)
{
	with (instance_place(x, y + (-sm64_mario_get_velY(global.mario) / MARIO_SCALE), obj_destructibles))
		instance_destroy()
	with (instance_place(x, y + (-sm64_mario_get_velY(global.mario) / MARIO_SCALE), obj_metalblock))
		instance_destroy()
	with (instance_place(x, y + (-sm64_mario_get_velY(global.mario) / MARIO_SCALE), obj_baddie))
		instance_destroy()
}
if ((marioAction == SM64_ACT_JUMP || marioAction == SM64_ACT_DOUBLE_JUMP || marioAction == SM64_ACT_TRIPLE_JUMP || marioAction == SM64_ACT_JUMP_KICK) && (-sm64_mario_get_velY(global.mario) / MARIO_SCALE) > 0)
{
	with (instance_place(x, y + (-sm64_mario_get_velY(global.mario) / MARIO_SCALE), obj_baddie))
	{
		with (other)
			sm64_mario_set_velocity(global.mario, sm64_mario_get_velX(global.mario), 48, sm64_mario_get_velZ(global.mario))
		
		instance_destroy()
	}
}
if destroyDestructibles
{
	with (instance_place(x + (facingDirection * 48), centerY, obj_destructibles))
		instance_destroy()
	with (instance_place(x + (facingDirection * 48), centerY, obj_metalblock))
		instance_destroy()
	with (instance_place(x + (facingDirection * 48), centerY, obj_baddie))
		instance_destroy()
}

var totalSolids = instance_number(obj_solid) + instance_number(obj_platform) + instance_number(obj_slope)
if (totalSolids < global.mariosolids)
{
	print("Mario solid amount has decreased!")
	mario_reload_surfaces()
}

with (obj_player1)
{
	x = other.x
	y = other.y - (bbox_bottom - bbox_top) - 4
	hsp = 0
	vsp = 0
	state = states.mario
	sprite_index = spr_idle
	visible = false
}