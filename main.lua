-- Library functions

function string:split(delimiter)
   local result = {}
   local from   = 1
   local delim_from, delim_to = string.find( self, delimiter, from    )
   while delim_from do
      table.insert( result, string.sub( self, from , delim_from-1 ) )
      from = delim_to + 1
      delim_from, delim_to = string.find( self, delimiter, from  )
   end
   table.insert( result, string.sub( self, from  ) )
   return result
end

function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

-- Global Game Variables

window = {
	width = 800,
	height = 600
}


-- Game Functions

-- Creation functions

function createPlayer()
	player = {}
	player.width = 50
	player.height = 50
	player.x = love.math.random(0, window.width - player.width)
	player.y = love.math.random(0, window.height - player.height)
	player.speed = 200

	player.color = {}

	player.color.r = 0
	player.color.g = 255
	player.color.b = 125
	player.color.a = 255
end

function createEnemy()
	enemy = {}
	enemy.width = 25
	enemy.height = 25
	enemy.speed = 75
	enemy.justCreated = true;
	enemy.createdTimer = 0

	repeat
		enemy.x = love.math.random(0, window.width - enemy.width)
		enemy.y = love.math.random(0, window.height - enemy.height)
	until not CheckCollision(player.x, player.y, player.width, player.height, enemy.x, enemy.y, enemy.width, enemy.height)

	table.insert(enemies, enemy)
end

function createCoin()
	coin = {}
	coin.radius = 10

	repeat
		coin.x = love.math.random(0, window.width - coin.radius)
		coin.y = love.math.random(0, window.height - coin.radius)
	until not CheckCollision(player.x, player.y, player.width, player.height, coin.x, coin.y, coin.radius, coin.radius)

	table.insert(coins, coin)
end

function createSave()
	if (not save) then
		save = {}
		save.highscore = 0
		save.highstage = 1
		save.loaded = false

		if (love.filesystem.exists("save.dat")) then
			local data = love.filesystem.read("save.dat")
			local part = data:split(";")

			save.highscore = tonumber(part[1])
			save.highstage = tonumber(part[2])
		end

		save.loaded = true
	end
end

function createGame()
	game = {}
	game.score = 0
	game.stage = 1
	game.timer = 0
	game.paused = false
	game.pauseTimer = 0 

	createPlayer()
	
	enemies = {}
	enemies.created = false
	createEnemy()

	enemies.color = {}
	enemies.color.r = 255
	enemies.color.g = 125
	enemies.color.b = 0
	enemies.color.a = 255
	
	coins = {}
	coins.created = false
	createCoin()
	coins.color = {}
	coins.color.r = 255
	coins.color.g = 255
	coins.color.b = 0
	coins.color.a = 255

	createSave()
end

-- Reset functions

function resetCoin(coin)
	coin.x = love.math.random(0, window.width - coin.radius);
	coin.y = love.math.random(0, window.height - coin.radius);
end

function resetGame()
	if (game.score > save.highscore) then
		save.highscore = game.score
	end

	if (game.stage > save.highstage) then
		save.highstage = game.stage
	end

	createGame()
end

-- Update functions

function updatePlayer(dt)
	if (love.keyboard.isDown("left") and player.x >= 0) then
		player.x = player.x - player.speed * dt
	elseif (love.keyboard.isDown("right") and player.x + player.width <= window.width) then
		player.x = player.x + player.speed * dt
	elseif (love.keyboard.isDown("up") and player.y >= 0) then
		player.y = player.y - player.speed * dt
	elseif (love.keyboard.isDown("down") and player.y + player.height <= window.height) then
		player.y = player.y + player.speed * dt
	end
end

function updateEnemies(dt)
	for i, enemy in ipairs(enemies) do
		if (enemy.justCreated) then
			if (enemy.createdTimer > 2) then
				enemy.justCreated = false
			else
				enemy.createdTimer = enemy.createdTimer + dt;
			end
		else

			if (CheckCollision(player.x, player.y, player.width, player.height, enemy.x, enemy.y, enemy.width, enemy.height)) then
				resetGame()
			end
		
			if (player.x < enemy.x) then
				enemy.x = enemy.x - enemy.speed * dt
			end
			
			if (player.x > enemy.x) then
				enemy.x = enemy.x + enemy.speed * dt
			end

			if (player.y < enemy.y) then
				enemy.y = enemy.y - enemy.speed * dt
			end

			if (player.y > enemy.y) then
				enemy.y = enemy.y + enemy.speed * dt
			end

			if (CheckCollision(player.x, player.y, player.width, player.height, enemy.x, enemy.y, enemy.width, enemy.height)) then
				resetGame()
			end
		end
	end
end

function updateCoins(dt)
		for i, coin in ipairs(coins) do
		if (CheckCollision(player.x, player.y, player.width, player.height, coin.x, coin.y, coin.radius, coin.radius)) then
			resetCoin(coin)
			game.score = game.score + 1
		end
	end
end

function updateGame(dt)
	if (not game.paused) then
		updatePlayer(dt)
		updateEnemies(dt)
		updateCoins(dt)

		game.timer = game.timer + dt

		if (game.timer >= 10) then
			player.speed = player.speed + 50
			
			for i, enemy in ipairs(enemies) do
				enemy.speed = enemy.speed + 25
			end

			game.stage = game.stage + 1
			game.timer = 0

			enemies.created = false
			coins.created = false
		end

		if (game.stage % 2 == 0) then
			if (not enemies.created) then
				createEnemy()
				enemies.created = true
			end

			if (not coins.created) then
				createCoin()
				coins.created = true
			end
		end
	end

	game.pauseTimer = game.pauseTimer + dt

	if (love.keyboard.isDown("escape") and game.pauseTimer > 0.25) then
		game.paused = not game.paused
		game.pauseTimer = 0
	end
end

-- Draw functions

function drawPlayer()
	love.graphics.setColor(player.color.r, player.color.g, player.color.b, player.color.a);
	love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
end

function drawEnemies()
	love.graphics.setColor(enemies.color.r, enemies.color.g, enemies.color.b, enemies.color.a)

	for i, enemy in ipairs(enemies) do
		if (enemy.justCreated) then
			love.graphics.setColor(enemies.color.r, enemies.color.g, enemies.color.b, 128)
		end
		
		love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
	end
end

function drawCoins()
		love.graphics.setColor(coins.color.r, coins.color.g, coins.color.b, coins.color.a);

	for i, coin in ipairs(coins) do
		
		love.graphics.ellipse("fill", coin.x, coin.y, coin.radius, coin.radius)
	end
end

function drawGame()
	love.graphics.setBackgroundColor(0, 125, 175, 255)

	drawPlayer()
	drawEnemies()
	drawCoins()

	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print("Score: " .. game.score, 0, 0)
	love.graphics.print("Highscore: " .. save.highscore, 0, 20)
	love.graphics.print("Stage: " .. game.stage, 0, 60)
	love.graphics.print("Highstage: " .. save.highstage, 0, 40)
	
	if (game.paused) then
		love.graphics.print("Paused", window.width / 2, window.height / 2)
	end
end

-- Love2D Functions

function love.load()
	createGame()
end

function love.update(dt)
	updateGame(dt)
end

function love.draw()
	drawGame()
end

function love.quit()
	love.filesystem.write("save.dat", save.highscore .. ";" .. save.highstage)
end