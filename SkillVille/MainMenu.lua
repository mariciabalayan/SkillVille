-- Requirements --
local physics = require("physics")
local storyboard = require("storyboard")
local widget = require("widget")

-- Global Variables --
local scene = storyboard.newScene()
local levelgroup, easy, medium, hard, gamenum, font, bg
local instance1, instance2, instance3, scores, howtoplay, bgMusic, about, aboutgroup

--  Load font --
if "Win" == system.getInfo( "platformName" ) then
    font = "Cartwheel"
elseif "Android" == system.getInfo( "platformName" ) then
    font = "Cartwheel"
end

-- Functions for level select --
function easy_onBtnRelease()
	levelgroup:removeSelf()
	audio.stop( bgMusic )
	storyboard.gotoScene("Countdown", easy)
	return true
end

function medium_onBtnRelease()
	levelgroup:removeSelf()
	audio.stop( bgMusic )
	storyboard.gotoScene("Countdown", medium)
	return true
end

function hard_onBtnRelease()
	levelgroup:removeSelf()
	audio.stop( bgMusic )
	storyboard.gotoScene("Countdown", hard)
	return true
end

function exit_onBtnRelease()
	levelgroup:removeSelf()
	return true
end

-- Function for setting parameters --
function setparams(gamenum)

	easy =	{
		effect = "fade",
		time = 400,
		params = {
			categ = "easy",
			game = gamenum
		}
	}

	medium =	{
		effect = "fade",
		time = 400,
		params = {
			categ = "medium",
			game = gamenum
		}
	}
	hard =	{
		effect = "fade",
		time = 400,
		params = {
			categ = "hard",
			game = gamenum
		}
	}

end

------ GAME 1 Level Select Modal -------
local function button1 ( event )
	setparams("one")
	showlevelDialog()
end

------ GAME 2 Level Select Modal -------
local function button2 ( event )
	setparams("two")
	showlevelDialog()
end

------ GAME 3 Level Select Modal -------
local function button3 ( event )
	setparams("three")
	showlevelDialog()
end

-- Function for  Level Dialog Rendering -- 
function showlevelDialog()
	physics.pause()
	isPause = true
 	levelgroup = display.newGroup()
	local rect = display.newImage("images/modal/gray.png")
 	rect.x = display.contentCenterX;
 	rect.y = display.contentCenterY;
 	rect:addEventListener("touch", function() return true end)
	rect:addEventListener("tap", function() return true end)
	levelgroup:insert(rect)

	local dialog = display.newImage("images/modal/levelselect_wood.png")
 	dialog.x = display.contentCenterX;
 	dialog.y = display.contentCenterY;
 	levelgroup:insert(dialog)

	local easyBtn = widget.newButton{
		defaultFile="images/modal/Easy.png",
		overFile="images/modal/Easy.png",
		onRelease = easy_onBtnRelease 
	}
	easyBtn.x = bg.x - 5
	easyBtn.y = 115
	levelgroup:insert(easyBtn)

	local mediumBtn = widget.newButton{
		defaultFile="images/modal/Medium.png",
		overFile="images/modal/Medium.png",
		onRelease = medium_onBtnRelease
	}

	mediumBtn.x = bg.x
	mediumBtn.y = 190
	levelgroup:insert(mediumBtn)

	local hardBtn = widget.newButton{
		defaultFile="images/modal/Hard.png",
		overFile="images/modal/Hard.png",
		onRelease = hard_onBtnRelease	
	}
	hardBtn.x = bg.x - 5
	hardBtn.y = 250
	levelgroup:insert(hardBtn)

	local exitBtn = widget.newButton{
		defaultFile="images/modal/closebutton.png",
		overFile="images/modal/closebutton.png",
		onRelease = exit_onBtnRelease
	}
	exitBtn.x = bg.x + 115
	exitBtn.y = 67
	levelgroup:insert(exitBtn)

end

-- Function to remove about dialog -- 
function exit_about()
	aboutgroup.isVisible = false
	return true
end

function showaboutDialog(event)
	physics.pause()
 	aboutgroup = display.newGroup()

	local rectx = display.newImage("images/modal/gray.png")
 	rectx.x = display.contentCenterX;
 	rectx.y = display.contentCenterY;
 	rectx:addEventListener("touch", function() return true end)
	rectx:addEventListener("tap", function() return true end)
	aboutgroup:insert(rectx)

	local dialogx = display.newImage("images/modal/about.png")
 	dialogx.x = display.contentCenterX;
 	dialogx.y = display.contentCenterY;
 	aboutgroup:insert(dialogx)

 	local myText1 = display.newText( "Developers", display.contentCenterX-107, display.contentCenterY-35, native.systemFont, 16 )
 	myText1:setFillColor(0, 0, 0)
 	local myText = display.newText( "Balayan, Maricia Polene A.\nConoza, Vanessa Viel B.\nTolentino, Jasmine Mae M.", display.contentCenterX-60, display.contentCenterY+5, native.systemFont, 14 )
 	myText:setFillColor(0, 0, 0)
 	aboutgroup:insert(myText)
 	aboutgroup:insert(myText1)

 	local uplogo = display.newImageRect("images/uplogo.jpg", 100, 100)
 	uplogo.x = 330
 	uplogo.y = 170
 	aboutgroup:insert(uplogo)

 	local upitdc = display.newImageRect("images/upitdc.png", 200, 50)
 	upitdc.x = 200
 	upitdc.y = 220
 	aboutgroup:insert(upitdc)

 	local disclaimer = "Disclaimer: Some of the photos used for two of the games are from the following sites: www.clipartlord.com, www.freedigitalphotos.net, www.pixabay.com, www.vectorstock.com, www.clker.com, www.clipartsfree.net, and www.alloflife.com. Music used is by Kevin McLeod, owner of Incompetech.com"
 	local myText2 = display.newText( disclaimer, display.contentCenterX, display.contentHeight+40, display.contentWidth, display.contentHeight * 0.5, native.systemFont, 8 )
 	aboutgroup:insert(myText2)

	local exit = widget.newButton{
		defaultFile="images/modal/closebutton.png",
		overFile="images/modal/closebutton.png",
		onEvent = exit_about
	}
	exit.x = bg.x + 170
	exit.y = 85
	aboutgroup:insert(exit)

end

-- Function for creating scene. Rendering mainmenu -- 
function scene:createScene(event)
	storyboard.removeAll()
	local screenGroup = self.view

	bgMusic = event.params.music

	bg = display.newImageRect("images/menu/bg.png", 570, 320)
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;
	screenGroup:insert(bg)
	
	-- an image sheet with purple house
	local sheet1 = graphics.newImageSheet( "images/menu/blue.png", { width=220, height=160, numFrames=2 } )
	instance1 = display.newSprite( sheet1, { name="blue", start=1, count=2, time=1000 } )
	instance1.x = 60
	instance1.y = 210
	instance1:play()
	screenGroup:insert(instance1)
	instance1:addEventListener("tap", button1)
	
	-- an image sheet with orange house
	local sheet2 = graphics.newImageSheet( "images/menu/orange.png", { width=188, height=212, numFrames=2 } )
	instance2 = display.newSprite( sheet2, { name="orange", start=1, count=2, time=1000 } )
	instance2.x = 245
	instance2.y = 220
	instance2:play()
	screenGroup:insert(instance2)
	instance2:addEventListener("tap", button2)
	
	-- an image sheet with blue house
	local sheet3 = graphics.newImageSheet( "images/menu/purple.png", { width=158, height=212, numFrames=2 } )
	instance3 = display.newSprite( sheet3, { name="purple", start=1, count=2, time=1000 } )
	instance3.x = 420
	instance3.y = 205
	instance3:play()
	screenGroup:insert(instance3)	
	instance3:addEventListener("tap", button3)
	screenGroup: insert(instance3)
	
	howtoplay = widget.newButton{
		id = "howtoplay",
		defaultFile = "images/menu/howtoplay.png",
		overFile = "images/menu/howtoplay.png",
		emboss = true,
		onEvent = function() storyboard.gotoScene( "Instructions", "fade", 400 ); end,
	}
	howtoplay.x = (display.contentCenterX);
	howtoplay.y = (display.contentCenterY) - 100;
	screenGroup:insert(howtoplay)
	
	option =	{
		effect = "fade",
		time = 100,
		params = {
			music = bgMusic
		}
	}

	scores = widget.newButton{
		id = "scores",
		defaultFile = "images/menu/scores.png",
		overFile = "images/menu/scores.png",
		emboss = true,
		onEvent = function() storyboard.gotoScene( "Scoreboard", option); end,
	}
	scores.x = (display.contentCenterX) + 130;
	scores.y = (display.contentCenterY) - 75;
	screenGroup:insert(scores)

	about = display.newImage("images/menu/about.png", 45, 45)
	about.x = (display.contentCenterX) + 220;
	about.y = (display.contentCenterY) - 100;
	about.width = 60
	about.height = 60
	about:addEventListener("tap", showaboutDialog)
	screenGroup:insert(about)

	bg_ground = display.newImageRect("images/menu/ground2.png", 570, 320)
	bg_ground.x = display.contentCenterX;
	bg_ground.y = display.contentCenterY;
	screenGroup:insert(bg_ground)
	
	game1 = display.newText("Memory", 60, display.contentHeight-45, font, 20)
	game2 = display.newText("Search & Sort", display.contentCenterX, display.contentHeight-20, font, 20)
	game3 = display.newText("Spelling", 420, display.contentHeight-25, font, 20)
	screenGroup:insert(game1)
	screenGroup:insert(game2)
	screenGroup:insert(game3)

end

scene:addEventListener("createScene", scene)

return scene