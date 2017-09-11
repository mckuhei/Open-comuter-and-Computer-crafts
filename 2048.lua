local term = require("term")
local event = require("event")
local component = require("component")
local gpu = component.gpu
local keyboard = require("keyboard")
local math = require("math")

--数字数组
local number = {"2", "4", "8", "16", "32", "64", "128", "256", "512", "1024", "2048", "4096", "8192", "16384", "32768", "65536", "131072"}
local numberScore = {2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072}

--颜色
local F = 0xF9F6F2 			--数字颜色
local bottom_1 = 0xFFFF80	--4
local bottom_2 = 0x996D40
local bottom_3 = 0xFFB600
local bottom_4 = 0xFFB680
local scoreF = 0xE5E4F0		--分数颜色
local textF = 0xF2D6A5		--文字颜色

--初始化地图
local map = {}
for i=1, 4 do
	map[i] = {0, 0, 0, 0}
end

local score = 0
local run = true
local over = false

gpu.setResolution(51, 17) --设置分辨率

function isOver()
	local zeroCount = 0
	local x, y
	for y=1, 4 do
		for x=1, 4 do
			if map[y][x] == 0 then
				zeroCount = zeroCount + 1
			end
		end
	end
	
	if zeroCount ~= 0 then
		return false
	else
		for y=1, 4 do
			for x=1, 4 do
				--上
				if y ~= 1 then
					if map[y][x] == map[y-1][x] then
						return false
					end
				end
				--下
				if y ~= 4 then
					if map[y][x] == map[y+1][x] then
						return false
					end
				end
				--左
				if x ~= 1 then
					if map[y][x] == map[y][x-1] then
						return false
					end
				end
				--右
				if x ~= 4 then
					if map[y][x] == map[y][x+1] then
						return false
					end
				end
			end
		end
	end
	return true
end

function addScore(s)
	score = score + s
end

function randomNum()
	local count = math.random()*100%2 + 1
	count, _ = math.modf(count/1)
	local x, y, z
	local zeroCount = 0
	local randomTable = {}
	for y=1, 4 do
		for x=1, 4 do
			if map[y][x] == 0 then
				zeroCount = zeroCount + 1
				randomTable[zeroCount] = {y, x}
			end
		end
	end
	z = math.random()*100%zeroCount+1
	z, _ = math.modf(z/1)
	map[randomTable[z][1]][randomTable[z][2]] = count
end

function newGame()
	for i=1, 4 do
		map[i] = {0, 0, 0, 0}
	end
	score = 0
	over = false
end

function getData(arr)
	local r, m, nextI
	r = 1
	while r <= 4 do
		nextI = -1
		m=r+1
		while m <= 4 do
			if arr[m] ~= 0 then
				nextI = m
				break
			end
			m = m+1
		end
	
		if nextI ~= -1 then
			if arr[r] == 0 then
				arr[r] = arr[nextI]
				arr[nextI] = 0
				r = r - 1
			elseif arr[r] == arr[nextI] then
				arr[r] = arr[r] + 1
				addScore(numberScore[arr[r]])
				arr[nextI] = 0
			end
		end
		r = r+1
	end
	return arr
end

function Lmatrix(m)
	local n = {}
	for i=1, 4 do
		n[i] = {0, 0, 0, 0}
	end
	for y=1, 4 do
		for x=1, 4 do
			n[5-x][y] = m[y][x]
		end
	end
	return n
end

function move(dir)
	local i
	
	if dir == "UP" then
		map = Lmatrix(map)
		for i=1, 4 do
			map[i] = getData(map[i])
		end
		map = Lmatrix(map)
		map = Lmatrix(map)
		map = Lmatrix(map)
	end
	
	if dir == "DOWN" then
		map = Lmatrix(map)
		map = Lmatrix(map)
		map = Lmatrix(map)
		for i=1, 4 do
			map[i] = getData(map[i])
		end
		map = Lmatrix(map)
	end
	
	if dir == "LEFT" then
		for i=1, 4 do
			map[i] = getData(map[i])
		end
	end
	
	if dir == "RIGHT" then
		map = Lmatrix(map)
		map = Lmatrix(map)
		for i=1, 4 do
			map[i] = getData(map[i])
		end
		map = Lmatrix(map)
		map = Lmatrix(map)
	end
	
	if isOver() then
		over = true
	else
		randomNum()
	end
end

function Debug()
	for y=1, 4 do
		for x=1, 4 do
			gpu.set(38+x*2, 4+y, tostring(map[y][x]))
			gpu.set(41, 9, "Debug")
		end
	end
end

function eventListener(_, _, _, keyCode)
	--上键
	if keyCode == 200 then
		move("UP")
	end
	--下键
	if keyCode == 208 then
		move("DOWN")
	end
	--左键
	if keyCode == 203 then
		move("LEFT")
	end
	--右键
	if keyCode == 205 then
		move("RIGHT")
	end
	--Q键
	if keyCode == 16 then
		event.ignore("key_down", eventListener)
		gpu.setBackground(0x000000)
		gpu.setForeground(0xFFFFFF)
		gpu.setResolution(160, 50)
		term.clear()
		run = false
	end
	
	--空格
	if keyCode == 57 then
		newGame()
	end
end

function colF(color, x, y, str)
	gpu.setForeground(0x000000 + color)
	gpu.set(x, y, ""..str)
	gpu.setForeground(0xFFB600)
end

function printNum()
	local backGround = 0x000000
	local str = ""
	local z = 0
	for mapY=1, 4 do
		for mapX=1, 4 do
			if map[mapY][mapX] == 0 then
				backGround = bottom_1
				str = ""
			else
				backGround = bottom_3
				str = number[map[mapY][mapX]]
			end
			if map[mapY][mapX] >= 1 and map[mapY][mapX] <= 3 then
				z = 2
			end
			if map[mapY][mapX] >= 4 and map[mapY][mapX] <= 6 then
				z = 1
			end
			if map[mapY][mapX] >= 7 and map[mapY][mapX] <= 9 then
				z = 0
			end
			if map[mapY][mapX] >= 10 and map[mapY][mapX] <= 13 then
				z = 0
			end
			if map[mapY][mapX] >= 14 and map[mapY][mapX] <= 16 then
				z = -1
			end
			if map[mapY][mapX] >= 17 then
				z = -2
			end
			gpu.setBackground(backGround)
			gpu.fill((mapX-1)*8+3, (mapY-1)*4+2, 6, 3, " ")
			colF(F, (mapX-1)*8+4+z, (mapY-1)*4+3, str)
		end
	end
end

function printScore()
	gpu.setBackground(bottom_2)
	gpu.fill(38, 2, 11, 3, " ")
	colF(textF, 40, 3, score)
end

function printMap()
	gpu.setBackground(bottom_2)
	gpu.fill(1, 1, 34, 17, " ")
	gpu.setBackground(bottom_4)
	gpu.fill(35, 1, 17, 17, " ")
	
	printNum()
	printScore()
	
	gpu.setBackground(bottom_2)
	colF(textF, 41, 14, "  ^  ")
	colF(textF, 39, 15, " <     > ")
	colF(textF, 39, 10, " NewGame ")
	colF(textF, 39, 11, " <Space> ")
	if over then
		gpu.set(39, 6, "GAME OVER")
	end
end

randomNum()
randomNum()
event.listen("key_down", eventListener)
--执行循环
while run do
	term.clear()
	printMap()
	--Debug()
	os.sleep(0.1)
end
