-- Calculator helper functions
local geometry = require("protocols.geometry")
local matrix = require("libs.matrix")
local calculate = {}
-- Ship angles
-- Z in inverted direction
local rotation_matrix

local function quadrant(a, b)
	local angle = math.atan2(b, a)
	if angle < 0 then
		angle = angle + 2 * math.pi
	end
	return angle
end

-- NOTE: Cross product strategy
-- Finds the cross product using matrix lib given vector parameters
local function cross(a, b)
	local v_a = matrix:new({ { a.x }, { a.y }, { a.z } })
	local v_b = matrix:new({ { b.x }, { b.y }, { b.z } })
	local product = matrix.cross(v_a, v_b)
	return vector.new(product[1][1], product[2][1], product[3][1])
end

-- Calculate the rotation matrix based off the offsets
-- Takes block vector offset as value (distance of block from master computer)
-- Takes a vector object, converts into matrix form, then returns vector object.

local function get_offset(block_offset)
	local offset_vector = matrix:new({ { block_offset.x }, { block_offset.y }, { block_offset.z } })
	-- Convention YXZ
	offset_vector = matrix.mul(rotation_matrix, offset_vector)
	return vector.new(offset_vector[1][1], offset_vector[2][1], offset_vector[3][1])
end

-- Inverts the rotation back
local function invert_rotate(angle_vector)
	local rotated_vector = matrix:new({ { angle_vector.x }, { angle_vector.y }, { angle_vector.z } })
	-- Convention ZXY with negative angles
	rotated_vector = matrix.mul(matrix.transpose(rotation_matrix), rotated_vector)
	return vector.new(rotated_vector[1][1], rotated_vector[2][1], rotated_vector[3][1])
end

-- Get direction because gearshfits don't seem to support
-- negative angles (returns a table)
-- In xz plane, 1 is towards -x (anti-clockwise), -1 is towards x (clockwise)
-- Converts radians to degree
local function deg_direction(theta)
	if theta < 0 then
		return { angle = math.deg(math.abs(theta) % (2 * math.pi)), dir = 1 }
	else
		return { angle = math.deg(theta % (2 * math.pi)), dir = -1 }
	end
end

-- Returns reference angle, necessary for only calculating
-- limb joint angles at the first quadrant
local function reference(theta)
	if math.pi / 2 >= theta and theta > 0 then
		return theta
	elseif math.pi >= theta and theta > math.pi / 2 then
		return math.pi - theta
	elseif 3 * math.pi / 2 >= theta and theta > math.pi then
		return theta - math.pi
	else
		return 2 * math.pi - theta
	end
end

-- All ships have the same channels, thus ships need to be filtered.
-- Uses magnitude of distance between two computers to determine
-- if they both belong to the same ship.
function calculate.filter_ship(position, dock_to_pivot)
	local magnitude = math.sqrt(
		math.pow(position.x1 - position.x2, 2)
			+ math.pow(position.y1 - position.y2, 2)
			+ math.pow(position.z1 - position.z2, 2)
	)
	if magnitude > dock_to_pivot then
		return false
	else
		return true
	end
end

-- Calculates the distance and angle of the dock relative to the center of the arm
-- Uses the raw values and produces the dock vector
function calculate.process(raw)
	-- Convert every raw value except gimbals into rad
	local north = math.rad(raw.north)

	-- Gimbal, xy is flipped
	local ship_xz
	local ship_xy = -math.rad(raw.gimbal[2])
	local ship_zy = math.rad(raw.gimbal[1])

	-- Initialize the rotation matrices and their inverse rotations
	local Rz, Rx, Ry
	Rz = matrix:new({
		{ math.cos(ship_xy), -math.sin(ship_xy), 0 },
		{ math.sin(ship_xy), math.cos(ship_xy), 0 },
		{ 0, 0, 1 },
	})
	Rx = matrix:new({
		{ 1, 0, 0 },
		{ 0, math.cos(ship_zy), -math.sin(ship_zy) },
		{ 0, math.sin(ship_zy), math.cos(ship_zy) },
	})

	local normal = vector.new(0, 1, 0)
	local angle = vector.new(math.cos(north), 0, -math.sin(north))
	local gravity = matrix:new({ { 0 }, { 1 }, { 0 } })
	-- Convention XZ
	gravity = matrix.mul(Rx, matrix.mul(Rz, gravity))
	gravity = vector.new(gravity[1][1], gravity[2][1], gravity[3][1])

	-- Calculate (normal x angle) x gravity
	local local_cross = cross(gravity, cross(normal, angle))
	local global_cross = matrix:new({ { local_cross.x }, { local_cross.y }, { local_cross.z } })
	global_cross = matrix.mul(matrix.transpose(Rz), matrix.mul(matrix.transpose(Rx), global_cross))
	global_cross = vector.new(global_cross[1][1], global_cross[2][1], global_cross[3][1])
	ship_xz = math.atan2(-global_cross.z, global_cross.x) - math.pi / 2
	print(string.format("xz vector: (%f, %f, %f)", global_cross.x, global_cross.y, global_cross.z))
	print(string.format("ship_xz: %f", math.deg(ship_xz)))

	Ry = matrix:new({
		{ math.cos(ship_xz), 0, -math.sin(ship_xz) },
		{ 0, 1, 0 },
		{ -math.sin(ship_xz), 0, -math.cos(ship_xz) },
	})
	-- Convention YXZ
	rotation_matrix = matrix.mul(Ry, matrix.mul(Rx, Rz))

	local local_dock_vector = get_offset(raw.dock_offset)
	print(string.format("local vector: %s", local_dock_vector:toString()))
	local global_dock_vector = local_dock_vector:add(raw.global_coords)
	print(string.format("global vector: %s", global_dock_vector:toString()))

	return {
		dock_vector = global_dock_vector,
		pivot_angle = ship_xz,
	}
end

-- FIXIT: Figure out a way to take care of dock rotation

function calculate.angles(local_ship)
	-- Angles are in radians. The arm dock pivot angle is assumed to always be at 0,
	-- in order to be easily used by the ship pivot angle.
	-- Horizontal angle spins the pivot bearing, while the vertical angle is used to calculate each joint arm angle.
	local magnitude, h_angle, v_angle, limb1_angle, limb2_angle, ship_pivot_angle, center_pivot, dock_pivot

	-- Ship angles
	-- The ship is assumed to be level.
	local ship_x, ship_y, ship_z
	ship_pivot_angle = quadrant(local_ship.x2 - local_ship.x1, -(local_ship.z2 - local_ship.z1))
	ship_x = local_ship.x1
		+ local_ship.offset_x * math.cos(ship_pivot_angle)
		- local_ship.offset_z * math.sin(ship_pivot_angle)
	ship_z = local_ship.z1
		- local_ship.offset_x * math.sin(ship_pivot_angle)
		+ local_ship.offset_z * math.cos(ship_pivot_angle)
	ship_y = local_ship.y1 + local_ship.offset_y

	-- Arm to ship angles and magnitude (z is inverted)
	-- Current arm is initially rotated by 90 degrees
	h_angle = quadrant(ship_x - geometry.CENTER_X, -(ship_z - geometry.CENTER_Z))
	-- Using hypotenuse of x and z to find vertical angle
	local hypotenuse_xz = (ship_x - geometry.CENTER_X) / math.cos(h_angle)
	v_angle = quadrant(hypotenuse_xz, ship_y - geometry.CENTER_Y)
	magnitude = hypotenuse_xz / math.cos(v_angle)

	-- Calculate each joint arm angle
	-- If at quadrant 2, each joint arm angle is the reflection of their corresponding
	-- angle at quadrant 1. This is done to prevent the arm from going underground.
	limb1_angle = reference(v_angle) + math.acos(magnitude / geometry.ARM_RADIUS)
	limb2_angle = reference(v_angle) - math.acos(magnitude / geometry.ARM_RADIUS) - limb1_angle

	-- Calculate center pivot angle and direction
	center_pivot = deg_direction(geometry.INITIAL_ARM_ANGLE - h_angle)

	-- Calculate dock pivot angle and direction.
	-- The initial dock pivot angle is the same as the center pivot angle.
	dock_pivot = deg_direction(ship_pivot_angle - h_angle)

	return {
		v_angle = deg_direction(v_angle),
		limb1_angle = deg_direction(-limb1_angle),
		limb2_angle = deg_direction(-limb2_angle),
		center_pivot = center_pivot,
		dock_pivot = dock_pivot,
	}
end

return calculate
