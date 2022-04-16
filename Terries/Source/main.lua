import "CoreLibs/keyboard"
local gfx = playdate.graphics

gfx.setColor(gfx.kColorWhite)
safe = gfx.image.new("SystemAssets/safe.png")
success = gfx.image.new("SystemAssets/success.png")
boom = gfx.image.new("SystemAssets/boom.png")
cut = gfx.image.new("SystemAssets/cut.png")

debug = false

totalSuccesses = 0
mySeat = 1
turnCount = 0

deck = {}
hands = {}

cards = {
    BOOM = 1,
    SUCCESS = 2,
    SAFE = 3
}

function push(list, item)
    list[#list+1] = item
end

function shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

function pop(list)
    local item = list[#list]
    list[#list] = nil
    return item
end

function remove(list, index)
    local ret = list[index]
    for i = index, #list do
        list[i] = list[i+1]
    end
    return ret
end

function setupDeck(round, successes)
    round = round ~= nil and round or 1
    successes = successes ~= nil and successes or 0
    
    push(deck, cards.BOOM)
    
    for i = 1, playerCount - successes do
        push(deck, cards.SUCCESS)
    end
    
    while #deck < (6-round)*playerCount do
        push(deck, cards.SAFE)
    end
end

function deal()
    shuffle(deck)
    for i = 1,playerCount do
        hands[i] = {}
        for j = 1, 6 - currentRound do
            push(hands[i], pop(deck))
        end
    end
end

function assignRoles()
    roleDeck = {}
    if playerCount == 6 then
        push(roleDeck, 1)
        push(roleDeck, 1)
        push(roleDeck, 0)
        push(roleDeck, 0)
        push(roleDeck, 0)
        push(roleDeck, 0)
    elseif playerCount == 4 or playerCount == 5 then
        push(roleDeck, 1)
        push(roleDeck, 1)
        push(roleDeck, 0)
        push(roleDeck, 0)
        push(roleDeck, 0)
    elseif playerCount == 3 then
        push(roleDeck, 1)
        push(roleDeck, 0)
        push(roleDeck, 0)
    else
        print("invalid player count")
    end
    shuffle(roleDeck)
    role = roleDeck[mySeat]
end

menuInputHandlers = {

    upButtonDown = function()
        if cursor > 1 then
            cursor = cursor - 1
        end
    end,
    downButtonDown = function()
        if cursor < 4 then
            cursor = cursor + 1
        end
    end,
    leftButtonDown = function()
        if cursor == 2 then
            --players
            if playerCount > 3 then
                playerCount = playerCount - 1
            end
        elseif cursor == 3 then
            --seat
            if mySeat > 1 then
                mySeat = mySeat - 1
            end
        elseif cursor == 4 then
            --confirm
        else
            print("cursor too big")
        end
    end,
    rightButtonDown = function()
        if cursor == 2 then
            --players
            if playerCount < 6 then
                playerCount = playerCount + 1
            end
        elseif cursor == 3 then
            --seat
            if mySeat < playerCount then
                mySeat = mySeat + 1
            end
        elseif cursor == 4 then
            --confirm
        else
            print("cursor too big")
        end
    end,
    AButtonDown = function()
        if cursor == 1 then
            playdate.keyboard.show(randomSeed)
        elseif cursor == 4 then
            start()
        end
    end,
    BButtonDown = function()
        
    end,
}

gameInputHandlers = {
    AButtonDown = function()
        if #hands[mySeat] > 0 then
            local cutIndex = (pop(cuts) % #hands[mySeat]) + 1
            push(cutCards, remove(hands[mySeat], cutIndex))
        end
    end,
    BButtonDown = function()
        inRoundEnd = true
        playdate.inputHandlers.push(roundEndInputHandlers)
        successesThisRound = 0
        cursor = 1
    end,
    upButtonDown = function()
        turnCount = turnCount + 1
    end,
    downButtonDown = function()
        if turnCount > 0 then
            turnCount = turnCount - 1
        end
    end,
}

roundEndInputHandlers = {
    leftButtonDown = function()
        if cursor == 1 then
            successesThisRound = successesThisRound - 1
        end
    end,
    rightButtonDown = function()
        if cursor == 1 then
            successesThisRound = successesThisRound + 1
        end
    end,
    upButtonDown = function()
        if cursor > 1 then
            cursor = cursor - 1
        end
    end,
    downButtonDown = function()
        if cursor < 6 then
            cursor = cursor + 1
        end
    end,
    AButtonDown = function()
        if cursor == 2 then
            startNewRound()
        end
        if cursor == 6 then
            initialize()
        end
    end,
    BButtonDown = function()
        inRoundEnd = false
        playdate.inputHandlers.pop()
    end,
}

function initialize()
    playdate.inputHandlers.push(menuInputHandlers)
    seed = ""
    inMenu = true
    inRoundEnd = false
    totalSuccesses = 0
    role = 0
    playerCount = 3
    randomSeed = ""
    cursor = 1
    for i = 1, 4 do
        randomSeed = randomSeed..string.char(math.random(65, 90))
    end
    
    playdate.keyboard.show(randomSeed)
end

function playdate.keyboard.textChangedCallback()
    randomSeed = playdate.keyboard.text
end

function playdate.keyboard.keyboardWillHideCallback(okPressed)
    local intSeed = 0
    for i = 1, #randomSeed do
        intSeed = intSeed + math.pow(string.byte(randomSeed:sub(i, i)), i)
    end
    print("Seed: "..intSeed)
    math.randomseed(intSeed)
    cursor = cursor + 1
end

function start()
    currentRound = 1
    cuts = {}
    for i = 1, 100 do
        push(cuts, math.random(120))
    end
    cutCards = {}
    setupDeck()
    deal()
    assignRoles()
    playdate.inputHandlers.push(gameInputHandlers)
    inMenu = false
end

function startNewRound()
    currentRound = currentRound + 1
    totalSuccesses += successesThisRound
    setupDeck(currentRound, totalSuccesses)
    deal()
    inRoundEnd = false
    playdate.inputHandlers.pop()
    cutCards = {}
end

function formatMenuString(string, isSelected)
    if isSelected then
        return "["..string.."]"
    else
        return string
    end
end

function drawCard(type, x, y)
    if type == cards.BOOM then
        boom:draw(x, y)
    elseif type == cards.SUCCESS then
        success:draw(x, y)
    elseif type == cards.SAFE then
        safe:draw(x, y)
    else
        print("something went wrong, card "..i.." isn't a valid card")
    end
end

function drawGame()
    for i = 1, #hands[mySeat] do
        local x = (30 + (i-1) * 70)
        local y = 130
        drawCard(hands[mySeat][i], x, y)
    end
    
    for i = 1, #cutCards do
        local x = (30 + (i-1) * 70)
        local y = 60
        drawCard(cutCards[i], x, y)
        cut:draw(x, y)
    end
    
    if role == 0 then
        gfx.drawText("You are a SWAT", 30, 10)
    else
        gfx.drawText("You are a Terry", 30, 10)
    end
    gfx.drawText("A: cut one of my cards, B: next round.", 30, 220)
    gfx.drawText(totalSuccesses.." successes found.", 230, 10)
    gfx.drawText("Turn "..turnCount, 30, 30)
end

function drawGameDebug()
    for i = 1, #hands do
        for j = 1, #hands[i] do
            local h = i
            if h > 3 then h = h - 3 end
            local x = (10 + (h-1) * 125 + (j-1) * 17)
            local y = i > 3 and 50 or 150
            if hands[i][j] == cards.BOOM then
                boom:draw(x, y)
            elseif hands[i][j] == cards.SUCCESS then
                success:draw(x, y)
            elseif hands[i][j] == cards.SAFE then
                safe:draw(x, y)
            else
                print("something went wrong, "..hands[i][j].." isn't a valid card")
            end
        end
    end
end

function drawRoundEndModal()
    local prevColor = gfx.getColor()
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(64, 48, 273, 144)
    gfx.setColor(prevColor)
    gfx.drawRect(64, 48, 273, 144)
    gfx.drawText(formatMenuString("Successes this round: "..successesThisRound, cursor == 1), 70, 50)
    gfx.drawText(formatMenuString("Next Round", cursor == 2), 70, 70)
    gfx.drawText(formatMenuString("...", cursor == 3), 70, 90)
    gfx.drawText(formatMenuString("...", cursor == 4), 70, 110)
    gfx.drawText(formatMenuString("...", cursor == 5), 70, 130)
    gfx.drawText(formatMenuString("Restart Game", cursor == 6), 70, 150)
end

function playdate.update()
    gfx.fillRect(0, 0, 400, 240)
    if inMenu then
    --main menu
        gfx.drawText(formatMenuString("Random Seed: "..randomSeed, cursor == 1), 10, 20)
        gfx.drawText(formatMenuString("Player Count: "..playerCount, cursor == 2), 10, 40)
        gfx.drawText(formatMenuString("My Seat: "..mySeat, cursor == 3), 10, 60)
        gfx.drawText(formatMenuString("Start!", cursor == 4), 10, 80)
    else
    --gameplay
        if debug then
            drawGameDebug()
        else
            drawGame()
            if inRoundEnd then
                drawRoundEndModal()
            end
        end
    end
    
    playdate.drawFPS(0,0)
end

initialize()
