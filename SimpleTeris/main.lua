-- 俄罗斯方块 (Tetris) 基础实现

local menu = require "menu"
local game = require "game"

local bgm

local state = "menu" -- menu/game/exit

function love.load()
    menu.load()
    if  not bgm then
        bgm = love.audio.newSource("assets/bgm.mp3", "stream")  
        bgm:setLooping(true)
        love.audio.play(bgm)
    end
end

function love.update(dt)
    if state == "menu" then
        menu.update(dt)
    elseif state == "game" then
        game.update(dt)
    end
end

function love.draw()
    if state == "menu" then
        menu.draw()
    elseif state == "game" then
        game.draw()
    end
end

function love.keypressed(key)
    if state == "menu" then
        local action = menu.keypressed(key)
        if action == "start" then
            game.load()
            state = "game"
        elseif action == "exit" then
            love.event.quit()
        end
    elseif state == "game" then
        local action = game.keypressed(key)
        if action == "menu" then
            menu.load()
            state = "menu"
        end
    end
end

