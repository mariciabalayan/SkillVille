-- Requirements --
local storyboard = require ("storyboard")
local widget = require( "widget" )

-- Global Variables --
local scene = storyboard.newScene()
scene.purgeOnSceneChange = true
local text, category, boolFirst, gameTimer, currScore, game1music, itemSpeed, pauseCtr, totalHint, totalTries, item, muted

function scene:createScene(event)
	
	local screenGroup = self.view
	print("RELOADING....")

	boolFirst = event.params.first
	gameTimer = event.params.time
	category = event.params.categ
	currScore = event.params.score
	game1music = event.params.music
	itemSpeed = event.params.speed
	pauseCtr = event.params.pause
	item = event.params.itemWord
	totalTries = event.params.tries
	totalHint = event.params.hint
	muted = event.params.mute

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
			music = game1music,
			speed = itemSpeed,
			pause = pauseCtr,
			itemWord = item,
			tries = totalTries,
			hint = totalHint,
			mute = muted
		}
	}
	storyboard.removeScene("GameThree")
	storyboard.gotoScene("GameThree", option)
	storyboard.removeScene("ReloadGameThree")
	
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