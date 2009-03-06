allEDF = {}

addEventHandler ( "onClientGUILoaded", rootElement,
	function()
		triggerClientEvent ( client, "syncEDFDefinitions", client, allEDF )
	end
)

function setClientAddedEDFs(resources)
	table.map(resources, getResourceName)
	-- move superfluous resources to available list
	for i=#allEDF.addedEDF,1,-1 do
		if not table.find(resources, allEDF.addedEDF[i]) then
			table.insert(allEDF.availEDF, allEDF.addedEDF[i])
			table.remove(allEDF.addedEDF, i)
		end
	end
	-- remove added resources from available list
	table.subtract(allEDF.availEDF, resources)
	-- set added list
	allEDF.addedEDF = resources
	triggerClientEvent('syncEDFDefinitions', rootElement, allEDF)
end

function addClientEDFs(edfsToAdd)
	for i,edfToAdd in ipairs(edfsToAdd) do
		edfToAdd = getResourceName(edfToAdd)
		for j,availResName in ipairs(allEDF.availEDF) do
			if availResName == edfToAdd then
				table.remove(allEDF.availEDF, j)
				table.insert(allEDF.addedEDF, edfToAdd)
				break
			end
		end
	end
	triggerClientEvent('syncEDFDefinitions', rootElement, allEDF)
end

function removeClientEDFs(edfsToRemove)
	for i,edfToRemove in ipairs(edfsToRemove) do
		edfToRemove = getResourceName(edfToRemove)
		for j,addedResName in ipairs(allEDF.addedEDF) do
			if addedResName == edfToRemove then
				table.remove(allEDF.addedEDF, j)
				table.insert(allEDF.availEDF, edfToRemove)
				break
			end
		end
	end
	triggerClientEvent('syncEDFDefinitions', rootElement, allEDF)
end

function getClientAvailableEDFs()
	return table.map(table.shallowcopy(allEDF.availEDF), getResourceFromName)
end

function getClientAddedEDFs()
	return table.map(table.shallowcopy(allEDF.addedEDF), getResourceFromName)
end

addEventHandler ( "onResourceStart", thisResourceRoot,
	function ()
		if getResourceState( edf.res ) == "running" then
			loadedDefs = edf.edfGetLoadedEDFResources()
			--get EDF defs
			local resources = getResources()
			allEDF.availEDF = {}
			allEDF.addedEDF = {}
			for k,v in ipairs(resources) do
				if v ~= edf.res and v ~= getThisResource() and edf.edfHasDefinition(v) then
					local loaded = false
					for k, loadedResource in pairs(loadedDefs) do
						if v == loadedResource then
							loaded = true
							break
						end
					end
					if ( loaded ) then
						table.insert ( allEDF.addedEDF, getResourceName ( v ) )
					else
						table.insert ( allEDF.availEDF, getResourceName ( v ) )
					end
				end
			end
		end
	end
)

addEvent ( "reloadEDFDefinitions", true )
addEventHandler ( "reloadEDFDefinitions",rootElement,
function(newEDF)
	editor_gui.outputMessage ( getPlayerName(client).." updated the loaded definitions.", rootElement, 255, 255, 0 )
	loadedDefs = edf.edfGetLoadedEDFResources()
	--load new defs
	for k,resourceName in pairs(newEDF.addedEDF) do
		--check if the resource is loaded already
		local loaded = false
		local resource = getResourceFromName ( resourceName )
		for k, loadedResource in pairs(loadedDefs) do
			if loadedResource == resource then
				loaded = true
				break
			end
		end
		if loaded == false then
			outputDebugString ( "loading "..resourceName.." def." )
			--Only accept server config files and general files (for edf icons)
			-- startResource ( getResourceFromName(resourceName),false,true,false,false,false,false,false,true)
			edf.edfStartResource ( getResourceFromName(resourceName) )
		end
	end
	--unload defs
	for k, resourceName in pairs(newEDF.availEDF) do
		local loaded = false
		local resource = getResourceFromName ( resourceName )
		for k, loadedResource in pairs(loadedDefs) do
			if loadedResource == resource then
				loaded = true
				break
			end
		end
		if loaded == true then
			outputDebugString ( "unloading "..resourceName.." def." )
			-- stopResource ( getResourceFromName(resourceName) )
			edf.edfStopResource ( getResourceFromName(resourceName) )
		end
	end
	allEDF = newEDF
	triggerClientEvent('syncEDFDefinitions', rootElement, allEDF)
end )

addEventHandler ( "onResourceStop",thisResourceRoot,
	function()
		if not newEDF then return end --newEDF is cleared when the editor is stopped (prevent a debug error)
		for i, resourceName in ipairs(newEDF.addedEDF) do
			local resource = getResourceFromName(resourceName)
			if getResourceState ( resource ) == "running" then
				stopResource ( resource )
			end
		end
	end
)