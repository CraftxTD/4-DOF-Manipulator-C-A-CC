-- Modify values here for the arm
local x1 = -2
local y1 = -1
local z1 = 4
local x2 = 465
local y2 = 116
local z2 = 423
local length = 28
-- Arm angle
local angle = 90
-- Dock orientation
local ship = 0
-- 0: Left
-- -90: Back
-- 90: Front
-- 180: Right
-- Ship orientation when assembled
local orientation = 0
local offset = vector.new(0, 9, 0)

return {
	-- Coordinates of the first block in the limb 1 bearing.
	-- Must be configured everytime the arm location is changed.
	SHIP_DOCK_OFFSET = vector.new(x1, y1, z1),
	ARM = vector.new(x2 + offset.x, y2 + offset.y, z2 + offset.z),
	-- LODESTONE OFFSET
	-- Sum of both arm lengths
	-- Both arms must have the same radii
	ARM_RADIUS = length,
	-- The arm angle relative to the local xz plane.
	-- left: 90, front: 0, back: 180, right: 270
	INITIAL_ARM_ANGLE = math.rad(angle),
	-- Offset of dock relative to the second limb's point.
	-- These coordinates are then converted to the ship dock's
	-- local coordinates.
	DOCK_OFFSET = vector.new(-4.5, 1.5, 0),
	-- For use with the ship only
	DOCK_DIR = math.rad(ship),

	-- Idle limb angles
	LIMB_1 = math.rad(140),
	LIMB_2 = math.rad(-155),

	ORIENTATION = orientation,
}
