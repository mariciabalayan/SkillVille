-- Requirements --
local storyboard = require ("storyboard")
local widget = require( "widget" )

-- Global Variables --
local scene = storyboard.newScene()
local bgMusic = audio.loadSound("music/MainSong.mp3")
local backgroundMusicChannel

local startGame = function( event )
	option =	{
		effect = "fade",
		time = 400,
		params = {
			music = backgroundMusicChannel
		}
	}
	storyboard.gotoScene("MainMenu", option)
end

function scene:createScene(event)

	local screenGroup = self.view
	backgroundMusicChannel = audio.play( bgMusic, { loops=-1}  )

	bg = display.newImageRect("images/menu/bg_back.png", 600, 320)
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;
	screenGroup:insert(bg)

	building = display.newImage( "images/menu/building.png" )
	building.x = 254
	building.y =  display.contentCenterY;
	building.speed = 1
	screenGroup:insert(building)

	building2 = display.newImage( "images/menu/building.png" )
	building2.x = -315
	building2.y = display.contentCenterY;
	building2.speed = 1
	screenGroup:insert(building2)
	
	ground = display.newImageRect( "images/menu/ground.png",600, 320)
	ground.x = display.contentCenterX;
	ground.y =  display.contentCenterY;
	screenGroup:insert(ground)
	
	clouds = display.newImage( "images/menu/bg2.png" )
	clouds.x = 0
	clouds.y =  display.contentCenterY;
	clouds.speed = 2
	screenGroup:insert(clouds)

	clouds2 = display.newImage( "images/menu/bg2.png" )
	clouds2.x = 570
	clouds2.y = display.contentCenterY;
	clouds2.speed = 2
	screenGroup:insert(clouds2)
	
	
	title = widget.newButton{
		id = "title",
		defaultFile = "images/menu/title.png",
		overFile = "images/menu/title_over.png",
		emboss = true,
		onEvent = startGame,
	}
	title.x = (display.contentCenterX);
	title.y = (display.contentCenterY) + 10;
	title.width = 450
	title.height = 100
	screenGroup:insert(title)

	helpText = display.newText("Tap the title to start game", display.contentCenterX, (display.contentHeight/3)*2+15, Arial, 18)
	helpText:setFillColor(1, 1, 1)
	screenGroup:insert(helpText)
	
end

function moveBG(self,event)

	if self.x == -300 then
		self.x = 830
	else
		self.x = self.x - (self.speed)
	end
end

function moveBGx(self,event)
	if self.x == 795 then
		self.x = -315
	else
		self.x = self.x + (self.speed)
	end
end

function scene:enterScene(event)

	clouds.enterFrame = moveBG
    Runtime:addEventListener("enterFrame", clouds)
	
	clouds2.enterFrame = moveBG
    Runtime:addEventListener("enterFrame", clouds2)

    building.enterFrame = moveBGx
  	Runtime:addEventListener("enterFrame", building)

  	building2.enterFrame = moveBGx
  	Runtime:addEventListener("enterFrame", building2)

	
end

function scene:exitScene(event)
	Runtime:removeEventListener("enterFrame", clouds)
	Runtime:removeEventListener("enterFrame", clouds2)
	Runtime:removeEventListener("enterFrame", building)
	Runtime:removeEventListener("enterFrame", building2)
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)

return scene