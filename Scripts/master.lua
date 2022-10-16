--[[
	Advanced custom wall control for Open Hexagon.
	https://github.com/vittorioromeo/SSVOpenHexagon

	Copyright (C) 2021 Ricky Cui

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <https://www.gnu.org/licenses/>.

	Email: cuiricky4@gmail.com
	GitHub: https://github.com/Syyrion
]]

u_execDependencyScript('library_extbase', 'extbase', 'syyrion', 'utils.lua')

--[[
	* VERTEX CLASSES
]]

--[[
	* Discrete Vertex Class
	Handles a single vertex's col and transformations
]]

local DiscreteVertex = {
	ch = Channel,
	pol = Cascade.new(Filter.FUNCTION, __NOP)
}
DiscreteVertex.cart = DiscreteVertex.pol
DiscreteVertex.col = DiscreteVertex.pol
DiscreteVertex.__index = DiscreteVertex
function DiscreteVertex:new(r, g, b, a, pol, cart, col)
	local newInst = setmetatable({
		ch = self.ch:new(r, g, b, a),
		pol = self.pol:new(pol),
		cart = self.cart:new(cart),
		col = self.col:new(col)
	}, self)
	newInst.__index = newInst
	return newInst
end
function DiscreteVertex:result(...)
	local r, g, b, a = self.ch:get()
	return self.col:get()(r, g, b, a, ...)
end

--[[
	* Quad vertex class
	Handles 4 vertex classes at once
]]
local QuadVertex = {
	[0] = DiscreteVertex,
	[1] = DiscreteVertex,
	[2] = DiscreteVertex,
	[3] = DiscreteVertex
}
QuadVertex.__index = QuadVertex
function QuadVertex:new(r, g, b, a, pol, cart, col)
	local newInst = setmetatable({
		[0] = self[0]:new(r, g, b, a, pol, cart, col),
		[1] = self[1]:new(r, g, b, a, pol, cart, col),
		[2] = self[2]:new(r, g, b, a, pol, cart, col),
		[3] = self[3]:new(r, g, b, a, pol, cart, col)
	}, self)
	newInst.__index = newInst
	return newInst
end
function QuadVertex:chsetcolor(r, g, b) for i = 0, 3 do self[i].ch:setcolor(r, g, b) end end
function QuadVertex:chsetalpha(a) for i = 0, 3 do self[i].ch:setalpha(a) end end
function QuadVertex:chset(r, g, b, a) for i = 0, 3 do self[i].ch:set(r, g, b, a) end end
function QuadVertex:chsethsv(h, s, v) for i = 0, 3 do self[i].ch:sethsv(h, s, v) end end
function QuadVertex:chget()
	local r0, g0, b0, a0 = self[0].ch:get()
	local r1, g1, b1, a1 = self[1].ch:get()
	local r2, g2, b2, a2 = self[2].ch:get()
	local r3, g3, b3, a3 = self[3].ch:get()
	return r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3
end
function QuadVertex:chrawget()
	local r0, g0, b0, a0 = self[0].ch:rawget()
	local r1, g1, b1, a1 = self[1].ch:rawget()
	local r2, g2, b2, a2 = self[2].ch:rawget()
	local r3, g3, b3, a3 = self[3].ch:rawget()
	return r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3
end
function QuadVertex:chfreeze() for i = 0, 3 do self[i].ch:freeze() end end
function QuadVertex:chdefine(fn) for i = 0, 3 do self[i].ch:define(fn) end end

-- ! Depreciated
function QuadVertex:chresult(...)
	local r0, g0, b0, a0 = self[0]:result(...)
	local r1, g1, b1, a1 = self[1]:result(...)
	local r2, g2, b2, a2 = self[2]:result(...)
	local r3, g3, b3, a3 = self[3]:result(...)
	return r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3
end

function QuadVertex:polset(pol) for i = 0, 3 do self[i].pol:set(pol) end end
function QuadVertex:polget() return self[0].pol:get(), self[1].pol:get(), self[2].pol:get(), self[3].pol:get() end
function QuadVertex:polrawget() return self[0].pol:rawget(), self[1].pol:rawget(), self[2].pol:rawget(), self[3].pol:rawget() end
function QuadVertex:polfreeze() for i = 0, 3 do self[i].pol:freeze() end end
function QuadVertex:poldefine(fn) for i = 0, 3 do self[i].pol:define(fn) end end

function QuadVertex:cartset(cart) for i = 0, 3 do self[i].cart:set(cart) end end
function QuadVertex:cartget() return self[0].cart:get(), self[1].cart:get(), self[2].cart:get(), self[3].cart:get() end
function QuadVertex:cartrawget() return self[0].cart:rawget(), self[1].cart:rawget(), self[2].cart:rawget(), self[3].cart:rawget() end
function QuadVertex:cartfreeze() for i = 0, 3 do self[i].pol:freeze() end end
function QuadVertex:cartdefine(fn) for i = 0, 3 do self[i].pol:define(fn) end end

function QuadVertex:colset(col) for i = 0, 3 do self[i].col:set(col) end end
function QuadVertex:colget() return self[0].col:get(), self[1].col:get(), self[2].col:get(), self[3].col:get() end
function QuadVertex:colrawget() return self[0].col:rawget(), self[1].col:rawget(), self[2].col:rawget(), self[3].col:rawget() end
function QuadVertex:colfreeze() for i = 0, 3 do self[i].pol:freeze() end end
function QuadVertex:coldefine(fn) for i = 0, 3 do self[i].pol:define(fn) end end

--[[
	* PARAMETER CLASSES
]]

--[[
	* Dual angle parameter class
	Handles two angles and an offset
]]
local DualAngle = {
	origin = Cascade.new(Filter.NUMBER, 0)
}
DualAngle.extent = DualAngle.origin
DualAngle.offset = DualAngle.origin
DualAngle.__index = DualAngle
function DualAngle:new(a0, a1, ofs)
	local newInst = setmetatable({
		origin = self.origin:new(a0),
		extent = self.extent:new(a1),
		offset = self.offset:new(ofs)
	}, self)
	newInst.__index = newInst
	return newInst
end
function DualAngle:set(a0, a1, ofs) self.origin:set(a0) self.extent:set(a1) self.offset:set(ofs) end
function DualAngle:get() return self.origin:get(), self.extent:get(), self.offset:get() end
function DualAngle:rawget() return self.origin:rawget(), self.extent:rawget(), self.offset:rawget() end
function DualAngle:freeze() self.origin:freeze() self.extent:freeze() self.offset:freeze() end
function DualAngle:define(a0fn, a1fn, ofsfn) self.origin:define(a0fn) self.extent:define(a1fn) self.offset:define(ofsfn) end
function DualAngle:result()
	local ofs = self.offset:get()
	return self.origin:get() + ofs, self.extent:get() + ofs
end

--[[
	* Dual limit parameter class
	Handles origin and extent limits
]]
local DualLimit = {
	origin = Cascade.new(Filter.NUMBER, nil, function (self) return self.val or l_getWallSpawnDistance() end),
	extent = Cascade.new(Filter.NUMBER, nil, function (self) return self.val or getPivotRadius() end)
}
DualLimit.__index = DualLimit
function DualLimit:new(lim0, lim1)
	local newInst = setmetatable({
		origin = self.origin:new(lim0),
		extent = self.extent:new(lim1)
	}, self)
	newInst.__index = newInst
	return newInst
end
function DualLimit:set(lim0, lim1) self.origin:set(lim0) self.extent:set(lim1) end
function DualLimit:get() return self.origin:get(), self.extent:get() end
function DualLimit:rawget() return self.origin:rawget(), self.extent:rawget() end
function DualLimit:freeze() self.origin:freeze() self.extent:freeze() end
function DualLimit:define(lim0fn, lim1fn) self.origin:define(lim0fn) self.extent:define(lim1fn) end
function DualLimit:swap() self.origin, self.extent = self.extent, self.origin end
function DualLimit:order()
	local origin, extent = self.origin:get(), self.extent:get()
	if origin >= extent then return origin, extent, 1 end
	return extent, origin, -1
end
function DualLimit:dir() return self.origin:get() >= self.extent:get() and 1 or -1 end



--[[
	* LAYER CLASSES
]]

local verifydepth = function (depth)
	return type(depth) == 'number' and math.floor(depth) or 0
end

--[[
	* Generic class
]]
local Generic = {}
Generic.__index = Generic

-- Removes a wall with key <key>
function Generic:wremove(key)
	if type(key) ~= 'table' then errorf(2, 'WallRemoval', 'Argument #1 is not a table.') end
	if type(key.K) ~= 'number' then errorf(2, 'WallRemoval', 'Invalid or missing custom wall key.') end
	if not self.W[key] then errorf(2, 'WallRemoval', 'Custom wall <%d> does not exist.', key.K) end
	cw_setVertexPos4(key.K, 0, 0, 0, 0, 0, 0, 0, 0)
	cw_destroy(key.K)
	self.W[key] = nil
end

-- Removes all walls
function Generic:wxremove(depth)
	depth = verifydepth(depth)
	local function wxremove(currentLayer, layerDepth)
		if layerDepth <= 0 then
			for k, _ in pairs(currentLayer.W) do
				currentLayer:wremove(k)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				wxremove(nextLayer, layerDepth - 1)
			end
		end
	end
	wxremove(self, depth)
end

-- ! Legacy Function Names
Generic.rmWall = Generic.wremove
Generic.rrmWall = Generic.wxremove

-- ! Depreciated
-- Sets all layer wall colors.
function Generic:tint(depth, r, g, b, a)
	depth = verifydepth(depth)
	local function tint(currentLayer, layerDepth)
		if layerDepth <= 0 then
			for _, wall in pairs(currentLayer.W) do
				wall.vertex:chset(r, g, b, a)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				tint(nextLayer, layerDepth - 1)
			end
		end
	end
	tint(self, depth)
end

-- ! Depreciated
-- Union of tint and fill.
function Generic:shade(depth, r, g, b, a, ...)
	self:tint(depth, r, g, b, a)
	self:fill(depth, ...)
end

--[[
	* MockPlayer class
]]
local MockPlayerAttribute = setmetatable({
	angle = Cascade.new(Filter.NUMBER, nil, function (self) return self.val or u_getPlayerAngle() end),
	offset = DualAngle.origin,
	distance = Cascade.new(Filter.NUMBER, nil, function (self) return self.val or getDistanceBetweenCenterAndPlayerTip() end),
	height = Cascade.new(Filter.NUMBER, nil, function (self) return self.val or getPlayerHeight() end),
	width = Cascade.new(Filter.NUMBER, nil, function (self) return self.val or getPlayerBaseWidth() end)
}, Generic)
MockPlayerAttribute.__index = MockPlayerAttribute

MockPlayer = setmetatable({}, MockPlayerAttribute)
MockPlayerAttribute.L = MockPlayer

function MockPlayerAttribute:construct(parent, a0, ofs, d, h, w, r, g, b, a, pol, cart, col)
	return {
		angle = self.angle:new(a0),
		offset = self.offset:new(ofs),
		distance = self.distance:new(d),
		height = self.height:new(h),
		width = self.width:new(w),
		vertex = parent.vertex:new(r, g, b, a, pol, cart, col)
	}
end

function MockPlayerAttribute:new(...)
	local newInst = setmetatable(self:construct(...), getmetatable(self))
	newInst.__index = newInst
	local newLayer = setmetatable({}, newInst)
	newInst.L = newLayer
	newInst.W = {}
	return newLayer
end

-- Creates a MockPlayer
-- Returns a tuple of all created wall key objects
function MockPlayerAttribute:create(depth, ...)
	depth = verifydepth(depth)
	local function create(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			local key, mp = {K = cw_createNoCollision()}, currentLayer:construct(currentLayer, ...)
			currentLayer.W[key] = mp
			return mp, key
		else
			for _, nextLayer in pairs(currentLayer) do
				create(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	return create(self, depth, ...)
end

local function getSideRadiusAndAngle(halfWidth, baseRadius)
	return baseRadius, halfWidth / baseRadius + (baseRadius < 0 and math.pi or 0)
end

function enableAccurateMockPlayers()
	function getSideRadiusAndAngle(halfWidth, baseRadius)
		return (halfWidth * halfWidth + baseRadius * baseRadius) ^ 0.5, math.atan2(halfWidth, baseRadius) + (baseRadius < 0 and math.pi or 0)
	end
end

-- ! Depreciated movement functions
--#region

-- ! Depreciated
function MockPlayerAttribute:step(depth, mFocus, ...)
	depth = verifydepth(depth)
	local function step(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local angle, distance, halfWidth = wall.angle:get() + wall.offset:get(), wall.distance:get(), wall.width:get() * 0.5 * (mFocus and FOCUS_RATIO or 1)
				local baseRadius = distance - wall.height:get()
				local sideRadius, sideAngle = getSideRadiusAndAngle(halfWidth, baseRadius)

				local r0, a0 = wall.vertex[0].pol:get()(distance, angle, ...)
				local r1, a1 = wall.vertex[1].pol:get()(sideRadius, angle + sideAngle, ...)
				local r2, a2 = wall.vertex[2].pol:get()(sideRadius, angle - sideAngle, ...)
				local x0, y0 = wall.vertex[0].cart:get()(r0 * math.cos(a0), r0 * math.sin(a0), ...)
				local x1, y1 = wall.vertex[1].cart:get()(r1 * math.cos(a1), r1 * math.sin(a1), ...)
				local x2, y2 = wall.vertex[2].cart:get()(r2 * math.cos(a2), r2 * math.sin(a2), ...)
				cw_setVertexPos4(key.K, x0, y0, x1, y1, x2, y2, x2, y2)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				step(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	step(self, depth, ...)
end

-- ! Depreciated
-- Union of step and shade.
-- Note that polar, cartesian, and color transformation parameters are unioned.
function MockPlayerAttribute:draw(depth, mFocus, r, g, b, a, ...)
	self:step(depth, mFocus, ...)
	self:shade(depth, r, g, b, a, ...)
end

--#endregion



-- ! Passing arguments to transformations via movement functions is no longer supported.
function MockPlayerAttribute:move(depth, mFocus, ...)
	depth = verifydepth(depth)
	local function move(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local angle, distance, halfWidth = wall.angle:get() + wall.offset:get(), wall.distance:get(), wall.width:get() * 0.5 * (mFocus and FOCUS_RATIO or 1)
				local baseRadius = distance - wall.height:get()
				local sideRadius, sideAngle = getSideRadiusAndAngle(halfWidth, baseRadius)
				local r0, a0 = wall.vertex[0].pol:get()(distance, angle, ...)
				local r1, a1 = wall.vertex[1].pol:get()(sideRadius, angle + sideAngle, ...)
				local r2, a2 = wall.vertex[2].pol:get()(sideRadius, angle - sideAngle, ...)
				local x0, y0 = wall.vertex[0].cart:get()(r0 * math.cos(a0), r0 * math.sin(a0), ...)
				local x1, y1 = wall.vertex[1].cart:get()(r1 * math.cos(a1), r1 * math.sin(a1), ...)
				local x2, y2 = wall.vertex[2].cart:get()(r2 * math.cos(a2), r2 * math.sin(a2), ...)
				cw_setVertexPos4(key.K, x0, y0, x1, y1, x2, y2, x2, y2)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				move(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	move(self, depth, ...)
end

-- ! Passing arguments to transformations via movement functions is no longer supported.
function MockPlayerAttribute:fill(depth, ...)
	depth = verifydepth(depth)
	local function fill(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local R0, G0, B0, A0 = wall.vertex[0]:result(...)
				local R1, G1, B1, A1 = wall.vertex[1]:result(...)
				local R2, G2, B2, A2 = wall.vertex[2]:result(...)
				cw_setVertexColor4(key.K, R0, G0, B0, A0, R1, G1, B1, A1, R2, G2, B2, A2, R2, G2, B2, A2)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				fill(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	fill(self, depth, ...)
end

function MockPlayerAttribute:run(depth, mFocus)
	depth = verifydepth(depth)
	local function run(currentLayer, layerDepth)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local angle, distance, halfWidth = wall.angle:get() + wall.offset:get(), wall.distance:get(), wall.width:get() * 0.5 * (mFocus and FOCUS_RATIO or 1)
				local baseRadius = distance - wall.height:get()
				local sideRadius, sideAngle = getSideRadiusAndAngle(halfWidth, baseRadius)
				local r0, a0 = wall.vertex[0].pol:get()(distance, angle)
				local r1, a1 = wall.vertex[1].pol:get()(sideRadius, angle + sideAngle)
				local r2, a2 = wall.vertex[2].pol:get()(sideRadius, angle - sideAngle)
				local x0, y0 = wall.vertex[0].cart:get()(r0 * math.cos(a0), r0 * math.sin(a0))
				local x1, y1 = wall.vertex[1].cart:get()(r1 * math.cos(a1), r1 * math.sin(a1))
				local x2, y2 = wall.vertex[2].cart:get()(r2 * math.cos(a2), r2 * math.sin(a2))
				cw_setVertexPos4(key.K, x0, y0, x1, y1, x2, y2, x2, y2)
				local R0, G0, B0, A0 = wall.vertex[0]:result(r0, a0, x0, y0)
				local R1, G1, B1, A1 = wall.vertex[1]:result(r1, a1, x1, y1)
				local R2, G2, B2, A2 = wall.vertex[2]:result(r2, a2, x2, y2)
				cw_setVertexColor4(key.K, R0, G0, B0, A0, R1, G1, B1, A1, R2, G2, B2, A2, R2, G2, B2, A2)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				run(nextLayer, layerDepth - 1)
			end
		end
	end
	run(self, depth)
end

--[[
	* PolyWall Class
]]
local PolyWallAttribute = setmetatable({
	thickness = Cascade.new(Filter.NUMBER, THICKNESS),
	speed = Cascade.new(Filter.NUMBER, nil, function (self) return self.val or getWallSpeedInUnitsPerFrame() end),
	vertex = QuadVertex,
	angle = DualAngle,
	limit = DualLimit,
	P = MockPlayer
}, Generic)
PolyWallAttribute.__index = PolyWallAttribute

PolyWall = setmetatable({}, PolyWallAttribute)
PolyWallAttribute.L = PolyWall

function PolyWallAttribute:construct(th, sp, p, r, g, b, a, pol, cart, col, a0, a1, ofs, lim0, lim1)
	local newInst = {
		thickness = self.thickness:new(th),
		speed = self.speed:new(sp),
		vertex = self.vertex:new(r, g, b, a, pol, cart, col),
		angle = self.angle:new(a0, a1, ofs),
		limit = self.limit:new(lim0, lim1)
	}
	newInst.position = newInst.limit.origin:new(p)
	return newInst
end

function PolyWallAttribute:new(...)
	local newInst = setmetatable(self:construct(...), getmetatable(self))
	newInst.__index = newInst
	local newLayer = setmetatable({}, newInst)
	newInst.L = newLayer
	newInst.W = {}
	newInst.P = self.P:new(newInst)
	return newLayer
end

-- Creates a new layer with positive integer key <n>.
function PolyWallAttribute:add(n, ...)
	n = type(n) == 'number' and math.floor(n) or errorf(2, 'LayerCreation', 'Argument #1 is not a number.')
	if self[n] then errorf(2, 'LayerCreation', 'Cannot overwrite already existing layer <%d>', n) end
	local newLayer = self:new(...)
	self[n] = newLayer
	self.P[n] = newLayer.P
	return newLayer
end

-- Similar to add but acts recursively.
function PolyWallAttribute:radd(depth, n, ...)
	depth = verifydepth(depth)
	local layerTable = {}
	local function rrad(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			table.insert(layerTable, currentLayer:add(n, ...))
		else
			for _, nextLayer in pairs(currentLayer) do
				rrad(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	rrad(self, depth, ...)
	return layerTable
end

-- Removes a layer with integer key <n>.
function PolyWallAttribute:remove(n)
	n = type(n) == 'number' and math.floor(n) or errorf(2, 'LayerRemoval', 'Argument #1 is not a number.')
	if not self[n] then return end
	self[n].P:wxremove()
	self[n]:wxremove()
	self[n]:xremove()
	self[n] = nil
end

-- Similar to remove but acts recursively.
function PolyWallAttribute:rremove(depth, n)
	depth = verifydepth(depth)
	local function rremove(currentLayer, layerDepth)
		if layerDepth <= 0 then
			currentLayer:remove(n)
		else
			for _, nextLayer in pairs(currentLayer) do
				rremove(nextLayer, layerDepth - 1)
			end
		end
	end
	rremove(self, depth)
end

-- Removes all layers
function PolyWallAttribute:xremove(depth)
	depth = verifydepth(depth)
	local function xremove(currentLayer, layerDepth)
		if layerDepth <= 0 then
			for k, _ in pairs(currentLayer) do
				currentLayer:remove(k)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				xremove(nextLayer, layerDepth - 1)
			end
		end
	end
	xremove(self, depth)
end

-- ! Legacy Function Names
PolyWallAttribute.rrmLayer = PolyWallAttribute.xremove
PolyWallAttribute.rmLayer = PolyWallAttribute.remove


-- Creates a wall of specified type
-- Type can be 's', 'n' or 'd'
-- Returns a tuple of all created wall key objects
function PolyWallAttribute:wall(depth, t, ...)
	if type(t) ~= 'string' then errorf(2, 'WallCreation', 'Argument #2 is not a string.') end
	return (self[t .. 'Wall'] or errorf(2, 'WallCreation', 'Argument #2 is not equivalent to "s", "n", or "d".'))(depth, ...)
end

-- Creates a standard wall
-- Returns a tuple of all created wall key objects
function PolyWallAttribute:sWall(depth, ...)
	depth = verifydepth(depth)
	local function sWall(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			local key, wall = {K = cw_create()}, currentLayer:construct(...)
			currentLayer.W[key] = wall
			return wall, key
		else
			for _, nextLayer in pairs(currentLayer) do
				sWall(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	return sWall(self, depth, ...)
end

-- Creates a non-solid wall
-- Returns a tuple of all created wall key objects
function PolyWallAttribute:nWall(depth, ...)
	depth = verifydepth(depth)
	local function nWall(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			local key, wall = {K = cw_createNoCollision()}, currentLayer:construct(...)
			currentLayer.W[key] = wall
			return wall, key
		else
			for _, nextLayer in pairs(currentLayer) do
				nWall(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	return nWall(self, depth, ...)
end

-- Creates a deadly wall
-- Returns a tuple of all created wall key objects
function PolyWallAttribute:dWall(depth, ...)
	depth = verifydepth(depth)
	local function dWall(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			local key, wall = {K = cw_createDeadly()}, currentLayer:construct(...)
			currentLayer.W[key] = wall
			return wall, key
		else
			for _, nextLayer in pairs(currentLayer) do
				dWall(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	return dWall(self, depth, ...)
end

function PolyWallAttribute:pivotCap(depth, r, g, b, a, pol, cart, col, a0, a1, ofs)
	depth = verifydepth(depth)
	local function pivotCap(currentLayer, layerDepth)
		if layerDepth <= 0 then
			local wall, key = currentLayer:nWall(0, nil, 0, 0, r, g, b, a, pol, cart, col, a0, a1, ofs, nil, 0)
			wall.thickness:define(getCapRadius)
			return wall, key
		else
			for _, nextLayer in pairs(currentLayer) do
				pivotCap(nextLayer, layerDepth - 1)
			end
		end
	end
	return pivotCap(self, depth)
end

function PolyWallAttribute:pivotBorder(depth, r, g, b, a, pol, cart, col, a0, a1, ofs)
	depth = verifydepth(depth)
	local function pivotBorder(currentLayer, layerDepth)
		if layerDepth <= 0 then
			local wall, key = currentLayer:nWall(0, nil, 0, 0, r, g, b, a, pol, cart, col, a0, a1, ofs, nil, 0)
			wall.thickness:define(getPivotRadius)
			wall.limit.extent:define(getCapRadius)
			return wall, key
		else
			for _, nextLayer in pairs(currentLayer) do
				pivotBorder(nextLayer, layerDepth - 1)
			end
		end
	end
	return pivotBorder(self, depth)
end

-- Returns true if any of the checked layers has a wall.
function PolyWallAttribute:hasWalls(depth)
	depth = verifydepth(depth)
	local function hasWalls(currentLayer, layerDepth)
		if layerDepth <= 0 then
			assert(not next(currentLayer.W))
		else
			for _, nextLayer in pairs(currentLayer) do
				hasWalls(nextLayer, layerDepth - 1)
			end
		end
	end
	return not pcall(hasWalls, self, depth)
end

-- Creates <n> layers ranging from [0, <n>)
function PolyWallAttribute:template(depth, n, ...)
	depth = verifydepth(depth)
	n = type(n) == 'number' and math.floor(n) - 1 or errorf(2, 'Template', 'Argument #2 is not a number.')
	local function template(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			currentLayer:xremove()
			for i = 0, n do currentLayer:add(i, ...) end
		else
			for _, nextLayer in pairs(currentLayer) do
				template(nextLayer, depth - 1, ...)
			end
		end
	end
	template(self, depth, ...)
end

-- Rearranges layers into a regular shape.
-- Only affects layer indexes from [0, <shape>)
-- All layers to be affected must exist
function PolyWallAttribute:regularize(depth, shape, ofs)
	depth = verifydepth(depth)
	shape = Filter.SIDE_COUNT(shape) and shape or errorf(2, 'Regularize', 'Invalid side count.')
	ofs = type(ofs) == 'number' and ofs or 0
	local arc = math.tau / shape
	local cur = arc * -0.5
	local angles = {cur}
	for _ = 1, shape do
		cur = cur + arc
		table.insert(angles, cur)
	end
	local function regularize(currentLayer, layerDepth)
		if layerDepth <= 0 then
			for i = 1, shape do
				(currentLayer[i - 1] or errorf(depth + 3, 'Regularize', 'Layer <%d> does not exist. Did you forget to run the template function first?', i - 1)).angle:set(angles[i], angles[i + 1], ofs)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				regularize(nextLayer, layerDepth - 1)
			end
		end
	end
	regularize(self, depth)
end

-- Distributes the offset angles of layers
-- Only affects layers from [0, <shape>)
-- All layers effected must exist
function PolyWallAttribute:distribute(depth, shape, ofs)
	depth = verifydepth(depth)
	shape = Filter.SIDE_COUNT(shape) and shape or errorf(2, 'Distribute', 'Invalid side count.')
	ofs = type(ofs) == 'number' and ofs or 0
	local arc = math.tau / shape
	local angles = {[0] = ofs}
	for i = 1, shape - 1 do
		angles[i] = i * arc + ofs
	end
	local function distribute(currentLayer, layerDepth)
		if layerDepth <= 0 then
			for i = 0, shape - 1 do
				(currentLayer[i] or errorf(depth + 3, 'Distribute', 'Layer <%d> does not exist. Did you forget to run the template function first?', i)).angle.offset:set(angles[i])
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				distribute(nextLayer, layerDepth - 1)
			end
		end
	end
	distribute(self, depth)
end

-- Rearranges layers into a proportional shape.
-- Only affects layer indexes from [0, <ratio length>)
-- All layers to be affected must exist
-- Returns the largest index of the new layers
function PolyWallAttribute:proportionalize(depth, ofs, ...)
	depth = verifydepth(depth)
	ofs = type(ofs) == 'number' and ofs or 0
	local t, ref = {...}, {0}
	local l = #t
	for i = 1, l do
		if type(t[i]) ~= 'number' then errorf(2, 'Proportionalize', 'Argument #%d is not a number.', i + 1) end
		ref[i + 1] = ref[i] + t[i]
	end
	if ref[l + 1] <= 0 then errorf(2, 'Proportionalize', 'Ths sum of all values in the ratio must be greater than 0.') end
	local angles = {0}
	for i = 1, l do
		table.insert(angles, mapValue(ref[i + 1], 0, ref[l + 1], 0, math.tau))
	end
	local function proportionalize(currentLayer, layerDepth)
		if layerDepth <= 0 then
			for i = 1, l do
				(currentLayer[i - 1] or errorf(depth + 3, 'Proportionalize', 'Layer <%d> does not exist. Did you forget to run the template function first?', i - 1)).angle:set(angles[i], angles[i + 1], ofs)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				proportionalize(nextLayer, layerDepth - 1)
			end
		end
	end
	proportionalize(self, depth)
	return l
end

-- ! Depreciated movement functions
--#region

-- ! Depreciated
-- Calculates all layer wall positions.
-- The ... may seem useless, but it prevents a highly unpredictable bug from occuring.
function PolyWallAttribute:advance(depth, mFrameTime)
	depth = verifydepth(depth)
	local function advance(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local absth, outer, inner, dir = math.abs(wall.thickness:get()), wall.limit:order()
				local pos = wall.position:get() - mFrameTime * wall.speed:get() * dir
				if pos >= outer + absth or pos <= inner - absth then
					currentLayer:wremove(key)
				else
					wall.position:set(pos)
				end
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				advance(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	advance(self, depth)
end

-- ! Depreciated
-- Recursively updates all layer wall positions.
-- Depth is how many layers to descend to update walls
-- Transformations of all layers passed through while recursing are applied in reverse order when a wall is moved
-- The <tf> parameter is used for passing down transformation functions while recursing
-- Note that all polar and cartesian transformation parameters are unioned.
function PolyWallAttribute:step(depth, ...)
	depth = verifydepth(depth)
	local function step(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local angle0, angle1 = wall.angle:result()
				local pos, th, outer, inner, dir = wall.position:get(), wall.thickness:get(), wall.limit:order()
				local innerRad, outerRad = clamp(pos, inner, outer), clamp(pos + th * dir, inner, outer)
				local r0, a0 = wall.vertex[0].pol:get()(innerRad, angle0, ...)
				local r1, a1 = wall.vertex[1].pol:get()(innerRad, angle1, ...)
				local r2, a2 = wall.vertex[2].pol:get()(outerRad, angle1, ...)
				local r3, a3 = wall.vertex[3].pol:get()(outerRad, angle0, ...)
				local x0, y0 = wall.vertex[0].cart:get()(r0 * math.cos(a0), r0 * math.sin(a0), ...)
				local x1, y1 = wall.vertex[1].cart:get()(r1 * math.cos(a1), r1 * math.sin(a1), ...)
				local x2, y2 = wall.vertex[2].cart:get()(r2 * math.cos(a2), r2 * math.sin(a2), ...)
				local x3, y3 = wall.vertex[3].cart:get()(r3 * math.cos(a3), r3 * math.sin(a3), ...)
				cw_setVertexPos4(key.K, x0, y0, x1, y1, x2, y2, x3, y3)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				step(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	step(self, depth, ...)
end

-- ! Depreciated
-- Union of advance and tint.
function PolyWallAttribute:arrange(depth, mFrameTime, r, g, b, a)
	self:advance(depth, mFrameTime)
	self:tint(depth, r, g, b, a)
end

-- ! Depreciated
-- Union of fill and step.
-- Note that polar, cartesian, and color transformation parameters are unioned.
function PolyWallAttribute:update(depth, ...)
	self:step(depth, ...)
	self:fill(depth, ...)
end

-- ! Depreciated
-- Union of arrange and update.
-- Note that polar, cartesian, and color transformation parameters are unioned.
function PolyWallAttribute:draw(depth, mFrameTime, r, g, b, a, ...)
	self:arrange(depth, mFrameTime, r, g, b, a)
	self:update(depth, ...)
end

--#endregion



-- ! Passing arguments to transformations via movement functions is no longer supported.
-- Union of advance and step.
function PolyWallAttribute:move(depth, mFrameTime, ...)
	depth = verifydepth(depth)
	local function move(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local th = wall.thickness:get()
				local absth, outer, inner, dir = math.abs(th), wall.limit:order()
				local pos = wall.position:get() - mFrameTime * wall.speed:get() * dir
				if pos >= outer + absth or pos <= inner - absth then
					currentLayer:wremove(key)
				else
					wall.position:set(pos)
					local angle0, angle1 = wall.angle:result()
					local innerRad, outerRad = clamp(pos, inner, outer), clamp(pos + th * dir, inner, outer)
					local r0, a0 = wall.vertex[0].pol:get()(innerRad, angle0, ...)
					local r1, a1 = wall.vertex[1].pol:get()(innerRad, angle1, ...)
					local r2, a2 = wall.vertex[2].pol:get()(outerRad, angle1, ...)
					local r3, a3 = wall.vertex[3].pol:get()(outerRad, angle0, ...)
					local x0, y0 = wall.vertex[0].cart:get()(r0 * math.cos(a0), r0 * math.sin(a0), ...)
					local x1, y1 = wall.vertex[1].cart:get()(r1 * math.cos(a1), r1 * math.sin(a1), ...)
					local x2, y2 = wall.vertex[2].cart:get()(r2 * math.cos(a2), r2 * math.sin(a2), ...)
					local x3, y3 = wall.vertex[3].cart:get()(r3 * math.cos(a3), r3 * math.sin(a3), ...)
					cw_setVertexPos4(key.K, x0, y0, x1, y1, x2, y2, x3, y3)
				end
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				move(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	move(self, depth, ...)
end

-- ! Passing arguments to transformations via movement functions is no longer supported.
-- Updates wall colors recursively.
function PolyWallAttribute:fill(depth, ...)
	depth = verifydepth(depth)
	local function fill(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local R0, G0, B0, A0 = wall.vertex[0]:result(...)
				local R1, G1, B1, A1 = wall.vertex[1]:result(...)
				local R2, G2, B2, A2 = wall.vertex[2]:result(...)
				local R3, G3, B3, A3 = wall.vertex[3]:result(...)
				cw_setVertexColor4(key.K, R0, G0, B0, A0, R1, G1, B1, A1, R2, G2, B2, A2, R3, G3, B3, A3)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				fill(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	fill(self, depth, ...)
end

function PolyWallAttribute:run(depth, mFrameTime)
	depth = verifydepth(depth)
	local function run(currentLayer, layerDepth)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local th = wall.thickness:get()
				local absth, outer, inner, dir = math.abs(th), wall.limit:order()
				local pos = wall.position:get() - mFrameTime * wall.speed:get() * dir
				if pos >= outer + absth or pos <= inner - absth then
					currentLayer:wremove(key)
				else
					wall.position:set(pos)
					local angle0, angle1 = wall.angle:result()
					local innerRad, outerRad = clamp(pos, inner, outer), clamp(pos + th * dir, inner, outer)
					local r0, a0 = wall.vertex[0].pol:get()(innerRad, angle0)
					local r1, a1 = wall.vertex[1].pol:get()(innerRad, angle1)
					local r2, a2 = wall.vertex[2].pol:get()(outerRad, angle1)
					local r3, a3 = wall.vertex[3].pol:get()(outerRad, angle0)
					local x0, y0 = wall.vertex[0].cart:get()(r0 * math.cos(a0), r0 * math.sin(a0))
					local x1, y1 = wall.vertex[1].cart:get()(r1 * math.cos(a1), r1 * math.sin(a1))
					local x2, y2 = wall.vertex[2].cart:get()(r2 * math.cos(a2), r2 * math.sin(a2))
					local x3, y3 = wall.vertex[3].cart:get()(r3 * math.cos(a3), r3 * math.sin(a3))
					cw_setVertexPos4(key.K, x0, y0, x1, y1, x2, y2, x3, y3)
					local R0, G0, B0, A0 = wall.vertex[0]:result(r0, a0, x0, y0)
					local R1, G1, B1, A1 = wall.vertex[1]:result(r1, a1, x1, y1)
					local R2, G2, B2, A2 = wall.vertex[2]:result(r2, a2, x2, y2)
					local R3, G3, B3, A3 = wall.vertex[3]:result(r3, a3, x3, y3)
					cw_setVertexColor4(key.K, R0, G0, B0, A0, R1, G1, B1, A1, R2, G2, B2, A2, R3, G3, B3, A3)
				end
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				run(nextLayer, layerDepth - 1)
			end
		end
	end
	run(self, depth)
end

-- Sorts wall CW handles such that lower numbered handles are moved to lower layers and higher numbered handles to higher layers
-- Order can be reversed by setting <decending> parameter to true
-- Enables wall layering based on layer IDs
-- Only affects currently existing walls
-- Layering within layers is unstable and will very likely change
function PolyWallAttribute:sort(depth, descending)
	depth = verifydepth(depth)
	local keys, layers = {}, {len = 0}
	local function map(currentLayer, layerDepth, currentBranch)
		for key, _ in pairs(currentLayer.W) do
			table.insert(keys, key.K)
		end
		for key, _ in pairs(currentLayer.P.W) do
			table.insert(keys, key.K)
		end
		if layerDepth <= 0 then return end
		for nextLayerId, nextLayer in pairs(currentLayer) do
			local nextBranch = {ix = nextLayerId, len = 0}
			table.insert(currentBranch, nextBranch)
			currentBranch.len = currentBranch.len + 1
			map(nextLayer, layerDepth - 1, nextBranch)
		end
	end
	map(self, depth, layers)
	table.sort(keys, descending and function (a, b)
		return a > b
	end or nil)
	local keyIx = 1
	local function link(currentLayer, layerDepth, currentBranch)
		for key, _ in pairs(currentLayer.P.W) do
			key.K = keys[keyIx]
			keyIx = keyIx + 1
		end
		for key, _ in pairs(currentLayer.W) do
			key.K = keys[keyIx]
			keyIx = keyIx + 1
		end
		if layerDepth <= 0 then return end
		table.sort(currentBranch, function (a, b)
			return a.ix < b.ix
		end)
		for i = 1, currentBranch.len do
			link(currentLayer[currentBranch[i].ix], layerDepth - 1, currentBranch[i])
		end
	end
	link(self, depth, layers)
end