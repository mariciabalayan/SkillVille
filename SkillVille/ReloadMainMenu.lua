-- Requirements --
local storyboard = require ("storyboard")

-- Global Variables --
local scene = storyboard.newScene()

function scene:enterScene(event)
	mainMusic = audio.loadSound("music/MainSong.mp3")
	backgroundMusicChannel = audio.play( mainMusic, { loops=-1}  )
	option =	{
		effect = "fade",
		time = 400,
		params = {
			music = backgroundMusicChannel
		}
	}
	storyboard.gotoScene("MainMenu", option)
end
scene:addEventListener("enterScene", scene)
return scene