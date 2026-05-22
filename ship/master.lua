package.path = package.path .. ";/?.lua"
-- Gets position of the dock and sends it to the calculator
local channels = require("protocols.channels")
local network = require("protocols.network")
local geometry = require("protocols.geometry")
local calculate = require("protocols.calculate")
local modem = peripheral.find("modem") or error("No modem", 0)
modem.open(channels.SHIP_DOCK)

-- Offset values (x, y, z)
-- MUST BE CALIBRATED FOR EVERY SHIP.
-- Used to determine where the dock is with respect to the master computer
-- in the -Z,X plane (global coordinates)
local dock_offset = vector.new(-2, -1, 2)

-- Approximate distance between dock and ship. Used to filter other different ships.
local dock_to_pivot = 12

for _, name in ipairs(peripheral.getNames()) do
	print(string.format("Found peripheral %s to the %s..", peripheral.getType(name), name))
end

-- For checking if in docking mode
local relay_lever = "bottom"

-- For checking if docked. This uses the
-- comparator value from the dock connector.
local relay_check_dock = "right"

-- x and z normal vectors of corresponding nav tables
local x, z
x = peripheral.wrap("left")
z = peripheral.wrap("right")

while true do
	-- Check if docked
	if redstone.getInput(relay_lever) then
		print("Not in docking mode.. (redstone off)")
		sleep(1)
	else
		slave1 = network.poll(channels.SHIP_SLAVE1, 1)
		slave2 = network.poll(channels.SHIP_SLAVE2, 1)
		local raw = {
			x = x.getRelativeAngle(),
			y = slave1.y,
			z = z.getRelativeAngle(),
			north = slave1.north,
			altitude = slave2.altitude,
			gimbal = slave2.gimbal,
			dock_offset = dock_offset,
		}
		print(string.format("raw x: %f", raw.x))
		print(string.format("raw y: %f", raw.y))
		print(string.format("raw z: %f", raw.z))
		print(string.format("raw altitude: %f", raw.altitude))

		local processed = calculate.process(raw)
		print("vector:")
		print(processed.dock_vector)
		print(string.format("pivot angle: %f ", processed.pivot_angle))
		sleep(3)
	end
end
