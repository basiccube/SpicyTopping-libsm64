var dir = 0
var spd = 0

var move_up = keyboard_check(ord("W"))
var move_down = keyboard_check(ord("S"))
var move_left = keyboard_check(ord("A"))
var move_right = keyboard_check(ord("D"))

if (move_up && move_right)
{
    dir = -pi * 0.25
    spd = 1
}
else if (move_up && move_left)
{
    dir = -pi * 0.75
    spd = 1
}
else if (move_down && move_right)
{
    dir = pi * 0.25
    spd = 1
}
else if (move_down && move_left)
{
    dir = pi * 0.75
    spd = 1
}
else if move_up
{
    dir = -pi * 0.5
    spd = 1
}
else if move_down
{
    dir = pi * 0.5
    spd = 1
}
else if move_left
{
    dir = pi
    spd = 1
}
else if move_right
{
    dir = 0
    spd = 1
}

sm64_mario_set_input(global.mario,
	keyboard_check(ord("X")),
	keyboard_check(ord("C")),
	keyboard_check(ord("Z")),
	camX,
	camZ,
	cos(dir) * spd,
	sin(dir) * spd)

if (frameskip mod 2)
	sm64_mario_tick(global.mario)

if keyboard_check(ord("Q"))
    camAngle -= 0.04
if keyboard_check(ord("E"))
    camAngle += 0.04
if keyboard_check(ord("R"))
	camHeight += 20
if keyboard_check(ord("T"))
	camHeight -= 20

camX = sm64_mario_get_posX(global.mario) + 1000 * cos(camAngle)
camY = sm64_mario_get_posY(global.mario) + 250 + camHeight
camZ = sm64_mario_get_posZ(global.mario) + 1000 * sin(camAngle)
draw_light_define_point(0, camX, camZ, camY - camHeight, 500000, c_white)

frameskip++