package.path = package.path .. ";/?.lua"
local channels = require("protocols.channels")
local network = require("protocols.network")
local calculate = require("protocols.calculate")
local movement = require("programs.movement")

local modem = peripheral.find("modem") or error("No modem", 0)
modem.open(channels.CONTROLLER)

-- TODO: to change angles when already at a select location at calculate.
-- Maybe use constant values that change?
-- FIX: Focus only on one ship at a time


local docked = false
-- Incase other computers have not started up yet
sleep(5)
-- If chunk is loaded and arm is still docked
if redstone.getAnalogInput("front") == 15 then
  docked = true
else 
  movement.calibrate(1, modem)
end


while true do
  local data, raw
  if not(docked) then 
	  raw = network.poll(channels.SHIP_DOCK, 1)

	  print("Found ship.. ")
	  data = calculate.angles(calculate.process(raw))
  end

  if docked or (data ~= nil and movement.goto(data, modem)) then
    if not(docked) then
      -- Initial timer before checking comparator signal
      sleep(10)
    end
    while redstone.getAnalogInput("front") >= 1 do
      print("Dock is close..")
      sleep(0.5)
      if redstone.getAnalogInput("front") == 15 then
        while redstone.getAnalogInput("front") == 15 do
          print("Ship currently docked..")
          sleep(0.5)
        end
        break 
      end
    end
    print("Ship undocked, waiting 5 seconds..")
    sleep(5)
    modem.transmit(channels.SHIP_DOCK, channels.CONTROLLER, true)
    print("Returning back to idle position..")
    movement.calibrate(1, modem)
  end
  docked = false
  sleep(2)
end
