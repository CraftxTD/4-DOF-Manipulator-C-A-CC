-- Modify values here for the arm
local x1 = -2
local y1 = -1
local z1 = 4
local x2 = 465
local y2 = 116
local z2 = 423
local length = 28
local angle = 90
local offset = vector.new(0, 7, -2)
-- if angle == 0 then
-- 	offset = vector.new(-2, 7, 0)
-- elseif angle == 90 then
-- 	offset = vector.new(0, 7, -2)
-- elseif angle == 180 then
-- 	offset = vector.new(2, 7, 0)
-- elseif angle == 270 then
-- 	offset = vector.new(0, 7, 2)
-- end

return {
	-- Coordinates of the first block in the limb 1 bearing.
	-- Must be configured everytime the arm location is changed.
	SHIP_DOCK_OFFSET = vector.new(x1, y1, z1),
	ARM = vector.new(x2 + offset.x, y2 + offset.y, z2 + offset.z),
	-- LODESTONE OFFSET
	-- Sum of both arm lengths
	-- Both arms must have the same radii
	ARM_RADIUS = length,
	-- Max limit that a dock can rotate
	DOCK_LIMIT = { 0, math.pi },
	-- The arm angle relative to the local xz plane.
	-- left: 90, front: 0, back: 180, right: 270
	INITIAL_ARM_ANGLE = math.rad(angle),
	-- Offset of dock relative to the second limb's point.
	-- These coordinates are then converted to the ship dock's
	-- local coordinates.
	DOCK_OFFSET = vector.new(-4.5, 1.5, 0),

	-- Idle limb angles
	LIMB_1 = math.rad(140),
	LIMB_2 = math.rad(-155),
}
