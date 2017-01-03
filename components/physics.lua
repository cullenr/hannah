local Physics = class "Physics"

function Physics:init(vx, vy, bounce, friction)
    self.vx = vx or 0
    self.vy = vy or 0
    self.bounce = bounce or 0
    self.friction = friction or 0
    self.mask
end

return Physics
