local menu = {}
local gridW, gridH = 10, 20
local cell = 24
local options = {"Start Game", "Exit Game"}
local selected = 1

function menu.load()
    bgImg = love.graphics.newImage("assets/k1.png") -- 确保图片文件存在
    love.window.setTitle("俄罗斯方块 Tetris")
    love.window.setMode(gridW*cell, gridH*cell)
    selected = 1
end

function menu.update(dt)
    -- 菜单一般不需要update内容
end

function menu.draw()
    local winW, winH = love.graphics.getWidth(), love.graphics.getHeight()
    local imgW, imgH = bgImg:getWidth(), bgImg:getHeight()
    local sx, sy = winW / imgW, winH / imgH

    -- 先重置颜色再绘制图片
    love.graphics.setColor(1,1,1)
    love.graphics.draw(bgImg, 0, 0, 0, sx, sy)

    love.graphics.setFont(love.graphics.newFont(36))
    --love.graphics.printf("Tetris", 0, 80, love.graphics.getWidth(), "center")
    love.graphics.setFont(love.graphics.newFont(24))
    for i, v in ipairs(options) do
        if i == selected then
            love.graphics.setColor(1,0.8,0.2)
        else
            love.graphics.setColor(1,1,1)
        end
        love.graphics.printf(v, 0, 200 + i*40, love.graphics.getWidth(), "center")
    end
    -- 最后可以再重置一次颜色，防止影响后续绘制
    love.graphics.setColor(1,1,1)
end

function menu.keypressed(key)
    if key == "up" then
        selected = selected - 1
        if selected < 1 then selected = #options end
    elseif key == "down" then
        selected = selected + 1
        if selected > #options then selected = 1 end
    elseif key == "return" or key == "kpenter" then
        if selected == 1 then
            return "start"
        elseif selected == 2 then
            return "exit"
        end
    end
end

return menu 