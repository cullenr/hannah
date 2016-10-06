return {
  version = "1.1",
  luaversion = "5.1",
  tiledversion = "0.14.2",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 10,
  height = 10,
  tilewidth = 24,
  tileheight = 24,
  nextobjectid = 7,
  properties = {},
  tilesets = {
    {
      name = "tileset a",
      firstgid = 1,
      tilewidth = 24,
      tileheight = 24,
      spacing = 0,
      margin = 0,
      image = "../images/tileset-a.png",
      imagewidth = 72,
      imageheight = 96,
      tileoffset = {
        x = 0,
        y = 0
      },
      properties = {},
      terrains = {},
      tilecount = 12,
      tiles = {}
    },
    {
      name = "pickups",
      firstgid = 13,
      tilewidth = 16,
      tileheight = 16,
      spacing = 0,
      margin = 0,
      image = "../images/pickups.png",
      imagewidth = 32,
      imageheight = 32,
      tileoffset = {
        x = 4,
        y = -4
      },
      properties = {},
      terrains = {},
      tilecount = 4,
      tiles = {}
    }
  },
  layers = {
    {
      type = "imagelayer",
      name = "Background",
      x = 0,
      y = 0,
      visible = true,
      opacity = 1,
      image = "../images/slime.png",
      properties = {}
    },
    {
      type = "tilelayer",
      name = "Tile Layer 1",
      x = 0,
      y = 0,
      width = 10,
      height = 10,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        10, 8, 8, 8, 8, 8, 8, 8, 8, 6,
        10, 0, 0, 0, 0, 0, 0, 0, 0, 6,
        10, 0, 0, 0, 0, 0, 14, 0, 0, 6,
        10, 1, 2, 3, 0, 0, 0, 0, 0, 6,
        10, 0, 0, 0, 0, 0, 0, 5, 12, 6,
        10, 0, 0, 0, 0, 0, 0, 6, 10, 6,
        10, 0, 0, 0, 0, 0, 0, 6, 10, 6,
        10, 0, 0, 0, 0, 0, 5, 11, 12, 6,
        10, 5, 11, 11, 11, 11, 11, 11, 12, 6,
        10, 6, 8, 8, 8, 8, 8, 8, 10, 6
      }
    },
    {
      type = "objectgroup",
      name = "Colliders",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {
        ["collidable"] = "true"
      },
      objects = {
        {
          id = 2,
          name = "",
          type = "",
          shape = "rectangle",
          x = 0,
          y = 192,
          width = 240,
          height = 24,
          rotation = 0,
          visible = true,
          properties = {
            ["collidable"] = "true"
          }
        },
        {
          id = 3,
          name = "",
          type = "",
          shape = "rectangle",
          x = 144,
          y = 168,
          width = 72,
          height = 24,
          rotation = 0,
          visible = true,
          properties = {
            ["collidable"] = "true"
          }
        },
        {
          id = 6,
          name = "",
          type = "",
          shape = "rectangle",
          x = 24,
          y = 72,
          width = 72,
          height = 24,
          rotation = 0,
          visible = true,
          properties = {
            ["collidable"] = "true"
          }
        }
      }
    }
  }
}
