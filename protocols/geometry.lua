-- Modify values here for the arm
return {
	-- Coordinates of the first block in the limb 1 bearing.
	-- Must be configured everytime the arm location is changed.
	CENTER_X = 465,
	CENTER_Y = 116,
	CENTER_Z = 423,
	-- LODESTONE OFFSET
	LODESTONE_Y = 109,
	-- Sum of both arm lengths
	-- Both arms must have the same radii
	ARM_RADIUS = 28,
	-- Max limit that a dock can rotate
	DOCK_LIMIT = { 0, math.pi },
	-- The arm angle relative to the xz plane.
	INITIAL_ARM_ANGLE = math.pi / 2,
	-- Offset of dock relative to the second limb's point.
	-- These coordinates are then converted to the ship dock's
	-- local coordinates.
	DOCK_X = 2,
	DOCK_Y = 0,
	DOCK_Z = 0,
}
