--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuickNet = require(ReplicatedStorage.src.Shared.QuickNet)
local ModuleLoader = require(ReplicatedStorage.src.Shared.ModuleLoader)

-- you can optionally modify settings (also change it via the attributes on ModuleLoader)
ModuleLoader.ChangeSettings({
	FOLDER_SEARCH_DEPTH = 1,
	YIELD_THRESHOLD = 10,
	VERBOSE_LOADING = false,
	WAIT_FOR_SERVER = true,
})
-- pass any containers for your custom services to the Start() function
ModuleLoader.Start(script.Parent)

require(ReplicatedStorage.src.Shared.chrono).Start()
