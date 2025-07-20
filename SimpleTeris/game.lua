local game = {}

local gridW, gridH = 10, 20
local cell = 24
local timer, speed = 0, 0.5
local board = {}
-- 方块定义保持不变
local shapes = {
    -- 长条形 (I)
    {
        {{0,0},{1,0},{2,0},{3,0}},      -- 横
        {{0,0},{0,1},{0,2},{0,3}},      -- 竖
    },
    -- O (正方形)
    {
        {{1,0},{2,0},{1,1},{2,1}},
    },
    -- T
    {
        {{1,0},{0,1},{1,1},{2,1}},
        {{1,0},{1,1},{2,1},{1,2}},
        {{0,1},{1,1},{2,1},{1,2}},
        {{1,0},{0,1},{1,1},{1,2}},
    },
    -- S
    {
        {{1,0},{2,0},{0,1},{1,1}},
        {{1,0},{1,1},{2,1},{2,2}},
    },
    -- Z
    {
        {{0,0},{1,0},{1,1},{2,1}},
        {{2,0},{1,1},{2,1},{1,2}},
    },
    -- J
    {
        {{0,0},{0,1},{1,1},{2,1}},
        {{1,0},{2,0},{1,1},{1,2}},
        {{0,1},{1,1},{2,1},{2,2}},
        {{1,0},{1,1},{0,2},{1,2}},
    },
    -- L
    {
        {{2,0},{0,1},{1,1},{2,1}},
        {{1,0},{1,1},{1,2},{2,2}},
        {{0,1},{1,1},{2,1},{0,2}},
        {{0,0},{1,0},{1,1},{1,2}},
    },
}
local colors = {
    {0, 255, 255}, {255, 255, 0}, {128, 0, 128}, {0, 255, 0}, {255, 0, 0}, {0, 0, 255}, {255, 165, 0}
}

local current = {}
local gameover = false
local score = 0  -- 添加积分变量
local level = 1  -- 添加等级变量
local linesCleared = 0  -- 添加总消行数
local combo = 0  -- 连击计数器
local lastClearTime = 0  -- 上次消行时间

-- 生成新游戏板
local function newBoard()
    local b = {}
    for y=1,gridH do b[y]={} for x=1,gridW do b[y][x]=0 end end
    return b
end

-- 生成新方块
local function newBlock()
    local t = love.math.random(1, #shapes) -- random shape
    local rot = 1 -- initial rotation state
    local x, y = 4, 0 -- initial position
    return {type=t, rot=rot, x=x, y=y}
end

-- 检测移动可能性
local function canMove(b, blk, dx, dy, dr)
    local nrot = ((blk.rot-1 + dr) % #shapes[blk.type]) + 1
    local shape = shapes[blk.type][nrot]
    for _,p in ipairs(shape) do
        local nx, ny = blk.x + p[1] + dx, blk.y + p[2] + dy
        if nx < 1 or nx > gridW or ny > gridH then
            return false
        end
        if ny >= 1 and b[ny][nx] > 0 then
            return false
        end
    end
    return true
end

-- 合并方块到游戏板
local function mergeBlock(b, blk)
    local shape = shapes[blk.type][blk.rot]
    for _,p in ipairs(shape) do
        local nx, ny = blk.x + p[1], blk.y + p[2]
        if ny >= 1 and ny <= gridH then
            b[ny][nx] = blk.type
        end
    end
end

-- 消行函数（返回消行数量）
local function clearLines(b)
    local linesClearedThisTime = 0
    local newBoard = newBoard()
    local writeRow = gridH
    
    for readRow = gridH, 1, -1 do
        local full = true
        for x = 1, gridW do
            if b[readRow][x] == 0 then
                full = false
                break
            end
        end
        
        if not full then
            for x = 1, gridW do
                newBoard[writeRow][x] = b[readRow][x]
            end
            writeRow = writeRow - 1
        else
            linesClearedThisTime = linesClearedThisTime + 1
        end
    end
    
    for y = 1, gridH do
        for x = 1, gridW do
            b[y][x] = newBoard[y][x]
        end
    end
    
    return linesClearedThisTime
end

-- 计算消行得分
local function calculateScore(lines)
    local baseScore = 0
    if lines == 1 then baseScore = 100
    elseif lines == 2 then baseScore = 250
    elseif lines == 3 then baseScore = 400
    elseif lines >= 4 then baseScore = 500 + (lines - 4) * 200  -- Tetris奖励
    end
    
    -- 连击奖励
    local comboBonus = combo * 50
    if combo > 0 then combo = combo + 1 else combo = 1 end
    
    -- 速度奖励
    local speedBonus = math.floor((1 - speed) * 200)
    
    return baseScore + comboBonus + speedBonus
end

-- 加载游戏
function game.load()
    love.window.setTitle("俄罗斯方块 Tetris")
    love.window.setMode(gridW*cell + 150, gridH*cell)  -- 加宽窗口以显示信息面板
    board = newBoard()
    current = newBlock()
    timer, gameover = 0, false
    score = 0
    level = 1
    linesCleared = 0
    combo = 0
    lastClearTime = 0
end

-- 更新游戏状态
function game.update(dt)
    if gameover then return end
    
    -- 更新连击计时器
    if combo > 0 then
        lastClearTime = lastClearTime + dt
        if lastClearTime > 2.0 then  -- 2秒内无新消行重置连击
            combo = 0
        end
    end
    
    timer = timer + dt
    if timer >= speed then
        timer = 0
        if canMove(board, current, 0, 1, 0) then
            current.y = current.y + 1
        else
            mergeBlock(board, current)
            local lines = clearLines(board)
            if lines > 0 then
                -- 计算得分
                local points = calculateScore(lines)
                score = score + points
                linesCleared = linesCleared + lines
                lastClearTime = 0
                
                -- 每消10行升一级
                if linesCleared >= level * 10 then
                    level = level + 1
                    speed = math.max(0.1, speed * 0.8)  -- 速度上限为0.1秒
                end
            else
                combo = 0  -- 没有消行，重置连击
            end
            
            current = newBlock()
            if not canMove(board, current, 0, 0, 0) then
                gameover = true
            end
        end
    end
end

-- 绘制游戏界面
function game.draw()
    -- 绘制游戏区域背景
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", 0, 0, gridW*cell, gridH*cell)
    
    -- 绘制网格
    love.graphics.setColor(0.2, 0.2, 0.2)
    for x = 0, gridW do
        love.graphics.line(x * cell, 0, x * cell, gridH * cell)
    end
    for y = 0, gridH do
        love.graphics.line(0, y * cell, gridW * cell, y * cell)
    end
    
    -- 绘制已落下的方块
    for y=1,gridH do
        for x=1,gridW do
            if board[y][x]>0 then
                local c = colors[board[y][x]]
                love.graphics.setColor(c[1]/255, c[2]/255, c[3]/255)
                love.graphics.rectangle("fill", (x-1)*cell, (y-1)*cell, cell-1, cell-1)
                
                -- 方块内部高光
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.rectangle("fill", (x-1)*cell+2, (y-1)*cell+2, cell-5, cell-5)
            end
        end
    end
    
    -- 绘制当前方块
    if not gameover then
        local shape = shapes[current.type][current.rot]
        local c = colors[current.type]
        love.graphics.setColor(c[1]/255, c[2]/255, c[3]/255)
        for _,p in ipairs(shape) do
            local x = current.x + p[1]
            local y = current.y + p[2]
            if y>=1 then
                love.graphics.rectangle("fill", (x-1)*cell, (y-1)*cell, cell-1, cell-1)
                
                -- 方块内部高光
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.rectangle("fill", (x-1)*cell+2, (y-1)*cell+2, cell-5, cell-5)
            end
        end
    end
    
    -- 绘制信息面板
    local panelX = gridW * cell + 10
    love.graphics.setColor(0.15, 0.15, 0.2, 0.8)
    love.graphics.rectangle("fill", panelX, 10, 130, gridH*cell - 20)
    
    -- 绘制标题
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.printf("Tetrix", panelX, 20, 130, "center")
    
    -- 绘制分数
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(1, 1, 0.5)
    love.graphics.printf("Score", panelX, 70, 130, "center")
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(string.format("%08d", score), panelX, 95, 130, "center")
    
    -- 绘制等级
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(0.5, 1, 0.5)
    love.graphics.printf("Level", panelX, 140, 130, "center")
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(string.format("%02d", level), panelX, 165, 130, "center")
    
    -- 绘制消行数
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(0.5, 0.8, 1)
    love.graphics.printf("Cleared", panelX, 210, 130, "center")
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(string.format("%d", linesCleared), panelX, 235, 130, "center")
    
    -- 绘制连击
    if combo > 1 then
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.printf("Combo", panelX, 280, 130, "center")
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(1, 0.8, 0.8)
        love.graphics.printf(string.format("%dx Combo", combo), panelX, 305, 130, "center")
    end
    
    -- 绘制速度
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(1, 0.8, 0.5)
    love.graphics.printf("Speed", panelX, 350, 130, "center")
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(string.format("%.1fx", 1/speed), panelX, 375, 130, "center")
    
    -- 绘制游戏结束提示
    if gameover then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, gridH*cell/2-50, gridW*cell, 100)
        
        love.graphics.setFont(love.graphics.newFont(30))
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf("End Game!", 0, gridH*cell/2-40, gridW*cell, "center")
        
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("R to Restart", 0, gridH*cell/2+10, gridW*cell, "center")
    end
    
    -- 绘制操作提示
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("←→:Move  ↑:Rotate ↓:Speed Up", 0, gridH*cell-25, gridW*cell, "center")
end

-- 键盘事件处理
function game.keypressed(key)
    if key=="escape" then
        return "menu"
    end
    if gameover and (key=="r" or key=="R") then
        game.load()
        return
    end
    if gameover then return end
    
    -- 移动和旋转逻辑保持不变
    if key=="left" and canMove(board, current, -1, 0, 0) then
        current.x = current.x - 1
    elseif key=="right" and canMove(board, current, 1, 0, 0) then
        current.x = current.x + 1
    elseif key=="down" and canMove(board, current, 0, 1, 0) then
        current.y = current.y + 1
    elseif key=="up" then
        local nrot = ((current.rot)%#shapes[current.type])+1
        local test = {type=current.type, rot=nrot, x=current.x, y=current.y}
        local kicks = {
            {0,0}, {1,0}, {-1,0}, {2,0}, {-2,0}, {0,1}
        }
        for _, kick in ipairs(kicks) do
            if canMove(board, test, kick[1], kick[2], 0) then
                current.x = current.x + kick[1]
                current.y = current.y + kick[2]
                current.rot = nrot
                break
            end
        end
    end
end

return game
