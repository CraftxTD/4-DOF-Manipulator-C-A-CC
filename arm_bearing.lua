-- NOTE: As of typing this wired modems cannot be connected to vertical bearings for whatever reason
package.path = package.path .. ";/?.lua"

-- This is used to control the rotation of the ring, limb 1 and limb 2 bearings.
local channels = require("protocols.channels")
local network = require("protocols.network")
local calculate = require("protocols.calculate")
local args = { ... }
local localChannel
if args[1] == "1" then
	print("COMPUTER: RING BEARING")
	localChannel = channels.LIMB_RING_BEARING
elseif args[1] == "2" then
	print("COMPUTER: LIMB 1")
	localChannel = channels.LIMB_1
elseif args[1] == "3" then
	print("COMPUTER: LIMB 2")
	localChannel = channels.LIMB_2
elseif args[1] == "4" then
	print("COMPUTER: LIMB DOCK BEARING")
	localChannel = channels.LIMB_DOCK_BEARING
end

local modem = peripheral.wrap("left") or error("No modem", 0)
modem.open(localChannel)

for _, name in ipairs(peripheral.getNames()) do
	print(string.format("Found peripheral %s to the %s..", peripheral.getType(name), name))
end

local gearshift = peripheral.find("Create_SequencedGearshift")

local data

while true do
	data = network.poll(channels.CONTROLLER, 1)

	if type(data) == "number" then
		local bearing = peripheral.find("swivel_bearing")
		-- Go to a specific position relative to 0 degrees
		local pos = calculate.deg_direction(-math.rad(data - bearing.getTargetAngle()))
		gearshift.rotate(pos.angle, pos.dir)

		while gearshift.isRunning() do
			sleep(0.1)
		end

		modem.transmit(channels.CONTROLLER, channels.CONTROLLER, _)
	else
		gearshift.rotate(data.angle, data.dir)

		while gearshift.isRunning() do
			sleep(0.1)
		end

		modem.transmit(channels.CONTROLLER, channels.CONTROLLER, _)
	end
end
