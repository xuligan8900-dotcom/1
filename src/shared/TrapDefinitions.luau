--!strict
-- Period = safe + warning + active. Motion never uses random state.
local definitions = {
	move = {Motion="slide", Carry=true, Travel=1.8, Speed=0.65},
	lift = {Motion="lift", Carry=true, Travel=2.2, Speed=0.6},
	orbit = {Motion="orbit", Carry=true, Travel=1.4, Speed=0.7},
	rotor = {Motion="spin", Damage=100, Speed=0.7},
	doubleRotor = {Motion="spin", Damage=100, Speed=0.8},
	gear = {Motion="spin", Carry=true, Speed=0.6},
	blade = {Motion="spin", Damage=100, Speed=0.85},
	pendulum = {Motion="swing", Damage=100, Speed=0.85},
	pusher = {Motion="pulse", Travel=6, Push=32, Speed=1},
	press = {Motion="press", Travel=9, Damage=100, Speed=1},
	laser = {Motion="gate", Damage=100, Speed=1},
	fade = {Motion="fade", Carry=true, Speed=1},
	timer = {Motion="fade", Carry=true, Speed=1.15},
	conveyor = {Motion="belt", Carry=true, BeltSpeed=5, Speed=1},
	ring = {Motion="ring", Damage=100, Speed=0.65},
	door = {Motion="door", Travel=8, Speed=1},
}
for _, definition in definitions do
	definition.Size = 1 -- Uniform model scale; regenerate after changing.
	definition.SoundEnabled = true
	definition.DirectionX = if definition.Motion=="slide" or definition.Motion=="pulse" then 1 else 0
	definition.DirectionY = if definition.Motion=="lift" or definition.Motion=="spin" then 1 elseif definition.Motion=="press" then -1 else 0
	definition.DirectionZ = if definition.Motion=="ring" or definition.Motion=="swing" then 1 elseif definition.Motion=="belt" then -1 else 0
	definition.Safe = 3.8
	definition.Warning = 1.1
	definition.Active = 1.5
	definition.Damage = definition.Damage or 0
	definition.Push = definition.Push or 0
	definition.Travel = definition.Travel or 0
	definition.Carry = definition.Carry or false
	table.freeze(definition)
end
return table.freeze(definitions)
