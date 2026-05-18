package.path = package.path .. ";/?.lua"
local channels = require("protocols.channels")
local modem = peripheral.find("modem") or error("No modem", 0)
local altitude = peripheral.wrap("left")
local gimbal = peripheral.wrap("right")

while true do
	print("Sending gimbal and altitude data.. ")
	modem.transmit(
		channels.SHIP_DOCK,
		channels.SHIP_SLAVE2,
		{ altitude = altitude.getHeight(), gimbal = gimbal.getAngles() }
	)
	sleep(1)
end
