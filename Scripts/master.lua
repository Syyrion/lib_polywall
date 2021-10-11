u_execDependencyScript('library_extbase', 'extbase', 'syyrion', 'utils.lua')

--[[
	* METATABLE TOOLS
]]

-- Metatable that sets values to be weak.
local __WEAKVALUES = {__mode = 'v'}

--[[
	* ERROR MESSAGES
]]

local __E = setmetatable({
	tm = 'TemplatingError',
	lr = 'LayerRemovalError',
	lc = 'LayerCreationError',
	wc = 'WallCreationError',
	df = 'SetDefaultError',

	dne = 'Layer <%d> does not exist',
	ovr = 'Cannot overwrite already existing layer <%d>',
	sum = 'Sum of all values in ratio must be greater than 0',
	inv = 'Argument #%d is invalid',
	ret = 'Number of return values is incorrect. Should return %d values, got %d',
	arg = 'Argument #%d is not a %s',
	cus = '%s'
}, {
	__call = function (this, err, msg, ...)
		return string.format('[%s] %s.', this[err], string.format(this[msg], ...))
	end
})

--[[
	* DEFAULTER CLASS
]]

local __D = setmetatable({
	set = function (self, fn, verify)
		if type(fn) ~= "function" then self.fn = nil return end
		local t = {fn()}
		local l = #t
		assert(l == 1, __E('df', 'ret', 1, l))
		assert(verify(t[1]), __E('df', 'cus', 'Verification failed. Default function did not return proper values.'))
		self.fn = fn
	end
}, {
	__call = function (this, inherit, fn)
		return setmetatable({
			__index = function (this, key)
				local mt = getmetatable(this)
				return mt.fn and key == 'val' and mt.fn() or mt.inherit[key]
			end,
			fn = fn,
			inherit = inherit
		}, this)
	end
})
__D.__index = __D

--[[
	* BASE DISCRETE CLASSES
]]

--[[
	* Discrete class
	Contains functions that all discrete classes use
]]
local Discrete = {}
Discrete.__index = Discrete
function Discrete:new(init)
	local newInst = setmetatable({}, __D(self))
	newInst.__index = newInst
	newInst:set(init)
	return newInst
end
-- Sets a value. If verification fails, the value is removed
function Discrete:set(val) self.val = self.verify(val) and val or nil end
-- Gets a value
function Discrete:get() return self.val end
-- Gets a value without searching for a default value
function Discrete:rawget() return rawget(self, 'val') end
-- Gets the default value regardless of if a value is set
function Discrete:defget()
	local mt = getmetatable(self)
	return mt.fn and mt.fn() or mt.inherit['val']
end
-- Sets a value to its default
function Discrete:freeze() self.val = self:defget() end
-- Defines a value's default function
function Discrete:def(fn) getmetatable(self):set(fn, self.verify) end

--[[
	* Discrete Numeric class
	-- Handles a single numerical parameter value with default value 0
]]
local DiscreteNumeric = setmetatable({val = 0}, Discrete)
DiscreteNumeric.__index = DiscreteNumeric
function DiscreteNumeric.verify(val) return type(val) == 'number' end

--[[
	* Discrete Boolean class
	-- Handles a single boolean parameter value with default value false
]]
local DiscreteBoolean = setmetatable({val = false}, Discrete)
DiscreteBoolean.__index = DiscreteBoolean
function DiscreteBoolean.verify(val) return type(val) == 'boolean' end


--[[
	* TRANSFORMATION CLASSES
]]

--[[
	* Discrete Transformation Class
	Handles a discrete transformation
]]
local DiscreteTransform = setmetatable({}, Discrete)
DiscreteTransform.__index = DiscreteTransform
function DiscreteTransform:run(...) return self.val(...) end

--[[
	* Discrete Position Transformation Class
	Handles a single 2 arguement position transformation function
]]
local DiscretePositionTransform = setmetatable({val = function (a, b) return a, b end}, DiscreteTransform)
DiscretePositionTransform.__index = DiscretePositionTransform
function DiscretePositionTransform.verify(val) return type(val) == 'function' end

--[[
	* Color Transformation Class
	Handles a single 4 arguement col transformation function
]]
local DiscreteColorTransform = setmetatable({val = function (r, g, b, a) return r, g, b, a end}, DiscreteTransform)
DiscreteColorTransform.__index = DiscreteColorTransform
function DiscreteColorTransform.verify(val) return type(val) == 'function' end



--[[
	* COLOR CLASSES
]]

--[[
	* Discrete Channel Class
	Handles a discrete col channel
]]
local DiscreteChannel = setmetatable({}, DiscreteNumeric)
DiscreteChannel.__index = DiscreteChannel
function DiscreteChannel:set(val) self.val = self.verify(val) and clamp(math.floor(val), 0, 255) or nil end

--[[
	* Color Channel Classes
	Each handles a single channel
]]
local RChannel = setmetatable({}, __D(DiscreteChannel, function () return ({s_getMainColor()})[1] end))
RChannel.__index = RChannel
local GChannel = setmetatable({}, __D(DiscreteChannel, function () return ({s_getMainColor()})[2] end))
GChannel.__index = GChannel
local BChannel = setmetatable({}, __D(DiscreteChannel, function () return ({s_getMainColor()})[3] end))
BChannel.__index = BChannel
local AChannel = setmetatable({}, __D(DiscreteChannel, function () return ({s_getMainColor()})[4] end))
AChannel.__index = AChannel

Channel = {
	r = RChannel,
	g = GChannel,
	b = BChannel,
	a = AChannel,
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
function Channel:defget() return self.r:defget(), self.g:defget(), self.b:defget(), self.a:defget() end
function Channel:freeze() self.r:freeze() self.g:freeze() self.b:freeze() self.a:freeze() end
function Channel:def(rfn, gfn, bfn, afn) self.r:def(rfn) self.g:def(gfn) self.b:def(bfn) self.a:def(afn) end




--[[
	* VERTEX CLASSES
]]

--[[
	* Discrete Vertex Class
	Handles a single vertex's col and transformations
]]
local DiscreteVertex = {
	ch = Channel,
	pol = DiscretePositionTransform,
	cart = DiscretePositionTransform,
	col =DiscreteColorTransform
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
function DiscreteVertex:getres(...)
	local r, g, b, a = self.ch:get()
	return self.col:run(r, g, b, a, ...)
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
function QuadVertex:chdefget()
	local r0, g0, b0, a0 = self[0].ch:defget()
	local r1, g1, b1, a1 = self[1].ch:defget()
	local r2, g2, b2, a2 = self[2].ch:defget()
	return r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, self[3].ch:defget()
end
function QuadVertex:chfreeze() for i = 0, 3 do self[i].ch:freeze() end end
function QuadVertex:chdef(rfn, gfn, bfn, afn) for i = 0, 3 do self[i].ch:def(rfn, gfn, bfn, afn) end end

function QuadVertex:chgetres(...)
	local r0, g0, b0, a0 = self[0]:getres(...)
	local r1, g1, b1, a1 = self[1]:getres(...)
	local r2, g2, b2, a2 = self[2]:getres(...)
	return r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, self[3]:getres(...)
end

function QuadVertex:polset(pol) for i = 0, 3 do self[i].pol:set(pol) end end
function QuadVertex:polget() return self[0].pol:get(), self[1].pol:get(), self[2].pol:get(), self[3].pol:get() end
function QuadVertex:polrawget() return self[0].pol:rawget(), self[1].pol:rawget(), self[2].pol:rawget(), self[3].pol:rawget() end
function QuadVertex:poldefget() return self[0].pol:defget(), self[1].pol:defget(), self[2].pol:defget(), self[3].pol:defget() end
function QuadVertex:polfreeze() for i = 0, 3 do self[i].pol:freeze() end end
function QuadVertex:poldef(fn) for i = 0, 3 do self[i].pol:def(fn) end end

function QuadVertex:cartset(cart) for i = 0, 3 do self[i].cart:set(cart) end end
function QuadVertex:cartget() return self[0].cart:get(), self[1].cart:get(), self[2].cart:get(), self[3].cart:get() end
function QuadVertex:cartrawget() return self[0].cart:rawget(), self[1].cart:rawget(), self[2].cart:rawget(), self[3].cart:rawget() end
function QuadVertex:cartdefget() return self[0].cart:defget(), self[1].cart:defget(), self[2].cart:defget(), self[3].cart:defget() end
function QuadVertex:cartfreeze() for i = 0, 3 do self[i].pol:freeze() end end
function QuadVertex:cartdef(fn) for i = 0, 3 do self[i].pol:def(fn) end end

function QuadVertex:colset(col) for i = 0, 3 do self[i].col:set(col) end end
function QuadVertex:colget() return self[0].col:get(), self[1].col:get(), self[2].col:get(), self[3].col:get() end
function QuadVertex:colrawget() return self[0].col:rawget(), self[1].col:rawget(), self[2].col:rawget(), self[3].col:rawget() end
function QuadVertex:coldefget() return self[0].col:defget(), self[1].col:defget(), self[2].col:defget(), self[3].col:defget() end
function QuadVertex:colfreeze() for i = 0, 3 do self[i].pol:freeze() end end
function QuadVertex:coldef(fn) for i = 0, 3 do self[i].pol:def(fn) end end



--[[
	* PARAMETER CLASSES
]]

--[[
	* Dual angle parameter class
	Handles two angles and an offset
]]
local DualAngle = {
	origin = DiscreteNumeric,
	extent = DiscreteNumeric,
	offset = DiscreteNumeric
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
function DualAngle:defget() return self.origin:defget(), self.extent:defget(), self.offset:defget() end
function DualAngle:freeze() self.origin:freeze() self.extent:freeze() self.offset:freeze() end
function DualAngle:def(a0fn, a1fn, ofsfn) self.origin:def(a0fn) self.extent:def(a1fn) self.offset:def(ofsfn) end
function DualAngle:getres()
	local ofs = self.offset:get()
	return self.origin:get() + ofs, self.extent:get() + ofs
end

--[[
	* Limit head class
	Contains default starting limit
]]
local LimitOrigin = setmetatable({val = 1600}, DiscreteNumeric)
LimitOrigin.__index = LimitOrigin

--[[
	* Limit tail parameter class
	Contains default ending limit
]]
local LimitExtent = setmetatable({}, __D(DiscreteNumeric, getPolygonRadius))
LimitExtent.__index = LimitExtent

--[[
	* Dual limit parameter class
	Handles origin and extent limits
]]
local DualLimit = {
	origin = LimitOrigin,
	extent = LimitExtent
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
function DualLimit:defget() return self.origin:defget(), self.extent:defget() end
function DualLimit:freeze() self.origin:freeze() self.extent:freeze() end
function DualLimit:def(lim0fn, lim1fn) self.origin:def(lim0fn) self.extent:def(lim1fn) end
function DualLimit:swap()
	local o, e = self:get()
	self:set(e, o)
end
function DualLimit:order()
	local lh, lt = self.origin:get(), self.extent:get()
	if lh >= lt then return lt, lh end
	return lh, lt
end
function DualLimit:dir() return self.origin:get() >= self.extent:get() and 1 or -1 end

--[[
	* Thickness parameter class
	Contains default thickness value
]]
local Thickness = setmetatable({val = 40}, DiscreteNumeric)
Thickness.__index = Thickness

--[[
	* Speed parameter class
	Contains default speed calculation function
]]
local Speed = setmetatable({}, __D(DiscreteNumeric, getWallSpeed))
Speed.__index = Speed

local MockPlayerAngle = setmetatable({}, __D(DiscreteNumeric, u_getPlayerAngle))
MockPlayerAngle.__index = MockPlayerAngle
local MockPlayerRadius = setmetatable({}, __D(DiscreteNumeric, getPlayerTipRadius))
MockPlayerRadius.__index = MockPlayerRadius
local MockPlayerHeight = setmetatable({}, __D(DiscreteNumeric, getPlayerHeight))
MockPlayerHeight.__index = MockPlayerHeight
local MockPlayerWidth = setmetatable({}, __D(DiscreteNumeric, getPlayerWidth))
MockPlayerWidth.__index = MockPlayerWidth

local __VERIFYDEPTH = function (depth)
	return type(depth) == 'number' and math.floor(depth) or 0
end

--[[
	* Master class
]]
local __MASTER = {}
__MASTER.__index = __MASTER
function __MASTER:rw(key)
	cw_setVertexPos4(key, 0, 0, 0, 0, 0, 0, 0, 0)
	cw_destroy(key)
	self.array[key] = nil
	collectgarbage()
end
function __MASTER:fullrw(depth)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for k, _ in pairs(self.array) do
			self:rw(k)
		end
	else
		for _, v in pairs(self.layer) do
			v:fullrw(depth - 1)
		end
	end
end
-- Sets all layer wall colors.
function __MASTER:tint(depth, r, g, b, a)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for _, v in pairs(self.array) do
			v.vertex:chset(r, g, b, a)
		end
	else
		for _, v in pairs(self.layer) do
			v:tint(depth - 1, r, g, b, a)
		end
	end
end
-- Union of advance and tint.
function __MASTER:arrange(depth, mFrameTime, r, g, b, a)
	self:advance(depth, mFrameTime)
	self:tint(depth, r, g, b, a)
end
-- Union of fill and step.
-- Note that polar, cartesian, and color transformation parameters are unioned.
function __MASTER:update(depth, ...)
	self:step(depth, ...)
	self:fill(depth, ...)
end
-- Union of advance and step.
function __MASTER:move(depth, mFrameTime, ...)
	self:advance(depth, mFrameTime)
	self:step(depth, ...)
end
-- Union of tint and step.
function __MASTER:shade(depth, r, g, b, a, ...)
	self:tint(depth, r, g, b, a)
	self:fill(depth, ...)
end
-- Union of arrange and update.
-- Note that polar, cartesian, and color transformation parameters are unioned.
function __MASTER:draw(depth, mFrameTime, r, g, b, a, ...)
	self:arrange(depth, mFrameTime, r, g, b, a)
	self:update(depth, ...)
end

--[[
	* MockPlayer class
]]
local MockPlayer = setmetatable({
	angle = DiscreteNumeric,
	offset = DiscreteNumeric,
	radius = MockPlayerRadius,
	height = MockPlayerHeight,
	width = MockPlayerWidth,
	accurate = DiscreteBoolean,
	layer = setmetatable({}, __WEAKVALUES),
	array = {}
}, __MASTER)
MockPlayer.__index = MockPlayer

function MockPlayer:new(parent)
	local newInst = setmetatable({
		angle = self.angle:new(),
		offset = self.offset:new(),
		radius = self.radius:new(),
		height = self.height:new(),
		width = self.width:new(),
		vertex = parent.vertex:new(),
		accurate = self.accurate:new(),
		layer = setmetatable({}, __WEAKVALUES),
		array = {}
	}, self)
	newInst.__index = newInst
	return newInst
end

-- Creates a MockPlayer
-- Returns the custom wall handle but only if depth is 0
function MockPlayer:create(depth, ...)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		local key = cw_createNoCollision()
		self.array[key] = self:new(...)
		return key
	else
		for _, v in pairs(self.layer) do
			v:create(depth - 1, ...)
		end
	end
end
-- MockPlayer advance function has no use
function MockPlayer:advance() end
function MockPlayer:step(depth, mFocus, ...)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for k, v in pairs(self.array) do
			local angle, radius, halfWidth = v.angle:get(), v.radius:get(), v.width:get() * 0.5 * (mFocus and FOCUSRATIO or 1)
			local baseRadius, accurate = radius - v.height:get(), v.accurate:get()
			local sideRadius = accurate and (halfWidth * halfWidth + baseRadius * baseRadius) ^ 0.5 or baseRadius
			local sideAngle = (accurate and math.atan or function (n)
				return n
			end)(halfWidth / baseRadius) + (baseRadius < 0 and math.pi or 0)

			local r0, a0 = v.vertex[0].pol:run(radius, angle, ...)
			local r1, a1 = v.vertex[1].pol:run(sideRadius, angle + sideAngle, ...)
			local r2, a2 = v.vertex[2].pol:run(sideRadius, angle - sideAngle, ...)
			local x0, y0 = v.vertex[0].cart:run(r0 * math.cos(a0), r0 * math.sin(a0), ...)
			local x1, y1 = v.vertex[1].cart:run(r1 * math.cos(a1), r1 * math.sin(a1), ...)
			local x2, y2 = v.vertex[2].cart:run(r2 * math.cos(a2), r2 * math.sin(a2), ...)
			cw_setVertexPos4(k, x0, y0, x1, y1, x2, y2, x2, y2)
		end
	else
		for _, v in pairs(self.layer) do
			v:step(depth - 1, mFocus, ...)
		end
	end
end
function MockPlayer:fill(depth, ...)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for k, v in pairs(self.array) do
			cw_setVertexColor4(k, unpack({v.vertex:chgetres(...)}))
		end
	else
		for _, v in pairs(self.layer) do
			v:fill(depth - 1, ...)
		end
	end
end

--[[
	* PolyWall Class
]]
PolyWall = setmetatable({
	angle = DualAngle,
	limit = DualLimit,
	thickness = Thickness,
	speed = Speed,
	vertex = QuadVertex,
	layer = setmetatable({}, __WEAKVALUES),
	array = {},
	player = MockPlayer
}, __MASTER)
PolyWall.__index = PolyWall

function PolyWall:new(a0, a1, ofs, lim0, lim1, th, sp, p, r, g, b, a, pol, cart, col)
	local newInst = setmetatable({
		angle = self.angle:new(a0, a1, ofs),
		limit = self.limit:new(lim0, lim1),
		thickness = self.thickness:new(th),
		speed = self.speed:new(sp),
		position = type(p) == 'number' and p or nil,
		vertex = self.vertex:new(r, g, b, a, pol, cart, col),
		layer = setmetatable({}, __WEAKVALUES),
		array = {}
	}, {
		__index = function (this, key)
			return type(key) ~= 'number' and (function ()
				local mt = getmetatable(this)
				return mt.inherit[key]
			end)() or nil
		end,
		inherit = self
	})
	newInst.player = self.player:new(newInst)
	newInst.__index = newInst
	return newInst
end
function PolyWall:posset(p) self.position = type(p) == 'number' and p or nil end
function PolyWall:posget() return self.position or (self.speed:get() >= 0 and self.limit.origin:get() or self.limit.extent:get()) end
function PolyWall:posrawget() return rawget(self, 'position') end

-- Creates a new layer with positive integer key <n>.
-- If <n> is nil or invalid, inserts new layer at end of list.
function PolyWall:add(n, ...)
	n = type(n) == 'number' and math.floor(n) or error(__E('lc', 'arg', 1, 'number'))
	assert(not self[n], __E('lc', 'ovr', n))
	local newInst = self:new(...)
	self[n] = newInst
	self.layer[n] = newInst
	self.player.layer[n] = newInst.player
end
-- Deletes a layer with positive integer key <n>.
-- If <n> is nil or invalid, deletes the layer at end of list.
function PolyWall:rm(n)
	n = type(n) == 'number' and math.floor(n) or error(__E('lr', 'arg', 1, 'number'))
	assert(self[n], __E('lr', 'dne', n))
	self[n]:fullrw()
	self[n]:fullrm()
	self[n] = nil
	collectgarbage()
end
-- Deletes all layers
function PolyWall:fullrm(depth)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for k, _ in pairs(self.layer) do
			self:rm(k)
		end
	else
		for _, v in pairs(self.layer) do
			v:fullrm(depth - 1)
		end
	end
end

-- Creates a wall of specified type
-- Type can be 's', 'n' or 'd'
-- Returns the custom wall handle
function PolyWall:wall(depth, t, ...)
	assert(type(t) == 'string', __E('wc', 'arg', 1, 'string'))
	return assert(self[t .. 'Wall'], __E('wc', 'inv', 1))(depth, ...)
end
-- Creates a standard wall
-- Returns the custom wall handle but only if depth is 0
function PolyWall:sWall(depth, ...)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		local key = cw_create()
		self.array[key] = self:new(...)
		return key
	else
		for _, v in pairs(self.layer) do
			v:sWall(depth - 1, ...)
		end
	end
end
-- Creates a non-solid wall
-- Returns the custom wall handle but only if depth is 0
function PolyWall:nWall(depth, ...)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		local key = cw_createNoCollision()
		self.array[key] = self:new(...)
		return key
	else
		for _, v in pairs(self.layer) do
			v:nWall(depth - 1, ...)
		end
	end
end
-- Creates a deadly wall
-- Returns the custom wall handle but only if depth is 0
function PolyWall:dWall(depth, ...)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		local key = cw_createDeadly()
		self.array[key] = self:new(...)
		return key
	else
		for _, v in pairs(self.layer) do
			v:dWall(depth - 1, ...)
		end
	end
end


function PolyWall:template(n, ...)
	n = type(n) == 'number' and math.floor(n) or error(__E('tm', 'arg', 1, 'number'))
	self:fullrm()
	for i = 1, n do self:add(i, ...) end
end

-- Rearranges layers into a regular shape.
-- Only affects layer indexes from 1 to <shape>
function PolyWall:regularize(shape, ofs)
	shape = verifyShape(shape)
	local arc = math.tau / shape
	local prev, cur = nil, arc * -0.5
	for i = 1, shape do
		prev = cur
		cur = cur + arc
		self[i].angle:set(prev, cur, ofs)
	end
end
-- Rearranges layers into a proportional shape.
-- Only affects layer indexes from 1 to ratio length
-- Returns the largest index of the new layers
function PolyWall:proportionalize(ofs, ...)
	local t, ref = {...}, {0}
	local l = #t
	for i = 1, l do
		assert(type(t[i]) == 'number', __E('tm', 'arg', 1 + i, 'number'))
		ref[i + 1] = ref[i] + t[i]
	end
	assert(ref[l] > 0, __E('tm', 'sum'))
	local prev = map(ref[1], 0, ref[l + 1], 0, math.tau)
	for i = 1, l do
		local cur = map(ref[i + 1], 0, ref[l + 1], 0, math.tau)
		self[i].angle:set(prev, cur, ofs)
		prev = cur
	end
	return l
end

-- Calculates all layer wall positions.
function PolyWall:advance(depth, mFrameTime)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for _, v in pairs(self.array) do
			v:posset(v:posget() - mFrameTime * v.speed:get() * v.limit:dir())
		end
	else
		for _, v in pairs(self.layer) do
			v:advance(depth - 1, mFrameTime)
		end
	end
end
-- Recursively updates all layer wall positions.
-- Depth is how many layers to descend to update walls
-- Transformations of all layers passed through while recursing are applied in reverse order when a wall is moved
-- The <tf> parameter is used for passing down transformation functions while recursing
-- Note that all polar and cartesian transformation parameters are unioned.
function PolyWall:step(depth, ...)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for k, v in pairs(self.array) do
			local angle0, angle1 = v.angle:getres()
			local pos, th, innerLim, outerLim = v:posget(), v.thickness:get(), v.limit:order()
			if pos <= innerLim - math.abs(th) or pos >= outerLim + math.abs(th) then
				self:rw(k)
			else
				local innerRad, outerRad = clamp(pos, innerLim, outerLim), clamp(pos + th * v.limit:dir(), innerLim, outerLim)
				local r0, a0 = v.vertex[0].pol:run(innerRad, angle0, ...)
				local r1, a1 = v.vertex[1].pol:run(innerRad, angle1, ...)
				local r2, a2 = v.vertex[2].pol:run(outerRad, angle1, ...)
				local r3, a3 = v.vertex[3].pol:run(outerRad, angle0, ...)
				local x0, y0 = v.vertex[0].cart:run(r0 * math.cos(a0), r0 * math.sin(a0), ...)
				local x1, y1 = v.vertex[1].cart:run(r1 * math.cos(a1), r1 * math.sin(a1), ...)
				local x2, y2 = v.vertex[2].cart:run(r2 * math.cos(a2), r2 * math.sin(a2), ...)
				local x3, y3 = v.vertex[3].cart:run(r3 * math.cos(a3), r3 * math.sin(a3), ...)
				cw_setVertexPos4(k, x0, y0, x1, y1, x2, y2, x3, y3)
			end
		end
	else
		for _, v in pairs(self.layer) do
			v:step(depth - 1, ...)
		end
	end
end
-- Updates all layer wall colors.
function PolyWall:fill(depth, ...)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for k, v in pairs(self.array) do
			cw_setVertexColor4(k, unpack({v.vertex:chgetres(...)}))
		end
	else
		for _, v in pairs(self.layer) do
			v:fill(depth - 1, ...)
		end
	end
end






-- TODO: Finish
-- Sorts wall CW handles such that lower numbered handles are moved to lower layers and higher numbered handles to higher layers
-- Sortings acts on all walls of all descendant layers of the origin layer
-- Order can be reversed by setting <decending> parameter to true
-- Enables wall layering based on layer IDs
-- Only affects currently existing walls
-- Layering within layers is unstable and will very likely change
function PolyWall:sort(descending)
	local keys, layers, layerInsert = {}, {}, function (layers, lx, wObj)
		table.insert(layers, {
			lx = lx,
			wObj = wObj
		})
	end
	for lx, lObj in pairs(self.layer) do
		for cwKey, wObj in pairs(lObj) do
			table.insert(keys, cwKey)
			layerInsert(layers, lx, wObj)
			self[lx].set[cwKey] = nil
		end
	end
	table.sort(keys, descending and function(a, b) return a > b end or function(a, b) return a < b end)
	table.sort(layers, function(a, b) return a.lx < b.lx end)
	for i = 1, #keys do
		self[layers.lx].set[keys[i]] = layers.wObj
	end
end