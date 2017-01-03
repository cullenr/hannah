local fun 		= require "fun"
local bit 		= require "luabit"
local physics 	= require "physics"
local system 	= tiny.processingSystem(class "PhysicsSystem")
local world 	= nil

system.filter = tiny.requireAll("shape", "physics")

function system:init(data)
   self.world = physics.init(data) 
end

function system:process(entity, dt)
    -- TODO add a box and check each shape collides with it to set their 
    -- sleeping value    
    -- checkSleep()
    
    move()

    if bit.band(collision.self.collider.mask, collision.other.collider.mask) then

    end
end

local function addShape(world, obj, shape_name)
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

local function move()
    
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

