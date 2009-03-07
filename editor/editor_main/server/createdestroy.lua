local rootElement = getRootElement()
local WAIT_LOAD_INTERVAL = 100 --ms

function makeElementStatic(element)
	if getElementType(element) == "vehicle" then
		triggerClientEvent(rootElement, "doSetVehicleStatic", element)
	elseif getElementType(element) == "ped" then
		triggerClientEvent(rootElement, "doSetPedStatic", element)
	else
		for i, child in ipairs(getElementChildren(element)) do
			makeElementStatic(child)
		end
	end
end

local specialSyncers = {
	position = function(element) return {edf.edfGetElementPosition(element)} end,
	rotation = function(element) return {edf.edfGetElementRotation(element)} end,
	dimension = function(element) return 0 end,
	interior = function(element) return edf.edfGetElementInterior(element) end,
	parent = function(element) return getElementData(element, "me:parent") end,
}

function setupNewElement(element, creatorResource, creatorClient, attachLater,shortcut,selectionSubmode)
	selectionSubmode = selectionSubmode or 1
	setElementParent(element, thisDynamicRoot)
	setElementDimension ( element, getWorkingDimension() )
	makeElementStatic( element )
	assignID ( element )
	triggerEvent ( "onElementCreate_undoredo", element )
	if attachLater then
		setTimer(triggerClientEvent, WAIT_LOAD_INTERVAL, 1, creatorClient, "doSelectElement", element, selectionSubmode, shortcut )
	end
	justCreated[element] = true --mark it so undoredo ignores first placement
	
	--store initial properties
	elementProperties[element] = {}
	for dataField in pairs(loadedEDF[creatorResource].elements[getElementType(element)].data) do
		if specialSyncers[dataField] then
			elementProperties[element][dataField] = specialSyncers[dataField](element)
		else
			elementProperties[element][dataField] = edf.edfGetElementProperty(element, dataField) or nil
		end
	end
	
	triggerEvent("onElementCreate", element)
	triggerClientEvent(rootElement, "onClientElementCreate", element)
end

addEventHandler ( "doCreateElement", rootElement,
	function ( elementType, resourceName, parameters, attachLater, shortcut )
		parameters = parameters or {}
		parameters.glued = true
		
		local creatorResource = getResourceFromName( resourceName )
		local edfElement = edf.edfCreateElement (
			elementType,
			creatorResource,
			parameters,
			true --editor mode
		)
		
		if edfElement then
			outputDebugString ( "Created '"..elementType..":"..tostring(edfElement).."' from '"..resourceName.."'" )
			setupNewElement(edfElement, creatorResource, client, attachLater, shortcut)
		else
			outputDebugString ( "Failed to create '"..elementType.." from '"..resourceName.."'" )
		end
	end
)

addEventHandler ( "doCloneElement", rootElement,
	function (attachMode,creator)
		local clone = edf.edfCloneElement(source,true)
		
		if clone then
			outputDebugString ( "Cloned '"..getElementType(source).."'." )
			setupNewElement(clone, creator or edf.edfGetCreatorResource(source), client, true, false, attachMode)
			setLockedElement(source, nil)
		else
			outputDebugString ( "Failed to clone '"..getElementType(source).."'" )
		end
	end
)

addEventHandler ( "doDestroyElement", rootElement,
	function ()
		if getLockedElement(client) == source then
			outputDebugString ( "Deleted '"..getElementType(source).."'." )
			triggerEvent ( "onElementDestroy_undoredo", source )
			setLockedElement(client, nil)
			
			triggerEvent("onElementDestroy", source)
			triggerClientEvent(rootElement, "onClientElementDestroyed", source)
		end
	end
)
