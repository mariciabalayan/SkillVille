-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
require "sqlite3"
local lfs = require "lfs"
local storyboard = require "storyboard"
local path = system.pathForFile("JaVaMiaDb.sqlite3", system.ResourceDirectory)
db = sqlite3.open( path )

storyboard.gotoScene("StartMenu")

--[[print("**DATABASE**")
for row in db:nrows("SELECT name FROM sqlite_master WHERE type='table';") do
	print(row.name)
end]]