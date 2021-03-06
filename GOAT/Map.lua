--[[
    Contains tile data and necessary code for rendering a tile map to the
    screen.
]]

require 'Util'

Map = Class{}

TILE_BRICK = 1
TILE_EMPTY = -1

-- cloud tiles
CLOUD_LEFT = 6
CLOUD_RIGHT = 7

-- bush tiles
BUSH_LEFT = 2
BUSH_RIGHT = 3

-- mushroom tiles
MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

-- jump block
JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9

--flag tiles
FLAG = 13
POLE1 = 8
POLE2 = 12
POLE3 =16

BLOCK = 9

-- a speed to multiply delta time to scroll map; smooth value
local SCROLL_SPEED = 62


-- constructor for our map object
function Map:init()

    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    self.sprites = generateQuads(self.spritesheet, 16, 16)
    self.music = love.audio.newSource('sounds/JJD.mp3', 'static')

    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 200
    self.mapHeight = 28
    self.tiles = {}

    -- applies positive Y influence on anything affected
    self.gravity = 15

    -- associate player with map
    self.player = Player(self)

    -- camera offsets
    self.camX = 0
    self.camY = -3

    -- cache width and height of map in pixels
    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

    -- first, fill map with empty tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            
            -- support for multiple sheets per tile; storing tiles as tables 
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    -- begin generating the terrain using vertical scan lines
    local x = 1
    while x < self.mapWidth do
        
         -- 2% chance to generate a cloud
        -- make sure we're 2 tiles from edge at least
        if x < self.mapWidth - 3 then
            if math.random(7) == 1 then
                
                -- choose a random vertical spot above where blocks/pipes generate
                local cloudStart = math.random(self.mapHeight / 2 - 10)

                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
            end

        if x > 10 and x < self.mapWidth - 5 then
            if x % 10 == 0 then
                if math.random(3) == 1 then
                    self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_TOP)
                    self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_BOTTOM)
                elseif math.random(3) == 2 then 
                    self:setTile(x, self.mapHeight / 2 - 3, MUSHROOM_TOP)
                    self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_BOTTOM)
                    self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_BOTTOM)
                else 
                    self:setTile(x, self.mapHeight / 2 - 4, MUSHROOM_TOP)
                    self:setTile(x, self.mapHeight / 2 - 3, MUSHROOM_BOTTOM)
                    self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_BOTTOM)
                    self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_BOTTOM)
                end
            end
        end

        end
        -- generate a pole
        -- make sure we're 3 tiles from edge
        if x == self.mapWidth - 3 then       
                -- choose a random vertical spot above where blocks/pipes generate
                self:setTile(x, self.mapHeight / 2 - 6, POLE1)
                self:setTile(x, self.mapHeight / 2 - 5, POLE2)
                self:setTile(x, self.mapHeight / 2 - 4, POLE2)
                self:setTile(x, self.mapHeight / 2 - 3, POLE2)
                self:setTile(x, self.mapHeight / 2 - 2, POLE2)
                self:setTile(x, self.mapHeight / 2 - 1, POLE3)

        end

        if x == self.mapWidth - 2 then
            self:setTile(x, self.mapHeight / 2 - 6, FLAG)

        end

        if   x == self.mapWidth / 2 + 2 then

            -- place bush component and then column of bricks
            
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1


        else 
            
            -- creates column of tiles going to bottom of map
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end

            -- next vertical scan line
            x = x + 1
        end
    end

    -- start the background music
    self.music:setLooping(true)
    self.music:play()
end

-- return whether a given tile is collidable
function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {
        TILE_BRICK
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
        return true 

        end
    end  

    return false
end

--Flag collidable jawn
function Map:fcollides(tile)
    -- define our collidable tiles
    local collidables = {
       FLAG,POLE1,POLE2,POLE3
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
        return true 

        end
    end  

    return false
end

--mushroom collide jawn
function Map:mcollides(tile)
    -- define our collidable tiles
    local collidables = {
        MUSHROOM_TOP, MUSHROOM_BOTTOM
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
        return true 

        end
    end  

    return false
end


-- function to update camera offset with delta time
function Map:update(dt)
    self.player:update(dt)
    
    -- keep camera's X coordinate following the player, preventing camera from
    -- scrolling past 0 to the left and the map's width
    self.camX = math.max(0, math.min(self.player.x - VIRTUAL_WIDTH / 2,
        math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, id)
    self.tiles[(y - 1) * self.mapWidth + x] = id
end


-- renders our map to the screen, to be called by main's render
function Map:render()
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.sprites[tile],
                    (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
            end
        end
    end

    self.player:render()

    

    if gameState1 then 

        love.graphics.setDefaultFilter('nearest','nearest')
        winFont = love.graphics.newFont('fonts/font.ttf', 32)
        minFont = love.graphics.newFont('fonts/font.ttf', 8)
        love.graphics.setFont(winFont)
        love.graphics.clear(225/255,140/255,0,1)
        tbl = {'graphics/Pic1.jpg','graphics/Pic2.jpg','graphics/Pic3.jpg','graphics/Pic4.jpg','graphics/Pic5.jpeg','graphics/Pic6.png','graphics/Pic7.jpg','graphics/Pic8.jpg'}
        meme = love.graphics.newImage(tbl[x])
        love.graphics.draw(meme, (self.player.x) - 200, self.mapHeight / 2 + 40)
        love.graphics.printf("You Win!", -125, self.tileHeight * ((self.mapHeight - 2) / 2) - 200 , self.player.x *2 + 30  , 'center')
        love.graphics.setFont(minFont)
        love.graphics.printf("Your won a meme as your prize! Press enter/return to exit.", -125, self.tileHeight * ((self.mapHeight - 2) / 2) - 170 , self.player.x *2 + 30  , 'center')
    
    elseif gameState2 then 
        midFont = love.graphics.newFont('fonts/font.ttf', 11)
        love.graphics.setDefaultFilter('nearest','nearest')
        winFont = love.graphics.newFont('fonts/font.ttf', 32)
        love.graphics.setFont(winFont)
        love.graphics.clear(225/255,140/255,0,1)
        love.graphics.printf("You Lost!", -10, self.tileHeight * ((self.mapHeight - 2) / 2) - 175 , self.player.x *2 + 30  , 'center')
        love.graphics.setFont(midFont)
        love.graphics.printf("Oh no! You didn't make it! You need to try again", -10, self.tileHeight * ((self.mapHeight - 2) / 2) - 120 , self.player.x *2 + 30  , 'center')
        love.graphics.printf("in order to win your special prize!", -10, self.tileHeight * ((self.mapHeight - 2) / 2) - 106 , self.player.x *2 + 30  , 'center')
        love.graphics.printf("Press enter/return to exit so you can try again.", -10, self.tileHeight * ((self.mapHeight - 2) / 2) - 92 , self.player.x *2 + 30  , 'center')
        love.graphics.setFont(winFont)
        love.graphics.printf(":(", -10, self.tileHeight * ((self.mapHeight - 2) / 2) - 69 , self.player.x *2 + 30  , 'center')


    else
        gameState1 = false
        gameState2= false
    end

end

