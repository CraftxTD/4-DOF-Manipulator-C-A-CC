package.path = package.path .. ";/?.lua"

local function firstMenu()
	term.clear()
	term.setCursorPos(1, 1)
	print("What do you want to configure?")
	print("1. Arm Controller")
	print("2. Ship")
	print("3. Reinstall")
	print("4. Exit")
end

local function armMenu()
	term.clear()
	term.setCursorPos(1, 1)
	print("What do you want to configure?")
	print("1. Arm Orientation")
	print("2. Arm Length")
	print("3. Exit")
end

local function shipMenu()
	term.clear()
	term.setCursorPos(1, 1)
	print("What do you want to configure?")
	print("1. Ship Coordinates")
	print("2. Dock Direction")
	print("3. Ship Orientation (Before assembly)")
	print("4. Exit")
end

local function angleMenu()
	term.clear()
	term.setCursorPos(1, 1)
	print("What new default orientation do you want your arm to be in?")
	print("1. North (Default)")
	print("2. West")
	print("3. East")
	print("4. South")
end

local function dirMenu()
	term.clear()
	term.setCursorPos(1, 1)
	print("What direction is the ship dock facing?")
	print("(Relative to the magnet table while un-assembled, front is facing forward.)")
	print("1. Front")
	print("2. Left")
	print("3. Right")
	print("4. Back")
end

local function orientMenu()
	term.clear()
	term.setCursorPos(1, 1)
	local angle = peripheral.find("navigation_table").getRelativeAngle()
	sleep(0.2)
	print("Navigation Table Angle: ", angle)
	print("! If your ship is not pointed towards the north, this angle is not accurate !")
	print("If angle is ~270, your ship was assembled north.")
	print("If angle is ~0 / ~360, your ship was assembled east.")
	print("If angle is ~180, your ship was assembled west.")
	print("If angle is ~90, your ship was assembled south.")
	print("")
	print("What orientation did you assemble your ship?")
	print("1. North")
	print("2. East")
	print("3. West")
	print("4. South")
	print("5. Restart")
end

local function readValue()
	::restart::
	print("")
	write("> ")
	local msg = read()
	local values = {}

	for num in string.gmatch(msg, "%S+") do
		if tonumber(num) == nil then
			print("Must be a number.")
			goto restart
		end
		table.insert(values, tonumber(num))
	end

	return values
end

local function setConfig(name, value)
	local file = fs.open("/protocols/geometry.lua", "r")
	local text = file.readAll()
	file.close()

	text = text:gsub("local%s+" .. name .. "%s*=%s*[%d%.%-]+", "local " .. name .. " = " .. tostring(value))

	file = fs.open("/protocols/geometry.lua", "w")
	file.write(text)
	file.close()
end

local function changeArm()
	armMenu()
	local _, chr = os.pullEvent("char")
	while tonumber(chr) == nil do
		_, chr = os.pullEvent("char")
	end

	chr = tonumber(chr)
	if chr == 3 then
		return
	elseif chr == 2 then
		term.clear()
		term.setCursorPos(1, 1)
		print("What is the new arm length?")
		print("(This is the sum of both each limb length. Default value is 28.")
		local c = readValue()
		if c[1] ~= nil then
			setConfig("length", c[1])
		end
	elseif chr == 1 then
		local num = 1
		repeat
			angleMenu()
			num = readValue()[1]
		until 1 <= num and num <= 4
		if num == 1 then
			setConfig("angle", 90)
		elseif num == 2 then
			setConfig("angle", 180)
		elseif num == 3 then
			setConfig("angle", 0)
		elseif num == 4 then
			setConfig("angle", 270)
		end
	end
end

local function changeShip()
	shipMenu()
	local _, chr = os.pullEvent("char")
	while tonumber(chr) == nil do
		_, chr = os.pullEvent("char")
	end

	chr = tonumber(chr)
	if chr == 4 then
		return
	elseif chr == 3 then
		term.clear()
		term.setCursorPos(1, 1)
		repeat
			print("Finding navigation table angle to determine orientation of the ship..")
			print("Please orient your ship until the table's arrow is in line with your ship.")
			print("Press 1 once correctly oriented..")
			local c = readValue()
		until c[1] == 1

		local num = {}
		repeat
			orientMenu()
			num = readValue()
		until 1 <= num[1] and num[1] <= 4

		if num[1] == 1 then
			setConfig("orientation", 0)
		elseif num[1] == 2 then
			setConfig("orientation", -90)
		elseif num[1] == 3 then
			setConfig("orientation", 90)
		elseif num[1] == 4 then
			setConfig("orientation", 180)
		end
	elseif chr == 2 then
		repeat
			local loop = false
			dirMenu()
			local c = readValue()
			if c[1] == 1 then
				loop = true
				setConfig("ship", -90)
			elseif c[1] == 2 then
				loop = true
				setConfig("ship", 0)
			elseif c[1] == 3 then
				loop = true
				setConfig("ship", 180)
			elseif c[1] == 4 then
				loop = true
				setConfig("ship", 90)
			end
		until loop
	elseif chr == 1 then
		repeat
			local loop = false
			print("What are the new ship offset coordinates? (x, y, z)")
			print("(These are the local coordinates of the ship's dock relative to the ship computer.)")
			local c = readValue()
			if c[1] ~= nil and c[2] ~= nil and c[3] ~= nil then
				loop = true
				setConfig("x1", c[1])
				setConfig("y1", c[2])
				setConfig("z1", c[3])
				print("Changing coordinates..")
			end
		until loop
	end
end

while true do
	firstMenu()
	local _, chr = os.pullEvent("char")
	while tonumber(chr) == nil do
		_, chr = os.pullEvent("char")
	end

	chr = tonumber(chr)
	if chr == 4 then
		shell.run("reboot")
	else
		if chr == 1 then
			changeArm()
		elseif chr == 2 then
			changeShip()
		elseif chr == 3 then
			shell.run("pastebin run rPcQdWUv")
			break
		end
	end
end
