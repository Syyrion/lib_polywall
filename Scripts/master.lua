u_execDependencyScript('library_extbase', 'extbase', 'syyrion', 'utils.lua')

--[[
	* METATABLE TOOLS
]]

local __WEAK = {__mode = 'v'}

-- Metatable which allows tables to be concatenated with the .. operator.
local __TABLECONCAT = {
	__concat = function (this, that)
		for k, v in pairs(that) do this[k] = v end
		return this
	end
}

-- Creates a metatable that gets a default value by calling a function (in case the default value changes).
local __DEFAULTFN = function (inherit, label, fn)
	return {
		__index = function (this, key)
			local mt = getmetatable(this)
			if key == mt.__LABEL then return mt.__FN() end
			return mt.__INHERIT[key]
		end,
		__LABEL = label,
		__FN = fn,
		__INHERIT = inherit
	}
end

--[[
	* ERROR MESSAGES
]]

local __E = setmetatable({
	pr = 'ProportionalizeError',
	lr = 'LayerRemovalError',
	lc = 'LayerCreationError',
	wc = 'WallCreationError',
	cm = 'CompilationError',
	ex = 'ExecutionError',
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
	__index = function (this, key)
		local mt = getmetatable(this)
		if mt.fn and key == 'val' then return mt.fn() end
		return mt.inherit[key]
	end,
	set = function (self, fn, verify)
		if type(val) ~= "function" then self.fn = nil return end
		local t = {fn()}
		local l = #t
		assert(l == 1, __E('df', 'ret', 1, l))
		assert(verify(t[1]), __E('df', 'cus', 'Verification failed. Default function did not return proper values.'))
		self.fn = fn
	end
}, {
	__call = function (this, inherit, fn)
		return setmetatable({
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
function Discrete:set(val) self.val = self.verify(val) and val or nil end
function Discrete:get() return self.val end
function Discrete:rawget() return rawget(self, 'val') end
function Discrete:freeze() self.val = self:get() end
function Discrete:default(fn) getmetatable(self):set(fn, self.verify) end

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
function DiscretePositionTransform.verify(val)
	if type(val) ~= "function" then return false end
	local t = #({val(0, 0)})
	if #t ~= 2 then return false end
	for i = 1, 2 do if type(t[i]) ~= 'number' then return false end end
	return true
end

--[[
	* Color Transformation Class
	Handles a single 4 arguement col transformation function
]]
local DiscreteColorTransform = setmetatable({val = function (r, g, b, a) return r, g, b, a end}, DiscreteTransform)
DiscreteColorTransform.__index = DiscreteColorTransform
function DiscreteColorTransform.verify(val)
	if type(val) ~= "function" then return false end
	local t = #({val(s_getMainColor())})
	if #t ~= 4 then return false end
	for i = 1, 4 do if type(t[i]) ~= 'number' then return false end end
	return true
end



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



--[[
	* VERTEX CLASSES
]]

--[[
	* Discrete Vertex Class
	Handles a single vertex's col and transformations
]]
local DiscreteVertex = {
	r = RChannel,
	g = GChannel,
	b = BChannel,
	a = AChannel
}
DiscreteVertex.__index = DiscreteVertex
function DiscreteVertex:new(r, g, b, a, pol, cart, col)
	local newInst = setmetatable({
		r = self.r:new(r),
		g = self.g:new(g),
		b = self.b:new(b),
		a = self.a:new(a),
		pol = DiscretePositionTransform:new(pol),
		cart = DiscretePositionTransform:new(cart),
		col = DiscreteColorTransform:new(col)
	}, self)
	newInst.__index = newInst
	return newInst
end
function DiscreteVertex:setRGBA(r, g, b, a) self.r:set(r) self.g:set(g) self.b:set(b) self.a:set(a) end
function DiscreteVertex:setRGB(r, g, b) self.r:set(r) self.g:set(g) self.b:set(b) end
function DiscreteVertex:setHSVA(h, s, v, a) self:setRGBA(unpack(setmetatable({fromHSV(h, s, v)}, __TABLECONCAT) .. {a})) end
function DiscreteVertex:setHSV(h, s, v) self:setRGB(fromHSV(h, s, v)) end
function DiscreteVertex:getRGBA() return self.r:get(), self.g:get(), self.b:get(), self.a:get() end
function DiscreteVertex:getRGBAResult(...) return self.col:run(self.r:get(), self.g:get(), self.b:get(), self.a:get(), ...) end
function DiscreteVertex:rawgetRGBA() return self.r:rawget(), self.g:rawget(), self.b:rawget(), self.a:rawget() end
function DiscreteVertex:freezeRGBA() self.r:freeze() self.g:freeze() self.b:freeze() self.a:freeze() end

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
function QuadVertex:setRGBA(r, g, b, a) for i = 0, 3 do self[i]:setRGBA(r, g, b, a) end end
function QuadVertex:setRGB(r, g, b) for i = 0, 3 do self[i]:setRGB(r, g, b) end end
function QuadVertex:setHSVA(h, s, v, a) for i = 0, 3 do self[i]:setHSVA(h, s, v, a) end end
function QuadVertex:setHSV(h, s, v) for i = 0, 3 do self[i]:setHSV(h, s, v) end end
function QuadVertex:getRGBA() return unpack(setmetatable({self[0]:getRGBA()}, __TABLECONCAT) .. {self[1]:getRGBA()} .. {self[2]:getRGBA()} .. {self[3]:getRGBA()}) end
function QuadVertex:getRGBAResult(...) return unpack(setmetatable({self[0]:getRGBAResult(...)}, __TABLECONCAT) .. {self[1]:getRGBAResult(...)} .. {self[2]:getRGBAResult(...)} .. {self[3]:getRGBAResult(...)}) end
function QuadVertex:rawgetRGBA() return unpack(setmetatable({self[0]:rawgetRGBA()}, __TABLECONCAT) .. {self[1]:rawgetRGBA()} .. {self[2]:rawgetRGBA()} .. {self[3]:rawgetRGBA()}) end
function QuadVertex:freezeRGBA() for i = 0, 3 do self[i]:freezeRGBA() end end

function QuadVertex:setR(r) for i = 0, 3 do self[i].r:set(r) end end
function QuadVertex:getR() return self[0].r:get(), self[1].r:get(), self[2].r:get(), self[3].r:get() end
function QuadVertex:rawgetR() return self[0].r:rawget(), self[1].r:rawget(), self[2].r:rawget(), self[3].r:rawget() end
function QuadVertex:freezeR() for i = 0, 3 do self[i].r:freeze() end end

function QuadVertex:setG(g) for i = 0, 3 do self[i].g:set(g) end end
function QuadVertex:getG() return self[0].g:get(), self[1].g:get(), self[2].g:get(), self[3].g:get() end
function QuadVertex:rawgetG() return self[0].g:rawget(), self[1].g:rawget(), self[2].g:rawget(), self[3].g:rawget() end
function QuadVertex:freezeG() for i = 0, 3 do self[i].g:freeze() end end

function QuadVertex:setB(b) for i = 0, 3 do self[i].b:set(b) end end
function QuadVertex:getB() return self[0].b:get(), self[1].b:get(), self[2].b:get(), self[3].b:get() end
function QuadVertex:rawgetB() return self[0].b:rawget(), self[1].b:rawget(), self[2].b:rawget(), self[3].b:rawget() end
function QuadVertex:freezeB() for i = 0, 3 do self[i].b:freeze() end end

function QuadVertex:setA(a) for i = 0, 3 do self[i].a:set(a) end end
function QuadVertex:getA() return self[0].a:get(), self[1].a:get(), self[2].a:get(), self[3].a:get() end
function QuadVertex:rawgetA() return self[0].a:rawget(), self[1].a:rawget(), self[2].a:rawget(), self[3].a:rawget() end
function QuadVertex:freezeA() for i = 0, 3 do self[i].a:freeze() end end

function QuadVertex:setPolar(pol) for i = 0, 3 do self[i].pol:set(pol) end end
function QuadVertex:getPolar() return self[0].pol:get(), self[1].pol:get(), self[2].pol:get(), self[3].pol:get() end
function QuadVertex:rawgetPolar() return self[0].pol:rawget(), self[1].pol:rawget(), self[2].pol:rawget(), self[3].pol:rawget() end
function QuadVertex:freezePolar() for i = 0, 3 do self[i].pol:freeze() end end

function QuadVertex:setCartesian(cart) for i = 0, 3 do self[i].cart:set(cart) end end
function QuadVertex:getCartesian() return self[0].cart:get(), self[1].cart:get(), self[2].cart:get(), self[3].cart:get() end
function QuadVertex:rawgetCartesian() return self[0].cart:rawget(), self[1].cart:rawget(), self[2].cart:rawget(), self[3].cart:rawget() end
function QuadVertex:freezeCartesian() for i = 0, 3 do self[i].pol:freeze() end end

function QuadVertex:setColor(col) for i = 0, 3 do self[i].col:set(col) end end
function QuadVertex:getColor() return self[0].col:get(), self[1].col:get(), self[2].col:get(), self[3].col:get() end
function QuadVertex:rawgetColor() return self[0].col:rawget(), self[1].col:rawget(), self[2].col:rawget(), self[3].col:rawget() end
function QuadVertex:freezeColor() for i = 0, 3 do self[i].pol:freeze() end end



--[[
	* PARAMETER CLASSES
]]

--[[
	* Dual angle parameter class
	Handles two angles
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
function DualAngle:freeze() self.origin:freeze() self.extent:freeze() self.offset:freeze() end
function DualAngle:getResult()
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
local LimitExtent = setmetatable({val = 58}, __D(DiscreteNumeric, getPolygonRadius))
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
function DualLimit:freeze() self.origin:freeze() self.extent:freeze() end
function DualLimit:swap()
	local o, e = self:get()
	self:set(e, o)
end
function DualLimit:getInOrder()
	local lh, lt = self.origin:get(), self.extent:get()
	if lh >= lt then return lt, lh end
	return lh, lt
end
function DualLimit:getDir() return self.origin:get() >= self.extent:get() and 1 or -1 end

--[[
	* Thickness parameter class
	Contains default thickness value
]]
local Thickness = setmetatable({val = THICKNESS}, DiscreteNumeric)
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
function __MASTER:rwAll(depth)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for k, _ in pairs(self.array) do
			self:rw(k)
		end
	else
		for _, v in pairs(self.layer) do
			v:rwAll(depth - 1)
		end
	end
end
-- Sets all layer wall colors.
function __MASTER:tint(depth, r, g, b, a)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for _, v in pairs(self.array) do
			v.vertex:setRGBA(r, g, b, a)
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
	self:step(depth, nil, ...)
	self:fill(depth, nil, ...)
end
-- Union of advance and step.
function __MASTER:move(depth, mFrameTime, ...)
	self:advance(depth, mFrameTime)
	self:step(depth, nil, ...)
end
-- Union of tint and step.
function __MASTER:shade(depth, r, g, b, a, ...)
	self:tint(depth, r, g, b, a)
	self:fill(depth, nil, ...)
end
-- Union of arrange and update.
-- Note that polar, cartesian, and color transformation parameters are unioned.
function __MASTER:draw(depth, mFrameTime, r, g, b, a, ...)
	self:arrange(depth, mFrameTime, r, g, b, a)
	self:update(depth, nil, ...)
end

local __VERIFYDEPTH = function (depth)
	return type(depth) == 'number' and math.floor(depth) or 0
end

local __FOCUSCONST = 0.625

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
	layer = setmetatable({}, __WEAK),
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
		layer = setmetatable({}, __WEAK),
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
function MockPlayer:step(depth, tf, mFocus, ...)
	if type(tf) ~= 'table' then tf = {} end
	depth = __VERIFYDEPTH(depth)
	table.insert(tf, {
		pol = {self.vertex:getPolar()},
		cart = {self.vertex:getCartesian()}
	})
	if depth <= 0 then
		local tfLen = #tf
		for k, v in pairs(self.array) do
			local angle, radius, halfWidth = v.angle:get(), v.radius:get(), v.width:get() * 0.5 * (mFocus and __FOCUSCONST or 1)
			local baseRadius, accurate = radius - v.height:get(), v.accurate:get()
			local sideRadius = accurate and (halfWidth * halfWidth + baseRadius * baseRadius) ^ 0.5 or baseRadius
			local sideAngle = (accurate and math.atan or function (n)
				return n
			end)(halfWidth / baseRadius) + (baseRadius < 0 and math.pi or 0)

			local r0, a0 = v.vertex[0].pol:run(radius, angle, ...)
			local r1, a1 = v.vertex[1].pol:run(sideRadius, angle + sideAngle, ...)
			local r2, a2 = v.vertex[2].pol:run(sideRadius, angle - sideAngle, ...)
			for i = tfLen, 1, -1 do
				r0, a0 = tf[i].pol[1](r0, a0, ...)
				r1, a1 = tf[i].pol[2](r1, a1, ...)
				r2, a2 = tf[i].pol[3](r2, a2, ...)
			end
			local x0, y0 = v.vertex[0].cart:run(r0 * math.cos(a0), r0 * math.sin(a0), ...)
			local x1, y1 = v.vertex[1].cart:run(r1 * math.cos(a1), r1 * math.sin(a1), ...)
			local x2, y2 = v.vertex[2].cart:run(r2 * math.cos(a2), r2 * math.sin(a2), ...)
			for i = tfLen, 1, -1 do
				x0, y0 = tf[i].cart[1](x0, y0, ...)
				x1, y1 = tf[i].cart[2](x1, y1, ...)
				x2, y2 = tf[i].cart[3](x2, y2, ...)
			end
			cw_setVertexPos4(k, x0, y0, x1, y1, x2, y2, x2, y2)
		end
	else
		for _, v in pairs(self.layer) do
			v:step(depth - 1, tf, mFocus, ...)
		end
	end
end
function MockPlayer:fill(depth, tf, ...)
	if type(tf) ~= 'table' then tf = {} end
	depth = __VERIFYDEPTH(depth)
	table.insert(tf, {self.vertex:getColor()})
	if depth <= 0 then
		local tfLen = #tf
		for k, v in pairs(self.array) do
			local r0, g0, b0, a0 = v.vertex[0]:getRGBAResult(...)
			local r1, g1, b1, a1 = v.vertex[1]:getRGBAResult(...)
			local r2, g2, b2, a2 = v.vertex[2]:getRGBAResult(...)
			for i = tfLen, 1, -1 do
				r0, g0, b0, a0 = tf[i][1](r0, g0, b0, a0, ...)
				r1, g1, b1, a1 = tf[i][2](r1, g1, b1, a1, ...)
				r2, g2, b2, a2 = tf[i][3](r2, g2, b2, a2, ...)
			end
			cw_setVertexColor4(k, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r2, g2, b2, a2)
		end
	else
		for _, v in pairs(self.layer) do
			v:fill(depth - 1, tf, ...)
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
	layer = setmetatable({}, __WEAK),
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
		layer = setmetatable({}, __WEAK),
		array = {}
	}, self)
	newInst.player = self.player:new(newInst)
	newInst.__index = newInst
	return newInst
end
function PolyWall:setPosition(p) self.position = type(p) == 'number' and p or nil end
function PolyWall:getPosition() return self.position or (self.speed:get() >= 0 and self.limit.origin:get() or self.limit.extent:get()) end
function PolyWall:rawgetPosition() return self.position end

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
	self[n]:rwAll()
	self[n]:rmAll()
	self[n] = nil
	collectgarbage()
end
-- Deletes all layers
function PolyWall:rmAll(depth)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for k, _ in pairs(self.layer) do
			self:rm(k)
		end
	else
		for _, v in pairs(self.layer) do
			v:rmAll(depth - 1)
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

-- Recreates and arranges layers into a regular shape.
-- Operation deletes all layers and resets all parameters besides angles.
-- New layer indexes range from 1 to <shape>
function PolyWall:regularize(shape, ofs)
	self:rmAll()
	shape = verifyShape(shape)
	local arc = math.tau / shape
	local prev, cur = nil, arc / 2
	for i = 1, shape do
		prev = cur
		cur = cur + arc
		self:add(i, prev, cur, ofs)
	end
end
-- Recreates and arranges layers into a proportional shape.
-- Operation deletes all layers and resets all parameters besides angles.
-- New layer indexes range from 1 to ratio length
-- Returns the largest index of the new layers
function PolyWall:proportionalize(ofs, ...)
	self:rmAll()
	local t, ref = {...}, {0}
	local l = #t
	for i = 1, l do
		assert(type(t[i]) == 'number', __E('pr', 'arg', 1 + i, 'number'))
		ref[i + 1] = ref[i] + t[i]
	end
	assert(ref[l] > 0, __E('pr', 'sum'))
	local prev = map(ref[1], 0, ref[l + 1], 0, math.tau)
	for i = 1, l do
		local cur = map(ref[i + 1], 0, ref[l + 1], 0, math.tau)
		self:add(i, prev, cur, ofs)
		prev = cur
	end
	return l
end

-- Calculates all layer wall positions.
function PolyWall:advance(depth, mFrameTime)
	depth = __VERIFYDEPTH(depth)
	if depth <= 0 then
		for _, v in pairs(self.array) do
			v:setPosition(v:getPosition() - mFrameTime * v.speed:get() * v.limit:getDir())
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
function PolyWall:step(depth, tf, ...)
	if type(tf) ~= 'table' then tf = {} end
	depth = __VERIFYDEPTH(depth)
	table.insert(tf, {
		pol = {self.vertex:getPolar()},
		cart = {self.vertex:getCartesian()}
	})
	if depth <= 0 then
		local tfLen = #tf
		for k, v in pairs(self.array) do
			local angle0, angle1 = v.angle:getResult()
			local pos, th, innerLim, outerLim = v:getPosition(), v.thickness:get(), v.limit:getInOrder()
			if pos <= innerLim - math.abs(th) or pos >= outerLim + math.abs(th) then
				self:rw(k)
			else
				local innerRad, outerRad = clamp(pos, innerLim, outerLim), clamp(pos + th * v.limit:getDir(), innerLim, outerLim)
				local r0, a0 = v.vertex[0].pol:run(innerRad, angle0, ...)
				local r1, a1 = v.vertex[1].pol:run(innerRad, angle1, ...)
				local r2, a2 = v.vertex[2].pol:run(outerRad, angle1, ...)
				local r3, a3 = v.vertex[3].pol:run(outerRad, angle0, ...)
				for i = tfLen, 1, -1 do
					r0, a0 = tf[i].pol[1](r0, a0, ...)
					r1, a1 = tf[i].pol[2](r1, a1, ...)
					r2, a2 = tf[i].pol[3](r2, a2, ...)
					r3, a3 = tf[i].pol[4](r3, a3, ...)
				end
				local x0, y0 = v.vertex[0].cart:run(r0 * math.cos(a0), r0 * math.sin(a0), ...)
				local x1, y1 = v.vertex[1].cart:run(r1 * math.cos(a1), r1 * math.sin(a1), ...)
				local x2, y2 = v.vertex[2].cart:run(r2 * math.cos(a2), r2 * math.sin(a2), ...)
				local x3, y3 = v.vertex[3].cart:run(r3 * math.cos(a3), r3 * math.sin(a3), ...)
				for i = tfLen, 1, -1 do
					x0, y0 = tf[i].cart[1](x0, y0, ...)
					x1, y1 = tf[i].cart[2](x1, y1, ...)
					x2, y2 = tf[i].cart[3](x2, y2, ...)
					x3, y3 = tf[i].cart[4](x3, y3, ...)
				end
				cw_setVertexPos4(k, x0, y0, x1, y1, x2, y2, x3, y3)
			end
		end
	else
		for _, v in pairs(self.layer) do
			v:step(depth - 1, tf, ...)
		end
	end
end
-- Updates all layer wall colors.
function PolyWall:fill(depth, tf, ...)
	if type(tf) ~= 'table' then tf = {} end
	depth = __VERIFYDEPTH(depth)
	table.insert(tf, {self.vertex:getColor()})
	if depth <= 0 then
		local tfLen = #tf
		for k, v in pairs(self.array) do
			local r0, g0, b0, a0 = v.vertex[0]:getRGBAResult(...)
			local r1, g1, b1, a1 = v.vertex[1]:getRGBAResult(...)
			local r2, g2, b2, a2 = v.vertex[2]:getRGBAResult(...)
			local r3, g3, b3, a3 = v.vertex[3]:getRGBAResult(...)
			for i = tfLen, 1, -1 do
				r0, g0, b0, a0 = tf[i][1](r0, g0, b0, a0, ...)
				r1, g1, b1, a1 = tf[i][2](r1, g1, b1, a1, ...)
				r2, g2, b2, a2 = tf[i][3](r2, g2, b2, a2, ...)
				r3, g3, b3, a3 = tf[i][4](r3, g3, b3, a3, ...)
			end
			cw_setVertexColor4(k, r0, g0, b0, a0, r1, g1, b1, a1, r2, g2, b2, a2, r3, g3, b3, a3)
		end
	else
		for _, v in pairs(self.layer) do
			v:fill(depth - 1, tf, ...)
		end
	end
end

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