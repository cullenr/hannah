local log = require "lib.log"
local splash = require "lib.splash"

local module = {}
-- loads a complete layer into a new world and returns it.
module.loadLayer = function(data)
    local world = splash.new()
    
    for _, obj in ipairs(data.objects) do
		module.addObject(world, obj, obj.shape)
	end

    return world
end

-- add a shape to the world
module.addObject = function(world, obj, shape_name)
	local shape = false

	if shape_name == "rectangle" then
		shape = splash.aabb(obj.x, obj.y, obj.width, obj.height)
	end
	if shape_name == "polyline" then

		shape = splash.seg(
		obj.x + obj.polyline[1].x,
		obj.y + obj.polyline[1].y,
		obj.x + obj.polyline[2].x,
		obj.y + obj.polyline[2].y
		)
	end
	if shape_name == "circle" then
		shape = splash.circle(obj.x, obj.y, obj.radius)
	end

	if shape then
		log.debug("adding", obj.shape)
		world:add(obj, shape)
	else
		log.error("could not load shape", shape_name, obj)
	end

end

module.moveObject = function(world, object, x, y)
	world:move(object, x, y)
end

-- debug draw the physics world
module.draw = function(world, offset_x, offset_y, scale)
	-- TODO move this to somewhere better or use a library - maybe fun.lua
	function map(f, t)
		local t2 = {}
		for k,v in ipairs(t) do t2[k] = f(v) end
		return t2
	end
	
	local function transform(s)
		local out = map(function(v) return v * scale end, s)
		
		-- we offset the position after scaling, offsets are not scaled
		-- in this game engine
		out[1] = out[1] - offset_x 
		out[2] = out[2] - offset_y

		return unpack(out)
	end
	
	local shape_draws = {
		circle = function(s, m)
			local x, y, r = transform(s)
			love.graphics.circle(m, x, y, r)
			love.graphics.line(x, y - r, x, y)
		end,
		aabb = function(s, m)
			local x, y, w, h = transform(s)
			love.graphics.rectangle(m, x, y, w, h) 
		
		end,
		seg = function(s, m)
			local x, y, dx, dy = transform(s)
			love.graphics.line(x, y, x + dx, y + dy) 
		end
	}

	local function draw_shape(shape, mode)
		mode = mode or "line"
		shape_draws[shape.type](shape, mode)
	end

	love.graphics.setColor(255, 0, 255)
	for thing in world:iterAll() do
		draw_shape(world:shape(thing))
	end
	love.graphics.setColor(255, 255, 255)
end

return module
