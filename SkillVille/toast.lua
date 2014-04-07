--------
-- Corona-Toast-Notifications
-- by PitchBlackCat
----
-- Retrieved from: https://github.com/PitchBlackCat/Corona-Toast-Notifications
-- Modified by Developers
--------
module(..., package.seeall)

local trueDestroy;
local bg;

function trueDestroy(toast)
    if bg ~= nil then
        bg.setVisible = false
    end
    toast:removeSelf();
    toast = nil;
end

function new(pText, pTime, xcoord, ycoord, game)

    local text = pText or "nil";
    local pTime = pTime;
    local toast = display.newGroup();

    if game == "toastText" then 
        toast.text                      = display.newText(toast, pText, xcoord + 5, ycoord, native.systemFont, 12);
        toast.text.align                = "center"
        toast.background                = display.newRoundedRect( toast, xcoord, - 105, toast.text.width + 20, toast.text.height + 20, 16 );
        toast.background.strokeWidth    = 4
        toast.background:setFillColor(0.28, 0.25, 0.28)
        toast.background:setStrokeColor(0.38, 0.35, 0.38)
        toast.text:toFront();
        toast.text:setFillColor(1,1,1)
        toast.x = display.contentWidth * .5
        toast.y = display.contentHeight * .9
    elseif game == "toastGameTwo" then
        bg = display.newImage( text )
        bg.xScale = bg.xScale * 1.5
        bg.yScale = bg.yScale * 1.5
        rect = display.newImage("images/modal/gray.png")
        toast:insert(rect)
        toast:insert(bg)
        toast:insert(bg)
        toast.anchorChildren = true
        toast.x = display.contentCenterX
        toast.y = display.contentCenterY
    else
        bg = display.newImage( text, 10, 10 )
        toast:insert(bg)
        toast.x = xcoord
        toast.y = ycoord
    end

    toast.alpha = 0;
    toast.transition = transition.to(toast, {time=150, alpha = 1});

    if pTime ~= nil then
        timer.performWithDelay(pTime, function() destroy(toast) end);
    end

    return toast;
end

function destroy(toast)
    toast.transition = transition.to(toast, {time=150, alpha = 0, onComplete = function() trueDestroy(toast) end});
end