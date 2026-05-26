-- Github file tree for installation
return {
	directories = {
		programs = { "controller.lua", "gyro.lua", "ship.lua", "movement.lua" },
		libs = { "complex.lua", "matrix.lua" },
		protocols = { "calculate.lua", "channels.lua", "geometry.lua", "network.lua" },
		testing = { "goto.lua", "calibrate.lua" },
	},
	root_files = {
		"arm_bearing.lua",
	},
}
