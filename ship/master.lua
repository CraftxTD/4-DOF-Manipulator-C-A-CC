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
local offset = vector.new(-2, -1, 4)

-- Approximate distance between dock and ship. Used to filter other different ships.
local dock_to_pivot = 12

for _, name in ipairs(peripheral.getNames()) do
	print(string.format("Found peripheral %s to the %s..", peripheral.getType(name), name))
end

-- For checking if in docking mode
local relay_lever = "left"
local gimbal = peripheral.wrap("front")
local north = peripheral.wrap("back")
local modem = peripheral.wrap("right")

while true do
	-- Check if docked
	if redstone.getInput(relay_lever) then
		print("Not in docking mode.. (redstone off)")
		sleep(1)
	else
		local x, y, z = gps.locate(1, false)
		local raw = {
			north = north.getRelativeAngle(),
			gimbal = gimbal.getAngles(),
			x = x,
			y = y,
			z = z,
		}

		-- Transmit to the controller
		print("Sending data to controller..")
		modem.transmit(channels.CONTROLLER, channels.SHIP_DOCK, raw)

		sleep(3)
	end
end
