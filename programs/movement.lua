-- Used for controller movement
package.path = package.path .. ";/?.lua"
local movement = {}
local channels = require("protocols.channels")
local geometry = require("protocols.geometry")
local network = require("protocols.network")

-- Makes the dock go back to either:
-- 0: Base position (0 Degrees)
-- 1: Idle position
function movement.calibrate(arg, modem)
	local degrees = {}
	-- Go to base position (0 degrees)
	if type(arg) == 0 then
		degrees[1], degrees[2], degrees[3] = 0, 0, 0
	-- Go to neutral position
	elseif arg == 1 then
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
end

-- Goes to where the ship is. Takes processed data as argument.
-- Returns boolean on whether going to the ship is safe or not 
-- (If false, doesn't go to ship)
function movement.goto(data, modem)
  if not data.possible then
  	print("! Ship cannot be safely docked, please align dock or go closer to the arm's center !")
    modem.transmit(channels.SHIP_DOCK, channels.CONTROLLER, false)
    return false
  end
  print("Ship can be docked..")
  modem.transmit(channels.SHIP_DOCK, channels.CONTROLLER, true)
  print("Rotating ring bearing..")
  modem.transmit(channels.LIMB_RING_BEARING, channels.CONTROLLER, data.center_pivot)
  network.poll(channels.CONTROLLER, 1)
  print("Rotating limb 2 and dock bearing..")
  modem.transmit(channels.LIMB_2, channels.CONTROLLER, data.limb2_angle)
  modem.transmit(channels.LIMB_DOCK_BEARING, channels.CONTROLLER, data.dock_pivot)
  print("Rotating limb 1 bearing..")
  modem.transmit(channels.LIMB_1, channels.CONTROLLER, data.limb1_angle)
  return true
end

return movement
