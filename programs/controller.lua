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


while true do
	local raw = network.poll(channels.SHIP_DOCK, 1)

	print("Found ship.. ")
	local data = calculate.angles(calculate.process(raw))

  if movement.goto(data, modem) then
    while redstone.getAnalogInput("front") == 15 do
      print("Ship currently docked..")
      sleep(0.5)
    end
    print("Ship undocked, waiting 5 seconds..")
    sleep(5)
    print("Returning back to idle position..")
    movement.calibrate(1, modem)
  end
  sleep(2)
end
