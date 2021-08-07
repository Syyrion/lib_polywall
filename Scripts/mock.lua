u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")
print("!! WARNING !! mock.lua is deprecated and will be removed on Dec. 1 2021.\nNo further updates will be given to this script.\nPlease migrate code to use master.lua.")

--[[ Mock Class ]]--
-- An abstract class of which MockPolygon and MockPlayer inherit from

Mock = {}
Mock.__index = Mock

-- Sets the angle of a mock object
function Mock:setAngle(a) self.angle = a or 0 end

-- Returns the angle of a mock object
function Mock:getAngle() return self.angle end

-- Sets the polar transfromation of a mock object
function Mock:setTransPolar(tp) self.transPolar = type(tp) == 'function' and tp or function(r, a) return r, a end end

-- Returns the polar transfromation of a mock object
function Mock:getTransPolar() return self.transPolar end

-- Sets the cartesian transformation of a mock object
function Mock:setTransCartesian(tc) self.transCartesian = type(tc) == 'function' and tc or function(x, y) return x, y end end

-- Returns the cartesian transformation of a mock object
function Mock:getTransCartesian() return self.transCartesian end

--[[ Mock Class ]]--





--[[ Mock Polygon Class ]]--
-- Creates fake polygons that somewhat resemble the center polygon

MockPolygon = {}
MockPolygon.__index = MockPolygon
setmetatable(MockPolygon, Mock)

-- Creates a new MockPolygon
function MockPolygon:new(tp, tc, s, a, r, w, cR, cG, cB, cA, bR, bG, bB, bA)
    local newInst = {}
	setmetatable(newInst, self)

	newInst.cap, newInst.border = {}, {}
	newInst:setRadius(r)
	newInst:setWeight(w)
	newInst:setAngle(a)
	newInst:setSides(s)
	newInst:setTransPolar(tp)
	newInst:setTransCartesian(tc)
	newInst:shade(cR, cG, cB, cA, bR, bG, bB, bA)

	return newInst
end

-- Sets the radius of the polygon
function MockPolygon:setRadius(r) self.radius = r or 58 end

-- Returns the radius of the polygon
function MockPolygon:getRadius() return self.radius end

-- Sets the thickness of the polygon's border (extended inwards from the radius)
-- Must be between 0 and the radius
function MockPolygon:setWeight(w) self.weight = w and clamp(w, 0, self.radius) or 4 end

-- Returns the thickness of the polygon's border
function MockPolygon:getWeight() return self.weight end

-- Replaces the polygon with a new one with a new amount of sides
function MockPolygon:setSides(s)
	s = s and math.max(s, 3) or l_getSides()
	self.sides = s
	self:del()
	self.cap, self.border = {}, {}
	for i = 1, self.sides do
		table.insert(self.cap, cw_createNoCollision())
		table.insert(self.border, cw_createNoCollision())
	end
end

-- Returns the number of sides the current polygon has
function MockPolygon:getSides() return self.sides end

-- Deletes all custom walls. Must be run before deleting the class or else cw handles will be lost
function MockPolygon:del()
	for k, v in pairs(self.cap) do
		cw_setVertexPos4(v, 0, 0, 0, 0, 0, 0, 0, 0)
		cw_destroy(v)
	end
	for k, v in pairs(self.border) do
		cw_setVertexPos4(v, 0, 0, 0, 0, 0, 0, 0, 0)
		cw_destroy(v)
	end
end

-- Updates the shape and location of the polygon
-- The third parameter of a transformation function is the vertex index which is detailed below
-- The fourth parameter of a transformation function is the section type ('border' or 'cap')
--          bV3.____________________.bV2
--              \     'border'     /
--       cV3/bV0.\________________/.cV2/bV1
--                \              /
--   CCW  <<       \   'cap'    /       >> CW
--                  \          /
--                   \        /
--                cV0.\______/.cV1 <- Normally these points are both at radius 0, meaning they're located at the same position

function MockPolygon:update(...)
	local r0, r1, range = self.radius - self.weight, self.radius, math.tau / self.sides
	for i = 1, self.sides do
		local a0, a1 = (i - 0.5) * range, (i + 0.5) * range

		local rC0, aC0 = self.transPolar(0, a0, 0, 'cap', ...)
		local rC1, aC1 = self.transPolar(0, a1, 1, 'cap', ...)
		local rC2, aC2 = self.transPolar(r0, a1, 2, 'cap', ...)
		local rC3, aC3 = self.transPolar(r0, a0, 3, 'cap', ...)
		local rB0, aB0 = self.transPolar(r0, a0, 0, 'border', ...)
		local rB1, aB1 = self.transPolar(r0, a1, 1, 'border', ...)
		local rB2, aB2 = self.transPolar(r1, a1, 2, 'border', ...)
		local rB3, aB3 = self.transPolar(r1, a0, 3, 'border', ...)

		local xC0, yC0 = self.transCartesian(rC0 * math.cos(aC0), rC0 * math.sin(aC0), 0, 'cap', ...)
		local xC1, yC1 = self.transCartesian(rC1 * math.cos(aC1), rC1 * math.sin(aC1), 1, 'cap', ...)
		local xC2, yC2 = self.transCartesian(rC2 * math.cos(aC2), rC2 * math.sin(aC2), 2, 'cap', ...)
		local xC3, yC3 = self.transCartesian(rC3 * math.cos(aC3), rC3 * math.sin(aC3), 3, 'cap', ...)
		local xB0, yB0 = self.transCartesian(rB0 * math.cos(aB0), rB0 * math.sin(aB0), 0, 'border', ...)
		local xB1, yB1 = self.transCartesian(rB1 * math.cos(aB1), rB1 * math.sin(aB1), 1, 'border', ...)
		local xB2, yB2 = self.transCartesian(rB2 * math.cos(aB2), rB2 * math.sin(aB2), 2, 'border', ...)
		local xB3, yB3 = self.transCartesian(rB3 * math.cos(aB3), rB3 * math.sin(aB3), 3, 'border', ...)

		cw_setVertexPos4(self.cap[i], xC0, yC0, xC1, yC1, xC2, yC2, xC3, yC3)
		cw_setVertexPos4(self.border[i], xB0, yB0, xB1, yB1, xB2, yB2, xB3, yB3)
	end
end

-- Updates the cap color of the polygon
function MockPolygon:shadeCap(R, G, B, A)
	if not (R and G and B and A) then R, G, B, A = s_getCapColorResult() end
	for i = 1, self.sides do
		cw_setVertexColor4Same(self.cap[i], R, G, B, A)
	end
end

-- Updates the border color of the polygon
function MockPolygon:shadeBorder(R, G, B, A)
	if not (R and G and B and A) then R, G, B, A = s_getMainColor() end
	for i = 1, self.sides do
		cw_setVertexColor4Same(self.border[i], R, G, B, A)
	end
end

-- Union of the shade cap and shade border functions
function MockPolygon:shade(cR, cG, cB, cA, bR, bG, bB, bA)
	self:shadeCap(cR, cG, cB, cA)
	self:shadeBorder(bR, bG, bB, bA)
end

-- Union of the update and shade functions
function MockPolygon:draw(cR, cG, cB, cA, bR, bG, bB, bA, ...)
	self:shade(cR, cG, cB, cA, bR, bG, bB, bA)
	self:update(...)
end
--[[ End Mock Polygon Class ]]--




--[[ Mock Player Class ]]--
-- Creates fake players

MockPlayer = {}
MockPlayer.__index = MockPlayer
setmetatable(MockPlayer, Mock)

function MockPlayer:new(tp, tc, d, h, w, a, R, G, B, A)
	local newInst = {}
	setmetatable(newInst, self)

	newInst.handle = cw_createNoCollision()
	newInst:setDistance(d)
	newInst:setHeight(h)
	newInst:setWidth(w)
	newInst:setAngle(a)
	newInst:setTransPolar(tp)
	newInst:setTransCartesian(tc)
	newInst:shade(R, G, B, A)

	return newInst
end

-- Sets the distance the player is from the center
function MockPlayer:setDistance(d) self.distance = d or 80 end

-- Returns the distance the player is from the conter
function MockPlayer:getDistance() return self.distance end

-- Sets the height of the player (the height of the triangle)
function MockPlayer:setHeight(h) self.height = h or 11 end

-- Returns the height of the player (the height of the triangle)
function MockPlayer:getHeight() return self.height end

-- Sets the width of the player (the base width of the triangle)
function MockPlayer:setWidth(w) self.width = w or 22 end

-- Returns the width of the player (the base width of the triangle)
function MockPlayer:getWidth() return self.width end

-- Returns the cw handle of player (there's only one)
function MockPlayer:getHandle() return self.handle end

-- Deletes the associated cw. Must be run before deleting the class or else cw handles will be lost
function MockPlayer:del()
	cw_setVertexPos4(self.handle, 0, 0, 0, 0, 0, 0, 0, 0)
	cw_destroy(self.handle)
end

-- Updates the player's color
function MockPlayer:shade(R, G, B, A)
	if R and G and B and A then cw_setVertexColor4Same(self.handle, R, G, B, A)
	else cw_setVertexColor4Same(self.handle, s_getPlayerColor()) end
end

-- Updates the location of the player
-- This function or the draw function should be called continuously to keep the player's position accurate
-- The angle parameter can be used to override the class's own angle for constant control
-- Th distance offset is helpful for animating the beatpulse offset
-- The third parameter of a transformation function is the vertex index which is detailed below
--                V0.
--                  /\
--                /'  '\
--   CCW <<     /' PLYR '\     >> CW
--         V1./'__________'\.V2
function MockPlayer:update(mFocus, angleOverride, distanceOffset, ...)
	local d, h, w, a = self.distance + (distanceOffset or 0), self.height, self.width * (mFocus and 0.6 or 1), angleOverride or self.angle
	local db = d - h
	local sd, sa = ((w / 2) ^ 2 + db ^ 2) ^ 0.5, math.atan(w / 2 / db) + (db < 0 and math.pi or 0)

	local r0, a0 = self.transPolar(d, a, 0, ...)
	local r1, a1 = self.transPolar(sd, a - sa, 1, ...)
	local r2, a2 = self.transPolar(sd, a + sa, 2,...)

	local x0, y0 = self.transCartesian(r0 * math.cos(a0), r0 * math.sin(a0), 0, ...)
	local x1, y1 = self.transCartesian(r1 * math.cos(a1), r1 * math.sin(a1), 1, ...)
	local x2, y2 = self.transCartesian(r2 * math.cos(a2), r2 * math.sin(a2), 2, ...)

	cw_setVertexPos4(self.handle, x0, y0, x0, y0, x1, y1, x2, y2)
end

-- Union or shade and update functions
-- This function or the update function should be called continuously to keep the player's position accurate
function MockPlayer:draw(mFocus, angleOverride, distanceOffset, R, G, B, A, ...)
	self:update(mFocus, angleOverride, distanceOffset, ...)
	self:shade(R, G, B, A)
end