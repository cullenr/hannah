local log = require "lib.log"

local module = {}

-- helper used to make map paths in a tmx file more meaningful to love2d's file
-- handling
local function normalize_path(path)
	local np_gen1,np_gen2  = '[^SEP]+SEP%.%.SEP?','SEP+%.?SEP'
	local np_pat1, np_pat2 = np_gen1:gsub('SEP','/'), np_gen2:gsub('SEP','/')
	local k

	repeat -- /./ -> /
		path,k = path:gsub(np_pat2,'/')
	until k == 0

	repeat -- A/../ -> (empty)
		path,k = path:gsub(np_pat1,'')
	until k == 0

	if path == '' then path = '.' end

	return path
end

-- Returns an object containing:
--      tiles: An array of tilequads
--      layers: drawable layers in order
--      data: the raw map data
module.load = function(path, display, mapping, physics)
    local data = love.filesystem.load(path)()
    local map_dir = path:gsub("(.*/)(.*)", "%1")
    -- this dictionary contains a key for each tile in this map, multiple
    -- tilesets are contained within. Each value contains a reference to a
    -- sprite batch for drawing and a quad to access the correct part of the
    -- batch
    local tiles = {}

    local draw_layers = {} -- ordered list of drawable layers
    local phys_layers = {} -- physics layers

    -- load all of the tilesets into memory for this map
    for _, tileset in ipairs(data.tilesets) do
        -- correct the path to the image
        tileset.image = normalize_path(map_dir .. tileset.image)
        
        mapping.loadTileset(tileset, display, data.tilewidth, data.tileheight,
                     tiles)
    end 

    -- process all the layers in this map
    for _, layer in ipairs(data.layers) do 
        if layer.type == "imagelayer" then
            log.debug("image layer found - not implemented")
            

            -- tileset.image = normalize_path(map_dir .. layer.image)
            -- TODO add this to the draw_layers
        end
        if layer.type == "objectgroup" then
            log.debug("object group found")        
            
            local world = physics.loadLayer(layer)
            phys_layers[#phys_layers + 1] = world

        end
        if layer.type == "tilelayer" then
            log.debug("tile layer group found: " .. #draw_layers + 1)
            draw_layers[#draw_layers + 1] = layer
        end
    end
    
    return {
        total_tiles = data.width * data.height,
        size_pw = data.width * data.tilewidth,
        size_ph = data.height * data.tileheight,
        tiles = tiles,
        draw_layers = draw_layers,
        phys_layers = phys_layers,
        data = data
    }
end

return module
