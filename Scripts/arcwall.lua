u_execScript('basewall.lua')
print("!! WARNING !! arcwall.lua is deprecated.\nNo further feature updates will be given to this script.\nPlease migrate code to use master.lua.")

--[[ ArcWall Class ]]--
-- Inherits from Basewall
ArcWall = {}
ArcWall.__index = ArcWall
setmetatable(ArcWall, BaseWall)

--[[ Creation Functions ]]--
-- Functions for creating new instances of the ArcWall class

-- Creates a new ArcWall class with no layers
-- The type is specified under the label <type>
function BaseWall:new()
	local newInst = {}
	setmetatable(newInst, self)

	newInst.layer, newInst.layerMap, newInst.type = {}, {}, 'arcwall'
	
	return newInst
end

--[[ End Creation Functions ]]--




--[[ Layer Control Functions ]]--
-- For creation and modification of layers

-- Nothing to override

--[[ End Layer Control Functions ]]--




--[[ Layer Parameter Functions ]]--
-- Setter, getter, and clearer functions for layer parameters.
-- Setters set parameters. If nothing is passed in, they set the parameters to their default value.
-- Getters return parameters. Less convoluted than trying to access values directly.
-- Clearers remove parameters. This will cause newly created walls to fallback to their own specific parameters.
-- Functions do nothing if layer doesn't exist.

-- Nothing to override

--[[ End Layer Parameter Functions]]--





--[[ Wall Control Functions ]]--
-- Functions for creation, deletion, and setup of walls

-- Overrides BaseWall setLayer function to include primary angle and secondary angle parameter
-- Creates a normal ArcWall.
-- Returns the handle of the created custom wall
function ArcWall:wall(l, a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	l = l or 0
	if self:layerExists(l) then
		local key = cw_create()
		self.layerMap[key] = l
		self.layer[l].set[key] = {}
		self:setWall(key, a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p)
		return key
	end
end

-- Overrides BaseWall setLayer function to include primary angle and secondary angle parameter
-- Creates a non-solid ArcWall.
-- Returns the handle of the created custom wall
function ArcWall:wallNC(l, a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	l = l or 0
	if self:layerExists(l) then
		local key = cw_createNoCollision()
		self.layerMap[key] = l
		self.layer[l].set[key] = {}
		self:setWall(key, a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p)
		return key
	end
end

-- Overrides BaseWall setLayer function to include primary angle and secondary angle parameter
-- Creates a deadly ArcWall.
-- Returns the handle of the created custom wall
function ArcWall:wallD(l, a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	l = l or 0
	if self:layerExists(l) then
		local key = cw_createDeadly()
		self.layerMap[key] = l
		self.layer[l].set[key] = {}
		self:setWall(key, a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p)
		return key
	end
end

-- Overrides BaseWall wallMulti function to include side and shape parameter
-- Creates a basewall on all existing layers.
-- Returns all handles of the created custom walls in a table
function ArcWall:wallMulti(a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	local keys = {}
	for l, L in pairs(self:getLayers()) do
		table.insert(keys, self:wall(l, a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p))
	end
	return keys
end

-- Overrides BaseWall wallNCMulti function to include side and shape parameter
-- Creates a non-solid basewall on all existing layers.
-- Returns all handles of the created custom walls in a table
function ArcWall:wallNCMulti(a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	local keys = {}
	for l, L in pairs(self:getLayers()) do
		table.insert(keys, self:wallNC(l, a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p))
	end
	return keys
end

-- Overrides BaseWall wallDMulti function to include side and shape parameter
-- Creates a deadly basewall on all existing layers.
-- Returns all handles of the created custom walls in a table
function ArcWall:wallDMulti(a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	local keys = {}
	for l, L in pairs(self:getLayers()) do
		table.insert(keys, self:wallD(l, a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p))
	end
	return keys
end


-- Overrides BaseWall setLayer function to include primary angle and secondary angle parameter
-- Sets all parameters of a wall
-- Pass no parameters for defaults
function ArcWall:setWall(key, a0, a1, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	if self:map(key) then
		self:setWallAnglePrimary(key, a0)
		self:setWallAngleSecondary(key, a1)
		self:setWallThickness(key, th)
		self:setWallSpeed(key, sp)
		self:setWallLimitPrimary(key, lim0)
		self:setWallLimitSecondary(key, lim1)
		self:setWallTTL(key, ttl)
		self:setWallColor(key, R, G, B, A)
		self:setWallPosition(key, p)
	end
end

-- Overrides BaseWall printLayerWallInfo function to include primary angle and secondary angle parameter
-- Prints specific information about all walls on layer <l> (debug only)
function ArcWall:printLayerWallInfo(l)
	l = l or 0
	if self:layerExists(l) then
		u_log('')
		u_log('Wall Count: ' .. #self:getLayerSet(l))
		for k, v in pairs(self:getLayerSet(l)) do
			u_log('==============')
			u_log('\tHandle: ' .. k)
			u_log('\tPrimary Angle: ' .. self:getWallAnglePrimary(k))
			u_log('\tSecondary Angle: ' .. self:getWallAngleSecondary(k))
			u_log('\tThickness: ' .. self:getWallThickness(k))
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




--[[ Wall Parameter Function ]]--
-- Setter and getter functions for individual walls
-- Wall parameters always exist for every wall
-- Giving nothing to setter functions will default to the wall's specific layer parameter, then the default value

-- Adds primary angle parameter for walls
-- Sets a wall's side index
-- Defaults to 0
function ArcWall:setWallAnglePrimary(key, a0)
	local l = self:map(key)
	if l then self.layer[l].set[key].primary = a0 or 0 end
end

-- Gets a wall's primary angle
function ArcWall:getWallAnglePrimary(key)
	local l = self:map(key)
	if l then return self.layer[l].set[key].primary end
end



-- Adds secondary angle parameter for walls
-- Sets a wall's polygon shape
-- Defaults to 0
function ArcWall:setWallAngleSecondary(key, a1)
	local l = self:map(key)
	if l then self.layer[l].set[key].secondary = a1 or 0 end
end

-- Gets a wall's secondary angle
function ArcWall:getWallAngleSecondary(key)
	local l = self:map(key)
	if l then return self.layer[l].set[key].secondary end
end
--[[ End Parameter Functions ]]--





--[[ Movement Functions ]]--
-- Functions for movement and color changing

-- Uniquely defines movement for this class
-- Moves a single wall by it's <key> value
function ArcWall:wallMove(mFrameTime, key, ...)
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
		local anglePrimary, angleSecondary = self:getWallAnglePrimary(key), self:getWallAngleSecondary(key)
		local transPolar, transCartesian = self:getLayerTransPolar(l) or function(r, a) return r, a end, self:getLayerTransCartesian(l) or function(x, y) return x, y end

		-- Refer to BaseWall.lua for a diagram detailing vertex order
		local r0, a0 = transPolar(innerPos, anglePrimary, 0, ...)
		local r1, a1 = transPolar(innerPos, angleSecondary, 1, ...)
		local r2, a2 = transPolar(outerPos, angleSecondary, 2, ...)
		local r3, a3 = transPolar(outerPos, anglePrimary, 3, ...)
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