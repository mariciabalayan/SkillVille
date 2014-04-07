-- Requirements --
local storyboard = require ("storyboard")
local widget = require( "widget" )

-- Global Variables --
local scene = storyboard.newScene()
scene.purgeOnSceneChange = true
local text, category, boolFirst, gameTimer, currScore, roundNumber, correctCtr, roundSpeed, pauseCtr

function scene:createScene(event)
	local screenGroup = self.view
	boolFirst = event.params.first
	gameTimer = event.params.time
	category = event.params.categ
	currScore = event.params.score
	roundNumber = event.params.roundctr
	correctCtr = event.params.correctcount
	roundSpeed = event.params.roundspeed
	pauseCtr = event.params.pausecount
end

function scene:enterScene(event)
	local screenGroup = self.view
	option = {
		-- effect = "fade",
		time = 400,
		params = {
			categ = category,
			first = boolFirst,
			time = gameTimer,
			score = currScore,
			roundctr = roundNumber,
			first = boolFirst,
			correctcount = correctCtr,
			roundspeed = roundSpeed,
			pausecount = pauseCtr
		}
	}

	storyboard.removeScene("GameOne")
	storyboard.gotoScene("GameOne", option)
	storyboard.removeScene("ReloadGameOne")
end

function scene:exitScene(event)
	
end

function scene:destroyScene(event)

end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene