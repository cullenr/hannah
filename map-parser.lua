local log = require "lib.log"

local module = {}

-- How the map tools work
--
-- Maps contain many layers which contain tiles from many tilesets. We need to
-- be able to draw tiles from different tilesets as part of the same layer. To
-- complicate this tilesets are drawn in batches so we can reduce the number of
-- expensive draw calls made, as a result each tileset has a unique batch
-- associated with it. We need to make sure that the every batch is up to date
-- for each layer before the layer is drawn. One should be aware that a batch
-- could be drawn once for each layer if each layer contains tiles associated
-- with that batch.


-- todo move this out of here - currently it is used to join the paths that the
-- map file was loaded at and the relative paths defined within the map file.
-- These paths point to assets associated with this map
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

-- load a tileset - make a dictionary of all the tiles it contains with the key
-- being that tiles id and store a reference to the batch for this tile in the
-- tiles data structude
local function load_tileset(map_dir, data, display, 
                            map_tilewidth, map_tileheight, out_tiles)
    --  load the asset for this tileset and set its sampling so we can scale it
    --  cleannly
    local image_path = normalize_path(map_dir .. data.image)
    local image = love.graphics.newImage(image_path)
    image:setFilter("nearest", "nearest")
    
    -- how many tiles are there in this tilsets image
    local tiles_accross = math.floor(data.imagewidth / data.tilewidth);
    local tiles_down = math.floor(data.imageheight / data.tileheight);
    
    -- the tile index is unique among all tilesets, luckily tiled ensures this
    -- for us.
    local tile_index = data.firstgid
    
    -- we need to know how many quads this batch will be drawing so we get the
    -- size of the screen in tiles (for this tileset - each tileset may have
    -- different size tiles)
    -- XXX note that are using tile dimensions from display, this is the global
    -- tilesize and all tiles must base their positions off these coordinates.
    local display_tw = math.floor(display.pixels_w / display.scale / 
                                  map_tilewidth)
    local display_th = math.floor(display.pixels_h / display.scale / 
                                  map_tileheight)
    
    -- a batch is created for this tileset. batches are used to draw the same
    -- texture repeatedly. NOTE that this batch is for this tilest, a layer
    -- however is allowed to contain tiles from many tilesets.
    local batch = love.graphics.newSpriteBatch(image, display_tw * display_th)
    
    log.debug("loading tileset")
    log.debug("dimensions", tiles_accross, tiles_down)

    for y = 0, tiles_down -1 do
        for x = 0, tiles_accross - 1 do 

            out_tiles[tile_index] = {
                data = data,
                batch = batch,
                quad = love.graphics.newQuad(
                        x * data.tilewidth, y * data.tileheight,
                        data.tilewidth, data.tileheight,
                        image:getWidth(), image:getHeight())
            }

            log.debug("loaded tile", tile_index)

            tile_index = tile_index + 1
        end
    end
end

-- Returns an object containing:
--      tiles: An array of tilequads
--      layers: drawable layers in order
--      data: the raw map data
function module:load(path, display)
    local data = love.filesystem.load(path)()
    local map_dir = path:gsub("(.*/)(.*)", "%1")
    log.debug("loaded map version: ", data.version)
    -- this dictionary contains a key for each tile in this map, multiple
    -- tilesets are contained within. Each value contains a reference to a
    -- sprite batch for drawing and a quad to access the correct part of the
    -- batch
    local tiles = {}

    --  this dictionary contains all of the draw layers in the order in which
    --  they are to be drawn
    local draw_layers = {}
    -- load all of the tilesets into memory for this map
    for _, tileset in ipairs(data.tilesets) do
        load_tileset(map_dir, tileset, display, data.tilewidth, data.tileheight,
                     tiles)
    end

    -- process all the layers in this map
    for _, layer in ipairs(data.layers) do 
        if layer.type == "imagelayer" then
            log.debug("image layer found - not implemented")
            -- TODO add this to the draw_layers
        end
        if layer.type == "objectgroup" then
            log.debug("object group found - not implemented")
        end
        if layer.type == "tilelayer" then
            log.debug("tile layer group found: " .. #draw_layers + 1)
            draw_layers[#draw_layers + 1] = layer
        end
    end
    -- load the tileset
    -- iterate over layers
    --      load tiles into tilelayer

    return {
        tiles = tiles,
        draw_layers = draw_layers,
        data = data
    }
end

-- we move the map and draw it all in one go - all layers are drawn when this
-- function is called, we do this so we can draw the batches directly (without 
-- using frame buffers or canvases) if we want to draw layers one at a time then
-- we would have to draw the layer to an intermediate object to preserve the
-- ordering of tiles from the source batches.
function module:draw(map, view_x, view_y, display)
    local tile_w = map.data.tilewidth
    local tile_h = map.data.tileheight
    
    -- the display dimensions in tiles
    -- note that we are using the global tilewidth and height here, not per layer
    local display_tw = math.floor(display.pixels_w / display.scale / tile_w)
    local display_th = math.floor(display.pixels_h / display.scale / tile_h)
  
	-- get the number of tiles to draw, make sure we stay in the bounds of the map	
	local draw_tw = math.min(display_tw, map.data.width)
	local draw_th = math.min(display_th, map.data.height)
 
    -- the map position in tiles
    local offset_tx = math.floor(view_x / tile_w)
    local offset_ty = math.floor(view_y / tile_h)

    -- the offset in pixels (for smooth scrolling)
    local offset_mod_px = math.fmod(view_x, tile_w)
    local offset_mod_py = math.fmod(view_y,  tile_h)
    
    -- this is a cache of tilesetBatches to be drawn for this layer    
    local batches = {}
   
    -- draw layers one at a time - we still need to draw all the batches for
    -- each layer in case that batch is used in the layer or there are animated
    -- tiles in that layer.
    for _, layer in ipairs(map.draw_layers) do
		for y = 0, draw_tw - 1 do
			for x = 0, draw_tw - 1 do
				-- add the course offset in tiles so we can get the correct region
				local layer_tx = offset_tx + x
                local layer_ty = offset_ty + y

				-- get the tile add one as we are in lua land
                local tile_index = layer_ty * layer.width + layer_tx + 1 
                local tile_id = layer.data[tile_index] 
				
	
				--log.debug("xy        ", x, y)
				--log.debug("layer_txy ", layer_tx, layer_ty)
				--log.debug("map_txy   ", offset_tx, offset_ty)
				--log.debug("tile_index", tile_index)
				--log.debug("tile_id   ", tile_id)
				--log.debug("================")
				
				--  zero means there is no tile 
				if tile_id ~= 0 then	
                    -- add one to the array as the tile_ids are 0 indexed
					local tile = map.tiles[tile_id]

					if not batches[tile.data.name] then
                        batches[tile.data.name] = tile.batch
						-- clear the batch now as we should only run this once
						tile.batch:clear()
					end

					-- where to we draw the tile in display pixels
					local tile_px = layer_tx * tile_w + tile.data.tileoffset.x;
					local tile_py = layer_ty * tile_h - tile.data.tileoffset.y;

					tile.batch:add(tile.quad, tile_px, tile_py, 0) 
				end
            end
        end

        log.debug("batches", batches)

        -- now draw all the batches we used in this layer
        for _, batch in pairs(batches) do
            print ("draw that batch", _, batch, offset_mod_px, offset_mod_py, display.scale, display.scale)
            
            batch:flush()
            love.graphics.draw(batch, offset_mod_px, offset_mod_py, 0,
                               display.scale, display.scale)
        end
    end
end

return module
