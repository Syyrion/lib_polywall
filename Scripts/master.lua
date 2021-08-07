u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")

--[[
	* Discrete class
	Contains functions that all discrete classes use
]]
local Discrete = {}
Discrete.__index = Discrete
function Discrete:new(init)
	local newInst = setmetatable({}, self)
	newInst:set(init)
	return newInst
end
function Discrete:__INFOGET() return self:rawget() or self:get() .. '*' end


local DEFAULTCALL = {__index = function (this, key) return this.__DEFAULT[key](key) end}



--[[
	* TRANSFORMATION CLASSES
]]

--[[
	* Discrete Transformation Class
	Handles a discrete transformation
]]
local DiscreteTransform = setmetatable({}, Discrete)
DiscreteTransform.__index = DiscreteTransform
function DiscreteTransform:set(fn) self.fn = type(fn) == 'function' and fn or nil end
function DiscreteTransform:get() return self.fn end
function DiscreteTransform:rawget() return rawget(self, 'fn') end
function DiscreteTransform:run(...) return self.fn(...) end
function DiscreteTransform:__INFOGET() return self:rawget() and 'Set' or '[None]' end

--[[
	* Discrete Position Transformation Class
	Handles a single 2 arguement position transformation function
]]
local DiscretePositionTransform = setmetatable({fn = function (a, b) return a, b end}, DiscreteTransform)
DiscretePositionTransform.__index = DiscretePositionTransform

--[[
	* Color Transformation Class
	Handles a single 4 arguement color transformation function
]]
local DiscreteColorTransform = setmetatable({fn = function (r, g, b, a) return r, g, b, a end}, DiscreteTransform)
DiscreteColorTransform.__index = DiscreteColorTransform



--[[
	* COLOR CLASSES
]]

--[[
	* Discrete Channel Class
	Handles a discrete color channel
]]
local DiscreteChannel = setmetatable({}, Discrete)
DiscreteChannel.__index = DiscreteChannel
DiscreteChannel.__INHERITCALL = {__index = function(_, _) return function (key) return DiscreteChannel[key] end end}
function DiscreteChannel:set(ch) self.ch = type(ch) == 'number' and clamp(math.floor(ch), 0, 255) or nil end
function DiscreteChannel:get() return self.ch end
function DiscreteChannel:rawget() return rawget(self, 'ch') end

--[[
	* Color Channel Classes
	Each handles a single channel
]]
local RChannel = setmetatable({__DEFAULT = setmetatable({ch = function () local r, _, _, _ = s_getMainColor() return r end}, DiscreteChannel.__INHERITCALL)}, DEFAULTCALL)
RChannel.__index = RChannel
local GChannel = setmetatable({__DEFAULT = setmetatable({ch = function () local _, g, _, _ = s_getMainColor() return g end}, DiscreteChannel.__INHERITCALL)}, DEFAULTCALL)
GChannel.__index = GChannel
local BChannel = setmetatable({__DEFAULT = setmetatable({ch = function () local _, _, b, _ = s_getMainColor() return b end}, DiscreteChannel.__INHERITCALL)}, DEFAULTCALL)
BChannel.__index = BChannel
local AChannel = setmetatable({__DEFAULT = setmetatable({ch = function () local _, _, _, a = s_getMainColor() return a end}, DiscreteChannel.__INHERITCALL)}, DEFAULTCALL)
AChannel.__index = AChannel


--[[
	* VERTEX CLASSES
]]

--[[
	* Discrete vertex class
	Handles a single vertex's color and transformations
]]
local DiscreteVertex = {__TYPE = 'DiscreteVertex', r = RChannel, g = GChannel, b = BChannel, a = AChannel, polar = DiscretePositionTransform, cartesian = DiscretePositionTransform, color = DiscreteColorTransform}
DiscreteVertex.__index = DiscreteVertex
function DiscreteVertex:new(r, g, b, a, pol, cart, col)
	return setmetatable({
		r = RChannel:new(r),
		g = GChannel:new(g),
		b = BChannel:new(b),
		a = AChannel:new(a),
		polar = DiscretePositionTransform:new(pol),
		cartesian = DiscretePositionTransform:new(cart),
		color = DiscreteColorTransform:new(col)
	}, self)
end
-- * Utility fromHSV function with type checking
function DiscreteVertex.fromHSV(h, s, v) return fromHSV(type(h) == 'number' and h or 0, type(s) == 'number' and clamp(s, 0, 1) or nil, type(v) == 'number' and clamp(v, 0, 1) or nil) end
function DiscreteVertex:setRGBA(r, g, b, a) self.r:set(r) self.g:set(g) self.b:set(b) self.a:set(a) end
function DiscreteVertex:setRGB(r, g, b) self.r:set(r) self.g:set(g) self.b:set(b) end
function DiscreteVertex:setHSVA(h, s, v, a) self:setRGBA(self.fromHSV(h, s, v), a) end
function DiscreteVertex:setHSV(h, s, v) self:setRGB(self.fromHSV(h, s, v)) end
function DiscreteVertex:getRGBA() return self.r:get(), self.g:get(), self.b:get(), self.a:get() end
function DiscreteVertex:getRGBAResult(...) return self.color:run(self:getRGBA(), ...) end
function DiscreteVertex:rawgetRGBA() return self.r:rawget(), self.g:rawget(), self.b:rawget(), self.a:rawget() end
function DiscreteVertex:info(ind)
	ind = type(ind) == 'number' and string.rep('\t', math.floor(ind)) or ''
	print(
		'\n'.. ind ..'Type:\t\t', self.__TYPE,
		'\n'.. ind ..'RGBA:\t\t', self.r:__INFOGET(), self.g:__INFOGET(), self.b:__INFOGET(), self.a:__INFOGET(),
		'\n'.. ind ..'Polar Transform:', self.polar:__INFOGET(),
		'\n'.. ind ..'Cartesian Transform:', self.cartesian:__INFOGET(),
		'\n'.. ind ..'Color Transform:', self.color:__INFOGET()
	)
end

--[[
	* Quad vertex class
	Handles 4 vertex classes at once
]]
local QuadVertex = {__TYPE = 'QuadVertex', [0] = DiscreteVertex, [1] = DiscreteVertex, [2] = DiscreteVertex, [3] = DiscreteVertex}
QuadVertex.__index = QuadVertex
function QuadVertex:new(r, g, b, a, pol, cart, col)
	if type(r) ~= "table" then r = {r, r, r, r} end
	if type(g) ~= "table" then g = {g, g, g, g} end
	if type(b) ~= "table" then b = {b, b, b, b} end
	if type(a) ~= "table" then a = {a, a, a, a} end
	if type(pol) ~= "table" then pol = {pol, pol, pol, pol} end
	if type(cart) ~= "table" then cart = {cart, cart, cart, cart} end
	if type(col) ~= "table" then col = {col, col, col, col} end
	return setmetatable({
		[0] = DiscreteVertex:new(r[1], g[1], b[1], a[1], pol[1], cart[1], col[1]),
		[1] = DiscreteVertex:new(r[2], g[2], b[2], a[2], pol[2], cart[2], col[2]),
		[2] = DiscreteVertex:new(r[3], g[3], b[3], a[3], pol[3], cart[3], col[3]),
		[3] = DiscreteVertex:new(r[4], g[4], b[4], a[4], pol[4], cart[4], col[4])
	}, self)
end
function QuadVertex:setRGBA(r, g, b, a) for i = 0, 3 do self[i]:setRGBA(r, g, b, a) end end
function QuadVertex:setRGB(r, g, b) for i = 0, 3 do self[i]:setRGB(r, g, b) end end
function QuadVertex:setHSVA(h, s, v, a) for i = 0, 3 do self[i]:setHSVA(h, s, v, a) end end
function QuadVertex:setHSV(h, s, v) for i = 0, 3 do self[i]:setHSV(h, s, v) end end
function QuadVertex:getRGBA() return self[0]:getRGBA(), self[1]:getRGBA(), self[2]:getRGBA(), self[3]:getRGBA() end
function QuadVertex:getRGBAResult(...) return self[0]:getRGBAResult(...), self[1]:getRGBAResult(...), self[2]:getRGBAResult(...), self[3]:getRGBAResult(...) end
function QuadVertex:rawgetRGBA() return self[0]:rawgetRGBA(), self[1]:rawgetRGBA(), self[2]:rawgetRGBA(), self[3]:rawgetRGBA() end
function QuadVertex:setR(r) for i = 0, 3 do self[i].r:set(r) end end
function QuadVertex:getR() return self[0].r:get(), self[1].r:get(), self[2].r:get(), self[3].r:get() end
function QuadVertex:rawgetR() return self[0].r:rawget(), self[1].r:rawget(), self[2].r:rawget(), self[3].r:rawget() end
function QuadVertex:setG(g) for i = 0, 3 do self[i].g:set(g) end end
function QuadVertex:getG() return self[0].g:get(), self[1].g:get(), self[2].g:get(), self[3].g:get() end
function QuadVertex:rawgetG() return self[0].g:rawget(), self[1].g:rawget(), self[2].g:rawget(), self[3].g:rawget() end
function QuadVertex:setB(b) for i = 0, 3 do self[i].b:set(b) end end
function QuadVertex:getB() return self[0].b:get(), self[1].b:get(), self[2].b:get(), self[3].b:get() end
function QuadVertex:rawgetB() return self[0].b:rawget(), self[1].b:rawget(), self[2].b:rawget(), self[3].b:rawget() end
function QuadVertex:setA(a) for i = 0, 3 do self[i].a:set(a) end end
function QuadVertex:getA() return self[0].a:get(), self[1].a:get(), self[2].a:get(), self[3].a:get() end
function QuadVertex:rawgetA() return self[0].a:rawget(), self[1].a:rawget(), self[2].a:rawget(), self[3].a:rawget() end
function QuadVertex:setPolar(pol) for i = 0, 3 do self[i].polar:set(pol) end end
function QuadVertex:getPolar() return self[0].polar:get(), self[1].polar:get(), self[2].polar:get(), self[3].polar:get() end
function QuadVertex:rawgetPolar() return self[0].polar:rawget(), self[1].polar:rawget(), self[2].polar:rawget(), self[3].polar:rawget() end
function QuadVertex:setCartesian(cart) for i = 0, 3 do self[i].cartesian:set(cart) end end
function QuadVertex:getCartesian() return self[0].cartesian:get(), self[1].cartesian:get(), self[2].cartesian:get(), self[3].cartesian:get() end
function QuadVertex:rawgetCartesian() return self[0].cartesian:rawget(), self[1].cartesian:rawget(), self[2].cartesian:rawget(), self[3].cartesian:rawget() end
function QuadVertex:setColor(col) for i = 0, 3 do self[i].color:set(col) end end
function QuadVertex:getColor() return self[0].color:get(), self[1].color:get(), self[2].color:get(), self[3].color:get() end
function QuadVertex:rawgetColor() return self[0].color:rawget(), self[1].color:get(), self[2].color:rawget(), self[3].color:rawget() end
function QuadVertex:info(ind)
	ind = type(ind) == 'number' and math.floor(ind) or 0
	local t = string.rep('\t', ind)
	print(t .. 'Type:', self.__TYPE)
	for i = 0, 3 do
		print(t .. 'Vertex', i)
		self[i]:info(ind + 1)
	end
end



--[[
	* PARAMETER CLASSES
]]

--[[
	* Discrete Numeric class
	-- Handles a single numerical parameter value
]]
local DiscreteNumeric = setmetatable({val = 0}, Discrete)
DiscreteNumeric.__index = DiscreteNumeric
DiscreteNumeric.__INHERITCALL = {__index = function (_, _) return function (key) return DiscreteNumeric[key] end end}
function DiscreteNumeric:set(val) self.val = type(val) == 'number' and val or nil end
function DiscreteNumeric:get() return self.val end
function DiscreteNumeric:rawget() return rawget(self, 'val') end

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
local Speed = setmetatable({__DEFAULT = setmetatable({val = function () return l_getSpeedMult() * 5 end}, DiscreteNumeric.__INHERITCALL)}, DEFAULTCALL)
Speed.__index = Speed

--[[
	* Limit head class
	Contains default starting limit
]]
local LimitHead = setmetatable({val = 1600}, DiscreteNumeric)
LimitHead.__index = LimitHead

--[[
	* Limit tail parameter class
	Contains default ending limit
]]
local LimitTail = setmetatable({val = 58}, DiscreteNumeric)
LimitTail.__index = LimitTail

--[[
	* Limit pair parameter class
	Handles both head and tail limits
]]
local LimitPair = {head = LimitHead, tail = LimitTail}
LimitPair.__index = LimitPair
function LimitPair:new(lim0, lim1) return setmetatable({head = LimitHead:new(lim0), tail = LimitTail:new(lim1)}, self) end
function LimitPair:set(lim0, lim1) self.head:set(lim0) self.tail:set(lim1) end
function LimitPair:get() return self.head:get(), self.tail:get() end
function LimitPair:rawget() return self.head:rawget(), self.tail:rawget() end
function LimitPair:getInOrder()
	local lh, lt = self.head:get(), self.tail:get()
	if lh >= lt then return lt, lh end
	return lh, lt
end

--[[
	* Shape parameter class
	Contains default shape calculation function
]]
local Shape = setmetatable({__DEFAULT = setmetatable({val = l_getSides}, DiscreteNumeric.__INHERITCALL)}, DEFAULTCALL)
function Shape:set(val) self.val = type(val) == 'number' and math.floor(val) or nil end
Shape.__index = Shape

--[[
	* Ratio list class
	-- WORK IN PROGRESS
]]
local RatioList = setmetatable({ratio = {1}}, Discrete)
RatioList.__index = RatioList
function RatioList.isInvalid(val) return type(val) ~= 'number' or val <= 0 end
function RatioList:set(t)
	if type(t) ~= 'table' then self.ratio = nil return end
	local max = table.maxn(t)
	if max < 1 then self.ratio = nil return end
	for i = 1, max do if self.isInvalid(t[i]) then self.ratio = nil return end end
	self.ratio = t
end
function RatioList:insert(pos, val)
	if self.isInvalid(val) then return end
	table.insert(self.ratio, type(pos) == 'number' and math.max(1, pos) or nil, val)
end
function RatioList:remove(pos) table.remove(self.ratio, type(pos) == "number" and math.max(1, pos) or nil) end
function RatioList:get() return self.ratio end
function RatioList:rawget() rawget(self, 'ratio') end
function RatioList:sum(to)
	to = type(to) == "number" and to % #self.ratio or #self.ratio
	local sum0, sum1 = 0, 0
	for i = 1, to do sum0 = sum0 + self.ratio[i] end
	for i = to + 1, #self.ratio do sum1 = sum1 + self.ratio[i] end
	return sum0 + sum1, sum0
end



--[[
	* WALL AND LAYER SUBTYPE CLASSES
]]

--[[
	* Sub type class
	Super class for all wall/layer types
]]
local SubType = {}
SubType.__index = SubType
function SubType.newAbstractBaseType(r, g, b, a, pol, cart, col, ttl)
	return setmetatable({
		vertex = QuadVertex:new(r, g, b, a, pol, cart, col),
		ttl = DiscreteNumeric:new(ttl),
	}, {
		__add = function (this, that)
			for k, v in pairs(that) do this[k] = v end
			return this
		end
	})
end

--[[
	* Radial type class
	Super class for all radial wall/layer types
]]
local RadialType = setmetatable({}, SubType)
RadialType.__index = RadialType
function RadialType:newAbstractRadialType(th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return self.newAbstractBaseType(r, g, b, a, pol, cart, col, ttl) + {
		thickness = Thickness:new(th),
		speed = Speed:new(sp),
		limit = LimitPair:new(lim0, lim1),
		position = type(p) == 'number' and p or nil
	}
end
function RadialType:setPosition(p) self.position = type(p) == 'number' and p or nil end
function RadialType:getPosition() return self.position or (self.speed:get() >= 0 and self.limit.head:get() or self.limit.tail:get()) end
function RadialType:rawgetPosition() return self.position end
function RadialType:getDir() return self.limit.head:get() >= self.limit.tail:get() and 1 or -1 end
function RadialType:info()
	print(
		'\nVertices'
	)
	self.vertex:info(1)
	print(
		'\nTTL:\t', self.ttl:rawget(),
		'\nThickness:', self.thickness:__INFOGET(),
		'\nSpeed:\t', self.speed:__INFOGET(),
		'\nHead Limit:', self.limit.head:__INFOGET(),
		'\nTail Limit:', self.limit.tail:__INFOGET(),
		'\nPosition:', self:rawgetPosition() or self:getPosition() .. '*'
	)
end

--[[
	* Radial wall class
	Super class for all radial wall types
]]
local RadialWall = setmetatable({}, RadialType)
RadialWall.__index = RadialWall
function RadialWall:newAbstractRadialWall(key, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return self:newAbstractRadialType(th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl) + {key = key}
end
function RadialWall:del()
	cw_setVertexPos4(self.key, 0, 0, 0, 0, 0, 0, 0, 0)
	cw_destroy(self.key)
	self = nil
end
function RadialWall:getCoords(angle0, angle1, ...)
	local pos, th, innerLim, outerLim = self:getPosition(), self.thickness:get(), self.limit:getInOrder()
	if pos <= innerLim - math.abs(th) or pos >= outerLim + math.abs(th) then self:del() end
	local innerRad, outerRad = clamp(pos, innerLim, outerLim), clamp(pos + th * self:getDir(), innerLim, outerLim)
	local r0, a0 = self[0].polar:run(innerRad, angle0, ...)
	local r1, a1 = self[1].polar:run(innerRad, angle1, ...)
	local r2, a2 = self[2].polar:run(outerRad, angle1, ...)
	local r3, a3 = self[3].polar:run(outerRad, angle0, ...)
	local x0, y0 = self[0].cartesian:run(r0 * math.cos(a0), r0 * math.sin(a0), ...)
	local x1, y1 = self[1].cartesian:run(r1 * math.cos(a1), r1 * math.sin(a1), ...)
	local x2, y2 = self[2].cartesian:run(r2 * math.cos(a2), r2 * math.sin(a2), ...)
	local x3, y3 = self[3].cartesian:run(r3 * math.cos(a3), r3 * math.sin(a3), ...)
	return x0, y0, x1, y1, x2, y2, x3, y3
end
function RadialWall:advance(mFrameTime) self:setPosition(self:getPosition() - mFrameTime * self.speed:get() * self:getDir()) end
function RadialWall:fill(...) cw_setVertexColor4(self.key, self.vertex:getRGBAResult(...)) end
function RadialWall:update(...) self:step(...) self:fill(...) end
function RadialWall:move(mFrameTime, ...) self:advance(mFrameTime) self:step(...) end
function RadialWall:shade(r, g, b, a, ...) self.vertex:setRGBA(r, g, b, a) self:fill(...) end
function RadialWall:draw(mFrameTime, r, g, b, a, ...) self:move(mFrameTime, ...) self:shade(r, g, b, a, ...) end

--[[
	* Radial layer class
	Super class for all radial layer types
]]
local RadialLayer = setmetatable({}, RadialType)
RadialLayer.__index = RadialLayer
function RadialLayer:newAbstractRadialLayer(layer, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return self:newAbstractRadialType(th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl) + {layer = layer, wallSet = {}}
end
function RadialLayer:del() for _, v in pairs(self.wallSet) do v:del() end end
function RadialLayer:advance(mFrameTime) for _, v in pairs(self.wallSet) do v:advance(mFrameTime) end end
function RadialLayer:step(...) for _, v in pairs(self.wallSet) do v:step(...) end end
function RadialLayer:fill(...) for _, v in pairs(self.wallSet) do v:fill(...) end end
function RadialLayer:update(...) for _, v in pairs(self.wallSet) do v:update(...) end end
function RadialLayer:move(mFrameTime, ...) for _, v in pairs(self.wallSet) do v:move(mFrameTime, ...) end end
function RadialLayer:shade(r, g, b, a, ...) for _, v in pairs(self.wallSet) do v:shade(r, g, b, a, ...) end end
function RadialLayer:draw(mFrameTime, r, g, b, a, ...) for _, v in pairs(self.wallSet) do v:draw(mFrameTime, r, g, b, a, ...) end end
function RadialLayer:wall(...)
	local key = cw_create()
	self.wallSet[key] = self:fromLayer(key, ...)
	return key
end
function RadialLayer:wallNC(...)
	local key = cw_createNoCollision()
	self.wallSet[key] = self:fromLayer(key, ...)
	return key
end
function RadialLayer:wallD(...)
	local key = cw_createDeadly()
	self.wallSet[key] = self:fromLayer(key, ...)
	return key
end
function RadialLayer:info()
	local s = {}
	for k, _ in pairs(self.layer) do table.insert(s, k) end
	print(
		'\nType:\t\t', self.__TYPE,
		'\nAvailable Walls:', #s > 0 and unpack(s) or '[None]'
	)
end



--[[
	* SUBTYPE CLASSES
]]

local VERTEXSHORTCUT = function (this, key)
	if type(key) == 'number' then return this.vertex[key] end
	return getmetatable(this).inherit[key]
end
local WALLSETSHORTCUT = function (this, key)
	if type(key) == 'number' then return this.wallSet[key] end
	return getmetatable(this).inherit[key]
end

--[[
	* Discrete PolyWall Class
	Handles a single custom wall's parameters
]]
local DiscretePolyWall = setmetatable({__TYPE = 'DiscretePolyWall'}, RadialWall)
function DiscretePolyWall:new(key, s, th, sh, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return setmetatable(self:newAbstractRadialWall(key, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl) + {side = DiscreteNumeric:new(s), shape = Shape:new(sh)}, {
		__index = VERTEXSHORTCUT,
		inherit = self
	})
end
function DiscretePolyWall:step(...)
	local range, side = math.tau / self.shape:get(), self.side:get()
	cw_setVertexPos4(self.key, self:getCoords((side - 0.5) * range, (side + 0.5) * range, ...))
end
function DiscretePolyWall:info()
	
end

--[[
	* PolyWall Layer Class
	Manages multiple discrete polywalls
]]
local PolyLayer = setmetatable({__TYPE = 'PolyLayer'}, RadialLayer)
function PolyLayer:new(layer, s, th, sh, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return setmetatable(self:newAbstractRadialLayer(layer, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl) + {side = DiscreteNumeric:new(s), shape = Shape:new(sh)}, {
		__index = WALLSETSHORTCUT,
		inherit = self
	})
end
function PolyLayer:fromLayer(key, s, th, sh, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return DiscretePolyWall:new(
		key,
		s or self.side:rawget(),
		th or self.thickness:rawget(),
		sh or self.shape:rawget(),
		sp or self.speed:rawget(),
		lim0 or self.limit.head:rawget(),
		lim1 or self.limit.head:rawget(),
		p or self:getPosition(),
		r or {self.vertex:rawgetR()},
		g or {self.vertex:rawgetG()},
		b or {self.vertex:rawgetB()},
		a or {self.vertex:rawgetA()},
		pol or {self.vertex:rawgetPolar()},
		cart or {self.vertex:rawgetCartesian()},
		col or {self.vertex:rawgetColor()},
		ttl or self.ttl:rawget()
	)
end


local DiscreteArcWall = setmetatable({__TYPE = 'DiscreteArcWall'}, RadialWall)
function DiscreteArcWall:new(key, a0, a1, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return setmetatable(self:newAbstractRadialWall(key, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl) + {anglePrimary = DiscreteNumeric:new(a0), angleSecondary = DiscreteNumeric:new(a1)}, {
		__index = VERTEXSHORTCUT,
		inherit = self
	})
end
function DiscreteArcWall:step(...) cw_setVertexPos4(self.key, self:getCoords(self.anglePrimary:get(), self.angleSecondary:get(), ...)) end

local ArcLayer = setmetatable({__TYPE = 'ArcLayer'}, RadialLayer)
function ArcLayer:new(layer, a0, a1, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return setmetatable(self:newAbstractRadialLayer(layer, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl) + {anglePrimary = DiscreteNumeric:new(a0), angleSecondary = DiscreteNumeric:new(a1)}, {
		__index = WALLSETSHORTCUT,
		inherit = self
	})
end
function ArcLayer:fromLayer(key, a0, a1, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return DiscreteArcWall:new(
		key,
		a0 or self.anglePrimary:rawget(),
		a1 or self.angleSecondary:rawget(),
		th or self.thickness:rawget(),
		sp or self.speed:rawget(),
		lim0 or self.limit.head:rawget(),
		lim1 or self.limit.head:rawget(),
		p or self:getPosition(),
		r or {self.vertex:rawgetR()},
		g or {self.vertex:rawgetG()},
		b or {self.vertex:rawgetB()},
		a or {self.vertex:rawgetA()},
		pol or {self.vertex:rawgetPolar()},
		cart or {self.vertex:rawgetCartesian()},
		col or {self.vertex:rawgetColor()},
		ttl or self.ttl:rawget()
	)
end

local DiscreteRatioWall = setmetatable({__TYPE = 'DiscreteRatioWall'}, RadialWall)
function DiscreteRatioWall:new(key, s, ratio, angle, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return setmetatable(self:newAbstractRadialWall(key, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl) + {side = DiscreteNumeric:new(s), angle = DiscreteNumeric:new(angle), ratio = RatioList:new(ratio)}, {
		__index = VERTEXSHORTCUT,
		inherit = self
	})
end

function DiscreteRatioWall:step(...)
	local ofs, side = self.angle:get(), self.side:get()
	local full, part = self.ratio:sum(side)
	local div = math.tau / full
	local ang = part * div
	cw_setVertexPos4(self.key, self:getCoords(ang + ofs, ang + self.ratio:get()[side + 1] * div + ofs, ...))
end

local RatioLayer = setmetatable({__TYPE = 'RatioLayer'}, RadialLayer)
function RatioLayer:new(layer, s, ratio, angle, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return setmetatable(self:newAbstractRadialLayer(layer, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl) + {side = DiscreteNumeric:new(s), angle = DiscreteNumeric:new(angle), ratio = RatioList:new(ratio)}, {
		__index = WALLSETSHORTCUT,
		inherit = self
	})
end
function RatioLayer:fromLayer(key, s, ratio, angle, th, sp, lim0, lim1, p, r, g, b, a, pol, cart, col, ttl)
	return DiscreteRatioWall:new(
		key,
		s or self.side:rawget(),
		ratio or self.ratio:rawget(),
		angle or self.angle:rawget(),
		th or self.thickness:rawget(),
		sp or self.speed:rawget(),
		lim0 or self.limit.head:rawget(),
		lim1 or self.limit.head:rawget(),
		p or self:getPosition(),
		r or {self.vertex:rawgetR()},
		g or {self.vertex:rawgetG()},
		b or {self.vertex:rawgetB()},
		a or {self.vertex:rawgetA()},
		pol or {self.vertex:rawgetPolar()},
		cart or {self.vertex:rawgetCartesian()},
		col or {self.vertex:rawgetColor()},
		ttl or self.ttl:rawget()
	)
end


--[[
	* TYPE CLASSES
]]

local LAYERSHORTCUT = function (this, key)
	if type(key) == 'number' then return this.layer[key] end
	return getmetatable(this).inherit[key]
end

--[[
	* Super type class
	Super class for all type classes
]]
local SuperType = {}
SuperType.__index = SuperType
function SuperType:new()
	return setmetatable({layer = {}}, {
		__index = LAYERSHORTCUT,
		inherit = self
	})
end
function SuperType:newCL(from, to, ...) return self:new():createLayers(from, to, ...) end
function SuperType:del() for _, v in pairs(self.layer) do v:del() end end
function SuperType:advance(mFrameTime) for _, v in pairs(self.layer) do v:advance(mFrameTime) end end
function SuperType:step(...) for _, v in pairs(self.layer) do v:step(...) end end
function SuperType:fill(...) for _, v in pairs(self.layer) do v:fill(...) end end
function SuperType:update(...) for _, v in pairs(self.layer) do v:update(...) end end
function SuperType:move(mFrameTime, ...) for _, v in pairs(self.layer) do v:move(mFrameTime, ...) end end
function SuperType:shade(r, g, b, a, ...) for _, v in pairs(self.layer) do v:shade(r, g, b, a, ...) end end
function SuperType:draw(mFrameTime, r, g, b, a, ...) for _, v in pairs(self.layer) do v:draw(mFrameTime, r, g, b, a, ...) end end
function SuperType:wall(...) for _, v in pairs(self.layer) do v:wall(...) end end
function SuperType:wallNC(...) for _, v in pairs(self.layer) do v:wallNC(...) end end
function SuperType:wallD(...) for _, v in pairs(self.layer) do v:wallD(...) end end
function SuperType:createLayers(from, to, ...)
	from = type(from) == 'number' and from or 0
	to = type(to) == 'number' and to >= from and to or from
	for i = from, to do if not self[i] then self.layer[i] = self.__LAYERTYPE:new(i, ...) end end
end
function SuperType:info()
	local s = {}
	for k, _ in pairs(self.layer) do table.insert(s, k) end
	print(
		'\nType:\t\t', self.__TYPE,
		'\nAvailable Layers:', #s > 0 and unpack(s) or '[None]'
	)
end

--[[
	* PolyWall class
	Handles PolyLayers
]]
PolyWall = setmetatable({__LAYERTYPE = PolyLayer, __TYPE = 'PolyWall'}, SuperType)
PolyWall.__index = PolyWall

--[[
	* PolyWall class
	Handles PolyLayers
]]
ArcWall = setmetatable({__LAYERTYPE = ArcLayer, __TYPE = 'ArcWall'}, SuperType)
ArcWall.__index = ArcWall

--[[
	* PolyWall class
	Handles PolyLayers
]]
RatioWall = setmetatable({__LAYERTYPE = RatioLayer, __TYPE = 'RatioWall'}, SuperType)
RatioWall.__index = RatioWall