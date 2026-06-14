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

-- Get direction because gearshifts don't seem to support
-- negative angles (returns a table)
-- In xz plane, 1 is towards -x (anti-clockwise), -1 is towards x (clockwise)
-- Converts radians to degrees
function calculate.deg_direction(theta)
	if theta < 0 then
		return { angle = math.deg(math.abs(theta) % (2 * math.pi)), dir = 1 }
	else
		return { angle = math.deg(theta % (2 * math.pi)), dir = -1 }
	end
end

-- Determines whether ship is pivoted at an angle that the arm
-- can reach onto. Returns a table containing a boolean and
-- the pivot angle to rotate to.
-- Note that center pivot is a table from calculate.deg_direction function
local function pivot_check(center_pivot, ship_pivot)
	local local_pos
	if center_pivot.dir == 1 then
		local_pos = geometry.INITIAL_ARM_ANGLE + math.rad(center_pivot.angle)
	elseif center_pivot.dir == -1 then
		local_pos = geometry.INITIAL_ARM_ANGLE - math.rad(center_pivot.angle)
		if local_pos < 0 then
			local_pos = math.pi * 2 - local_pos
		end
	end
	-- Ship yaw is 0 degrees when ship is facing the -z axis
	ship_pivot = (ship_pivot + math.pi) % (math.pi * 2)
	print(string.format("ship pivot: %f, local pos: %f", math.deg(ship_pivot), math.deg(local_pos)))

	-- Check if ship is in correct quadrant. They are in the correct quadrant
	-- if they are in the quadrant diagonal to the arm's quadrant.
	-- Quadrant 1
	if math.pi / 2 >= local_pos then
		-- Check if ship in Quadrant 3
		if not (ship_pivot > math.pi and 3 * math.pi / 2 >= ship_pivot) then
			return { bool = false, angle = 0 }
		end
	-- Quadrant 2
	elseif math.pi >= local_pos then
		-- Check if ship in Quadrant 4
		if not (ship_pivot > 3 * math.pi / 2 and 2 * math.pi >= ship_pivot) then
			return { bool = false, angle = 0 }
		end
	-- Quadrant 3
	elseif 3 * math.pi / 2 >= local_pos then
		-- Check if ship in Quadrant 1
		if not (ship_pivot > 0 and math.pi / 2 >= ship_pivot) then
			return { bool = false, angle = 0 }
		end
	-- Quadrant 4
	else
		-- Check if ship in Quadrant 2
		if not (ship_pivot > math.pi / 2 and math.pi >= ship_pivot) then
			return { bool = false, angle = 0 }
		end
	end
	return { bool = true, angle = (ship_pivot + math.pi) % (math.pi * 2) - local_pos }
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
	if ship_xz > math.pi then
		ship_xz = ship_xz - math.pi * 2
	elseif ship_xz < -math.pi then
		ship_xz = ship_xz + math.pi * 2
	end
	print(string.format("xz vector: (%f, %f, %f)", global_cross.x, global_cross.y, global_cross.z))
	print(string.format("ship_xz: %f", math.deg(ship_xz)))

	Ry = matrix:new({
		{ math.cos(ship_xz), 0, math.sin(ship_xz) },
		{ 0, 1, 0 },
		{ -math.sin(ship_xz), 0, math.cos(ship_xz) },
	})
	-- Convention YXZ
	rotation_matrix = matrix.mul(Ry, matrix.mul(Rx, Rz))

	local dock_dir = matrix:new({
		{ math.cos(raw.dock_dir), 0, math.sin(raw.dock_dir) },
		{ 0, 1, 0 },
		{ -math.sin(raw.dock_dir), 0, math.cos(raw.dock_dir) },
	})

	local dock_offset =
		matrix:new({ { geometry.DOCK_OFFSET.x }, { geometry.DOCK_OFFSET.y }, { geometry.DOCK_OFFSET.z } })
	dock_offset = matrix.mul(dock_dir, dock_offset)
	dock_offset = vector.new(dock_offset[1][1], dock_offset[2][1], dock_offset[3][1])
	print("dock_offset: ", dock_offset)

	local ship_dock_offset = vector.new(raw.dock_x, raw.dock_y, raw.dock_z)
	local local_dock_vector = get_offset(dock_offset:add(ship_dock_offset))
	print(string.format("local vector: %s", local_dock_vector:tostring()))
	local global_dock_vector = local_dock_vector:add(vector.new(raw.x, raw.y, raw.z))
	print(string.format("global vector: %s", global_dock_vector:tostring()))
	print(string.format("pivot_angle: %f", math.deg(ship_xz)))

	print(raw.dock_dir)
	if raw.dock_dir == -math.pi / 2 then
		ship_xz = ship_xz - math.pi / 2
	elseif raw.dock_dir == math.pi / 2 then
		ship_xz = ship_xz + math.pi / 2
	elseif raw.dock_dir == math.pi then
		ship_xz = ship_xz - math.pi
	end

	return {
		ship_vector = global_dock_vector,
		pivot_angle = ship_xz,
	}
end

-- FIXIT: Figure out a way to take care of dock rotation

function calculate.angles(processed)
	-- Angles are in radians. The arm dock pivot angle is assumed to always be at 0,
	-- in order to be easily used by the ship pivot angle.
	-- Horizontal angle spins the pivot bearing (xz plane), while the vertical angle is used to calculate each joint arm angle.
	-- Ship is assumed to be level

	-- Arm to ship angles and magnitude (z is inverted)
	-- Current arm is initially rotated by 90 degrees
	local h_angle = quadrant(processed.ship_vector.x - geometry.ARM.x, -(processed.ship_vector.z - geometry.ARM.z))
	-- Using hypotenuse of x and z to find vertical angle
	local hypotenuse_xz = math.sqrt(
		math.pow((processed.ship_vector.x - geometry.ARM.x), 2)
			+ math.pow((processed.ship_vector.z - geometry.ARM.z), 2)
	)
	local v_angle = quadrant(hypotenuse_xz, processed.ship_vector.y - geometry.ARM.y)
	local magnitude = hypotenuse_xz / math.cos(v_angle)
	-- Calculate each joint arm angle
	-- If at quadrant 2, each joint arm angle is the reflection of their corresponding
	-- angle at quadrant 1. This is done to prevent the arm from going underground.
	local limb1_angle = reference(v_angle) + math.acos(magnitude / geometry.ARM_RADIUS)
	local limb2_angle = reference(v_angle) - math.acos(magnitude / geometry.ARM_RADIUS) - limb1_angle

	-- Account for idle position
	limb1_angle = limb1_angle - geometry.LIMB_1
	limb2_angle = limb2_angle - geometry.LIMB_2
	-- Calculate center pivot angle and direction
	local center_pivot = calculate.deg_direction(geometry.INITIAL_ARM_ANGLE - h_angle)
	print(string.format("h angle: %f", math.deg(h_angle)))
	print(string.format("center pivot: %f, dir: %f", center_pivot.angle, center_pivot.dir))

	-- Calculate dock pivot angle and direction.
	-- The initial dock pivot angle is the same as the center pivot angle.
	local dock_pivot = pivot_check(center_pivot, processed.pivot_angle)
	---@type ccTweaked.Vector
	local distance = (processed.ship_vector - geometry.ARM)
	local m = distance:length()

	if dock_pivot.bool and limb1_angle ~= nil and limb2_angle ~= nil and m <= geometry.ARM_RADIUS then
		-- Quick fix to optimize pivot angle rotation when above 180 degrees
		if center_pivot.angle > 180 then
			if center_pivot.dir == -1 then
				center_pivot.dir = 1
			else
				center_pivot.dir = -1
			end
			center_pivot.angle = center_pivot.angle - 360
		end
		return {
			possible = true,
			v_angle = calculate.deg_direction(v_angle),
			limb1_angle = calculate.deg_direction(-limb1_angle),
			limb2_angle = calculate.deg_direction(-limb2_angle),
			center_pivot = center_pivot,
			dock_pivot = calculate.deg_direction(dock_pivot.angle),
		}
	else
		return {
			possible = false,
		}
	end
end

return calculate
