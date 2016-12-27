local log = require "lib.log"

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
local module = {}


-- load a tileset - make a dictionary of all the tiles it contains with the key
-- being that tiles id and store a reference to the batch for this tile in the
-- tiles data structure
--
-- @data the raw data to be loaded
-- @display contains information about the main display (used for scaling)
-- @map_tilewidth|height the tile width and height for the map itself
module.loadTileset = function(data, display, map_tilewidth, map_tileheight, out)
    
    -- out can be an existing object, carful, name clashes will be overwritten
    out = out or {}
                            
    --  load the asset for this tileset and set its sampling so we can scale it
    --  cleannly
    local image = love.graphics.newImage(data.image)
    -- these filters are set as a default elsewhere however not setting them
    -- here too will result in lines around textures on debian:intel
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
    local display_tw = math.floor(display.size_pw / display.scale / 
                                  map_tilewidth)
    local display_th = math.floor(display.size_ph / display.scale / 
                                  map_tileheight)
    
    -- a batch is created for this tileset. batches are used to draw the same
    -- texture repeatedly. NOTE that this batch is for this tilest, a layer
    -- however is allowed to contain tiles from many tilesets.
    local batch = love.graphics.newSpriteBatch(image, display_tw * display_th)
    
    log.debug("loading tileset")
    log.debug("dimensions", tiles_accross, tiles_down)

    for y = 0, tiles_down -1 do
        for x = 0, tiles_accross - 1 do 

            out[tile_index] = {
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

    return out
end


-- we move the map and draw it all in one go - all layers are drawn when this
-- function is called, we do this so we can draw the batches directly (without 
-- using frame buffers or canvases) if we want to draw layers one at a time then
-- we would have to draw the layer to an intermediate object to preserve the
-- ordering of tiles from the source batches.
module.draw = function(map, view_x, view_y, display)
    local tile_w = map.data.tilewidth
    local tile_h = map.data.tileheight
    
    -- the display dimensions in tiles
    -- note that we are using the global tilewidth and height here, not per layer
    local display_tw = math.floor(display.size_pw / display.scale / tile_w)
    local display_th = math.floor(display.size_ph / display.scale / tile_h)
  
	-- get the number of tiles to draw, make sure we stay in the maps bounds - 
    -- NOTE that we add 1 to the display_tx here as we want to draw an extra
    -- tile if we are able to scroll, the extra tiles allows us to draw
    -- partially offscreen tiles
	local draw_tw = math.min(display_tw + 1, map.data.width)
	local draw_th = math.min(display_th + 1, map.data.height)
    
    -- calculate the maximum x and y tiles we can draw this map from (we draw
    -- from top left coordinates, so if the screen is 10x10 and the map is 12x15
    -- then the values would be 2, 5)
    local max_tx = map.data.width - draw_tw
    local max_ty = map.data.height - draw_th

    -- the map position in tiles 
	-- NOTE that we calculate the tile width scaled
	-- by the display so that we can keep the view_x|y seperate from scale - 
	-- if we just scaled the offset itself we would not be able to scroll 32
	-- pixels of a 16 pixel image at display.scale 2.
    local offset_tx = math.floor(view_x / (tile_w * display.scale))
    local offset_ty = math.floor(view_y / (tile_h * display.scale)) 
    
    -- limit this postition so that the view stays within the drawable area
    offset_tx = math.min(max_tx, math.max(offset_tx, 0))
    offset_ty = math.min(max_ty, math.max(offset_ty, 0))

    -- the offset in pixels (for smooth scrolling)
    local offset_mod_px = math.fmod(view_x, tile_w * display.scale)
    local offset_mod_py = math.fmod(view_y, tile_h * display.scale)
    
    -- if the map is smaller than the display then centre it in the middle of
    -- the display by setting the offset mod accordingly
    if map.size_pw * display.scale < display.size_pw then
        offset_mod_px = offset_mod_px + (display.size_pw - map.size_pw) * 0.5 
    end

    if map.size_ph * display.scale < display.size_ph then
        offset_mod_py = offset_mod_py + (display.size_ph - map.size_ph) * 0.5 
    end
    
    -- TODO make this more efficient once this drawing functionality is complete
    -- stop the map jitering as we try to scroll over its bounds
    if offset_mod_px < 0 or offset_tx == max_tx then offset_mod_px = 0 end
    if offset_mod_py < 0 or offset_ty == max_ty then offset_mod_py = 0 end

    -- this is a cache of tilesetBatches to be drawn for this layer    
    local batches = {}
   
    -- draw layers one at a time - we still need to draw all the batches for
    -- each layer in case that batch is used in the layer or there are animated
    -- tiles in that layer.
    for _, layer in ipairs(map.draw_layers) do
        for y = 0, draw_th - 1 do
            for x = 0, draw_tw - 1 do
				-- add the course offset in tiles so we can get the correct region
				local layer_tx = offset_tx + x
                local layer_ty = offset_ty + y

				-- get the tile add one as we are in lua land
                local tile_index = layer_ty * layer.width + layer_tx + 1 
                local tile_id = layer.data[tile_index] 
			    
                -- TODO remove this debug code and the goto statement

                if tile_index > map.total_tiles then
                    log.error("Error drawing tile")
                    log.error("xy        ", x, y)
                    log.error("layer_txy ", layer_tx, layer_ty)
                    log.error("map_txy   ", offset_tx, offset_ty)
                    log.error("tile_index", tile_index)
                    log.error("tile_id   ", tile_id)
    
                    love.event.quit()
                    goto fail
                -- zero means there is no tile 
                elseif tile_id ~= 0 then	
                    -- add one to the array as the tile_ids are 0 indexed
					local tile = map.tiles[tile_id]

					if not batches[tile.data.name] then
                        batches[tile.data.name] = tile.batch
						-- clear the batch now as we should only run this once
						tile.batch:clear()
					end

					-- where to we draw the tile in display pixels
					local tile_px = x * tile_w + tile.data.tileoffset.x;
					local tile_py = y * tile_h - tile.data.tileoffset.y;

		            tile.batch:add(tile.quad, tile_px, tile_py, 0) 
				end
            end
        end

        -- now draw all the batches we used in this layer
        for _, batch in pairs(batches) do
            
            batch:flush()
            love.graphics.draw(batch, -offset_mod_px, -offset_mod_py, 0,
                               display.scale, display.scale)
        end
    end
    ::fail::
end

return module 
