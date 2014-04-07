---------- REQUIREMENTS -------------------
MultiTouch 			= require("dmc_multitouch");
local storyboard 	= require ("storyboard")
local widget 		= require( "widget" )
local lfs 			= require("lfs")
local stopwatch 	= require("stopwatch")
local toast 		= require("toast");
local scene 		= storyboard.newScene()
-------------------------------------------

--------GLOBAL VARIABLES--------------------
--for the game
local numberOfCategories, selectedCategories
local answers, maxCount, baskets, selectedImage
--for the timer and reloading
local mainTimer, displayTimerText
--for the DB
local userAge, username, latestId
--for reloading params
local currentTime, isFirstEntry, currentScore, level, targetScore
--for sounds
local muted, muteButton, unmuteButton
--for analytics
local profileName, profileAge, pauseCount, count, roundCount
--for after modal
local name, age, displayName, displayAge -- forward reference (needed for Lua closure)

------- Load DB ---------
local path = system.pathForFile("JaVaMiaDb.sqlite3", system.ResourceDirectory)
db = sqlite3.open(path)
------- Load sounds ---------
local incorrectSound = audio.loadSound("music/incorrect.mp3")
local correctSound = audio.loadSound("music/correct.mp3")
local secondGameMusic = audio.loadSound("music/GameTwo.mp3")
local gameTwoMusicChannel
------- Load font ---------
local font
if "Win" == system.getInfo("platformName") then
    font = "Cartwheel"
elseif "Android" == system.getInfo("platformName") then
    font = "Cartwheel"
end
--------------------------------------------------- FUNCTIONS ------------------------------------------------------------------------

-- Function for the email pop-up, cannot be tested on simulator
local function onSendEmail( event )
	local options =
	{
	   to = "",
	   subject = "SkillVille: Game 2 Searching and Sorting Single Assessment",
	   body = "<html>Attached is the assessment for the most recently played Searching and Sorting game.<br>Name: "..username.text.."<br>Age: "..userAge.text.."</html>",
	   attachment = { baseDir=system.DocumentsDirectory, filename="SkillVille - Game 2 Searching and Sorting Single Assessment.txt", type="text" },
	   isBodyHtml = true
	}
	native.showPopup("mail", options)
end

-- Save game play details to DB
function insertToDB(category, score, name, age, timestamp, pausectr)
	local query = [[INSERT INTO GameTwo VALUES (NULL, ']] .. 
	category .. [[',']] ..
	score .. [[',']] ..
	name .. [[',']] ..
	timestamp .. [[',']] ..
	pausectr.. [[',']] ..
	age.. [[');]]
	db:exec(query)

	for row in db:nrows("SELECT id FROM GameTwo") do
		id = row.id
	end
	return id
end

-- Save analytics to DB
function insertAnalyticsToDB(gameid, roundid, word, category, isCorrect, speed)
	local query = [[INSERT INTO GameTwoAnalytics VALUES (NULL, ']] .. 
	gameid .. [[',']] ..
	roundid .. [[',']] ..
	word .. [[',']] ..
	category .. [[',']] ..
	isCorrect .. [[',']] ..
	speed .. [[');]]
	db:exec(query)
end

-- Generate analytics and save to text file
function saveToFile()
	report = ""
	report = report .. "------------------------------------------------------------"
	report = report .. "\nGAME 2 ANALYTICS\n"
	report = report .. "------------------------------------------------------------\n"
	report = report .. "The following information contains the analytics for the most recently played game for Game 2: Searching and Sorting (ORANGE HOUSE). Note: For Game 2, the image of the word is the basis for its category, not the meaning of the word. To complete one round, user must be able to categorize 10, 15 and 20 items respectively for each level.\n\n"

	for row in db:nrows("SELECT COUNT(*) as count FROM GameTwoAnalytics where gamenumber = '"..latestId.."'") do
		dbCount = row.count
	end

	-- If DB is empty, do not generate per round analytics
	if dbCount == 0 then
		report = report .. "GAME # " .. latestId .. "\n"
		for row in db:nrows("SELECT * FROM GameTwo where id = '" .. latestId .. "'") do
			report = report .. "\nPlayer:\t\t" .. row.name .. "\nAge:\t"..row.age.."\nCategory:\t" .. row.category .. "\nTimestamp:\t" ..row.timestamp .. "\nPause count:\t" .. row.pausecount .. "\nFinal score:\t" .. row.score
		end
	--If DB is not empty, generate per round analytics
	else
		gameNumber = {}
		for row in db:nrows("SELECT * FROM GameTwoAnalytics") do
			gameNumber[#gameNumber+1] = row.gamenumber
		end
		report = ""
		report = report .. "GAME # " .. gameNumber[#gameNumber]
		for row in db:nrows("SELECT * FROM GameTwo where id = '" .. gameNumber[#gameNumber] .. "'") do
			report = report .. "\nPlayer:\t\t" .. row.name .. "\nCategory:\t" .. row.category .. "\nTimestamp:\t" ..row.timestamp .. "\nPause count:\t" .. row.pausecount .. "\nFinal score:\t" .. row.score
		end
		allRoundNumbers = {}
		for row in db:nrows("SELECT roundnumber FROM GameTwoAnalytics WHERE gamenumber = '" .. gameNumber[#gameNumber] .. "'") do
			allRoundNumbers[#allRoundNumbers+1] = row.roundnumber
		end
		rounds = cleanArray(allRoundNumbers)

		for j = 1, #rounds do
			report = report .. "\n\nROUND "..rounds[j]
			for row in db:nrows("SELECT speed FROM GameTwoAnalytics WHERE roundnumber = '"..rounds[j].."' AND gamenumber = '"..gameNumber[#gameNumber].."'") do
				report = report .. "\nRound time: "..row.speed.." seconds"
				break
			end
			allCategories = {}
			for row in db:nrows("SELECT category FROM GameTwoAnalytics WHERE roundnumber = '"..rounds[j].."' AND gamenumber = '"..gameNumber[#gameNumber].."'") do
				allCategories[#allCategories+1] = row.category
			end
			categories = cleanArray(allCategories)

			for k = 1, #categories do
				report = report .. "\n\nCATEGORY: " .. categories[k]
				words = {}
				for row in db:nrows("SELECT word FROM GameTwoAnalytics WHERE isCorrect = '1' AND category = '"..categories[k].."' AND roundnumber = '"..rounds[j].."' AND gamenumber = '"..gameNumber[#gameNumber].."'") do
					words[#words+1] = row.word
				end
				report = report .. "\nCorrect Words: "..#words
				for w = 1, #words do
					report = report .. "\n\t"..words[w]
				end
				words = {}
				for row in db:nrows("SELECT word FROM GameTwoAnalytics WHERE isCorrect = '0' AND category = '"..categories[k].."' AND roundnumber = '"..rounds[j].."' AND gamenumber = '"..gameNumber[#gameNumber].."'") do
					words[#words+1] = row.word
				end
				report = report .. "\nIncorrect Words: "..#words
				for w = 1, #words do
					report = report .. "\n\t"..words[w]
				end
			end
		end
	end	
	-- Save to text file
	local path = system.pathForFile( "SkillVille - Game 2 Searching and Sorting Single Assessment.txt", system.DocumentsDirectory )
	local file = io.open( path, "w" )
	file:write(report)
	io.close( file )
	file = nil
end

-- Save Profile to DB
function saveProfile(dbname, dbage)
	local query = [[INSERT INTO Profile VALUES (NULL, ']] .. 
	dbname .. [[',']] ..
	dbage .. [[');]]
	db:exec(query)
	for row in db:nrows("UPDATE GameTwo SET name ='" .. dbname .. "' where id = '" .. latestId .. "'") do end
	for row in db:nrows("UPDATE GameTwo SET age ='" .. dbage .. "' where id = '" .. latestId .. "'") do end
end

-- Get name from textfield, cannot be tested on simulator
local function nameListener( event )
	if(event.phase == "began") then
	elseif(event.phase == "editing") then
	elseif(event.phase == "ended") then
		name.text = event.target.text
	end
end

-- Get age from textfield, cannot be tested on simulator
local function ageListener( event )
	if(event.phase == "began") then
	elseif(event.phase == "editing") then
	elseif(event.phase == "ended") then
		age.text = event.target.text
	end
end

-- Close profile modal
function closeDialog()
	username = display.newText(name.text, 190, 100, font, 20)
	username.isVisible = false
	userAge = display.newText(age.text, 190, 100, font, 20)
	userAge.isVisible = false

	-- SAVE TO PROFILE
	 if username.text == "" or userAge.text == "" then
	 	toast.new("Please enter your information.", 1000, 80, -105, "toastText")
	 else
		levelGroup.isVisible = false
		name.isVisible = false
		age.isVisible = false
		saveProfile(username.text, userAge.text)
		saveToFile()
	 end 
end

-- Show profile modal
function showAnalyticsDialog()
 	levelGroup = display.newGroup()

	local rect = display.newImage("images/modal/gray.png")
 	rect.x = display.contentCenterX;
 	rect.y = display.contentCenterY;
 	rect:addEventListener("touch", function() return true end)
	rect:addEventListener("tap", function() return true end)
	levelGroup:insert(rect)

	local dialog = display.newImage("images/modal/saveanalytics.png")
 	dialog.x = display.contentCenterX;
 	dialog.y = display.contentCenterY;
 	levelGroup:insert(dialog)

	displayName = display.newText("Kid's name", display.contentCenterX, 100, font, 25)
	displayName:setFillColor(0,0,0)
	name = native.newTextField( display.contentCenterX, 130, 220, 40 )    -- passes the text field object
    name.hintText= ""
   	name.text = name.hintText
   	levelGroup:insert(displayName)
   	levelGroup:insert(name)

   	displayAge = display.newText("Kid's Age", display.contentCenterX, 165, font, 25)
   	displayAge:setFillColor(0,0,0)
	age = native.newTextField( display.contentCenterX, 200, 100, 40 )    -- passes the text field object
   	age.inputType = "number"
   	age.hintText = ""
   	age.text = age.hintText
   	levelGroup:insert(displayAge)
   	levelGroup:insert(age)

	submitButton = widget.newButton{
		id = "okay",
		defaultFile = "images/buttons/submit_button.png",
		fontSize = 15,
		emboss = true,
		onEvent = closeDialog
	}
	submitButton.x = 350; submitButton.y = 235
	levelGroup:insert(submitButton)

   	name:addEventListener( "userInput", nameListener)
	age:addEventListener( "userInput", ageListener)
end

-- Show post-game over screen
local function finalMenu( )
	gameOverGroup = display.newGroup()

    displayRound = display.newText("ROUND: "..level, 0, 0, font, 15)
	displayRound.x = 150
	displayRound.y = display.contentCenterY - 120
	displayRound:setFillColor(0,0,0)
	gameOverGroup:insert(displayRound)

	displayScore = display.newText("SCORE: "..currentScore, 0, 0, font, 15)
	displayScore.x = 300
	displayScore.y = display.contentCenterY - 120
	displayScore:setFillColor(0,0,0)
	gameOverGroup:insert(displayScore)

	local playButton = display.newImage( "images/buttons/playagain_button.png")
    playButton.x = 130
    playButton.y = display.contentCenterY - 80
    playButton:addEventListener("touch", restart_onBtnRelease)
    gameOverGroup:insert(playButton)

    local displayPlayAgain = display.newText("PLAY AGAIN", display.contentCenterX-7, display.contentCenterY-80, font, 25) 
	displayPlayAgain:setFillColor(0,0,0)
    gameOverGroup:insert(displayPlayAgain)

    local homeButton = display.newImage( "images/buttons/home_button.png")
    homeButton.x = 130
    homeButton.y = display.contentCenterY - 25
    homeButton:addEventListener("touch", home)
    gameOverGroup:insert(homeButton)

    local displayHome = display.newText("BACK TO MENU", display.contentCenterX+10, display.contentCenterY-25, font, 25) 
	displayHome:setFillColor(0,0,0)
    gameOverGroup:insert(displayHome)

    local emailButton = display.newImage( "images/buttons/email_button.png")
    emailButton.x = 130
    emailButton.y = display.contentCenterY + 30
    emailButton:addEventListener("touch", onSendEmail)
    gameOverGroup:insert(emailButton)
    
    local displayEmail = display.newText("EMAIL RESULTS", display.contentCenterX+10, display.contentCenterY+30, font, 25) 
	displayEmail:setFillColor(0,0,0)
    gameOverGroup:insert(displayEmail)

    screenGroup:insert(gameOverGroup)
end

-- Game over sprite
function fallOver(event)
	if (i < 9) then
		crate = display.newImage( "images/game_two/" .. gameOverSprite:sub(i,i).. ".png" )
		crate.x = x
		crate.y = 270
		transition.to(crate, {time=1000, alpha=1})
		i = i + 1
		x = x + 60
	else
		mainTimer = nil
		finalMenu()
		showAnalyticsDialog()
	end
	screenGroup:insert(crate)
end

-- Game over: remove screen elements, and save data to DB
function gameOverDialog()
	local date = os.date( "%m" ) .. "-" .. os.date( "%d" ) .. "-" .. os.date( "%y" )
	local time = os.date( "%I" ) .. ":" .. os.date( "%M" ) .. os.date( "%p" )
	local timeStamp = date .. ", " .. time
	latestId = insertToDB(level, currentScore, profileName, profileAge, timeStamp, pauseCount)
	
	-- Remove screen elements
	displayTimerText:removeSelf()
	displayScore.isVisible = false
	pauseButton.isVisible = false
	basketGroup.isVisible = false
	gameBoardGroup.isVisible = false
	unmuteButton.isVisible = false
	muteButton.isVisible = false
	progressBar.isVisible = false
	progressBarFill.isVisible = false
	for i = 1, #images do
		images[i].isVisible = false
	end
	
	-- Launch gameover sprite	
	i = 1
	x = 20
	gameOverSprite = "GAMEOVER"
	timer.performWithDelay( 500, fallOver, 9)
end

-- Go back to main menu
function home(event)
	if(event.phase == "ended") then
		gameOverGroup.isVisible = false
		crate.isVisible = false
  		storyboard.removeScene("GameTwo")
  		storyboard.removeScene("MainMenu")

  		-- To be able to play music in main menu
  		audio.stop()
  		mainMusic = audio.loadSound("music/MainSong.mp3")
		backgroundMusicChannel = audio.play( mainMusic, { loops=-1}  )
		option = {
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

function unmuteGame(event)
	audio.resume(gameTwoMusicChannel)
	unmuteButton.isVisible = false
	muteButton.isVisible = true
	muted = 0
end

function muteGame(event)
	audio.pause(gameTwoMusicChannel)
	muteButton.isVisible = false
	unmuteButton.isVisible = true
	muted = 1
end

-- Zoom in tapped image
function zoomIn(event)
	filename = event.target.filename
	toast.new(filename, 1000, display.contentCenterX, display.contentCenterY, "toastGameTwo")
end

function pauseGame(event)
 	pauseCount = pauseCount + 1
	mainTimer:pause()
	audio.pause(gameTwoMusicChannel)
    pauseButton.isVisible = false
    showPauseDialog()
    return true
end

function resume_onBtnRelease()
	if (muted == 0) then 
		audio.resume(gameTwoMusicChannel)
	end
	pauseGroup.isVisible = false
	mainTimer:resume()
    pauseButton.isVisible = true
	return true
end
 
function restart_onBtnRelease()
	if level == "easy" then
		currentTime = 62
	elseif level == "medium" then
		currentTime = 122
	elseif level == "hard" then
		currentTime = 182
	end
	option =	{
		effect = "fade",
		time = 1000,
		params = {
			categ = level,
			first = true,
			time = currentTime,
			score = 0,
			pause = pauseCount,
			round = roundCount,
			mute = muted,
		}
	}
	audio.stop()
	Runtime:removeEventListener("enterFrame", onFrame)
	storyboard.gotoScene("ReloadGameTwo", option)
end

function exit_onBtnRelease()
	audio.stop()
	mainMusic = audio.loadSound("music/MainSong.mp3")
	backgroundMusicChannel = audio.play( mainMusic, { loops=-1}  )

	storyboard.gotoScene("MainMenu", "fade", 100, {music = backgroundMusicChannel})
end

-- Show pause modal
function showPauseDialog()
	pauseGroup = display.newGroup()
	local pausedialog = display.newImage("images/pause/pause_modal.png")
 	pausedialog.x = display.contentCenterX;
 	pausedialog.y = display.contentCenterY;
 	pausedialog:addEventListener("touch", function() return true end)
	pausedialog:addEventListener("tap", function() return true end)
	pauseGroup:insert(pausedialog)

	local resumeButton = widget.newButton{
		defaultFile="images/pause/resume_button.png",
		overFile="images/pause/resume_button.png",
		onEvent = resume_onBtnRelease -- event listener function
	}
	resumeButton.x = displayBg.x - 80
	resumeButton.y = 170
	pauseGroup:insert(resumeButton)

	local exitButton = widget.newButton{
		defaultFile="images/pause/exit_button.png",
		overFile="images/pause/exit_button.png",
		onEvent = exit_onBtnRelease -- event listener function
	}
	exitButton.x = displayBg.x + 100
	exitButton.y = 170
	pauseGroup:insert(exitButton)

	screenGroup:insert(pauseGroup)
end

-- Generate next round
function generateNew()
	roundCount = roundCount + 1
	isFirstEntry = false
	option = {
		time = 400,
		params = {
			categ = level,
			first = isFirstEntry,
			time = currentTime - mainTimer:getElapsedSeconds(),
			score = currentScore,
			pause = pauseCount,
			music = gameTwoMusicChannel,
			round = roundCount,
			mute = muted
		}
	}
	gameBoardGroup:removeSelf()
	basketGroup:removeSelf()
	displayTimerText:removeSelf()
	mainTimer = nil
	storyboard.gotoScene("ReloadGameTwo", option)
end

-- Check answer
function checkAnswer(target)
	for i = 1, numberOfCategories do
		if target.x == baskets[i].x then
			boxNumber = i
			break
		end
	end

	isCorrect = false
	for j = 1, maxCount do
		-- Answer is correct, adjust score and progress bar
		if answers[boxNumber][j] == target.label then
			toast.new("images/correct.png", 300, display.contentCenterX, display.contentCenterY, "correct")
			currentScore = currentScore + 1
			displayScore.text = "Score: "..currentScore
			isCorrect = true
			baskets[boxNumber].correctCount = baskets[boxNumber].correctCount + 1
			count = baskets[boxNumber].correctCount
			baskets[boxNumber].correctWords[count] = target.label

			audio.play(correctSound)
			targetScore = targetScore - 1
			target:removeSelf()

			progressValue = 10
			if level == 'medium' then
				progressValue = progressValue + 5
			else
				progressValue = progressValue + 10
			end
			progressBarFill.width = progressBarFill.width + (320/progressValue)
			break
		end
	end

	-- Answer is incorrect
	if isCorrect == false then
		audio.play(incorrectSound)
		toast.new("images/wrong.png", 300, display.contentCenterX, display.contentCenterY, "incorrect")
		if count == 0 then
			baskets[boxNumber].wrongCount = baskets[boxNumber].wrongCount + 1
			count = baskets[boxNumber].wrongCount
			baskets[boxNumber].wrongWords[count] = target.label					
		else
			isFirst = true
			for i = 1, #baskets[boxNumber].wrongWords do
				if baskets[boxNumber].wrongWords[i] == target.label then
					isFirst = false
					break
				end
			end
			if isFirst then
				baskets[boxNumber].wrongCount = baskets[boxNumber].wrongCount + 1
				count = baskets[boxNumber].wrongCount
				baskets[boxNumber].wrongWords[count] = target.label					
			end
		end
		-- Snap to original position
		target.x = target.initialX
		target.y = target.initialY
	end	

	-- If target round score has been achieved, generate next round
	if targetScore == 0 then
		local gameNumber = 0
		for row in db:nrows("SELECT id FROM GameTwo ORDER BY id DESC") do
			if row.id ~= nil then
				gameNumber = row.id				
				break
			end
		end
		gameNumber = gameNumber + 1

		-- Save analytics to DB
		for i = 1, numberOfCategories do
			for j = 1, #baskets[i].correctWords do
				insertAnalyticsToDB(gameNumber, roundCount, baskets[i].correctWords[j], baskets[i].label, 1, mainTimer:getElapsedSeconds())
			end
			for j = 1, #baskets[i].wrongWords do
				insertAnalyticsToDB(gameNumber, roundCount, baskets[i].wrongWords[j], baskets[i].label, 0, mainTimer:getElapsedSeconds())
			end
		end
		generateNew()
	end
end

-- If image is being dragged from original position
function dragImage (event)
	local imagePosX = {}
	local imagePosY = {}
	isMoved = false
	selectedImage = event.target
	screenGroup:insert(selectedImage)

	if event.phase == "moved" or event.phase == "ended" then
		-- Set screen boundaries
		if selectedImage.x > display.viewableContentWidth then
			selectedImage.x = display.viewableContentWidth
		elseif selectedImage.x < 0 then
			selectedImage.x = 0
		end
		if selectedImage.y > display.viewableContentHeight - 30 then
			selectedImage.y = display.viewableContentHeight - 30
		elseif selectedImage.y < 30 then
			selectedImage.y = 30
		end

		for i = 1, numberOfCategories do
			imagePosX[i] = math.abs(selectedImage.x - baskets[i].x)
			imagePosY[i] = math.abs(selectedImage.y - baskets[i].y)
		end

		-- Snap image to basket
		for i = 1, numberOfCategories do
			local initX = math.abs(selectedImage.initialX - selectedImage.x)
			local initY = math.abs(selectedImage.initialY - selectedImage.y)
			if (imagePosX[i] <= 50) and (imagePosY[i] <= 50) then
				selectedImage.x = baskets[i].x;
				selectedImage.y = baskets[i].y;
				isMoved = true
			elseif (initX <= 5) and (initY <= 5) then
				-- Snap image back to original position
				selectedImage.x = selectedImage.initialX
				selectedImage.y = selectedImage.initialY
			end
		end
	end

	-- If dragged to the basket, check the answer
	if event.phase == "ended" then
		if isMoved == true then
			checkAnswer(selectedImage)
		end
	end
	return true
end 

-- Function for setting the grid layout of the images
-- Retrieved from: https://github.com/worldstar/GridView-for-Corona-SDK
-- Modified by the developers
function drawGrid(gridX, gridY, photoArray, photoTextArray, columnNumber, paddingX, paddingY, photoWidth, photoHeight)
	local currentX = gridX
	local currentY = gridY
	images = {}
	gameBoardGroup = display.newGroup()
	fontSize = 12

	for i = 1, #photoArray do
		images[i] = display.newImageRect(photoArray[i], photoWidth, photoHeight)
		if images[i] == nil then
			images[i] = display.newImageRect("images/game_two/image.png", photoWidth, photoHeight)
			images[i].filename = "images/game_two/image.png"
			tempLabel = photoTextArray[i]
		else
			images[i].filename = photoArray[i]
			tempLabel = ""
		end
		images[i].x = currentX + 23
		images[i].y = currentY + 20
		images[i].initialX = images[i].x
		images[i].initialY = images[i].y
		images[i].label = photoTextArray[i]
		images[i]:addEventListener("tap", zoomIn)
		gameBoardGroup:insert(images[i])

		local textPosX = photoWidth/2 - (fontSize/2)*string.len(photoTextArray[i])/2
		textObject = display.newText( tempLabel, currentX + textPosX, currentY + photoHeight - 50, native.systemFontBold, fontSize )
		textObject:setFillColor( 0,0,0 )
		gameBoardGroup:insert(textObject)
		screenGroup:insert(gameBoardGroup)

		--Update the position of the next item
		currentX = currentX + photoWidth + paddingX

		if(i % columnNumber == 0) then
			currentX = gridX
			currentY = currentY + photoHeight + paddingY
		end

		MultiTouch.activate(images[i], "move", "single");
		images[i]:addEventListener(MultiTouch.MULTITOUCH_EVENT, dragImage);
	end
	screenGroup:insert(gameBoardGroup)
end

-- Generate categories for easy level: only shapes or colors
function randomizeEasy(categories)
	randomNumber = math.random(2)
	randomNumbers = {}

	colors = {3,4,5,6}
	shapes = {7,8,9}

	if randomNumber == 1 then
		-- colors
		randomNumbers[1] = math.random(#colors)
		randomNumbers[2] = math.random(#colors)
		while(randomNumbers[1] == randomNumbers[2]) do
			randomNumbers[2] = math.random(#colors)
		end
		randomNumbers[1] = colors[randomNumbers[1]]
		randomNumbers[2] = colors[randomNumbers[2]]
	else
		-- shapes
		randomNumbers[1] = math.random(#shapes)
		randomNumbers[2] = math.random(#shapes)
		while(randomNumbers[1] == randomNumbers[2]) do
			randomNumbers[2] = math.random(#shapes)
		end
		randomNumbers[1] = shapes[randomNumbers[1]]
		randomNumbers[2] = shapes[randomNumbers[2]]
	end
	return randomNumbers
end

-- Randomize categories for medium and hard
function randomizeCategory(categories)
	local numbers = {}
	for i = 1, numberOfCategories do
		-- Categories must be unique
		local unique, randomNumber
		while not unique do
			randomNumber = math.random(#categories)
	    	unique = true
		  	if level == 'medium' then
				while (randomNumber == 1 or randomNumber == 2) do
				    randomNumber = math.random(#categories)
				end
			end
	   		for k = 1, i-1 do
	      		if numbers[k] == randomNumber then
	      			unique = false
	      		end
	    	end
	  	end
	  	numbers[i] = randomNumber
	end
	return numbers
end

-- Shuffle array contents (Because built-in random function is not very random)
function shuffle(array)
	for i = 1, #array*2 do
		a = math.random(#array)
		b = math.random(#array)
		array[a], array[b] = array[b], array[a]
	end
	return array
end

-- Remove array duplicates
function cleanArray(array)
	results = {}
	ctr = 1
	for i = 1, #array do
		if ctr > 1 then
			isUnique = true
			for j = 1, #results do
				if array[i] == results[j] then
					isUnique = false
				end
			end
			if isUnique then
				results[ctr] = array[i]
				ctr = ctr + 1
			end
		else
			results[ctr] = array[i]
			ctr = ctr + 1
		end
	end
	return results
end

-- Fetch words from the DB
local function getWords(type, limit)
	dbFields = {}
	dbValues = {}
	for i = 1, #selectedCategories do
		if selectedCategories[i] == 1 or selectedCategories[i] == 2 then
			dbFields[i] = "livingThingCategory"
			dbValues[i] = values[selectedCategories[i]]
		elseif selectedCategories[i] >= 3 and selectedCategories[i] <= 6 then
			dbFields[i] = "colorCategory"
			dbValues[i] = values[selectedCategories[i]]
		elseif selectedCategories[i] >= 7 and selectedCategories[i] <= 9 then
			dbFields[i] = "shapeCategory" 
			dbValues[i] = values[selectedCategories[i]]			
		elseif selectedCategories[i] == 10 then
			dbFields[i] = "animalCategory"
			dbValues[i] = values[selectedCategories[i]]
		elseif selectedCategories[i] == 11 then
			dbFields[i] = "bodyPartCategory"
			dbValues[i] = values[selectedCategories[i]]				
		end
	end

	--Query database: get correct words
	answers = {}
	correctWords = {}
	for i = 1, #dbFields do
	    answers[i] = {}
	    j = 1
		for row in db:nrows("SELECT * FROM Words where "..dbFields[i].." = '".. dbValues[i] .. "'") do
			answers[i][j] = row.name
			j = j + 1
		end
	end

	for row in db:nrows("SELECT COUNT(*) as count FROM Words where livingThingCategory = '0'") do
		maxCount = row.count
	end

	-- Remove duplicates
	correctWords[1] = answers[1][1]
	for i = 1, #dbFields do
		for j = 1, maxCount do
			isUnique = true
			for k = 1, #correctWords do
				if answers[i][j] == correctWords[k] then
					isUnique = false
				end
			end
			if isUnique == true and answers[i][j] ~= nil then
				correctWords[#correctWords+1] = answers[i][j]
			end
		end
	end

	if type == "correct" then
		words = correctWords
	--Query database: get extra words
	elseif type == "incorrect" then
		words = {}
		for i = 1, #dbFields do
			ctr = 1
			for row in db:nrows("SELECT * FROM Words where "..dbFields[i].." = '-1'") do
				isUnique = true
				if ctr == 1 then
					for row in db:nrows("SELECT * FROM Words where "..dbFields[1].." = '-1'") do
						words[1] = row.name
					end
				else
					-- Remove duplicates
					for j = 1, #words-1 do
						if row.name == words[j] then
							isUnique = false
						end
					end
					-- Remove correct words
					for j = 1, #correctWords do
						if row.name == correctWords[j] then
							isUnique = false
						end
					end
					if isUnique == true then
						words[#words+1] = row.name
					end
				end
				ctr = ctr + 1
			end
		end
	end

	-- Shuffle and select n words
	wordsCopy = {}
	wordsCopy = shuffle(words)
	for i = 1, limit do
		words[i] = wordsCopy[i]
	end

	return words
end

-- Timer function
local function onFrame(event)
	if (mainTimer ~= nil) then
   		displayTimerText.text = mainTimer:toRemainingString()
   		local done = mainTimer:isElapsed()
 		local secs = mainTimer:getElapsedSeconds()

   		if(done) then
	   		Runtime:removeEventListener("enterFrame", onFrame)
	    	gameOverDialog()
		end
	end  
end

function displayScreenElements()
	--bg
	width = 550; height = 320;
	displayBg = display.newImageRect("images/game_two/game2bg.png", width, height)
	displayBg.x = display.contentCenterX;
	displayBg.y = display.contentCenterY;
	screenGroup:insert(displayBg)
	--score
	displayScore = display.newText("Score: "..currentScore, 15, 12, font, 25 )	
	displayScore:setFillColor(0,0,0)
	screenGroup:insert(displayScore)
	--time
	displayTimerText = display.newText("", 482, 12, font, 25) 
	displayTimerText:setFillColor(0,0,0)
	screenGroup:insert(displayTimerText)
	--pause button
	pauseButton = display.newImageRect( "images/game_two/pause.png", 20, 20)
    pauseButton.x = 438
    pauseButton.y = 12
    pauseButton:addEventListener("touch", pauseGame)
    pauseButton:addEventListener("tap", pauseGame)
    screenGroup:insert( pauseButton )
    --unmute button
    unmuteButton = display.newImageRect( "images/game_two/mute_button.png", 20, 20)
    unmuteButton.x = 415
    unmuteButton.y = 12
	unmuteButton:addEventListener("touch", unmuteGame)
    unmuteButton:addEventListener("tap", unmuteGame)
    screenGroup:insert( unmuteButton )
    unmuteButton.isVisible = false
    --mute button
	muteButton = display.newImageRect( "images/game_two/unmute_button.png", 20, 20)
    muteButton.x = 415
    muteButton.y = 12
    muteButton:addEventListener("touch", muteGame)
    muteButton:addEventListener("tap", muteGame)
    screenGroup:insert( muteButton )
    --outer rectangle
    progressBar = display.newRect(display.contentCenterX, 10, 322, 15)
    -- progressBar:setReferencePoint(display.BottomLeftReferencePoint)
    progressBar.strokeWidth = 1
    progressBar:setStrokeColor( 0, 0, 0) 
    progressBar:setFillColor( 0, 0, 0 )  
    screenGroup:insert( progressBar )
    --inner rectangle which fills up
    progressBarFill = display.newRect(display.contentWidth/6 + 1, 10, 0, 10)
    progressBarFill:setFillColor(0.2 , 0.8, 0.12)
    progressBarFill.anchorX = 0
    screenGroup:insert( progressBarFill )
end

function generateBaskets()
	basketGroup = display.newGroup()
	baskets = {}
	basketSize = 50

	if level == 'easy' then
		selectedCategories = randomizeEasy(allCategories)
	else
		selectedCategories = randomizeCategory(allCategories)
	end

	for i = 1, numberOfCategories do
		baskets[i] = display.newImageRect("images/game_two/"..allCategories[selectedCategories[i]].. ".png", 150, 100)
		baskets[i].label = allCategories[selectedCategories[i]]
		baskets[i].correctCount = 0
		baskets[i].wrongCount = 0
		baskets[i].correctWords = {}
		baskets[i].wrongWords = {}
		basketGroup:insert(baskets[i])
	end

	if level == 'easy' then
		baskets[1].x = width/4; baskets[1].y = 290
		baskets[2].x = width/4 + (4*basketSize); baskets[2].y = 290	
		numberOfCorrectAnswers = 14
		numberOfIncorrectAnswers = 10
		gridX = width/7
	elseif level == 'medium' then
		baskets[1].x = width/3 - (2*basketSize) + 20; baskets[1].y = 290
		baskets[2].x = width/3 + basketSize + 10; baskets[2].y = 290
		baskets[3].x = width/3 + (3*basketSize) + 40; baskets[3].y = 290
		numberOfCorrectAnswers = 17
		numberOfIncorrectAnswers = 15
		gridX = width/22
	else
		baskets[1].x = width/4 - (2*basketSize) + 10; baskets[1].y = 290
		baskets[2].x = width/4 + basketSize - 15; baskets[2].y = 290
		baskets[3].x = width/4 + (3*basketSize) + 10; baskets[3].y = 290
		baskets[4].x = width/4 + (5*basketSize) + 30; baskets[4].y = 290
		numberOfCorrectAnswers = 24
		numberOfIncorrectAnswers = 16
		gridX = -30
	end
	screenGroup:insert(basketGroup)
end

function generateImages()
	allWords = getWords("correct", numberOfCorrectAnswers)
	allExtras = getWords("incorrect", numberOfIncorrectAnswers)

	labels = {}
	length = numberOfCorrectAnswers + numberOfIncorrectAnswers	
	for i = 1, numberOfCorrectAnswers do
		labels[i] = allWords[i]
	end
	for i = numberOfCorrectAnswers+1, length do
		labels[i] = allExtras[i - numberOfCorrectAnswers]
	end
	labels = shuffle(labels)

	photos = {}
	for i = 1, length do
		photos[i] = "images/pictures/"..labels[i]..".png"
	end

	--gridX, gridY, photoArray, photoTextArray, columnNumber, paddingX, paddingY, photoWidth, photoHeight
	drawGrid(gridX, 30, photos, labels, length/4, 5, 5, 50, 50)
end

------------------CREATE SCENE: MAIN -----------------------------
function scene:createScene(event)

	-- Parameters from previous scene
	isFirstEntry = event.params.first
	level = event.params.categ
	currentScore = event.params.score
	currentTime = event.params.time
	pauseCount = event.params.pause
	roundCount = event.params.round

	-- Temporary Profile
	profileName = "Default"
	profileAge = 4
	count = 0

	-- Start timer
	mainTimer = stopwatch.new(currentTime)
	screenGroup = self.view
	displayScreenElements()
	
	-- Set game parameters
	allCategories = {"living", "nonliving", "red", "green", "blue", "yellow", "triangle", "rectangle", "circle", "animal", "bodypart"}
	values = {"1", "0", "red", "green", "blue", "yellow", "triangle", "rectangle", "circle", "1", "1"}

	if level == 'easy' then
		targetScore = 10
		numberOfCategories = 2
	elseif level == 'medium' then
		targetScore = 15
		numberOfCategories = 3
	else
		targetScore = 20
		numberOfCategories = 4
	end

    if isFirstEntry then
		muted = 0
		gameTwoMusicChannel = audio.play( secondGameMusic, { loops=-1}  )
		pauseCount = 0
		roundCount = 1
	else
		muted = event.params.mute
		if muted == 1 then
			muteGame()
		else
			gameTwoMusicChannel = event.params.music
			audio.resume(gameTwoMusicChannel)
		end
		pauseCount = event.params.pause
		roundCount = event.params.round
	end
    
    generateBaskets()
    generateImages()
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)
Runtime:addEventListener("enterFrame", onFrame)

return scene