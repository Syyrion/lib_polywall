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

Channel = {
	r = Discrete:new(nil, function (self) return self.val or ({s_getMainColor()})[1] end, 'number'),
	g = Discrete:new(nil, function (self) return self.val or ({s_getMainColor()})[2] end, 'number'),
	b = Discrete:new(nil, function (self) return self.val or ({s_getMainColor()})[3] end, 'number'),
	a = Discrete:new(nil, function (self) return self.val or ({s_getMainColor()})[4] end, 'number')
}
Channel.__index = Channel
function Channel:new(r, g, b, a)
	local newInst = setmetatable({
		r = self.r:new(r),
		g = self.g:new(g),
		b = self.b:new(b),
		a = self.a:new(a),
	}, self)
	newInst.__index = newInst
	return newInst
end
function Channel:set(r, g, b, a) self.r:set(r) self.g:set(g) self.b:set(b) self.a:set(a) end
function Channel:sethsv(h, s, v)
	local r, g, b = fromHSV(h, s, v)
	self.r:set(r) self.g:set(g) self.b:set(b)
end
function Channel:get() return self.r:get(), self.g:get(), self.b:get(), self.a:get() end
function Channel:rawget() return self.r:rawget(), self.g:rawget(), self.b:rawget(), self.a:rawget() end
function Channel:freeze() self.r:freeze() self.g:freeze() self.b:freeze() self.a:freeze() end
function Channel:define(rfn, gfn, bfn, afn) self.r:define(rfn) self.g:define(gfn) self.b:define(bfn) self.a:define(afn) end



--[[
	* VERTEX CLASSES
]]

--[[
	* Discrete Vertex Class
	Handles a single vertex's col and transformations
]]
local DiscreteVertex = {
	ch = Channel,
	pol = Discrete:new(function (a, b) return a, b end, nil, 'function'),
	cart = Discrete:new(function (a, b) return a, b end, nil, 'function'),
	col = Discrete:new(function (r, g, b, a) return r, g, b, a end, nil, 'function')
}
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
function QuadVertex:chset(r, g, b, a) for i = 0, 3 do self[i].ch:set(r, g, b, a) end end
function QuadVertex:chsethsv(h, s, v) for i = 0, 3 do self[i].ch:sethsv(h, s, v) end end
function QuadVertex:chget()
	local r0, g0, b0, a0 = self[0].ch:get()
	local r1, g1, b1, a1 = self[1].ch:get()
	local r2, g2, b2, a2 = self[2].ch:get()
	return r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, self[3].ch:get()
end
function QuadVertex:chrawget()
	local r0, g0, b0, a0 = self[0].ch:rawget()
	local r1, g1, b1, a1 = self[1].ch:rawget()
	local r2, g2, b2, a2 = self[2].ch:rawget()
	return r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, self[3].ch:rawget()
end
function QuadVertex:chfreeze() for i = 0, 3 do self[i].ch:freeze() end end
function QuadVertex:chdefine(rfn, gfn, bfn, afn) for i = 0, 3 do self[i].ch:define(rfn, gfn, bfn, afn) end end

function QuadVertex:chresult(...)
	local r0, g0, b0, a0 = self[0]:result(...)
	local r1, g1, b1, a1 = self[1]:result(...)
	local r2, g2, b2, a2 = self[2]:result(...)
	return r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, self[3]:result(...)
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
	origin = Discrete:new(0, nil, 'number'),
	extent = Discrete:new(0, nil, 'number'),
	offset = Discrete:new(0, nil, 'number')
}
DualAngle.__index = DualAngle
function DualAngle:new(a0, a1, ofs)
	local newInst = setmetatable({
		origin = self.origin:new(a0),
		extent = self.extent:new(a1),
		offset = self.offset:new(ofs),
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
	origin = Discrete:new(1600, nil, 'number'),
	extent = Discrete:new(nil, function (self) return self.val or getPivotRadius() end, 'number')
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
function DualLimit:swap()
	local o, e = self:get()
	self:set(e, o)
end
function DualLimit:order()
	local lh, lt = self.origin:get(), self.extent:get()
	if lh > lt then return lt, lh end
	return lh, lt
end
function DualLimit:dir() return self.origin:get() >= self.extent:get() and 1 or -1 end



--[[
	* LAYER CLASSES
]]

local __VERIFY_DEPTH = function (depth)
	return type(depth) == 'number' and math.floor(depth) or 0
end

--[[
	* Master class
]]
local __MASTER = {}
__MASTER.__index = __MASTER

-- Deletes all walls
function __MASTER:rrmWall(depth)
	depth = __VERIFY_DEPTH(depth)
	local function rrmWall(currentLayer, layerDepth)
		if layerDepth <= 0 then
			for k, _ in pairs(currentLayer.W) do
				currentLayer:rmWall(k)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				rrmWall(nextLayer, layerDepth - 1)
			end
		end
	end
	rrmWall(self, depth)
end

-- Sets all layer wall colors.
function __MASTER:tint(depth, r, g, b, a)
	depth = __VERIFY_DEPTH(depth)
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

-- Union of tint and fill.
function __MASTER:shade(depth, r, g, b, a, ...)
	self:tint(depth, r, g, b, a)
	self:fill(depth, ...)
end

--[[
	* MockPlayer class
]]
local MockPlayerAttribute = setmetatable({
	angle = Discrete:new(nil, function (self) return self.val or u_getPlayerAngle() end, 'number'),
	offset = Discrete:new(0, nil, 'number'),
	distance = Discrete:new(nil, function (self) return self.val or getDistanceBetweenCenterAndPlayerTip() end, 'number'),
	height = Discrete:new(nil, function (self) return self.val or getPlayerHeight() end, 'number'),
	width = Discrete:new(nil, function (self) return self.val or getPlayerBaseWidth() end, 'number'),
	accurate = Discrete:new(false, nil, 'boolean')
}, __MASTER)
MockPlayerAttribute.__index = MockPlayerAttribute

MockPlayer = setmetatable({}, MockPlayerAttribute)
MockPlayerAttribute.L = MockPlayer

function MockPlayerAttribute:construct(parent, a0, ofs, d, h, w, r, g, b, a, pol, cart, col, acc)
	return {
		angle = self.angle:new(a0),
		offset = self.offset:new(ofs),
		distance = self.distance:new(d),
		height = self.height:new(h),
		width = self.width:new(w),
		vertex = parent.vertex:new(r, g, b, a, pol, cart, col),
		accurate = self.accurate:new(acc)
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
	depth = __VERIFY_DEPTH(depth)
	local function create(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			local key = {K = cw_createNoCollision()}
			currentLayer.W[key] = currentLayer:construct(currentLayer, ...)
			return key
		else
			for _, nextLayer in pairs(currentLayer) do
				create(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	return create(self, depth, ...)
end

function MockPlayerAttribute:rmWall(key)
	if type(key) ~= 'table' then errorf(2, 'PlayerRemoval', 'Argument #1 is not a table.') end
	if type(key.K) ~= 'number' then errorf(2, 'PlayerRemoval', 'Invalid or missing custom wall key.') end
	if not self.W[key] then errorf(2, 'PlayerRemoval', 'Custom wall <%d> does not exist.', key.K) end
	cw_setVertexPos4(key.K, 0, 0, 0, 0, 0, 0, 0, 0)
	cw_destroy(key.K)
	self.W[key] = nil
end

function MockPlayerAttribute:step(depth, mFocus, ...)
	depth = __VERIFY_DEPTH(depth)
	local function step(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local angle, distance, halfWidth = wall.angle:get() + wall.offset:get(), wall.distance:get(), wall.width:get() * 0.5 * (mFocus and FOCUS_RATIO or 1)
				local baseRadius, accurate = distance - wall.height:get(), wall.accurate:get()
				local sideRadius = accurate and (halfWidth * halfWidth + baseRadius * baseRadius) ^ 0.5 or baseRadius
				local sideAngle = (accurate and math.atan2 or function (a, b) return a / b end)(halfWidth, baseRadius) + (baseRadius < 0 and math.pi or 0)

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

function MockPlayerAttribute:fill(depth, ...)
	depth = __VERIFY_DEPTH(depth)
	local function fill(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2 = wall.vertex:chresult(...)
				cw_setVertexColor4(key.K, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r2, g2, b2, a2)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				fill(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	fill(self, depth, ...)
end

-- Union of step and shade.
-- Note that polar, cartesian, and color transformation parameters are unioned.
function MockPlayerAttribute:draw(depth, mFocus, r, g, b, a, ...)
	self:step(depth, mFocus, ...)
	self:shade(depth, r, g, b, a, ...)
end

--[[
	* PolyWall Class
]]
local PolyWallAttribute = setmetatable({
	thickness = Discrete:new(THICKNESS, nil, 'number'),
	speed = Discrete:new(nil, function (self) return self.val or getWallSpeedInUnitsPerFrame() end, 'number'),
	vertex = QuadVertex,
	angle = DualAngle,
	limit = DualLimit,
	P = MockPlayer
}, __MASTER)
PolyWallAttribute.__index = PolyWallAttribute

PolyWall = setmetatable({}, PolyWallAttribute)
PolyWallAttribute.L = PolyWall

function PolyWallAttribute:construct(th, sp, p, r, g, b, a, pol, cart, col, a0, a1, ofs, lim0, lim1)
	local newInst = {
		thickness = self.thickness:new(th),
		speed = self.speed:new(sp),
		vertex = self.vertex:new(r, g, b, a, pol, cart, col),
		angle = self.angle:new(a0, a1, ofs),
		limit = self.limit:new(lim0, lim1),
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
end

function PolyWallAttribute:radd(depth, n, ...)
	depth = __VERIFY_DEPTH(depth)
	local function rrad(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			currentLayer:add(n, ...)
		else
			for _, nextLayer in pairs(currentLayer) do
				rrad(nextLayer, layerDepth - 1)
			end
		end
	end
	rrad(self, depth, ...)
end

-- Deletes a layer with integer key <n>.
function PolyWallAttribute:rmLayer(n)
	n = type(n) == 'number' and math.floor(n) or errorf(2, 'LayerRemoval', 'Argument #1 is not a number.')
	if not self[n] then errorf(2, 'LayerRemoval', 'Layer <%d> does not exist.', n) end
	self[n].P:rrmWall()
	self[n]:rrmWall()
	self[n]:rrmLayer()
	self[n] = nil
end

-- Deletes all layers
function PolyWallAttribute:rrmLayer(depth)
	depth = __VERIFY_DEPTH(depth)
	local function rrmLayer(currentLayer, layerDepth)
		if layerDepth <= 0 then
			for k, _ in pairs(currentLayer) do
				currentLayer:rmLayer(k)
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				rrmLayer(nextLayer, layerDepth - 1)
			end
		end
	end
	rrmLayer(self, depth)
end

-- Deletes a layer with cw key <n>.
function PolyWallAttribute:rmWall(key)
	if type(key) ~= 'table' then errorf(2, 'WallRemoval', 'Argument #1 is not a table.') end
	if type(key.K) ~= 'number' then errorf(2, 'WallRemoval', 'Invalid or missing custom wall key.') end
	if not self.W[key] then errorf(2, 'WallRemoval', 'Custom wall <%d> does not exist.', key.K) end
	cw_setVertexPos4(key.K, 0, 0, 0, 0, 0, 0, 0, 0)
	cw_destroy(key.K)
	self.W[key] = nil
end

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
	depth = __VERIFY_DEPTH(depth)
	local function sWall(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			local key = {K = cw_create()}
			currentLayer.W[key] = currentLayer:construct(...)
			return key
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
	depth = __VERIFY_DEPTH(depth)
	local function nWall(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			local key = {K = cw_createNoCollision()}
			currentLayer.W[key] = currentLayer:construct(...)
			return key
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
	depth = __VERIFY_DEPTH(depth)
	local function dWall(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			local key = {K = cw_createDeadly()}
			currentLayer.W[key] = currentLayer:construct(...)
			return key
		else
			for _, nextLayer in pairs(currentLayer) do
				dWall(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	return dWall(self, depth, ...)
end

function PolyWallAttribute:pivotCap(depth, r, g, b, a, pol, cart, col, a0, a1, ofs)
	depth = __VERIFY_DEPTH(depth)
	local function pivotCap(currentLayer, layerDepth)
		if layerDepth <= 0 then
			local key = currentLayer:nWall(0, nil, 0, 0, r, g, b, a, pol, cart, col, a0, a1, ofs, nil, 0)
			currentLayer.W[key].thickness:define(getCapRadius)
			return key
		else
			for _, nextLayer in pairs(currentLayer) do
				pivotCap(nextLayer, layerDepth - 1)
			end
		end
	end
	return pivotCap(self, depth)
end

function PolyWallAttribute:pivotBorder(depth, r, g, b, a, pol, cart, col, a0, a1, ofs)
	depth = __VERIFY_DEPTH(depth)
	local function pivotBorder(currentLayer, layerDepth)
		if layerDepth <= 0 then
			local key = currentLayer:nWall(0, nil, 0, 0, r, g, b, a, pol, cart, col, a0, a1, ofs, nil, 0)
			currentLayer.W[key].thickness:define(getPivotRadius)
			currentLayer.W[key].limit.extent:define(getCapRadius)
			return key
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
	depth = __VERIFY_DEPTH(depth)
	local function hasWalls(currentLayer, layerDepth)
		if layerDepth <= 0 then
			assert(not next(currentLayer.W))
		else
			for _, nextLayer in pairs(currentLayer) do
				pivotBorder(nextLayer, layerDepth - 1)
			end
		end
	end
	local out = pcall(hasWalls, self, depth)
	return out
end

-- Creates <n> layers ranging from [0, <n>)
function PolyWallAttribute:template(depth, n, ...)
	depth = __VERIFY_DEPTH(depth)
	n = type(n) == 'number' and math.floor(n) - 1 or errorf(2, 'Template', 'Argument #2 is not a number.')
	local function template(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			currentLayer:rrmLayer()
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
	depth = __VERIFY_DEPTH(depth)
	shape = verifyShape(shape)
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
	depth = __VERIFY_DEPTH(depth)
	shape = verifyShape(shape)
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
	depth = __VERIFY_DEPTH(depth)
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

-- Calculates all layer wall positions.
-- The ... may seem useless, but it prevents a highly unpredictable bug from occuring.
function PolyWallAttribute:advance(depth, mFrameTime)
	depth = __VERIFY_DEPTH(depth)
	local function advance(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for _, wall in pairs(currentLayer.W) do
				wall.position:set(wall.position:get() - mFrameTime * wall.speed:get() * wall.limit:dir())
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				advance(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	advance(self, depth)
end

-- Recursively updates all layer wall positions.
-- Depth is how many layers to descend to update walls
-- Transformations of all layers passed through while recursing are applied in reverse order when a wall is moved
-- The <tf> parameter is used for passing down transformation functions while recursing
-- Note that all polar and cartesian transformation parameters are unioned.
function PolyWallAttribute:step(depth, ...)
	depth = __VERIFY_DEPTH(depth)
	local function step(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				local angle0, angle1 = wall.angle:result()
				local pos, th, innerLim, outerLim = wall.position:get(), wall.thickness:get(), wall.limit:order()
				if pos <= innerLim - math.abs(th) or pos >= outerLim + math.abs(th) then
					currentLayer:rmWall(key)
				else
					local innerRad, outerRad = clamp(pos, innerLim, outerLim), clamp(pos + th * wall.limit:dir(), innerLim, outerLim)
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
				step(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	step(self, depth, ...)
end

-- Updates all layer wall colors.
function PolyWallAttribute:fill(depth, ...)
	depth = __VERIFY_DEPTH(depth)
	local function fill(currentLayer, layerDepth, ...)
		if layerDepth <= 0 then
			for key, wall in pairs(currentLayer.W) do
				cw_setVertexColor4(key.K, wall.vertex:chresult(...))
			end
		else
			for _, nextLayer in pairs(currentLayer) do
				fill(nextLayer, layerDepth - 1, ...)
			end
		end
	end
	fill(self, depth, ...)
end

-- Union of advance and tint.
function PolyWallAttribute:arrange(depth, mFrameTime, r, g, b, a)
	self:advance(depth, mFrameTime)
	self:tint(depth, r, g, b, a)
end

-- Union of fill and step.
-- Note that polar, cartesian, and color transformation parameters are unioned.
function PolyWallAttribute:update(depth, ...)
	self:step(depth, ...)
	self:fill(depth, ...)
end

-- Union of advance and step.
function PolyWallAttribute:move(depth, mFrameTime, ...)
	self:advance(depth, mFrameTime)
	self:step(depth, ...)
end

-- Union of arrange and update.
-- Note that polar, cartesian, and color transformation parameters are unioned.
function PolyWallAttribute:draw(depth, mFrameTime, r, g, b, a, ...)
	self:arrange(depth, mFrameTime, r, g, b, a)
	self:update(depth, ...)
end

-- Sorts wall CW handles such that lower numbered handles are moved to lower layers and higher numbered handles to higher layers
-- Order can be reversed by setting <decending> parameter to true
-- Enables wall layering based on layer IDs
-- Only affects currently existing walls
-- Layering within layers is unstable and will very likely change
function PolyWallAttribute:sort(depth, descending)
	depth = __VERIFY_DEPTH(depth)
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