require "set_paths"


function locals()
  local variables = {}
  local idx = 1
  while true do
    local ln, lv = debug.getlocal(2, idx)
    if ln ~= nil then
      variables[ln] = lv
    else
      break
    end
    idx = 1 + idx
  end
  return variables
end


print(_VERSION)

local log = require "lib.log"
local parser = require "map-parser"
local anim8 = require "lib.anim8"

-- controllers are defined here so we can inject them where they need to bu used
local physicsCtl = require "physics"
local mappingCtl = require "mapping"

local time
local hannah
local run

local map
local display = {
    scale = 2,
    size_pw = love.graphics.getWidth(),
    size_ph = love.graphics.getHeight() 
}

love.graphics.setBackgroundColor(60, 90, 230)

function love.load(args)
    
    -- parse command line	
    for _, v in pairs(args) do
        if(v == "--verbose") then log.level = "trace" end
    end
	
    log.info("args", args, display)

    map = parser.load("assets/maps/w1l1.lua", display, mappingCtl, physicsCtl)

    love.graphics.setDefaultFilter("nearest", "nearest")
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

local view_px = 0
local view_py = 0

function love.update(dt)
    local speed = 10
	
	if love.keyboard.isDown("escape") then love.event.quit() end
    
    if love.keyboard.isDown("a", "left") then
        view_px = view_px - speed
    elseif love.keyboard.isDown("d", "right") then
        view_px = view_px + speed
    end

    if love.keyboard.isDown("w", "up") then
        view_py = view_py - speed
    elseif love.keyboard.isDown("s", "down") then
        view_py = view_py + speed
    end


    run:update(dt)
	time = time + dt;
	local factor = math.abs(math.cos(time)); --so it keeps going/repeating
	myShader:send("factor", factor)
end

function love.draw()
--	love.graphics.setShader(myShader)

    run:draw(hannah, 250, 64, 0, 1)
    mappingCtl.draw(map, view_px, view_py, display)
    physicsCtl.draw(map.phys_layers[1], view_px, view_py, display.scale)
	
--    love.graphics.setShader()
    
--    love.event.quit()
end
