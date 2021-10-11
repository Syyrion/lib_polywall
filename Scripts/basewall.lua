u_execDependencyScript("ohvrvanilla", "base", "vittorio romeo", "utils.lua")
print("!! WARNING !! basewall.lua is deprecated and will be removed on Jan. 1 2023.\nNo further updates will be given to this script.\nPlease migrate code to use master.lua.")

--[[ BaseWall Class ]]--
-- Table to facilitate the BaseWall class
-- This class holds all functions that are shared between other classes for basic functionality
BaseWall = {}
BaseWall.__index = BaseWall


-- Functions labeled as CLASS SPECIFIC may likely need to be defined uniquely by each subclass
-- The BaseWall class does not function without these functions filled in for each subclass
-- A brief explaination of what each class specific function should do is included

--[[ Creation Functions ]]--
-- Functions for creating new instances of the BaseWall class to be inherited

-- CLASS SPECIFIC FUNCTION
-- Creates a new BaseWall class with no layers
-- The type is specified under the label <type>
function BaseWall:new()
	local newInst = {}
	setmetatable(newInst, self)

	newInst.layer, newInst.layerMap, newInst.type = {}, {}, 'polywall'
	
	return newInst
end

-- Creates a new BaseWall class with empty layers
function BaseWall:newCL(...)
	local newInst = self:new()
	newInst:createLayers(...)
	return newInst
end

-- Creates a new BaseWall class with defined layers
function BaseWall:newCLSet(th, sp, lim0, lim1, R, G, B, A, tp, tc, p, ...)
	local newInst = self:newCL(...)
	newInst:setLayerAll(th, sp, lim0, lim1, R, G, B, A, tp, tc, p)
	return newInst
end

-- Creates a new BaseWall class with default layers
function BaseWall:newCLSetDefaults(...)
	local newInst = self:newCL(...)
	newInst:setLayerDefaultsAll()
	return newInst
end

-- Returns the class type
function BaseWall:getType()
	return self.type
end
--[[ End Creation Functions ]]--




--[[ Layer Control Functions ]]--
-- For creation, deletion, and setup of layers

-- Creates empty layers based on a numeric table
-- If layer already exists, it is skipped
-- Giving no 
function BaseWall:createLayers(...)
	local l = {...}
	if #l == 0 then
		if not self:layerExists(0) then self.layer[0] = {set = {}} end
	elseif #l == 1 then
		for i = 0, l[1] - 1 do
			if not self:layerExists(i) then self.layer[i] = {set = {}} end
		end
	else
		for k, v in pairs(l) do
			if not self:layerExists(v) then self.layer[v] = {set = {}} end
		end
	end
end

-- CLASS SPECIFIC FUNCTION
-- Creates or modifies a layer
-- If the layer already exists, all given parameters will overwrite layer values. Custom wall set is preserved
-- If a parameter is not provided, it will be defered to individual wall params
-- Setting a bound option will simultaneously set the other
function BaseWall:setLayer(l, th, sp, lim0, lim1, R, G, B, A, tp, tc, p)
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

-- CLASS SPECIFIC FUNCTION
-- Sets all existing layers to provided parameters
function BaseWall:setLayerAll(th, sp, lim0, lim1, R, G, B, A, tp, tc, p)
	for k, v in pairs(self:getLayers()) do
		self:setLayer(k, th, sp, lim0, lim1, R, G, B, A, tp, tc, p)
	end
end

-- CLASS SPECIFIC FUNCTION
-- Creates or sets a layer with all default global layer parameters
function BaseWall:setLayerDefaults(l)
	-- Preserve the set if it exists
	local s
	if self:layerExists(l) then s = self.layer[l].set end
	self.layer[l] = {}
	self:setLayerThickness(l)
	self:setLayerSpeed(l)
	self:setLayerLimits(l)
	self:setLayerColor(l)
	self:clearLayerTransPolar(l)
	self:clearLayerTransCartesian(l)
	self:clearLayerPosition(l)
	self.layer[l].set = s or {}
end

-- Sets all existing layers to defaults
function BaseWall:setLayerDefaultsAll()
	for k, v in pairs(self:getLayers()) do
		self:setLayerDefaults(k)
	end
end

-- Returns true if the layer exists, false otherwise
function BaseWall:layerExists(l)
	if self.layer[l] then return true end
	return false
end

-- Returns the table of all layers
function BaseWall:getLayers()
	return self.layer
end

-- Deletes layer <l> and all parameters and walls associated with it
function BaseWall:delLayer(l)
	self:delAll(l)
	self.layer[l] = nil
end

-- Deletes all layers, parameters, and walls
-- Run this before deleting the entire class so cw handles don't get lost
function BaseWall:delLayerAll()
	self:delAllAllLayers()
	self.layer = {}
end

-- CLASS SPECIFIC FUNCTION
-- Prints layer information to the lua console (debug only)
function BaseWall:printLayerInfo()
	u_log('')
	u_log('Layer Count: ' .. #self:getLayers() + 1)
	for k, v in pairs(self:getLayers()) do
		u_log('==============')
		u_log('\tLayer: ' .. k)
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
-- Clearers remove parameters. This will cause newly created walls to fall back to their own specific parameters.
-- Functions do nothing if layer doesn't exist.
-- Limit Parameters are an exeption in that there are functions that set, get, and, clear both limits simultaneously. It is recommended to use the combined functions instead of the individual ones


-- These parameters are universal to all subclasses and are thus declared in the BaseWall class


-- Sets global layer thickness in <l> to <th>
-- Passing nothing sets it to 40
function BaseWall:setLayerThickness(l, th)
	if self:layerExists(l) then self.layer[l].thickness = th or 40 end
end

-- Returns the global layer thickness in <l>
function BaseWall:getLayerThickness(l)
	if self:layerExists(l) then return self.layer[l].thickness end
end

-- Removes global layer thickness in <l> and defers it to individual wall parameter.
function BaseWall:clearLayerThickness(l)
	if self:layerExists(l) then self.layer[l].thickness = nil end
end



-- Sets global layer speed in <l> to <sp>
-- Passing nothing sets it to current level speed
-- Note this is only set once so if the speed mult changes the class won't update
-- Remove this parameter and don't pass in the speed parameter to any newly created walls to have walls obey the current speed multiplier
function BaseWall:setLayerSpeed(l, sp)
	if self:layerExists(l) then self.layer[l].speed = sp or l_getSpeedMult() * 5 end
end

-- Returns the global layer speed in <l>
function BaseWall:getLayerSpeed(l)
	if self:layerExists(l) then return self.layer[l].speed end
end

-- Removes global layer speed in <l> and defers it to individual wall parameter.
function BaseWall:clearLayerSpeed(l)
	if self:layerExists(l) then self.layer[l].speed = nil end
end



-- Sets global layer bounds in <l> simultaneously
-- Passing nothing for a parameter assumes their respective default values (58 and 1600)
function BaseWall:setLayerLimits(l, lim0, lim1)
	if self:layerExists(l) then
		self.layer[l].limitPrimary = lim0 or 1600
		self.layer[l].limitSecondary = lim1 or 58
	end
end

-- Returns the global bounds in <l>
function BaseWall:getLayerLimits(l)
	if self:layerExists(l) then return self.layer[l].limitPrimary, self.layer[l].limitSecondary end
end

-- Removes global layer bounds in <l> and defers it to individual wall parameters.
function BaseWall:clearLayerLimits(l)
	if self:layerExists(l) then self.layer[l].limitPrimary, self.layer[l].limitSecondary = nil, nil end
end




-- Sets global layer primary limit in <l> to <lim0>
-- Passing nothing sets it to 1600
function BaseWall:setLayerLimitPrimary(l, lim0)
	if self:layerExists(l) then self.layer[l].limitPrimary = lim0 or 1600 end
end

-- Returns the global layer primary limit in <l>
function BaseWall:getLayerLimitPrimary(l)
	if self:layerExists(l) then return self.layer[l].limitPrimary end
end

-- Removes global layer primary limit in <l> and defers it to individual wall parameter.
function BaseWall:clearLayerLimitPrimary(l)
	if self:layerExists(l) then self.layer[l].limitPrimary = nil end
end



-- Sets global layer secondary limit in <l> to <lim1>
-- Passing nothing sets it to 58
function BaseWall:setLayerLimitSecondary(l, lim1)
	if self:layerExists(l) then self.layer[l].limitSecondary = lim1 or 58 end
end

-- Returns the global layer secondary limit in <l>
function BaseWall:getLayerLimitSecondary(l)
	if self:layerExists(l) then return self.layer[l].limitSecondary end
end

-- Removes global layer secondary limit in <l> and defers it to individual wall parameter.
function BaseWall:clearLayerLimitSecondary(l)
	if self:layerExists(l) then self.layer[l].limitSecondary = nil end
end



-- Sets global layer color in <l> to {R, G, B, A}
-- Passing less than 4 color channels will default the color to the main color
-- This does not affect already existing walls, only newly created ones.
function BaseWall:setLayerColor(l, R, G, B, A)
	if self:layerExists(l) then
		if R and G and B and A then	self.layer[l].r, self.layer[l].g, self.layer[l].b, self.layer[l].a = clamp(R, 0, 255), clamp(G, 0, 255), clamp(B, 0, 255), clamp(A, 0, 255)
		else self.layer[l].r, self.layer[l].g, self.layer[l].b, self.layer[l].a = s_getMainColor() end
	end
end

-- Returns the global layer color in <l> as {R, G, B, A} (returns 4 values at once)
function BaseWall:getLayerColor(l)
	if self:layerExists(l) then return self.layer[l].r, self.layer[l].g, self.layer[l].b, self.layer[l].a end
end

-- Removes global layer color in <l> and defers it to individual wall parameter.
function BaseWall:clearLayerColor(l)
	if self:layerExists(l) then self.layer[l].r, self.layer[l].g, self.layer[l].b, self.layer[l].a = nil, nil, nil, nil end
end



-- Sets polar transformation function in <l> to <tp>
-- Polar transformation functions must accept two and return two coordinate values (radius and angle, respectively)
-- Transformations can accept more that 2 inputs, the third input is always the vertex index value of a Basewall (see vertex order below).
-- Any more inputs can be specified in the movement or step functions in the variadic part
function BaseWall:setLayerTransPolar(l, tp)
	if self:layerExists(l) then self.layer[l].transPolar = type(tp) == 'function' and tp or nil end
end

-- Returns the global layer polar transformation in <l>
function BaseWall:getLayerTransPolar(l)
	if self:layerExists(l) then return self.layer[l].transPolar end
end

-- Removes polar transformation function from <l>. Walls will stop being transformed.
function BaseWall:clearLayerTransPolar(l)
	if self:layerExists(l) then self.layer[l].transPolar = nil end
end



-- Sets cartesian transformation function in <l> to <tc>
-- Cartesian transformation functions must accept two and return two coordinate values (x and y, respectively)
-- Transformations can accept more that 2 inputs, the third input is always the vertex index value of a Basewall (see vertex order below).
-- Any more inputs can be specified in the movement or step functions in the variadic part
function BaseWall:setLayerTransCartesian(l, tc)
	if self:layerExists(l) then self.layer[l].transCartesian = type(tc) == 'function' and tc or nil end
end

-- Returns the global layer cartesian transformation in <l>
function BaseWall:getLayerTransCartesian(l)
	if self:layerExists(l) then return self.layer[l].transCartesian end
end

-- Removes cartesian transformation function from <l>. Walls will stop being transformed.
function BaseWall:clearLayerTransCartesian(l)
	if self:layerExists(l) then self.layer[l].transCartesian = nil end
end

-- Vertex Order for Basewalls
-- For positive speed (moving inwards):
--          V3.______________________________.V2
--             \                            /
--   CCW  <<    \       \/  WALL  \/       /    >> CW
--            V0.\________________________/.V1
--
-- For negative speed (moving outwards):
--          V0.______________________________.V1
--             \                            /
--   CCW  <<    \       /\  WALL  /\       /    >> CW
--            V3.\________________________/.V2



-- Spawn position layer parameter is not recommended for use as walls can figure out where they need to start by themselves
-- Usually best for decorative layers where walls need to be positions to be shown immediately without moving into a position
-- Sets global layer spawn position in <l> to <p>
-- Passing nothing does nothing
function BaseWall:setLayerPosition(l, p)
	if self:layerExists(l) and p then self.layer[l].position = p end
end

-- Returns the global layer spawn position in <l>
function BaseWall:getLayerPosition(l)
	if self:layerExists(l) then return self.layer[l].position end
end

-- Removes global layer spawn position in <l> and defers it to individual wall parameter.
function BaseWall:clearLayerPosition(l)
	if self:layerExists(l) then self.layer[l].position = nil end
end



-- Returns the set of walls from <l>
function BaseWall:getLayerSet(l)
	if self:layerExists(l) then return self.layer[l].set end
end
--[[ End Layer Parameter Functions]]--





--[[ Wall Control Functions ]]--
-- Functions for creation, deletion, and setup of walls

-- CLASS SPECIFIC FUNCTION
-- Creates a normal basewall.
-- Returns the handle of the created custom wall
function BaseWall:wall(l, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	l = l or 0
	if self:layerExists(l) then 
		local key = cw_create()
		self.layerMap[key] = l
		self.layer[l].set[key] = {}
		self:setWall(key, th, sp, lim0, lim1, ttl, R, G, B, A, p)
		return key
	end
end

-- CLASS SPECIFIC FUNCTION
-- Creates a non-solid basewall.
-- Returns the handle of the created custom wall
function BaseWall:wallNC(l, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	l = l or 0
	if self:layerExists(l) then 
		local key = cw_createNoCollision()
		self.layerMap[key] = l
		self.layer[l].set[key] = {}
		self:setWall(key, th, sp, lim0, lim1, ttl, R, G, B, A, p)
		return key
	end
end

-- CLASS SPECIFIC FUNCTION
-- Creates a deadly basewall.
-- Returns the handle of the created custom wall
function BaseWall:wallD(l, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	l = l or 0
	if self:layerExists(l) then 
		local key = cw_createDeadly()
		self.layerMap[key] = l
		self.layer[l].set[key] = {}
		self:setWall(key, th, sp, lim0, lim1, ttl, R, G, B, A, p)
		return key
	end
end

-- CLASS SPECIFIC FUNCTION
-- Creates a basewall on all existing layers.
-- Returns all handles of the created custom walls in a table
function BaseWall:wallMulti(th, sp, lim0, lim1, ttl, R, G, B, A, p)
	local keys = {}
	for l, L in pairs(self:getLayers()) do
		table.insert(keys, self:wall(l, th, sp, lim0, lim1, ttl, R, G, B, A, p))
	end
	return keys
end

-- CLASS SPECIFIC FUNCTION
-- Creates a non-solid basewall on all existing layers.
-- Returns all handles of the created custom walls in a table
function BaseWall:wallNCMulti(th, sp, lim0, lim1, ttl, R, G, B, A, p)
	local keys = {}
	for l, L in pairs(self:getLayers()) do
		table.insert(keys, self:wallNC(l, th, sp, lim0, lim1, ttl, R, G, B, A, p))
	end
	return keys
end

-- CLASS SPECIFIC FUNCTION
-- Creates a deadly basewall on all existing layers.
-- Returns all handles of the created custom walls in a table
function BaseWall:wallDMulti(th, sp, lim0, lim1, ttl, R, G, B, A, p)
	local keys = {}
	for l, L in pairs(self:getLayers()) do
		table.insert(keys, self:wallD(l, th, sp, lim0, lim1, ttl, R, G, B, A, p))
	end
	return keys
end

-- CLASS SPECIFIC FUNCTION
-- Sets all parameters of a wall by it's <key>
-- Used by wall creation functions to set parameters
-- Pass no parameters for defaults
function BaseWall:setWall(key, th, sp, lim0, lim1, ttl, R, G, B, A, p)
	if self:map(key) then
		self:setWallThickness(key, th)
		self:setWallSpeed(key, sp)
		self:setWallLimitPrimary(key, lim0)
		self:setWallLimitSecondary(key, lim1)
		self:setWallTTL(key, ttl)
		self:setWallColor(key, R, G, B, A)
		self:setWallPosition(key, p)
	end
end

-- Deletes a wall with handle <key> all attributes associated with it
function BaseWall:del(key)
	cw_setVertexPos4(key, 0, 0, 0, 0, 0, 0, 0, 0)
	cw_destroy(key)
	self.layer[self:map(key)].set[key] = nil
	self.layerMap[key] = nil
end

-- Deletes all walls on layer <l>
function BaseWall:delAll(l)
	l = l or 0
	if self:layerExists(l) then
		for k, v in pairs(self:getLayerSet(l)) do
			self:del(k)
		end
	end
end

-- Deletes all walls on all layers
function BaseWall:delAllAllLayers()
	for k, v in pairs(self:getLayers()) do
		self:delAll(k)
	end
end

-- Gets the layer that the cw with key <key> is associated with
-- Returns nil if the key doesn't exist
function BaseWall:map(key)
	return self.layerMap[key]
end

-- Returns the layer map
function BaseWall:getMap()
	return self.layerMap
end

-- Prints specific information about all walls on layer <l> (debug only)
function BaseWall:printLayerWallInfo(l)
	l = l or 0
	if self:layerExists(l) then
		u_log('')
		u_log('Wall Count: ' .. #self:getLayerSet(l))
		for k, v in pairs(self:getLayerSet(l)) do
			u_log('==============')
			u_log('\tHandle: ' .. k)
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





--[[ Wall Parameter Functions ]]--
-- Setter and getter functions for individual walls
-- Wall parameters always exist for every wall
-- Giving nothing to setter functions will default to the wall's specific layer parameter, then the default value 

-- Below are wall parameters that are universal to all subclasses and have thus been defined in the BaseWall class

-- Sets a wall's current position
-- If <p> is not provided then defaults to global layer position, then the determined outer position if speed >= 0, otherwise the determined inner position
-- Returns the new position (for convenience with calculations later)
function BaseWall:setWallPosition(key, p)
	local l = self:map(key)
	if l then
		local layerPos = self.layer[l].position
		if p then self.layer[l].set[key].position = p
		elseif layerPos then self.layer[l].set[key].position = layerPos
		else
			local speed = self.layer[l].set[key].speed or self.layer[l].speed or l_getSpeedMult()
			local outerLim = self.layer[l].set[key].limitPrimary or self.layer[l].limitPrimary or 1600
			local innerLim = self.layer[l].set[key].limitSecondary or self.layer[l].limitSecondary or 58
			-- Reorder to make sure that outerLim is greater than innerLim
			if outerLim < innerLim then outerLim, innerLim = innerLim, outerLim end
			self.layer[l].set[key].position = 0 <= speed and outerLim or innerLim
		end
		return self.layer[l].set[key].position
	end
end

-- Gets a wall's current position
function BaseWall:getWallPosition(key)
	local l = self:map(key)
	if l then return self.layer[l].set[key].position end
end



-- Sets a wall's thickness
-- Defaults to layer thickness, then 40
function BaseWall:setWallThickness(key, th)
	local l = self:map(key)
	if l then self.layer[l].set[key].thickness = th or self.layer[l].thickness or 40 end
end

-- Gets a wall's thickness
function BaseWall:getWallThickness(key)
	local l = self:map(key)
	if l then return self.layer[l].set[key].thickness end
end



-- Sets a wall's speed
-- Defaults to layer speed, then current level speed
function BaseWall:setWallSpeed(key, sp)
	local l = self:map(key)
	if l then self.layer[l].set[key].speed = sp or self.layer[l].speed or l_getSpeedMult() * 5 end
end

-- Gets a wall's speed
function BaseWall:getWallSpeed(key)
	local l = self:map(key)
	if l then return self.layer[l].set[key].speed end
end



-- Sets a wall's primary limit
-- Defaults to layer primary limit, then 1600
function BaseWall:setWallLimitPrimary(key, lim0)
	local l = self:map(key)
	if l then self.layer[l].set[key].limitPrimary = lim0 or self.layer[l].limitPrimary or 1600 end
end

-- Gets a wall's primary limit
function BaseWall:getWallLimitPrimary(key)
	local l = self:map(key)
	if l then return self.layer[l].set[key].limitPrimary end
end



-- Sets a wall's secondary limit
-- Defaults to layer secondary limit, then 58
function BaseWall:setWallLimitSecondary(key, lim1)
	local l = self:map(key)
	if l then self.layer[l].set[key].limitSecondary = lim1 or self.layer[l].limitSecondary or 58 end
end

-- Gets a wall's secondary limit
function BaseWall:getWallLimitSecondary(key)
	local l = self:map(key)
	if l then return self.layer[l].set[key].limitSecondary end
end



-- Sets a wall's time to live
-- Defaults to nil, disabling this feature for the wall
function BaseWall:setWallTTL(key, ttl)
	local l = self:map(key)
	if l then self.layer[l].set[key].ttl = ttl end
end

-- Gets a wall's current time to live
function BaseWall:getWallTTL(key)
	local l = self:map(key)
	if l then return self.layer[l].set[key].ttl end
end



-- Sets a wall's color
-- Does nothing if cw with handle <key> doesn't exist
-- If <key> does exist but less than 4 color channels are provided defaults to layer color then the main color
function BaseWall:setWallColor(key, R, G, B, A)
	local l = self:map(key)
	if l then
		if R and G and B and A then cw_setVertexColor4Same(key, clamp(R, 0, 255), clamp(G, 0, 255), clamp(B, 0, 255), clamp(A, 0, 255))
		elseif self.layer[l].r then cw_setVertexColor4Same(key, self.layer[l].r, self.layer[l].g, self.layer[l].b, self.layer[l].a)
		else cw_setVertexColor4Same(key, s_getMainColor()) end
	end
end
--[[ End Wall Parameter Functions ]]--





--[[ Movement Functions ]]--
-- Functions for movement and color changing

-- Moves all existing walls
-- mFrametime from onUpdate must be passed in
function BaseWall:move(mFrameTime, ...)
	for l, L in pairs(self:getLayers()) do
		self:lMove(mFrameTime, l, ...)
	end
end

-- Moves all existing walls in layer <l>
-- Does nothing if layer doesn't exist
-- mFrametime from onUpdate must be passed in
function BaseWall:lMove(mFrameTime, l, ...)
	if self:layerExists(l) then
		for key, cw in pairs(self:getLayerSet(l)) do
			self:wallMove(mFrameTime, key, ...)
		end
	end
end

-- CLASS SPECIFIC FUNCTION
-- Moves a single wall by it's <key> value
-- Does nothing. Must be customized for each subclass
function BaseWall:wallMove(mFrameTime, key, ...) end

-- Updates all existing walls to {R, G, B, A}
-- If no color is provided, falls back per global layer color
-- Does nothing if no colors are available
function BaseWall:shade(R, G, B, A)
	for l, L in pairs(self:getLayers()) do
		self:lShade(l, R, G, B, A)
	end
end

-- Updates all existing walls in layer <l> to {R, G, B, A}
-- If no color is provided, falls back to the global layer of <l> color
-- Does nothing if no colors are available or layer doesn't exist
function BaseWall:lShade(l, R, G, B, A)
	if self:layerExists(l) then
		for key, cw in pairs(self:getLayerSet(l)) do
			self:setWallColor(key, R, G, B, A)
		end
	end
end

-- Union of BaseWall:move and BaseWall:shade
-- mFrameTime must be passed in
function BaseWall:step(mFrameTime, R, G, B, A, ...)
	self:move(mFrameTime, ...)
	self:shade(R, G, B, A)
end

-- Union of BaseWall:lMove and BaseWall:lShade
function BaseWall:lStep(mFrameTime, l, R, G, B, A, ...)
	self:lMove(mFrameTime, l, ...)
	self:lShade(l, R, G, B, A)
end
--[[ End Movement Functions ]]--





--[[ Organization Functions ]]--
-- Functions that facilitate the movement of walls between layers and even layers between classes

-- Moves a wall's data to a new layer, effectively changing it's layer
-- The wall and layer being transfered to must already exist, if it doesn't the transfer is aborted
-- Transformations are applied by layer, so a transfered wall will immedietly obey any transformations of the new layer

-- <key> CW handle of the wall to be transferred
-- <to> Layer to be transferred to

function BaseWall:transferWall(key, to)
	local from = self:map(key)
	if from and self:layerExists(to) then
		self.layer[to].set[key] = self.layer[from].set[key]
		self.layer[from].set[key] = nil
		self.layerMap[key] = to
	end
end

-- Sorts wall CW handles such that lower numbered handles are moved to lower layers and higher numbered handles to higher layers
-- Order can be reversed by setting <decending> parameter to true
-- Enables wall layering based on layer IDs
-- Only affects currently existing walls
-- Layers to sort are given by a numerically indexed table (1 to n)
-- If no table is given, sorts all existing layers
-- Layering within layers is unstable and will very likely change
-- Color of affected walls will be set to their new corresponding layer's color. If the layer has no color set, then the current color of the wall will be reset to the default
-- This step can be skipped by setting <doNotResolveColors> to true

function BaseWall:sort(layerTable, decending, doNotResolveColors)
	local keys, layers, layersInsert = {}, {}, function(self, layers, K, L, D)
		table.insert(layers, {
			id = L,
			data = D or self.layer[L].set[K]
		})
		self.layer[L].set[K] = nil
		self.layerMap[K] = nil
	end
	
	if type(layerTable) == 'table' then
		-- Sort only keys given in layers
		for i = 1, #layerTable do
			for K, D in pairs(self:getLayerSet(layerTable[i])) do
				table.insert(keys, K)
				layersInsert(self, layers, K, layerTable[i], D)
			end
		end
	else
		-- Sort all keys
		for K, L in pairs(self:getMap()) do
			table.insert(keys, K)
			layersInsert(self, layers, K, L)
		end
	end

	table.sort(keys, decending and function(a, b) return a > b end or function(a, b) return a < b end)
	table.sort(layers, function(a, b) return a.id < b.id end)

	for i = 1, #keys do
		local K, L = keys[i], layers[i]
		self.layer[L.id].set[K] = L.data
		self.layerMap[K] = L.id
	end

	if doNotResolveColors then return end

	for i = 1, #keys do self:setWallColor(keys[i]) end
end

-- Imports a layer from another class. Class type must be the same or else the transfer is aborted
-- Source layer must exist
-- All layer data is copied over, including layerMap data. Data from source class is deleted
-- A new layer number can be specified, if left blank the imported layer will be put in the lowest empty slot greater than or equal to 0
-- If the layer slot to be imported to is already occupied, the transfer is aborted
-- The newly modified layer slot number is returned

-- <from> Class to import from
-- <which> Which layer from the Class to import
-- <to> Layer slot to import to (optional)

function BaseWall:importLayer(from, which, to)
	if from.type == self.type and from:layerExists(which) then
		if to then
			if self:layerExists(to) then return end
		else
			to = 0
			while self:layerExists(to) do to = to + 1 end
		end
		self.layer[to] = from.layer[which]
		from.layer[which] = nil
		for key, wall in pairs(self:getLayerSet(to)) do
			self.layerMap[key], from.layerMap[key] = to, nil
		end
		return to
	end
end
--[[ End Organization Functions]]--