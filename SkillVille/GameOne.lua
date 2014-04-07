------- Requirements ---------
MultiTouch = require("dmc_multitouch");
local storyboard = require ("storyboard")
local widget = require( "widget" )
local timer = require("timer")
local physics = require("physics")
local lfs = require("lfs")
local stopwatch = require("stopwatch")
local toast = require("toast")
local scene = storyboard.newScene()

------- Global Variables ---------
--for the blackboard
--local screenGroup
--for the timer and reloading
local timerr, timerText, blinker
--for reloading params
local currTime, boolFirst, currScore, category, option
--for the pause screen
local pausegroup
--for the gameover screen
local gameovergroup, round, score, gameover
--for backend
local rand, dimensions, order, current, answer
local obj, objectGroup
local r, g, b
--for analytics
local roundNumber, correctCtr, roundSpeed, pauseCtr, profileName, profileAge
--for after modal
local levelgroup
local name, email, age, namedisplay, agedisplay -- forward reference (needed for Lua closure)
local userAge, username, emailaddress, latestId
local isClick, numOfBlinks

local roundToDisplay
local isPaused = false
------- Load sounds ---------
local incorrectSound = audio.loadSound("music/incorrect.mp3")
local correctSound = audio.loadSound("music/correct.mp3")
local one = audio.loadSound("music/1.mp3")
local two = audio.loadSound("music/2.mp3")
local three = audio.loadSound("music/3.mp3")
local four = audio.loadSound("music/4.mp3")
local five = audio.loadSound("music/5.mp3")

------- Load font ---------
local font
if "Win" == system.getInfo( "platformName" ) then
    font = "Cartwheel"
elseif "Android" == system.getInfo( "platformName" ) then
    font = "Cartwheel"
end

---------- DB FUNCTIONS ---------------------------------
------- Load DB ---------
local path = system.pathForFile("JaVaMiaDb.sqlite3", system.ResourceDirectory)
db = sqlite3.open( path )
--save score
function insertToDB(category, score, name, age, timestamp, pausectr)
	local query = [[INSERT INTO GameOne VALUES (NULL, ']] .. 
	category .. [[',']] ..
	score .. [[',']] ..
	name .. [[',']] ..
	timestamp .. [[',']] ..
	pausectr.. [[',']] ..
	age.. [[');]]
	db:exec(query)
	for row in db:nrows("SELECT id FROM GameOne order by id desc") do
		return row.id
	end
end

--save analytics
function insertAnalyticsToDB(gameid, roundid, roundscore, roundspeed)
	local query = [[INSERT INTO GameOneAnalytics VALUES (NULL, ']] .. 
	gameid .. [[',']] ..
	roundid .. [[',']] ..
	roundscore .. [[',']] ..
	roundspeed .. [[');]]
	db:exec(query)
end

function saveProfile(dbname, dbage)
	local query = [[INSERT INTO Profile VALUES (NULL, ']] .. 
	dbname .. [[',']] ..
	dbage .. [[');]]
	db:exec(query)
	for row in db:nrows("UPDATE GameOne SET name ='" .. dbname .. "' where id = '" .. latestId .. "'") do end
	for row in db:nrows("UPDATE GameOne SET age ='" .. dbage .. "' where id = '" .. latestId .. "'") do end
end

---------------------------------------------------------

--------- FUNCTIONS FOR STRING MANIPULATIONS ------------
-- position in str to be replaced with ch
function replace_char (pos, str, ch)
	if (pos == 1) then return ch .. str:sub(pos+1)
	elseif (pos == str:len()) then return str:sub(1, str:len()-1) .. ch
	else return str:sub(1, pos-1) .. ch .. str:sub(pos+1)
	end
end

function get_char (pos, str)
	return str:sub(pos, pos)
end

function swap_char (pos1, pos2, str)
	local temp1 = get_char(pos1, str)
	local temp2 = get_char(pos2, str)
	str = replace_char(pos1, str, temp2)
	str = replace_char(pos2, str, temp1)
	return str
end

--------------- TIMER: RUNTIME FUNCTION --------------------

local function onFrame(event)
	if (timerr ~= nil) then
   		timerText.text = timerr:toRemainingString()
   		local done = timerr:isElapsed()
 		local secs = timerr:getElapsedSeconds()
   		if(done) then
   			Runtime:removeEventListener("enterFrame", onFrame)
   			objectGroup:removeSelf()
	    	gameoverdialog()
		end
	end  

end

--------------------------- EMAIL RESULTS -----------------------------
local function onSendEmail( event )
	local options =
	{
	   to = "",
	   subject = "SkillVille: Game 1 Memory Single Assessment",
	   body = "<html>Attached is the assessment for the most recently played Memory Game.<br>Name: "..username.text.."<br>Age: "..userAge.text.."</html>",
	   attachment = { baseDir=system.DocumentsDirectory, filename="SkillVille - Game 1 Memory Single Assessment.txt", type="text" },
	   isBodyHtml = true
	}
	native.showPopup("mail", options)
end

-----------------------FUNCTIONS FOR GETTING NAME ------------------------------------

function closedialog()
	username = display.newText(name.text, 190, 100, font, 20)
	username.isVisible = false
	userAge = display.newText(age.text, 190, 100, font, 20)
	userAge.isVisible = false

	if username.text == "" or userAge.text == "" then
		toast.new("Please enter your information.", 1000, 80, -105, "toastText")
	else
		levelgroup.isVisible = false
		name.isVisible = false
		age.isVisible = false
		saveProfile(username.text, userAge.text)
		queryAndSaveToFile(latestId)
	end
end

local function nameListener( event )
	if(event.phase == "began") then
	elseif(event.phase == "editing") then
	elseif(event.phase == "ended") then
		name.text = event.target.text
	end
end

local function ageListener( event )
	if(event.phase == "began") then
	elseif(event.phase == "editing") then
	elseif(event.phase == "ended") then
		age.text = event.target.text
	end
end

function showUserDialog()
 	levelgroup = display.newGroup()

	local rect = display.newImage("images/modal/gray.png")
 	rect.x = display.contentCenterX;
 	rect.y = display.contentCenterY;
 	rect:addEventListener("touch", function() return true end)
	rect:addEventListener("tap", function() return true end)
	levelgroup:insert(rect)

	local dialog = display.newImage("images/modal/saveanalytics.png")
 	dialog.x = display.contentCenterX;
 	dialog.y = display.contentCenterY;
 	levelgroup:insert(dialog)

   	namelabel = display.newText("Kid's name", display.contentCenterX, 100, font, 25)
	namelabel:setFillColor(0,0,0)
	name = native.newTextField( display.contentCenterX, 130, 220, 40 )    -- passes the text field object
    name.hintText= ""
   	name.text = name.hintText
   	levelgroup:insert(namelabel)
   	levelgroup:insert(name)

   	agelabel = display.newText("Kid's Age", display.contentCenterX, 165, font, 25)
   	agelabel:setFillColor(0,0,0)
	age = native.newTextField( display.contentCenterX, 200, 100, 40 )    -- passes the text field object
   	age.inputType = "number"
   	age.hintText = ""
   	age.text = age.hintText
   	levelgroup:insert(agelabel)
   	levelgroup:insert(age)

   	--checkbutton
	okay = widget.newButton{
		id = "okay",
		defaultFile = "images/buttons/submit_button.png",
		fontSize = 15,
		emboss = true,
		onEvent = closedialog
	}
	okay.x = 350; okay.y = 235
	levelgroup:insert(okay)

   	name:addEventListener( "userInput", nameListener)
	age:addEventListener( "userInput", ageListener)
end


--------------  FUNCTION FOR GO BACK TO MENU --------------------
function home(event)
	if(event.phase == "ended") then
		gameovergroup.isVisible = false
		gameover.isVisible = false
		scoreToDisplay.isVisible = false
		roundToDisplay.isVisible = false
		timerText.isVisible =false
  		storyboard.removeScene("GameOne")
  		storyboard.removeScene("MainMenu")

  		audio.stop()
  		mainMusic = audio.loadSound("music/MainSong.mp3")
		backgroundMusicChannel = audio.play( mainMusic, { loops=-1}  )

		option =	{
			effect = "fade",
			time = 100,
			params = {
				music = backgroundMusicChannel
			}
		}
		storyboard.gotoScene("MainMenu", option)
  		return true
  	end
end

------------------------ FINAL MENU --------------------------------

local function finalmenu()
	gameovergroup = display.newGroup()

	local playBtn = display.newImage("images/buttons/playagain_button.png", 140, display.contentCenterY+30)
    playBtn:addEventListener("touch", restart_onBtnRelease)
    gameovergroup:insert(playBtn)

    local playtext = display.newText(" PLAY\nAGAIN", 140, display.contentCenterY+75, font, 20) 
    playtext:setFillColor(0,0,0)
    gameovergroup:insert(playtext)

    local homeBtn = display.newImage("images/buttons/home_button.png", 240, display.contentCenterY+30)
   	homeBtn:addEventListener("touch", home)
    gameovergroup:insert(homeBtn)

    local hometext = display.newText("BACK TO\n  MENU", 240, display.contentCenterY+75, font, 20) 
    hometext:setFillColor(0,0,0)
    gameovergroup:insert(hometext)

    local emailBtn = display.newImage("images/buttons/email_button.png", 340, display.contentCenterY+30)
    emailBtn:addEventListener("touch", onSendEmail)
    gameovergroup:insert(emailBtn)
    
    local emailtext = display.newText(" EMAIL\nRESULTS", 342, display.contentCenterY+75, font, 20) 
    emailtext:setFillColor(0,0,0)
    gameovergroup:insert(emailtext)

    screenGroup:insert(gameovergroup)
end
------------------- GAME OVER ---------------------------

function moveBG(self,event)
	if(self.x == 240) then
		Runtime:removeEventListener("enterFrame", gameover)
		finalmenu()
		showUserDialog()
		timerr = nil
	else
		self.x = self.x - (self.speed)
	end
end

function queryAndSaveToFile(id)
	local report = ""
	report = report .. "------------------------------------------------------------"
	report = report .. "\nGAME 1 ANALYTICS\n"
	report = report .. "------------------------------------------------------------\n"
	report = report .. "The following information contains the analytics for the most recently played game Game 1: Memory (BLUE HOUSE).\n\n"

	for row in db:nrows("SELECT * FROM GameOne ORDER BY id DESC") do
		report = report .. "GAME # " .. row.id .."\n\nPlayer: ".. row.name.."\nAge: "..row.age.."\nCategory : "..row.category.."\nTimestamp: "..row.timestamp.. "\nPause count: " .. row.pausecount.."\nFinal Score: "..row.score.."\nNumber of rounds: "..roundNumber
		for row in db:nrows("SELECT * FROM GameOneAnalytics where gamenumber = '"..row.id.."'") do
			report = report .. "\n\nROUND "..row.roundnumber .. "\nRound time: "..row.speed.." second/s" .. "\nRound score: "..row.score
		end
		break
	end

	-- Save to file
	local path = system.pathForFile( "SkillVille - Game 1 Memory Single Assessment.txt", system.DocumentsDirectory )
	local file = io.open( path, "w" )
	file:write( report )
	io.close( file )
	file = nil
end

function gameoverdialog()
	-- ANALYTICS ----------------------
	local date = os.date( "%m" ) .. "-" .. os.date( "%d" ) .. "-" .. os.date( "%y" )
	local time = os.date( "%I" ) .. ":" .. os.date( "%M" ) .. os.date( "%p" )
	local timeStamp = date .. ", " .. time
	--save to DB
	latestId = insertToDB(category, currScore, profileName, profileAge, timeStamp, pauseCtr)
	--per round
	for i = 1, roundNumber do
		-- if last
		if tonumber(correctCtr[i]) > 0 and tonumber(roundSpeed[i]) == 0 then
			roundSpeed[i] = currTime - roundSpeed[i]
		end
		--save to db
		insertAnalyticsToDB(latestId, i, correctCtr[i], roundSpeed[i])
	end

	-------------------
	objectGroup:removeSelf()
	exitBtn:removeSelf()
	gameover = display.newImage( "images/game_one/gameover.png", 700, display.contentCenterY-10 )
	gameover.speed = 5

	gameover.enterFrame = moveBG
    Runtime:addEventListener("enterFrame", gameover)

    screenGroup:insert(gameover)
end

 --------------- RESTART GAME ----------------------
function restart_onBtnRelease()
	if category == "easy" then
		currTime = 62
	elseif category == "medium" then
		currTime = 122
	elseif category == "hard" then
		currTime = 182
	end
	option = {
		effect = "fade",
		time = 1000,
		params = {
			categ = category,
			first = true,
			time = currTime,
			score = 0
		}
	}
	audio.stop()
	Runtime:removeEventListener("touch", gestures)
	Runtime:removeEventListener("accelerometer", gestures)
	storyboard.gotoScene("ReloadGameOne", option)
end

---------------- EXIT FROM PAUSE ----------------
function exitGame(event)
	timerr = nil
	timerText.isVisible =false

	audio.stop()
	mainMusic = audio.loadSound("music/MainSong.mp3")
	backgroundMusicChannel = audio.play( mainMusic, { loops=-1}  )

	option =	{
		effect = "fade",
		time = 100,
		params = {
			music = backgroundMusicChannel
		}
	}
	storyboard.removeScene("GameOne")
	storyboard.gotoScene("MainMenu", option)
end

function shuffle(array)
	for i = 1, #array*2 do
		local a = math.random(#array)
		local b = math.random(#array)
		array[a], array[b] = array[b], array[a]
	end
	return array
end

function canClick()
	if timerr ~= nil then
		local done = timerr:isElapsed()
		if(not done) then
			toast.new("images/go.png", 300, display.contentCenterX, display.contentCenterY, "go")
		end
		isClick = true
	end
end

local function playBlink(event)
	if timerr ~= nil then
		local p1 = event.source.params.p1
		n = string.byte(order,p1) % 96
		obj = objectGroup[n]
		transition.to( obj, {time = 200, alpha = 0} )
		
		if (n % 5 == 0) then
			audio.play(one)
		elseif (n % 5 == 1) then
			audio.play(two)
		elseif (n % 5 == 2) then
			audio.play(three)
		elseif (n % 5 == 3) then
			audio.play(four)
		elseif (n % 5 == 4) then
			audio.play(five)
		end

		transition.to( obj, {delay = 200, time = 200, alpha = 1} )
		if p1 == numOfBlinks then
			timer.performWithDelay( 800, canClick )
		end
	end
end


local function startSequence(last)
	numOfBlinks = last
	isClick = false
	for i = 1, last do
		blinker = timer.performWithDelay(i*750, playBlink, 1)
		blinker.params = { p1 = i }
		current = i
	end
end


------------------CREATE SCENE: MAIN -----------------------------
function scene:createScene(event)
	print("SFLSKFLSDK")
	muted = 0
	profileName = "Default" --temp
	profileAge = 4 --temp
	isClick = false
	--get passed parameters from previous scene
	category = event.params.categ
	currScore = event.params.score
	currTime = event.params.time
	boolFirst = event.params.first

	-- Start timerr
	timerr = stopwatch.new(currTime)
	screenGroup = self.view

	if category == 'easy' then
		dimensions = 2
	elseif category == 'medium' then
		dimensions = 3
	elseif category == 'hard' then
		dimensions = 4
	end

	correctCtr = {}
	roundSpeed = {}

	if(boolFirst) then
		roundNumber = 1
		correctCtr[1] = 0
		roundSpeed[1] = 0
		pauseCtr = 0
	else
		roundNumber = event.params.roundctr
		correctCtr = event.params.correctcount
		correctCtr[roundNumber] = 0
		roundSpeed = event.params.roundspeed
		roundSpeed[roundNumber] = 0
		pauseCtr = event.params.pausecount
	end

	-- Screen Elements
	--bg
	width = 550; height = 320;
	imageCategory = math.random(5)
	local filename = "images/game_one/game3bg.png"
	if (imageCategory == 1) then
		filename = "images/game_one/bg/bg_garden.png"
	elseif (imageCategory == 2) then
		filename = "images/game_one/bg/bg_kitchen.png"
	elseif (imageCategory == 3) then
		filename = "images/game_one/bg/bg_clouds.png"
	elseif (imageCategory == 4) then
		filename = "images/game_one/bg/bg_teaparty.png"
	elseif (imageCategory == 5) then
		filename = "images/game_one/bg/bg_night.png"
	end

	bg = display.newImageRect(filename, width, height)
	bg.x = display.contentCenterX;
	bg.y = display.contentCenterY;
	screenGroup:insert(bg)

	rect = display.newRect( 0, 0, 570, 50)
	rect:setFillColor( 0.5, 1, 0.5, 0.25 )
	rect.x = display.contentCenterX;
	rect.y = 10
	screenGroup:insert(rect)

	--score
	scoreToDisplay = display.newText("Score: "..currScore, 20, 17, font, 25 )	
	scoreToDisplay:setFillColor(0,0,0)
	screenGroup:insert(scoreToDisplay)

	--round
	roundToDisplay = display.newText("Round "..roundNumber, display.contentCenterX, 17, font, 25 )
	roundToDisplay:setFillColor(0,0,0)
	screenGroup:insert(roundToDisplay)

	--exit button
	exitBtn  = display.newImageRect( "images/exit.png", 20, 20)
	exitBtn.x = 435
	exitBtn.y = 17
	exitBtn:addEventListener("tap", exitGame)
--	exitBtn:addEventListener("touch", exitGame)
	screenGroup:insert(exitBtn)

	--timertext
	timerText = display.newText("", 480, 17, font, 25) 
	timerText:setFillColor(0,0,0)
    screenGroup:insert(timerText)

    -- GAME
	objectGroup = display.newGroup()

	order = ""
	size = 0
	if category == 'easy' then
		imageCategoryCount = 1
		size = 2
	elseif category == 'medium' then
		imageCategoryCount = 2
		size = 1.5
	elseif category == 'hard' then
		imageCategoryCount = 3
		size = 1
	end

	-- imageCategory = math.random(4) FOUND BEFORE THE BG IS SET
	x = 0
	y = 0
	local z = 0
	for i = 1, dimensions * dimensions do
		if (i % dimensions ~= 1) then
			x = x + (70*size)
		elseif(i % dimensions == 1 and i > 1) then
			x = 0
			y = y + (60*size)
		end

		local pixelWidth = 50
		local pixelHeight = 50
		if (imageCategory == 1) then
			flowerNumber = math.random(8)
			filename = "images/game_one/flowers" .. flowerNumber .. ".png"
		elseif (imageCategory == 2) then
			fruitNumber = math.random(6)
			filename = "images/game_one/fruits" .. fruitNumber .. ".png"
		elseif (imageCategory == 3) then
			cloudNumber = math.random(5)
			filename = "images/game_one/clouds" .. cloudNumber .. ".png"
			pixelWidth = 75
		elseif (imageCategory == 4) then
			teaNumber = math.random(5)
			teaTypeNumber = math.random(4)
			teaType = {"smallpot", "bigpot", "cup", "pitcher"}
			filename = "images/game_one/" .. teaType[teaTypeNumber] .. teaNumber .. ".png"
		elseif(imageCategory == 5) then
			nightNumber = math.random(10)
			filename = "images/game_one/night" .. nightNumber .. ".png"
			if(nightNumber >= 7) then
				pixelWidth = 75
			end
		end

		obj = display.newImageRect(filename, pixelWidth*size, pixelHeight*size)
		obj.x = x
		obj.y = y

		obj.name = "" .. string.char(96+i)
		objectGroup:insert(i, obj)

		obj.isVisible = false
	end

	objectGroup.anchorChildren = true
	objectGroup.x = display.viewableContentWidth/2
	objectGroup.y = display.viewableContentHeight/2 + 10

	-- SHUFFLE -------------
	-- 97 == a
	order = ""
	for i = 1, dimensions * dimensions do
		order = order .. string.char(96+i)
	end

	for i = order:len(), 2, -1 do -- backwards
		local r = math.random(i) -- select a random number between 1 and i
		order = swap_char(i, r, order) -- swap the randomly selected item to position i
	end 
	-- ---------------------
	answer = ""
	startSequence(1)

	for i = 1, dimensions*dimensions do
		obj = objectGroup[string.byte(order,i) % 96]
		obj.isVisible = true
		obj.alpha = 1
		obj:addEventListener("tap", checkanswer)
	end
	screenGroup:insert(objectGroup)

end

function checkanswer(event)
	local t = event.target
	if isClick == true then
		answer = answer .. t.name
		a,b = string.find(order, answer)

		if(string.find(order, answer) ~= nil and a == 1) then
			n = string.byte(t.name) % 96
			obj = objectGroup[n]
			transition.to( obj, {time = 200, alpha = 0} )
			if (n % 5 == 0) then
				audio.play(one)
			elseif (n % 5 == 1) then
				audio.play(two)
			elseif (n % 5 == 2) then
				audio.play(three)
			elseif (n % 5 == 3) then
				audio.play(four)
			elseif (n % 5 == 4) then
				audio.play(five)
			end

			transition.to( obj, {delay = 200, time = 200, alpha = 1} )
			
			if (a == 1 and b == current) then
				currScore = currScore + 1
				correctCtr[roundNumber] = correctCtr[roundNumber] + 1
				scoreToDisplay.text = "Score: "..currScore
				toast.new("images/correct.png", 300, display.contentCenterX, display.contentCenterY, "correct")
				roundToDisplay.text = "Round "..roundNumber
				--next!
				answer = ""
				if (current + 1 <= dimensions*dimensions) then
					startSequence(current+1)
				else
					reload()
				end
			elseif (a == 1 and b < current) then
				currScore = currScore + 1
				correctCtr[roundNumber] = correctCtr[roundNumber] + 1
				scoreToDisplay.text = "Score: "..currScore
			end
		else
			---------- HERE: HINDI NAGPPLAY BEFORE MAG RELOAD.
			---------- ALSO, PAAYOS NG TOAST BEFORE MAG RELOAD.
			audio.play(incorrectSound)
			toast.new("images/wrong.png", 80, display.contentCenterX, display.contentCenterY, "incorrect")
			reload()
		end
	end
end

function reload()
	isClick = false
	objectGroup:removeSelf()
	timerText:removeSelf()
	boolFirst = false
	roundSpeed[roundNumber] = timerr:getElapsedSeconds()
	roundNumber = roundNumber + 1
	option = {
		effect = "fade",
		time = 300,
		params = {
			categ = category,
			first = true,
			time = currTime - timerr:getElapsedSeconds(),
			score = currScore,
			first = boolFirst,
			roundctr = roundNumber,
			correctcount = correctCtr,
			roundspeed = roundSpeed,
			pausecount = pauseCtr
		}
	}
	timerr = nil
	audio.stop()
	storyboard.gotoScene("ReloadGameOne", option)
end


function scene:enterScene(event)

end

function scene:exitScene(event)

end

function scene:destroyScene(event)

end


scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)
Runtime:addEventListener("enterFrame", onFrame)
return scene