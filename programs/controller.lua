package.path = package.path .. ";/?.lua"
local channels = require("protocols.channels")
local network = require("protocols.network")
local calculate = require("protocols.calculate")

local modem = peripheral.find("modem") or error("No modem", 0)
modem.open(channels.CONTROLLER)

-- TODO: Fully implement controller
-- TODO: Initial angle for manipulator when idle, implement system
-- to change angles when already at a select location at calculate.
-- Maybe use constant values that change?
-- FIX: Focus only on one ship at a time

while true do
	local raw = network.poll(channels.SHIP_DOCK, 1)

	print("Found ship.. ")
	local data = calculate.angles(calculate.process(raw))

	if not data.possible then
		print("! Ship cannot be safely docked, please align dock to the arm's center !")
		goto skip
	end
	print("Rotating ring bearing..")
	modem.transmit(channels.LIMB_RING_BEARING, channels.CONTROLLER, data.center_pivot)
	network.poll(channels.CONTROLLER, 1)

	-- Waits until the ring bearing has moved
	print("Rotating limb 1 bearing..")
	modem.transmit(channels.LIMB_1, channels.CONTROLLER, data.limb1_angle)
	print("Rotating limb 2 and dock bearing..")
	modem.transmit(channels.LIMB_2, channels.CONTROLLER, data.limb2_angle)
	modem.transmit(channels.LIMB_DOCK_BEARING, channels.CONTROLLER, data.dock_pivot)

	for _, bearing in pairs(data) do
		if type(bearing) ~= "boolean" then
			bearing.dir = -bearing.dir
		end
	end

	sleep(10)

	print("Going back to resting position..")

	print("Rotating limb 1 bearing..")
	modem.transmit(channels.LIMB_1, channels.CONTROLLER, data.limb1_angle)
	print("Rotating limb 2 and dock bearing..")
	modem.transmit(channels.LIMB_2, channels.CONTROLLER, data.limb2_angle)
	modem.transmit(channels.LIMB_DOCK_BEARING, channels.CONTROLLER, data.dock_pivot)
	network.poll(channels.CONTROLLER, 1)

	-- Waits until every bearing has moved
	print("Rotating ring bearing..")
	modem.transmit(channels.LIMB_RING_BEARING, channels.CONTROLLER, data.center_pivot)
	network.poll(channels.CONTROLLER, 1)

	::skip::
	print("Sleeping..")
	sleep(10)
end
