package.path = package.path .. ";/?.lua"
local channels = require("protocols.channels")
local network = require("protocols.network")
local calculate = require("protocols.calculate")
local geometry = require("protocols.geometry")
local args = { ... }

local modem = peripheral.find("modem") or error("No modem", 0)
modem.open(channels.CONTROLLER)

local degrees = {}
-- Go to base position (0 degrees)
if type(args[1]) == "nil" then
	degrees[1], degrees[2], degrees[3] = 0, 0, 0
-- Go to neutral position
elseif args[1] == "n" then
	degrees[1], degrees[2], degrees[3] = math.deg(geometry.LIMB_1), math.deg(geometry.LIMB_2), 0
end

print("Rotating limb 1 bearing..")
modem.transmit(channels.LIMB_1, channels.CONTROLLER, degrees[1])

print("Rotating limb 2 bearing..")
modem.transmit(channels.LIMB_2, channels.CONTROLLER, degrees[2])

print("Rotating dock bearing..")
modem.transmit(channels.LIMB_DOCK_BEARING, channels.CONTROLLER, degrees[3])

-- Waits until everything has moved
print("Rotating ring bearing..")
modem.transmit(channels.LIMB_RING_BEARING, channels.CONTROLLER, degrees[3])
network.poll(channels.CONTROLLER, 1)
