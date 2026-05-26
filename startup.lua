-- NOTE: Link: wget https://raw.githubusercontent.com/CraftxTD/4-DOF-Manipulator-C-A-CC/refs/heads/vanilla-gps/startup.lua  /startup.lua
local directories = {
	programs = { "controller.lua", "gyro.lua" },
	libs = { "complex.lua", "matrix.lua" },
	protocols = { "calculate.lua", "channels.lua", "geometry.lua", "network.lua" },
	ship = { "master.lua" },
	test = { "test.lua", "calibrate.lua" },
}
local root_files = {
	"arm_bearing.lua",
}

local base = "https://raw.githubusercontent.com/CraftxTD/4-DOF-Manipulator-C-A-CC/refs/heads/vanilla-gps/"

for dir, files in pairs(directories) do
	fs.makeDir(dir)
	for _, file in pairs(files) do
		shell.run("rm", dir .. "/" .. file)

		print("Downloading " .. file)

		shell.run("wget", base .. dir .. "/" .. file, dir .. "/" .. file)
	end
end

for _, file in pairs(root_files) do
	shell.run("rm", "/" .. file)

	print("Downloading " .. file)

	shell.run("wget", base .. "/" .. file, "/" .. file)
end

print("Successfully downloaded.")
