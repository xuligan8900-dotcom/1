--!strict
local Numeric={}
function Numeric.near(a,b,tolerance)
	-- Roblox Vector3/Part.Size use float32, whereas Luau literals use doubles.
	return math.abs(a-b)<=(tolerance or 0.001)
end
return table.freeze(Numeric)
