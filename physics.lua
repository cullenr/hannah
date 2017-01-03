local log 		= require "lib.log"
local splash 	= require "lib.splash"

local module = {}
-- loads a complete layer into a new world and returns it.
module.loadLayer = function(data)
    local objects = {}

    for i, obj in ipairs(data.objects) do
		objects[i] = module.addObject(world, obj, obj.shape)
	end

    return objects
end

-- add a shape to the world
module.addObject = function(world, obj, shape_name)
	local shape

	if shape_name == "rectangle" then
		shape = world:rectangle(obj.x, obj.y, obj.width, obj.height)
    elseif shape_name == "polyline" then
        local points = {}

        for _, vector in ipairs(obj.polyline) do
            table.insert(points, vector.x)
            table.insert(points, vector.y)
        end
        
        shape = world:polygon(points)
    elseif shape_name == "circle" then
		shape = world:circle(obj.x, obj.y, obj.radius)
	else
        log.error("could not load shape", shape_name, obj)
	end
    
    return shape
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
