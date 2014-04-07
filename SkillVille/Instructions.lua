-- Requirements --
local physics = require("physics")
local storyboard = require("storyboard")
local widget= require("widget")

-- Global Variables --
local scene = storyboard.newScene()
local gameScreen, tabGroup

function scene:createScene( event )
	local slideView = require("slideView")
	
	local myImages = {
		"images/menu/howtoplay1.png",
		"images/menu/howtoplay2.png",
		"images/menu/howtoplay3.png",
	}		

	slideView.new( myImages )	
end

scene:addEventListener( "createScene", scene )

return scene