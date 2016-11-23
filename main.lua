local log = require "lib.log"
log.level = "warn"

local map = require "map-parser"
local anim8 = require "lib.anim8"
local time
local hannah
local run

local map_data
local display = {
    scale = 1,
    size_pw = love.graphics.getWidth(),
    size_ph = love.graphics.getHeight() 
}

love.graphics.setBackgroundColor(60, 90, 230)

function love.load(args)
	log.info("args", args)
    
    -- parse command line	
    for _, v in pairs(args) do
        if(v == "--verbose") then log.level = "trace" end
    end

    -- here we have some dummy data for the display
    map_data = map:load("assets/maps/test.lua", display)

    love.graphics.setDefaultFilter("nearest")
	myShader = love.graphics.newShader[[
		extern number factor = 0;
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
			vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color 
			        
			//number average = (pixel.r+pixel.b+pixel.g)/3.0;

			//pixel.r = pixel.r + (average-pixel.r) * factor;
			//pixel.g = pixel.g + (average-pixel.g) * factor;
			//pixel.b = pixel.b + (average-pixel.b) * factor; 

       		if(pixel.r > pixel.b && pixel.r > pixel.g) {   
            	pixel.r = pixel.r - factor;
			}

			return pixel;	
		}
	]]
	hannah = love.graphics.newImage("assets/images/hannah.png")
	local grid = anim8.newGrid(16, 24, hannah:getWidth(), hannah:getHeight())
	run = anim8.newAnimation(grid("4-5", 1, "1-4", 2), 0.1)
	time = 0;
end

function love.update(dt)
	run:update(dt)
	time = time + dt;
	local factor = math.abs(math.cos(time)); --so it keeps going/repeating
	myShader:send("factor", factor)
end

function love.draw()
	love.graphics.setShader(myShader)
	run:draw(hannah, 250, 100, 0, 8)
	--love.graphics.draw(hannah, 250, 100, 0, 8, 8)
	love.graphics.setShader()
    
    map:draw(map_data, 0, 0, display)

--love.event.quit(dd)
end
