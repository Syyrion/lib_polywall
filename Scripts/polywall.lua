u_execScript('basewall.lua')
print("!! WARNING !! polwall.lua is deprecated and will be removed on Dec. 1 2021.\nNo further updates will be given to this script.\nPlease migrate code to use master.lua.")

--[[ PolyWall class ]]--
-- Inherits from BaseWall
PolyWall = {}
PolyWall.__index = PolyWall
setmetatable(PolyWall, BaseWall)




--[[ Creation Functions ]]--
-- Functions for creating new instances of the PolyWall class

-- Creates a new PolyWall class with no layers
-- The type is specified under the label <type>
function BaseWall:new()
	local newInst = {}
	setmetatable(newInst, self)

	newInst.layer, newInst.layerMap, newInst.type = {}, {}, 'polywall'
	
	return newInst
end

-- Creates a new PolyWall class with defined layers
function PolyWall:newCLSet(sh, th, sp, lim0, lim1, R, G, B, A, tp, tc, p, ...)
	local newInst = self:newCL(...)
	newInst:setLayerAll(sh, th, sp, lim0, lim1, R, G, B, A, tp, tc, p)
	return newInst
end

--[[ End Creation Functions ]]--




--[[ Layer Control Functions ]]--
-- For creation, deletion, and setup of layers

-- Overrides BaseWall setLayer function to include shape parameter
-- Creates or modifies a layer with ID <l>
-- If the layer already exists, all given parameters will overwrite layer values. Custom wall set is preserved
-- If a parameter is not provided, it will be defered to individual wall params
function PolyWall:setLayer(l, sh, th, sp, lim0, lim1, R, G, B, A, tp, tc, p)
	-- Preserve the set if it exists
	local s
	if self:layerExists(l) then s = self.layer[l].set end
	-- Reset or create layer
	self.layer[l] = {}
	-- Unordered set of walls containing cw handles as keys and tables containing wall parameters
	self.layer[l].set = s or {}

	-- Global layer parameters. These parameters are applied to all walls within the layer's set when they're created
	-- If the value is nil then it falls back to the wall's individual parameters
	-- Values from global layer parameters are only set when a wall is created and may change over time
	
	self.layer[l].shape = sh and math.max(3, sh)
	self.layer[l].thickness = th
	self.layer[l].speed = sp
	self.layer[l].limitPrimary = lim0
	self.layer[l].limitSecondary = lim1
	if R and G and B and A then self.layer[l].r, self.layer[l].g, self.layer[l].b, self.layer[l].a = clamp(R, 0, 255), clamp(G, 0, 255), clamp(B, 0, 255), clamp(A, 0, 255)
	else self.layer[l].r, self.layer[l].g, self.layer[l].b, self.layer[l].a = nil, nil, nil, nil end
	self.layer[l].transPolar = type(tp) == 'function' and tp or nil
	self.layer[l].transCartesian = type(tc) == 'function' and tc or nil
	self.layer[l].position = p
end

-- Overrides BaseWall setLayer function to include shape parameter
-- Sets all layers to provided parameters
function PolyWall:setLayerAll(sh, th, sp, lim0, lim1, R, G, B, A, tp, tc, p)
	for k, v in pairs(self:getLayers()) do
		self:setLayer(k, sh, th, sp, lim0, lim1, R, G, B, A, tp, tc, p)
	end
end

-- Overrides BaseWall setLayer function to include shape parameter
-- Creates or sets a layer with ID <l> with all default global layer parameters
function PolyWall:setLayerDefaults(l)
	-- Preserve the set if it exists
	local s
	if self:layerExists(l) then s = self.layer[l].set end
	self.layer[l] = {}
	self:setLayerShape(l)
	self:setLayerThickness(l)
	self:setLayerSpeed(l)
	self:setLayerLimits(l)
	self:setLayerColor(l)
	self:clearLayerTransPolar(l)
	self:clearLayerTransCartesian(l)
	self:clearLayerPosition(l)
	self.layer[l].set = s or {}
end

-- Overrides BaseWall printLayerInfo to include shape parameter
-- Prints layer information to the lua console (debug only)
function PolyWall:printLayerInfo()
	u_log('')
	u_log('Layer Count: ' .. #self:getLayers() + 1)
	for k, v in pairs(self:getLayers()) do
		u_log('==============')
		u_log('\tLayer: ' .. k)
		u_log('\tShape: ' .. (self:getLayerShape(k) or 'nil'))
		u_log('\tThickness: ' .. (self:getLayerThickness(k) or 'nil'))
		u_log('\tSpeed: ' .. (self:getLayerSpeed(k) or 'nil'))
		u_log('\tPrimary Bound: ' .. (self:getLayerLimitPrimary(k) or 'nil'))
		u_log('\tSecondary Bound: ' .. (self:getLayerLimitSecondary(k) or 'nil'))
		local r, g, b, a = self:getLayerColor(k)
		u_log('\tColor: ' .. (r or 'nil') .. ', ' .. (g or 'nil') .. ', ' .. (b or 'nil') .. ', ' .. (a or 'nil'))
		u_log('\tPolar Transformation: ' .. (self:getLayerTransPolar(k) and 'Yes' or 'No'))
		u_log('\tCartesian Transformation: ' .. (self:getLayerTransCartesian(k) and 'Yes' or 'No'))
		u_log('\tSpawn Position: ' .. (self:getLayerPosition(k) or 'nil'))
		u_log('\tCustom Wall Count: ' .. #v.set)
		local keys = ''
		for k, v in pairs(v.set) do
			keys = keys .. k .. ' '
		end
		u_log('\tCustom Wall Keys: ' .. keys)
	end
	u_log('==============')
end

--[[ End Layer Control Functions ]]--




--[[ Layer Parameter Functions ]]--
-- Setter, getter, and clearer functions for layer parameters.
-- Setters set parameters. If nothing is passed in, they set the parameters to their default value.
-- Getters return parameters. Less convoluted than trying to access values directly.
-- Clearers remove parameters. This will cause newly created walls to fallback to their own specific parameters.
-- Functions do nothing if layer doesn't exist.
-- Limit Parameters are an exeption in that there are functions that set, get, and, clear both limits simultaneously. It is recommended to use the combined functions instead of the individual ones

-- These parameters are unique to the PolyWall class


-- Adds shape parameter for layers
-- Sets global layer shape in <l> to <sh>
-- Passing nothing sets it to the current level shape
-- Note this is only set once so if the level shape changes the class won't update
-- Remove this parameter and don't pass in the shape parameter to any newly created walls to have walls obey the current level shape
function PolyWall:setLayerShape(l, sh)
	if self:layerExists(l) then self.layer[l].shape = sh and math.max(3, sh) or l_getSides() end
end

-- Returns the global layer shape in <l>
function PolyWall:getLayerShape(l)
	if self:layerExists(l) then return self.layer[l].shape end
end

-- Removes global layer shape in <l> and defers it to individual wall parameter.
function PolyWall:clearLayerShape(l)
	if self:layerExists(l) then self.layer[l].shape = nil end
end

--[[ End Layer Parameter Functions]]--




--[[ Wall Control Functions ]]--
-- Functions for creation, deletion, and setup of walls

-- Overrides BaseWall wall function to include side and shape parameter
-- Creates a normal PolyWall.
-- Returns the handle of the created custom wall
function PolyWall:wall(l, s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p)
	l = l or 0
	if self:layerExists(l) then 
		local key = cw_create()
		self.layerMap[key] = l
		self.layer[l].set[key] = {}
		self:setWall(key, s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p)
		return key
	end
end

-- Overrides BaseWall wallNC function to include side and shape parameter
-- Creates a non-solid PolyWall.
-- Returns the handle of the created custom wall
function PolyWall:wallNC(l, s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p)
	l = l or 0
	if self:layerExists(l) then 
		local key = cw_createNoCollision()
		self.layerMap[key] = l
		self.layer[l].set[key] = {}
		self:setWall(key, s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p)
		return key
	end
end

-- Overrides BaseWall wallD function to include side and shape parameter
-- Creates a deadly PolyWall.
-- Returns the handle of the created custom wall
function PolyWall:wallD(l, s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p)
	l = l or 0
	if self:layerExists(l) then 
		local key = cw_createDeadly()
		self.layerMap[key] = l
		self.layer[l].set[key] = {}
		self:setWall(key, s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p)
		return key
	end
end

-- Overrides BaseWall wallMulti function to include side and shape parameter
-- Creates a basewall on all existing layers.
-- Returns all handles of the created custom walls in a table
function PolyWall:wallMulti(s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p)
	local keys = {}
	for l, L in pairs(self:getLayers()) do
		table.insert(keys, self:wall(l, s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p))
	end
	return keys
end

-- Overrides BaseWall wallNCMulti function to include side and shape parameter
-- Creates a non-solid basewall on all existing layers.
-- Returns all handles of the created custom walls in a table
function PolyWall:wallNCMulti(s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p)
	local keys = {}
	for l, L in pairs(self:getLayers()) do
		table.insert(keys, self:wallNC(l, s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p))
	end
	return keys
end

-- Overrides BaseWall wallDMulti function to include side and shape parameter
-- Creates a deadly basewall on all existing layers.
-- Returns all handles of the created custom walls in a table
function PolyWall:wallDMulti(s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p)
	local keys = {}
	for l, L in pairs(self:getLayers()) do
		table.insert(keys, self:wallD(l, s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p))
	end
	return keys
end

-- Overrides BaseWall setLayer function to include side and shape parameter
-- Sets all parameters of a wall
-- Pass no parameters for defaults
function PolyWall:setWall(key, s, th, sh, sp, lim0, lim1, ttl, R, G, B, A, p)
	if self:map(key) then
		self:setWallSide(key, s)
		self:setWallThickness(key, th)
		self:setWallShape(key, sh)
		self:setWallSpeed(key, sp)
		self:setWallLimitPrimary(key, lim0)
		self:setWallLimitSecondary(key, lim1)
		self:setWallTTL(key, ttl)
		self:setWallColor(key, R, G, B, A)
		self:setWallPosition(key, p)
	end
end


-- Overrides BaseWall printLayerWallInfo function to include side and shape parameter
-- Prints specific information about all walls on layer <l> (debug only)
function PolyWall:printLayerWallInfo(l)
	l = l or 0
	if self:layerExists(l) then
		u_log('')
		u_log('Wall Count: ' .. #self:getLayerSet(l))
		for k, v in pairs(self:getLayerSet(l)) do
			u_log('==============')
			u_log('\tHandle: ' .. k)
			u_log('\tSide: ' .. self:getWallSide(k))
			u_log('\tThickness: ' .. self:getWallThickness(k))
			u_log('\tShape: ' .. self:getWallShape(k))
			u_log('\tSpeed: ' .. self:getWallSpeed(k))
			u_log('\tPrimary Bound: ' .. self:getWallLimitPrimary(k))
			u_log('\tSecondary Bound: ' .. self:getWallLimitSecondary(k))
			u_log('\tTTL: ' .. (self:getWallTTL(k) or 'nil'))
			u_log('\tPosition: ' .. self:getWallPosition(k))
		end
	end
	u_log('==============')
end
--[[ End Wall Control Functions ]]--





--[[ Wall Parameter Functions ]]--
-- Setter and getter functions for individual walls
-- Wall parameters always exist for every wall
-- Giving nothing to setter functions will default to the wall's specific layer parameter, then the default value

-- Adds side parameter for walls
-- Sets a wall's side index
-- Defaults to 0
function PolyWall:setWallSide(key, s)
	local l = self:map(key)
	if l then self.layer[l].set[key].side = s or 0 end
end

-- Gets a wall's side index
function PolyWall:getWallSide(key)
	local l = self:map(key)
	if l then return self.layer[l].set[key].side end
end



-- Adds shape parameter for walls
-- Sets a wall's polygon shape
-- Defaults to layer shape, then current level shape
function PolyWall:setWallShape(key, sh)
	local l = self:map(key)
	if l then self.layer[l].set[key].shape = sh or self.layer[l].shape or l_getSides() end
end

-- Gets a wall's shape
function PolyWall:getWallShape(key)
	local l = self:map(key)
	if l then return self.layer[l].set[key].shape end
end
--[[ End Wall Parameter Functions ]]--





--[[ Movement Functions ]]--
-- Functions for movement and color changing

-- Uniquely defines movement for this class
-- Moves a single wall by it's <key> value
function PolyWall:wallMove(mFrameTime, key, ...)
	local l = self:map(key)
	if l then
		local speed, thickness, outerLim, innerLim = self:getWallSpeed(key), self:getWallThickness(key), self:getWallLimitPrimary(key), self:getWallLimitSecondary(key)
		-- Reorder to make sure that outerLim is greater than innerLim
		if outerLim < innerLim then outerLim, innerLim = innerLim, outerLim end
		local newPos = self:setWallPosition(key, self:getWallPosition(key) - (mFrameTime * speed))
		if newPos < innerLim - thickness  or newPos > outerLim + thickness then
			self:del(key)
			return
		end
		local innerPos, outerPos = clamp(newPos, innerLim, outerLim), clamp(newPos + (speed >= 0 and 1 or -1) * thickness, innerLim, outerLim)
		local range, side = math.tau / self:getWallShape(key), self:getWallSide(key)
		local transPolar, transCartesian = self:getLayerTransPolar(l) or function(r, a) return r, a end, self:getLayerTransCartesian(l) or function(x, y) return x, y end

		-- Refer to BaseWall.lua for a diagram detailing vertex order
		local r0, a0 = transPolar(innerPos, (side - 0.5) * range, 0, ...)
		local r1, a1 = transPolar(innerPos, (side + 0.5) * range, 1, ...)
		local r2, a2 = transPolar(outerPos, (side + 0.5) * range, 2, ...)
		local r3, a3 = transPolar(outerPos, (side - 0.5) * range, 3, ...)
		local x0, y0 = transCartesian(r0 * math.cos(a0), r0 * math.sin(a0), 0, ...)
		local x1, y1 = transCartesian(r1 * math.cos(a1), r1 * math.sin(a1), 1, ...)
		local x2, y2 = transCartesian(r2 * math.cos(a2), r2 * math.sin(a2), 2, ...)
		local x3, y3 = transCartesian(r3 * math.cos(a3), r3 * math.sin(a3), 3, ...)

		cw_setVertexPos4(key, x0, y0, x1, y1, x2, y2, x3, y3)

		local ttl = self:getWallTTL(key)
		if ttl then
			if ttl <= 0 then self:del(key)
			else self:setWallTTL(key, ttl - 1) end
		end
	end
end

--[[ End Movement Functions ]]--





--[[ Organization Functions ]]--

-- Nothing to override

--[[ End Organization Functions ]]--