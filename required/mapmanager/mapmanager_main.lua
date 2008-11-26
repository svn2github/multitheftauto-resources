currentGamemode = nil
currentGamemodeMap = nil
nextGamemode = nil
nextGamemodeMap = nil

setGameType(false)
setMapName("None")

rootElement = getRootElement()

addEvent("onGamemodeStart")
addEvent("onGamemodeStop")
addEvent("onGamemodeMapStart")
addEvent("onGamemodeMapStop")

addEventHandler("onResourceStop", rootElement, 
	function (stoppedResource)
		local resourceRoot = getResourceRootElement(stoppedResource)
		if stoppedResource == currentGamemode then
			currentGamemode = nil
			setGameType(false)
			
			triggerEvent("onGamemodeStop", resourceRoot, currentGamemode)
			
			if currentGamemodeMap then
				stopResource(currentGamemodeMap)
			elseif nextGamemode then
				startGamemodeT(nextGamemode)
				nextGamemode = nil
				if nextGamemodeMap then
					startGamemodeMapT(nextGamemodeMap)
					nextGamemodeMap = nil
				end
			end
		elseif stoppedResource == currentGamemodeMap then
			currentGamemodeMap = nil
			resetMapInfo()
			setMapName("None")
			
			triggerEvent("onGamemodeMapStop", resourceRoot, currentGamemodeMap)
			
			if nextGamemode then
				startGamemodeT(nextGamemode)
				nextGamemode = nil
				if nextGamemodeMap then
					startGamemodeMapT(nextGamemodeMap)
					nextGamemodeMap = nil
				end
			elseif nextGamemodeMap then
				startGamemodeMapT(nextGamemodeMap)
				nextGamemodeMap = nil
			end
		end
	end
)

addEventHandler("onGamemodeStart", rootElement, 
	function ( startedGamemode )
		local gamemodeName = getResourceInfo(startedGamemode, "name") or getResourceName(startedGamemode)
		
		if get("ASE") then
			setGameType(gamemodeName)
		end
		if get("messages") then
			outputMapManager("Gamemode '"..gamemodeName.."' started.")
		end
	end
)

addEventHandler("onGamemodeMapStart", rootElement, 
	function ( startedGamemodeMap )
		local gamemodeMapName = getResourceInfo(startedGamemodeMap, "name") or getResourceName(startedGamemodeMap)
		
		applyMapSettings( currentGamemodeMap )
		
		if get("ASE") then
			setMapName(gamemodeMapName)
		end
		if get("messages") then
			outputMapManager("Map '"..gamemodeMapName.."' started.")
		end
	end
)

function changeGamemodeMap_cmd(source, command, mapName, gamemodeName)
	source = source or serverConsole

	local map
	if mapName then
		map = getResourceFromName(mapName)
		if not isMap(map) then
			outputMapManager("'"..mapName.."' is not a valid map.",source)
			return false
		end
	else
		outputMapManager("Usage: /"..command.." map [gamemode]",source)
		return false
	end
	
	local gamemode = currentGamemode
	if gamemodeName then
		gamemode = getResourceFromName(gamemodeName)
		if not isGamemode(gamemode) then
			outputMapManager("'"..gamemodeName.."' is not a valid gamemode.",source)
			return false
		end
	end

	if not isGamemode(gamemode) then
		outputMapManager("No gamemode is running.",source)
	elseif not isMapCompatibleWithGamemode(map, gamemode) then
		outputMapManager("Map '"..getResourceName(map)..
			"' is not compatible with '"..getResourceName(gamemode).."'.",source)
	else
		changeGamemodeMap(map, gamemode)
	end
end
addCommandHandler("changemap", changeGamemodeMap_cmd, true)

function changeGamemode_cmd(source, command, gamemodeName, mapName)
	source = source or serverConsole

	local gamemode
	if gamemodeName then
		gamemode = getResourceFromName(gamemodeName)
		if not isGamemode(gamemode) then
			outputMapManager("'"..gamemodeName.."' is not a valid gamemode.",source)
			return false
		end
	else
		outputMapManager("Usage: /"..command.." gamemode [map]",source)
		return false
	end
	
	local map
	if mapName then
		map = getResourceFromName(mapName)
		if not isMap(map) then
			outputMapManager("'"..mapName.."' is not a valid map.",source)
			return false
		end
	end
	
	changeGamemode(gamemode,map)
end
addCommandHandler("gamemode", changeGamemode_cmd, true)
addCommandHandler("changemode", changeGamemode_cmd, true)

function stopGamemode_cmd(source)
	source = source or serverConsole
	
	if currentGamemode then
		stopGamemode()
		local gamemodeName = getResourceInfo(currentGamemode, "name") or getResourceName(currentGamemode)
		outputMapManager("Gamemode '"..gamemodeName.."' stopped.",source)
	else
		outputMapManager("No gamemode is running.",source)
	end
end
addCommandHandler("stopmode", stopGamemode_cmd, true)

function stopGamemodeMap_cmd(source)
	source = source or serverConsole
	
	if currentGamemodeMap then
		stopGamemodeMap()
		local mapName = getResourceInfo(currentGamemodeMap, "name") or getResourceName(currentGamemodeMap)
		outputMapManager("Map '"..mapName.."' stopped.",source)
	else
		outputMapManager("No gamemode map is running.",source)
	end
end
addCommandHandler("stopmap", stopGamemodeMap_cmd, true)

function outputGamemodeListToConsole(source)
	source = source or serverConsole

	local allGamemodes = getGamemodes()
	local numberOfGamemodes = #allGamemodes

	if numberOfGamemodes == 0 then
		outputMapManagerConsole("There are no gamemodes.", source)
	else
		local s = "s"
		if numberOfGamemodes == 1 then s="" end
		outputMapManagerConsole("There are "..numberOfGamemodes.." gamemode"..s..":", source)
	end

	for k, gamemode in ipairs(allGamemodes) do
		local gamemodeFriendlyName = getResourceInfo(gamemode, "name")
		if gamemodeFriendlyName then
			gamemodeFriendlyName = " ("..gamemodeFriendlyName..") "
		else
			gamemodeFriendlyName = ""
		end
		
		local numberOfCompatibleMaps = #getMapsCompatibleWithGamemode(gamemode)
		
		local s = "s"
		if numberOfCompatibleMaps == 1 then s="" end
		
		outputMapManagerConsole(getResourceName(gamemode) .. gamemodeFriendlyName .. " [".. numberOfCompatibleMaps .. " map"..s.."]", source)
	end
end
addCommandHandler("gamemodes",outputGamemodeListToConsole)

function outputMapListToConsole(source, command, gamemodeName)
	source = source or serverConsole

	if not gamemodeName then
		local allMaps = getMaps()
		local numberOfMaps = #allMaps
		
		if numberOfMaps == 0 then
			outputMapManagerConsole("There are no maps.", source)
		else
			local s = "s"
			if numberOfMaps == 1 then s="" end
			outputMapManagerConsole("There are "..numberOfMaps.." map"..s..":", source)
		end
		
		for k, map in ipairs(allMaps) do
			local gamemodeMapFriendlyName = getResourceInfo(map, "name")
			if gamemodeMapFriendlyName then
				gamemodeMapFriendlyName = " ("..gamemodeMapFriendlyName..") "
			else
				gamemodeMapFriendlyName = ""
			end
			outputMapManagerConsole(getResourceName(map) .. gamemodeMapFriendlyName, source)
		end
	else
		local gamemode = getResourceFromName(gamemodeName)
		if not gamemode then
			outputMapManager("Gamemode '"..gamemodeName.."' does not exist.", source)
			return false
		end
		
		local compatibleMaps = getMapsCompatibleWithGamemode(gamemode)
		if not compatibleMaps then
			outputMapManager("Gamemode '"..gamemodeName.."' does not exist.", source)
			return false
		end
		
		local numberOfCompatibleMaps = #compatibleMaps
		if numberOfCompatibleMaps == 0 then
			outputMapManagerConsole("'"..gamemodeName.."' has no maps.", source)
		else
			local s = "s"
			if numberOfCompatibleMaps == 1 then s="" end
			outputMapManagerConsole("'"..gamemodeName.."' has "..#compatibleMaps.." map"..s..":", source)
		end
		
		for k, map in ipairs(compatibleMaps) do
			local gamemodeMapFriendlyName = getResourceInfo(map, "name")
			if gamemodeMapFriendlyName then
				gamemodeMapFriendlyName = " ("..gamemodeMapFriendlyName..") "
			else
				gamemodeMapFriendlyName = ""
			end
			outputMapManagerConsole(getResourceName(map) .. gamemodeMapFriendlyName, source)
		end
	end
end
addCommandHandler("maps",outputMapListToConsole)

function startGamemode(gamemode)
	if startResource(gamemode) then
		currentGamemode = gamemode
		triggerEvent("onGamemodeStart", getResourceRootElement(gamemode), gamemode)
	else
		error("mapmanager: gamemode resource could not be started.", 2)
	end
end

function startGamemodeT(gamemode)
	setTimer(startGamemode, 50, 1, gamemode)
end

function startGamemodeMap(map)
	if startResource(map) then
		currentGamemodeMap = map
		triggerEvent("onGamemodeMapStart", getResourceRootElement(map), map)
	else
		error("mapmanager: map resource could not be started.", 2)
	end
end

function startGamemodeMapT(map)
	setTimer(startGamemodeMap, 50, 1, map)
end

local serverConsole = getElementByIndex("console", 0)

function outputMapManager(message, toElement)
	toElement = toElement or rootElement
	local r, g, b = getColorFromString(string.upper(get("color")))
	if getElementType(toElement) == "console" then
		outputServerLog(message)
	else
		outputChatBox(message, toElement, r, g, b)
		if toElement == rootElement then
			outputServerLog(message)
		end
	end
end

function outputMapManagerConsole(message, toElement)
	toElement = toElement or rootElement
	if getElementType(toElement) == "console" then
		outputServerLog(message)
	else
		outputConsole(message, toElement)
		if toElement == rootElement then
			outputServerLog(message)
		end
	end
end

function doesMapSupportPlayerCount( map )
	local mapName = getResourceName(map)
	local minPlayers = get(mapName..".minplayers")
	local minPlayers = get(mapName..".maxplayers")
	
	local playersIn = getPlayerCount()
	
	if minPlayers and minPlayers < playersIn then
		outputMapManager( "More than "..(minPlayers-1).." are required to start '"..mapName.."'" )
		return false
	end
	
	if maxPlayers and maxPlayers > playersIn then
		outputMapManager( "Less than "..(maxPlayers+1).." are required to start '"..mapName.."'" )
		return false
	end
		
	return true
end

local hr, mn

local settingApplier = {
	gamespeed = function(value) setGameSpeed(tonumber(value)) end,
	gravity = function(value) setGravity(tonumber(value)) end,
	time = function(value)
		local splitString = split(value, string.byte(':'))
		hr = tonumber(splitString[1]) or 12
		mn = tonumber(splitString[2]) or 0
		setTime(hr, mn)
	end,
	weather = function(value) setWeather(tonumber(value)) end,
	waveheight = function(value) setWaveHeight(tonumber(value)) end,
}

local defaultSettings = {
	gamespeed = 1,
	gravity = 0.008,
	time = "12:00",
	weather = 0,
	waveheight = 0,
}

function freezeTimeOnJoin()
	triggerClientEvent(source, "mm.doFreezeTime", source, hr, mn)
end

function removeTimeFreeze()
	local hr, mn = getTime()
	triggerClientEvent(rootElement, "mm.doUnfreezeTime", rootElement, hr, mn)
	removeEventHandler("onPlayerJoin", rootElement, freezeTimeOnJoin)
end
addEventHandler("onGamemodeMapStop", rootElement, removeTimeFreeze)

function applyMapSettings( map )
	local mapSettingsGroup = getResourceName(map).."."
	for setting, defaultValue in pairs(defaultSettings) do
		settingApplier[setting](get(mapSettingsGroup..setting) or defaultValue)
	end
	
	if get(mapSettingsGroup.."locked_time") then
		triggerClientEvent(rootElement, "mm.doFreezeTime", rootElement, hr, mn)
		addEventHandler("onPlayerJoin", rootElement, freezeTimeOnJoin)
	end
end
