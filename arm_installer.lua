--[[ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                  4 DOF MANIPULATOR INSTALLER
                          VERSION 1.0

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -]]

-- NOTE: Change raw github link to main branch before merging

package.path = package.path .. ";/?.lua"

local function firstMenu()
	term.clear()
	term.setCursorPos(1, 1)
	print("Automatic Arm Refueler Installer v1.0")
	print("! WARNING: MAKE SURE THE GPS IS FULLY SETUP BEFORE PROCEEDING !")
	sleep(0.2)
	print()
	print("Which computer am I?")
	print("1. Arm Controller")
	print("2. Ship")
	print("3. Ring Bearing")
	print("4. Limb 1")
	print("5. Limb 2")
	print("6. Dock Bearing")
	print("7. Gyro")
	print("8. Exit")
end

local function angleMenu()
	term.clear()
	term.setCursorPos(1, 1)
	print("What default orientation do you want your arm to be in?")
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
	print("If angle is near 270, you assembled your ship facing north.")
	print("If angle is near 360, you assembled your ship facing east.")
	print("If angle is near 180, you assembled your ship facing west.")
	print("If angle is near 90, you assembled your ship facing south.")
	print("What orientation did you assemble your ship?")
	print("1. North")
	print("2. East")
	print("3. West")
	print("4. South")
	print("5. Restart")
end

local function install()
	print("Installing files..")
	local base = "https://raw.githubusercontent.com/CraftxTD/4-DOF-Manipulator-C-A-CC/refs/heads/vanilla-gps/"

	local tree_file = "tree.lua"
	shell.run("rm", "/" .. tree_file)

	print("Downloading " .. tree_file)

	shell.run("wget", base .. "/" .. tree_file, "/" .. tree_file)

	local tree = require("tree")

	for dir, files in pairs(tree.directories) do
		fs.makeDir(dir)
		for _, file in pairs(files) do
			shell.run("rm", dir .. "/" .. file)

			print("Downloading " .. file)

			shell.run("wget", base .. dir .. "/" .. file, dir .. "/" .. file)
		end
	end

	for _, file in pairs(tree.root_files) do
		shell.run("rm", "/" .. file)

		print("Downloading " .. file)

		shell.run("wget", base .. "/" .. file, "/" .. file)
	end

	print("Successfully downloaded.")
end

-- Change config value in geometry.lua
local function setConfig(name, value)
	local file = fs.open("/protocols/geometry.lua", "r")
	local text = file.readAll()
	file.close()

	text = text:gsub("local%s+" .. name .. "%s*=%s*[%d%.%-]+", "local " .. name .. " = " .. tostring(value))

	file = fs.open("/protocols/geometry.lua", "w")
	file.write(text)
	file.close()
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

local function setStartup(chr)
	if fs.exists("/startup.lua") then
		fs.delete("/startup.lua")
	end
	local file = fs.open("/startup.lua", "w")

	term.clear()
	term.setCursorPos(1, 1)
	if chr == 1 then
		file.writeLine('shell.run("/programs/controller")')
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

		print("Finding controller coordinates..")
		local x2, y2, z2 = gps.locate()
		print(string.format("Controller coordinates are: %f, %f, %f", x2, y2, z2))
		setConfig("x2", x2)
		setConfig("y2", y2)
		setConfig("z2", z2)

		term.clear()
		term.setCursorPos(1, 1)
		print("What is the arm length?")
		print("(This is the sum of both each limb length. Default value is 28.")
		local c = readValue()
		if c[1] ~= nil then
			setConfig("length", c[1])
		end
	elseif chr == 2 then
		file.writeLine('shell.run("/programs/ship")')
		repeat
			local loop = false
			print("What are the ship offset coordinates? (x, y, z)")
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

		term.clear()
		term.setCursorPos(1, 1)
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
	elseif chr == 3 then
		file.writeLine('shell.run("/arm_bearing", 1)')
	elseif chr == 4 then
		file.writeLine('shell.run("/arm_bearing", 2)')
	elseif chr == 5 then
		file.writeLine('shell.run("/arm_bearing", 3)')
	elseif chr == 6 then
		file.writeLine('shell.run("/arm_bearing", 4)')
	elseif chr == 7 then
		file.writeLine('shell.run("/programs/gyro")')
	end
	file.close()
	term.clear()
	term.setCursorPos(1, 1)
end

while true do
	firstMenu()
	local _, chr = os.pullEvent("char")
	while tonumber(chr) == nil do
		_, chr = os.pullEvent("char")
	end

	chr = tonumber(chr)
	if chr == 8 then
		shell.run("reboot")
	else
		install()
		setStartup(chr)
	end
end
