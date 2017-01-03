local fun 		= require "fun"
local bit 		= require "luabit"
local physics 	= require "physics"
local system 	= tiny.processingSystem(class "PhysicsSystem")
local world 	= nil

system.filter = tiny.requireAll("shape", "physics")

function system:init(data)
   world = physics.init(data) 
end

function system:process(entity, dt)

--[[
    local geom = entity.geometry
    local vel = entity.velocity
    local col = entity.colliider

    for _, world in ipairs(worlds) do
        -- TODO change this to moveExt so we can handle trigger collisions
        -- TODO change this to the physics.moveExt version
        geom.x, geom.y, collisions = physics.move(entity, 
                                 geom.x + vel.x + dt, geom.y + vel.y * dt, 
                                 col.filter)

		for _, collision in ipairs(collisions) do
			if bit.band(collision.self.collider.mask, collision.other.collider.mask)
			then

			end
		end
    end
]]--
end

local function addShape(world, obj, shape_name)
	local shape = false

	if shape_name == "rectangle" then
		shape = world:rectangle(obj.x, obj.y, obj.width, obj.height)
	end
	if shape_name == "polyline" then
        shape = world:polygon()

		shape = splash.seg(
		obj.x + obj.polyline[1].x,
		obj.y + obj.polyline[1].y,
		obj.x + obj.polyline[2].x,
		obj.y + obj.polyline[2].y
		)
	end
	if shape_name == "circle" then
		shape = world:circle(obj.x, obj.y, obj.radius)
	end

	if not shape then
		log.error("could not load shape", shape_name, obj)
	end
    
    return shape
end



function system:onAdd(entity)
    local geom = entity.geometry
    
    physics.add(world, geometry, geometry.shape)
end

function filter(e1, e2)
    local function case(e1, e2, f1, f2)
        return (e1[f1] and e2[f2]) or (e1[f2] and e2[e1])
    end
    
    -- swao this for a mask, its easier to check for errors and we can just make
    -- a limit to the number of layers there are for a physics layers.
    case(e1, e2 "isHero", "isStatic") 

end

