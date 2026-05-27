package.path = package.path .. ";/?.lua"
-- Gets position of the dock and sends it to the calculator
local channels = require("protocols.channels")
local network = require("protocols.network")
local modem = peripheral.find("modem") or error("No modem", 0)
modem.open(channels.SHIP_DOCK)

for _, name in ipairs(peripheral.getNames()) do
	print(string.format("Found peripheral %s to the %s..", peripheral.getType(name), name))
end

-- For checking if in docking mode
local relay_lever = "left"
local gimbal, north, modem, speaker =
	peripheral.find("gimbal_sensor"),
	peripheral.find("navigation_table"),
	peripheral.find("modem"),
	peripheral.find("speaker")

local function play(num)
	-- Success
	if num == 1 then
		speaker.playNote("chime", 2, 8)
		speaker.playNote("chime", 2, 12)
		speaker.playNote("chime", 2, 15)
	-- Fail
	elseif num == 2 then
		speaker.playNote("didgeridoo", 2, 24)
	end
end

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
		-- Poll for 3 seconds for controller response
		local success = network.poll_for(channels.CONTROLLER, 3)
		if type(success) ~= "nil" then
			if success then
				play(1)
			end
		else
			play(2)
		end
		sleep(1)
	end
end
