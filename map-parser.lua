local parser = {}

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
function normalize_path(path)
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
local function load_tileset(map_dir, data, display, out_tiles)
    --  load the asset for this tileset and set its sampling so we can scale it
    --  cleannly
    local image_path = normalize_path(map_dir .. data.image)
    image = love.graphics.newImage(image_path)
    image:setFilter("nearest", "linear")
    
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
    local display_tw = math.floor(display.px / display.scale / display.tilewidth)
    local display_th = math.floor(display.py / display.scale / display.tileheight)
    
    -- a batch is created for this tileset. batches are used to draw the same
    -- texture repeatedly. NOTE that this batch is for this tilest, a layer
    -- however is allowed to contain tiles from many tilesets.
    local batch = love.graphics.newSpriteBatch(image, display_tw * display_th)

    for x = 0, tiles_accross do 
        for y = 0, tiles_down do
            out_tiles[tile_index] = {
                batch = batch,
                quad = love.graphics.newQuad(x * data.tilewidth,
                                             y * data.tileheight,
                                             data.tilewidth,
                                             data.tileheight,
                                             image:getWidth(),
                                             image:getHeight())
            }
        end
    end
end

-- load the map at the path and return a data object representing this map
function parser:load(path)
    local data = love.filesystem.load(path)()
    local map_dir = path:gsub("(.*/)(.*)", "%1")
    print(data.version)
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
        load_tileset(map_dir, tileset, {scale = 1, px=320, py=240}, tiles)
    end

    -- process all the layers in this map
    for _, layer in ipairs(data.layers) do 
        if layer.type == "imagelayer" then
            print("image layer found - not implemented")
            -- TODO add this to the draw_layers
        end
        if layer.type == "objectgroup" then
            print("object group found - not implemented")
        end
        if layer.type == "tilelayer" then
            draw_layers[#draw_layers + 1] = layer
        end
    end
    -- load the tileset
    -- iterate over layers
    --      load tiles into tilelayer

    return map {
        tiles = tiles,
        layers = layers,
        data = data
    }
end

-- we move the map and draw it all in one go - all layers are drawn when this
-- function is called, we do this so we can draw the batches directly (without 
-- using frame buffers or canvases) if we want to draw layers one at a time then
-- we would have to draw the layer to an intermediate object to preserve the
-- ordering of tiles from the source batches.
function draw(map, offset_x, offset_y, display)
    -- note that we are using the global tilewidth and height here, not per
    -- layer.
    local display_tw = math.floor(display.px / display.scale / map.data.tilewidth)
    local display_th = math.floor(display.py / display.scale / map.data.tileheight)
   
    -- draw layers one at a time
    for _, layer in ipairs(map.draw_layers) do
        for x=0, display_tw -1 do
            for y=0, display_th -1 do

--                local map_tx = layer.data
--                 local tileid = map.tiles[map[x+math.floor(mapX)][y+math.floor(mapY)]],                tilesetBatch:add(
--                x*tileSize, y*tileSize)
            end
        end

    end
  -- clear all batches
  --tilesetBatch:clear()
 --flush all tilesets
  --tilesetBatch:flush()
end

return parser
