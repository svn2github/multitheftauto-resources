--
-- viewer.lua
--

Viewer = {}
Viewer.__index = Viewer
Viewer.instances = {}

---------------------------------------------------------------------------
--
-- Viewer:create()
--
--
--
---------------------------------------------------------------------------
function Viewer:create(name)
	local id = #Viewer.instances + 1
	Viewer.instances[id] = setmetatable(
		{
			id = id,
			name				= name,
			lastUsedTime		= getTickCount (),
			DEFAULTCOLUMNSIZE	= "180px",
			httpColumns			= {},
			httpRows			= {},
			queryTargetName		= "",
			queryCategoryName	= "",
			queryFilterText		= "",
			queryOptionsText	= "",
			categoryUpdateTime  = {},
			bQueryDone		    = false,
			lastTargets			= {},
			lastCategories		= {},
			lastRows			= {},
			lastHeaders		    = {},
		},
		self
	)

	Viewer.instances[id]:postCreate()
	return Viewer.instances[id]
end


---------------------------------------------------------------------------
--
-- Viewer:postCreate()
--
--
--
---------------------------------------------------------------------------
function Viewer:postCreate()
end


---------------------------------------------------------------------------
--
-- Viewer:destroy()
--
--
--
---------------------------------------------------------------------------
function Viewer:destroy()
	Viewer.instances[self.id] = nil
	self.id = 0
end


---------------------------------------------------------------------------
--
-- Viewer:getSecondsSinceLastUsed()
--
--
--
---------------------------------------------------------------------------
function Viewer:getSecondsSinceLastUsed()
	local ticks = getTickCount () - self.lastUsedTime
	return ticks / 1000
end


---------------------------------------------------------------------------
--
-- Viewer:setUsed()
--
--
--
---------------------------------------------------------------------------
function Viewer:setUsed()
	self.lastUsedTime = getTickCount ()
end


---------------------------------------------------------------------------
--
-- Viewer:getCurrentTarget()
--
--
--
---------------------------------------------------------------------------
function Viewer:getCurrentTarget ()
	local currentTarget = getTargetFromName(self.queryTargetName)
	currentTarget = validateTarget(currentTarget)
	return currentTarget
end


---------------------------------------------------------------------------
--
-- Viewer:getCategoryIndex()
--
--
--
---------------------------------------------------------------------------
function Viewer:getCategoryIndex ( categoryName )
	local idx = 1
	for _,category in pairs(self:getCategoriesRaw ()) do
		if category == categoryName then
			return idx
		end
		idx = idx + 1
	end
	return 1
end

---------------------------------------------------------------------------
--
-- Viewer:getCategoriesIfChanged()
--
-- Browser wants to know what categories to put in the list
--
---------------------------------------------------------------------------
function Viewer:getCategoriesIfChanged ()
	local categories = self:getCategoriesRaw ()
	local bChanged = not table.cmp(categories, self.lastCategories)
	self.lastCategories = categories
	return bChanged and categories or false
end


---------------------------------------------------------------------------
--
-- Viewer:getCategoriesRaw()
--
--
--
---------------------------------------------------------------------------
function Viewer:getCategoriesRaw ()
	local target = self:getCurrentTarget()
	if not target then return { "no target" } end
	if not target.bSupportsStats then return { "not supported" } end
	-- Get active categories
	local columnList,rowList = target:getPerformanceStats(self.name,"")
	local categories = {}
	for _,row in ipairs(rowList) do
		table.insert( categories, row[1] )
	end
	return categories
end


---------------------------------------------------------------------------
--
-- Viewer:getTargetsIfChanged()
--
-- Browser wants to know what targets to put in the list
--
---------------------------------------------------------------------------
function Viewer:getTargetsIfChanged ()
	local targets = getTargetNameList ()
	local bChanged = not table.cmp(targets, self.lastTargets)
	self.lastTargets = targets
	return bChanged and targets or false
end


---------------------------------------------------------------------------
--
-- Viewer:getHeadersIfChanged()
--
-- returns false if not changed
--
---------------------------------------------------------------------------
function Viewer:getHeadersIfChanged ()
	local headers = self.httpColumns
	local bChanged = not table.cmp(headers, self.lastHeaders)
	self.lastHeaders = headers
	return bChanged and headers or false
end


---------------------------------------------------------------------------
--
-- Viewer:getRowsIfChanged()
--
-- returns false if not changed
--
---------------------------------------------------------------------------
function Viewer:getRowsIfChanged ()
	local rows = self.httpRows
	local bChanged = not table.cmp(rows, self.lastRows)
	self.lastRows = rows
	return bChanged and rows or false
end


---------------------------------------------------------------------------
--
-- Viewer:setQuery()
--
-- Browser has display request
--
---------------------------------------------------------------------------
function Viewer:setQuery ( counter, targetName, categoryName, optionsText, filterText )
	self:setUsed()

	local restoredQueryOptionsText = false
	local restoredQueryFilterText = false

	-- Is this the first call from a new page?
	if counter == 0 then
		if #self.lastTargets == 0 then
			-- Set initial settings
			targetName = getTargetNameList ()[1]
			categoryName = self:getCategoriesRaw ()[1]
		else
			-- Restore last settings
			self.lastTargets = {}
			self.lastCategories = {}
			self.lastHeaders = {}
			self.lastRows = {}
			targetName = self.queryTargetName
			categoryName = self.queryCategoryName
			optionsText = self.queryOptionsText
			filterText = self.queryFilterText

			restoredQueryOptionsText = optionsText
			restoredQueryFilterText = filterText
		end
	end

	self.queryTargetName = targetName
	self.queryCategoryName = categoryName
	self.queryOptionsText = optionsText
	self.queryFilterText = filterText

	local targets = self:getTargetsIfChanged ()
	local targetIndex = getTargetIndex( self:getCurrentTarget() )

	local categories = self:getCategoriesIfChanged ()
	local categoryIndex = self:getCategoryIndex( self.queryCategoryName )

	self:updateCache()
	local headers = self:getHeadersIfChanged()
	local rows = self:getRowsIfChanged()

	local status2 = tostring(self.queryTargetName)
	local status1 = status2=="" and "" or "Performance stats for: "

	return	counter,
			self.bQueryDone,
			categories, categoryIndex - 1,
			targets, targetIndex - 1,
			headers,
			rows,
            restoredQueryOptionsText,
            restoredQueryFilterText,
			status1, status2
end


---------------------------------------------------------------------------
--
-- Viewer:updateCache()
--
-- Update cached table
--
---------------------------------------------------------------------------
function Viewer:updateCache()

	local bClearChange = getTickCount() - (self.categoryUpdateTime[self.queryCategoryName] or 0) > 60000
	self.categoryUpdateTime[self.queryCategoryName] = getTickCount()

	local columnSize = self.DEFAULTCOLUMNSIZE

	-- Fetch table
	local target = self:getCurrentTarget()
	if not target then
		self.httpColumns = {{name="no",size=columnSize},{name="target",size=columnSize}}
		self.httpRows = {}
		return
	end
	if not target.bSupportsStats then
		self.httpColumns = {{name="not",size=columnSize},{name="supported",size=columnSize}}
		self.httpRows = {}
		return
	end
	local columnList,rowList, bQueryDone = target:getPerformanceStats( self.name, self.queryCategoryName, self.queryOptionsText, self.queryFilterText )
	self.bQueryDone = bQueryDone

	if not columnList then
		return
	end

	if #columnList == 1 then
		columnSize = "500px"
	end

	-- Process columns
	local rowIndices = {}
	local newColumns = {}
	local prevSectionName = ""
	local idx = 1
	for k,columnName in pairs(columnList) do
		local parts = split ( columnName, string.byte( '.' ) )
		if #parts == 2 then
			local sectionName = parts[1]
			columnName = parts[2]
			if sectionName ~= prevSectionName then
				prevSectionName = sectionName
				table.insert(rowIndices,false)
				table.insert(newColumns,{name=" "..sectionName,size=columnSize})
			end
		end
		table.insert(rowIndices,idx)
		idx = idx + 1	
		table.insert(newColumns,{name=columnName,size=columnSize})
	end
	self.httpColumns = newColumns

	-- Process rows
	local newRows = {}
	for _, row in ipairs(rowList) do
		local rowdata = {}
		local style = "main"
		if #row > 0 then
			if string.find( row[1], '.', 1, true ) ~= nil then
				style = "sub"
			end
		end
		table.insert(rowdata,style)
		for i, idx in ipairs(rowIndices) do
			if idx then
				if bClearChange and newColumns[i].name == "change" then
					table.insert(rowdata,"")
				else
					table.insert(rowdata,row[idx])
				end
			else
				table.insert(rowdata,style == "sub" and " + " or " | ")
			end
		end
		table.insert(newRows,rowdata)
	end
	self.httpRows = newRows
end


---------------------------------------------------------------------------
--
-- table.cmp
--
-- Test for table equality
--
---------------------------------------------------------------------------
function table.cmp(t1, t2)
	if not t1 or not t2 or #t1 ~= #t2 then
		return false
	end
	for k,v in pairs(t1) do
		if v ~= t2[k] then
			return false
		end
	end
	return true
end
