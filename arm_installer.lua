--[[ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                  4 DOF MANIPULATOR INSTALLER
                          VERSION 0.1

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -]]

package.path = package.path .. ";/?.lua"

local function firstMenu()
	term.clear()
	term.setCursorPos(1, 1)
	print("Automatic Arm Refueler Installer v0.1")
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

local function setStartup(chr)
	local file = fs.open("startup.lua", "w")
	if chr == 1 then
		file.writeLine('shell.run("/programs/controller")')
	elseif chr == 2 then
		file.writeLine('shell.run("/programs/ship")')
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

while true do
	firstMenu()
	local _, chr = os.pullEvent("char")
	while tonumber(chr) == nil do
		_, chr = os.pullEvent("char")
	end

	install()
	if chr == 8 then
		break
	else
		setStartup(chr)
	end
end
