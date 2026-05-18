package.path = package.path .. ";/?.lua"
local channels = require("protocols.channels")
local modem = peripheral.find("modem") or error("No modem", 0)
local north = peripheral.wrap("left")
local zy = peripheral.wrap("right")

while true do
	print("Sending ZY plane and ship pivot data.. ")
	modem.transmit(
		channels.SHIP_DOCK,
		channels.SHIP_SLAVE1,
		{ zy = zy.getRelativeAngle(), north = north.getRelativeAngle() }
	)
	sleep(1)
end
