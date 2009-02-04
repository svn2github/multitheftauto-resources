g_Root = getRootElement()
g_ResRoot = getResourceRootElement(getThisResource())
scoreboard = createResourceCallInterface('scoreboard')
votemanager = createResourceCallInterface('votemanager')
mapmanager = createResourceCallInterface('mapmanager')
allowRPC('setVehicleFrozen', 'setElementPosition','setPedGravity')
g_MotorBikeIDs = table.create({ 448, 461, 462, 463, 468, 471, 521, 522, 523, 581, 586 }, true)
g_ArmedVehicleIDs = table.create({ 425, 447, 520, 430, 464, 432 }, true)
g_AircraftIDs = table.create({ 592, 577, 511, 548, 512, 593, 425, 520, 417, 487, 553, 488, 497, 563, 476, 447, 519, 460, 469, 513 }, true)
g_RCVehicleIDs = table.create({ 441, 464, 465, 501, 564 }, true)
g_FixedColorVehicles = {
	[{ 438, 420 }] = false
}
g_VehicleClothes = {
	[{ 490, 523, 598, 596, 597, 599}] = { [16] = false, [17] = 4 }
}

g_CurrentRaceMode = nil

g_Spawnpoints = {}			-- { i = { position={x, y, z}, rotation=rotation, vehicle=vehicleID, paintjob=paintjob, upgrades={...} } }
g_Checkpoints = {}			-- { i = { position={x, y, z}, size=size, color={r, g, b}, type=type, vehicle=vehicleID, paintjob=paintjob, upgrades={...} } }
g_Objects = {}				-- { i = { position={x, y, z}, rotation={x, y, z}, model=modelID } }
g_Pickups = {}				-- { i = { position={x, y, z}, type=type, vehicle=vehicleID, paintjob=paintjob, upgrades={...} }

g_Players = {}				-- { i = player }
g_Vehicles = {}				-- { player = vehicle }

--_DEBUG = {'NOundef','NOopt','NOtoptimes','NOstate','damageproof','racewar'}   -- More error output
_TESTING = true             -- Any user can issue test commands

addEventHandler('onGamemodeMapStart', g_Root,
	function(mapres)
		outputDebugString('onGamemodeMapStart(' .. getResourceName(mapres) .. ')')
		if getPlayerCount() == 0 then
			outputDebugString('Stopping map')
			triggerEvent('onGamemodeMapStop', g_Root)
            return
		end
        gotoState('LoadingMap')
		if g_CurrentRaceMode then
			outputDebugString('Unloading previous map')
			unloadAll()
		end
		if not loadMap(mapres) then
			return
		end
		g_CurrentRaceMode = RaceMode.getApplicableMode():create()
		outputDebugString('Loaded race mode ' .. g_CurrentRaceMode:getName())
		startRace()
	end
)

function cacheGameOptions()
    if not g_GameOptions then
        g_GameOptions = {}
        g_GameOptions.timeafterfirstfinish  = get('race.timeafterfirstfinish') or 30000
        g_GameOptions.hurrytime             = get('race.hurrytime') or 15000
        g_GameOptions.ghostmode             = get('race.ghostmode') or false
        g_GameOptions.ghostalpha            = get('race.ghostalpha') or false
        g_GameOptions.randommaps            = get('race.randommaps') or false
        g_GameOptions.statskey              = get('race.statskey') or 'name'
        g_GameOptions.vehiclecolors         = get('race.vehiclecolors') or 'file'
        g_GameOptions.skins                 = get('race.skins') or 'cj'
        g_GameOptions.autopimp              = get('race.autopimp') or true
        g_GameOptions.vehicleweapons        = get('race.vehicleweapons') or true
        g_GameOptions.ghostmode_map_can_override        = get('race.ghostmode_map_can_override') or true
        g_GameOptions.skins_map_can_override            = get('race.skins_map_can_override') or true
        g_GameOptions.vehicleweapons_map_can_override   = get('race.vehicleweapons_map_can_override') or true
        g_GameOptions.autopimp_map_can_override         = get('race.autopimp_map_can_override') or true
        g_GameOptions.ghostmode_warning_if_map_override         = get('race.ghostmode_warning_if_map_override') or false
        g_GameOptions.vehicleweapons_warning_if_map_override    = get('race.vehicleweapons_warning_if_map_override') or false

        if g_GameOptions.statskey ~= 'name' and g_GameOptions.statskey ~= 'serial' then
            outputWarning( "statskey is not set to 'name' or 'serial'" )
            g_GameOptions.statskey = 'name'
        end
    end
end



-- Called from:
--      onGamemodeMapStart
function loadMap(res)
	local map = RaceMap.load(res)
	if not map then
		outputDebugString('Error loading map')
		return false
	end
	
	-- set options
	if map:isRaceFormat() then
		if map.time then
			setTime(map.time:match('(%d+):(%d+)'))
		end
		if map.weather then
			setWeather(map.weather)
		end
	end
    g_MapInfo = {}
    g_MapInfo.name      = map.info['name'] or 'unnamed'
    g_MapInfo.resname   = map.info['resname'] or getResourceName(res)
	g_MapOptions = {}
	g_MapOptions.duration = map.duration and map.duration*1000 or 1800000
	g_MapOptions.respawn = map.respawn
	if not g_MapOptions.respawn or g_MapOptions.respawn ~= 'none' then
		g_MapOptions.respawn = 'timelimit'
	end
	g_MapOptions.respawntime = g_MapOptions.respawn == 'timelimit' and (map.respawntime and map.respawntime*1000 or 5000)
	g_MapOptions.skins = map.skins or 'cj'
	g_MapOptions.vehicleweapons = map.vehicleweapons == 'true'
    g_MapOptions.ghostmode = map.ghostmode == 'true'
    g_MapOptions.autopimp = map.autopimp == 'true'

    -- Set ghostmode from g_GameOptions if not defined in the map, or map override not allowed
    if not map.ghostmode or not g_GameOptions.ghostmode_map_can_override then
        g_MapOptions.ghostmode = g_GameOptions.ghostmode
    elseif g_GameOptions.ghostmode_warning_if_map_override and g_MapOptions.ghostmode ~= g_GameOptions.ghostmode then
        if g_MapOptions.ghostmode then
            outputChatBox( 'Notice: Collisions are turned off for this map' )
        else
            outputChatBox( 'Notice: Collisions are turned on for this map' )
        end
    end

    -- Set skins from g_GameOptions if not defined in the map, or map override not allowed
    if not map.skins or not g_GameOptions.skins_map_can_override then
        g_MapOptions.skins = g_GameOptions.skins
    end

    -- Set vehicleweapons from g_GameOptions if not defined in the map, or map override not allowed
    if not map.vehicleweapons or not g_GameOptions.vehicleweapons_map_can_override then
        g_MapOptions.vehicleweapons = g_GameOptions.vehicleweapons
    elseif g_GameOptions.vehicleweapons_warning_if_map_override and g_MapOptions.vehicleweapons ~= g_GameOptions.vehicleweapons then
        if g_MapOptions.vehicleweapons then
            outputChatBox( 'Notice: Vehicle weapons are turned on for this map' )
        else
            outputChatBox( 'Notice: Vehicle weapons are turned off for this map' )
        end
    end

    -- Set autopimp from g_GameOptions if not defined in the map, or map override not allowed
    if not map.autopimp or not g_GameOptions.autopimp_map_can_override then
        g_MapOptions.autopimp = g_GameOptions.autopimp
    end

	
	-- read spawnpoints
	g_Spawnpoints = map:getAll('spawnpoint')
	
	-- read checkpoints
	g_Checkpoints = map:getAll('checkpoint')
	if map:isDMFormat() then
		-- sort checkpoints
		local chains = {}		-- a chain is a list of checkpoints that immediately follow each other
		local prevchainnum, chainnum, nextchainnum
		for i,checkpoint in ipairs(g_Checkpoints) do
			-- is it the finish?
			if not checkpoint.nextid then
				table.insert(chains, { checkpoint })
			else
				-- any chain we can place this checkpoint after?
				chainnum = table.find(chains, '[last]', 'nextid', checkpoint.id)
				if chainnum then
					table.insert(chains[chainnum], checkpoint)
					nextchainnum = table.find(chains, 1, 'id', checkpoint.nextid)
					if nextchainnum then
						table.merge(chains[chainnum], chains[nextchainnum])
						table.remove(chains, nextchainnum)
					end
				else
					-- any chain we can place it before?
					chainnum = table.find(chains, 1, 'id', checkpoint.nextid)
					if chainnum then
						table.insert(chains[chainnum], 1, checkpoint)
						prevchainnum = table.find(chains, '[last]', 'nextid', checkpoint.id)
						if prevchainnum then
							table.merge(chains[prevchainnum], chains[chainnum])
							table.remove(chains, chainnum)
						end
					else
						-- new chain
						table.insert(chains, { checkpoint })
					end
				end
			end
		end
		g_Checkpoints = chains[1]
	end
	
	-- read objects
	g_Objects = map:getAll('object')
	
	-- read pickups
	g_Pickups = map:getAll('pickup')
	
	-- unload map xml
	map:unload()
	return true
end

-- Called from:
--      onGamemodeMapStart
function startRace()
    gotoState('PreGridCountdown')
    --g_SToptimesManager:setModeAndMap( g_CurrentRaceMode:getName(), g_MapInfo.name, g_GameOptions.statskey )
    triggerEvent('onStartingMap', g_Root, g_CurrentRaceMode:getName(), g_MapInfo.name, g_GameOptions.statskey )
	g_Players = {}
	g_SpawnTimer = setTimer(joinHandler, 500, 0)
	if g_CurrentRaceMode:isRanked() then
		g_RankTimer = setTimer(updateRank, 1000, 0)
	end
    g_SpawnpointCounter = 0
end


-- Called from:
--      g_RaceStartCountdown
function launchRace()
	table.each(g_Vehicles, setVehicleFrozen, false)
	table.each(g_Players, setPedGravity, 0.008)
	clientCall(g_Root, 'launchRace', g_MapOptions.duration, g_MapOptions.vehicleweapons)
	if g_MapOptions.duration then
		g_RaceEndTimer = setTimer(raceTimeout, g_MapOptions.duration, 1)
	end
	g_CurrentRaceMode:launch()
	g_CurrentRaceMode.running = true
	triggerEvent('onRaceLaunch', getResourceRootElement(mapmanager.getRunningGamemodeMap()))
    gotoState('Running')
end

g_RaceStartCountdown = Countdown.create(6, launchRace)
g_RaceStartCountdown:useImages('img/countdown_%d.png', 474, 204)
g_RaceStartCountdown:enableFade(true)
g_RaceStartCountdown:addClientHook(3, 'playSoundFrontEnd', 44)
g_RaceStartCountdown:addClientHook(2, 'playSoundFrontEnd', 44)
g_RaceStartCountdown:addClientHook(1, 'playSoundFrontEnd', 44)
g_RaceStartCountdown:addClientHook(0, 'playSoundFrontEnd', 45)


-- Called from:
--      Currently unused
function restartRace()
	for i,player in pairs(g_Players) do
		clientCall(player, 'vehicleUnloading')
		destroyElement(g_Vehicles[player])
		destroyBlipsAttachedTo(player)
	end
	startRace()
end


-- Called from:
--      event onPlayerJoin
--      g_SpawnTimer = setTimer(joinHandler, 500, 0) in startRace
-- Interesting calls to:
--      g_RaceStartCountdown:start()
function joinHandler(player)
	if #g_Spawnpoints == 0 then
		-- start vote if no map is loaded
		outputDebugString('No map loaded; showing votemanager')
        RaceMode.endMap()
		return
	end
	if g_SpawnTimer then
		for i,p in ipairs(getElementsByType('player')) do
			if not table.find(g_Players, p) then
				player = p
				break
			end
		end
		if not player then
			killTimer(g_SpawnTimer)
			g_SpawnTimer = nil
            gotoState('GridCountdown')
			g_RaceStartCountdown:start()
			return
		end
	end
	local playerJoined = not player
	if playerJoined then
		player = source
	end
	table.insert(g_Players, player)
	
	local spawnpoint = g_CurrentRaceMode:pickFreeSpawnpoint()
	
	local x, y, z = unpack(spawnpoint.position)
	-- Set random seed dependant on map name, so everyone gets the same models
    setRandomSeedForMap('clothes')

	if g_MapOptions.skins == 'cj' then
		spawnPlayer(player, x + 4, y, z, 0, 0)
		
		local clothes = { [16] = math.random(12, 13), [17] = 7 }    -- 16=Hats(12:helmet 13:moto) 17=Extra(7:garageleg)
		for vehicles,vehicleclothes in pairs(g_VehicleClothes) do
			if table.find(vehicles, spawnpoint.vehicle) then
				for type,index in pairs(vehicleclothes) do
					clothes[type] = index or nil
				end
			end
		end
		local texture, model
		for type,index in pairs(clothes) do
			texture, model = getClothesByTypeIndex(type, index)
			addPedClothes(player, texture, model, type)
		end
	elseif g_MapOptions.skins == 'random' then
		repeat until spawnPlayer(player, x + 4, y, z, 0, math.random(9, 288))
	else
        local ok
        for i=1,20 do
            ok = spawnPlayer(player, x + 4, y, z, 0, getRandomFromRangeList(g_MapOptions.skins))
            if ok then break end
        end
        if not ok then
            spawnPlayer(player, x + 4, y, z, 0, 264)
        end
	end

	setPedStat(player, 160, 1000)
	setPedStat(player, 229, 1000)
	setPedStat(player, 230, 1000)
	
	local vehicle
	if spawnpoint.vehicle then
		local nick = getPlayerName(player)
        setRandomSeedForMap('vehiclecolors')
		vehicle = createVehicle(spawnpoint.vehicle, x, y, z, 0, 0, spawnpoint.rotation, #nick <= 8 and nick or nick:sub(1, 8))
		setVehicleFrozen(vehicle, true)
		setPedGravity(player, 0.0001)
		if playerJoined and g_CurrentRaceMode.running then
			setTimer(
				function()
					if not table.find(g_Players, player) then
						return
					end
					setVehicleFrozen(vehicle, false)
					setPedGravity(player, 0.008)
				end,
				3000,
				1
			)
		end
		
		if spawnpoint.paintjob or spawnpoint.upgrades then
			setVehiclePaintjobAndUpgrades(vehicle, spawnpoint.paintjob, spawnpoint.upgrades)
		else
            if g_MapOptions.autopimp then
			    pimpVehicleRandom(vehicle)
            end
            if g_GameOptions.vehiclecolors == 'random' then
                setRandomSeedForMap('vehiclecolors')
			    local vehicleColorFixed = false
			    for vehicles,color in pairs(g_FixedColorVehicles) do
				    if table.find(vehicles, spawnpoint.vehicle) then
					    if color then
						    setVehicleColor(vehicle, color, 0, 0, 0)
					    end
					    vehicleColorFixed = true
					    break
				    end
			    end
			    if not vehicleColorFixed then
				    setVehicleColor(vehicle, math.random(0, 126), math.random(0, 126), 0, 0)
			    end
            end
		end
		setTimer(warpPedIntoVehicle, 500, 10, player, vehicle)
		
		g_Vehicles[player] = vehicle
	end
	
    -- Tell all clients to re-apply ghostmode settings in 100ms
    setTimer(function() clientCall(g_Root, 'setGhostMode', g_MapOptions.ghostmode) end, 100, 1 )

    -- Send client all info
    local playerInfo = {}
    playerInfo.admin    = isPlayerInACLGroup(player, 'Admin')
    playerInfo.testing  = _TESTING
	local duration = playerJoined and (g_MapOptions.duration and (g_MapOptions.duration - g_CurrentRaceMode:getTimePassed()) or true)
	clientCall(player, 'initRace', vehicle, g_Checkpoints, g_Objects, g_Pickups, g_MapOptions, g_CurrentRaceMode:isRanked(), duration, g_GameOptions, g_MapInfo, playerInfo )
	
	createBlipAttachedTo(player, 0, 1, 200, 200, 200)
	g_CurrentRaceMode:onPlayerJoin(player, spawnpoint)

    -- Tell all clients to re-apply ghostmode settings in 1000ms
    setTimer(function() clientCall(g_Root, 'setGhostMode', g_MapOptions.ghostmode) end, 1000, 1 )
	
	if playerJoined and getPlayerCount() <= 2 then
		---- Start random map vote if someone joined a lone player
        startMidMapVoteForRandomMap()
	end
end
addEventHandler('onPlayerJoin', g_Root, joinHandler)


-- Called from:
--      g_RankTimer = setTimer(updateRank, 1000, 0) in startRace
function updateRank()
    if g_CurrentRaceMode then
	    for i,player in ipairs(g_Players) do
		    if not isPlayerFinished(player) then
			    setElementData(player, 'Race rank', g_CurrentRaceMode:getPlayerRank(player))
		    end
	    end
    end
end


-- Set random seed dependent on map name
--
-- Note: Some clients will experience severe stutter and stalls if any
-- players have different skin/clothes.
-- For smooth gameplay, ensure everyone has the same skin setup including crash helmet etc.
function setRandomSeedForMap( type )
    local seed = 0
    if type == 'clothes' then
        seed = 100                  -- All players get the same driver skin/clothes
    elseif type == 'upgrades' then
        seed = 0                    -- All players get the same set of vehicle upgrades
    elseif type == 'vehiclecolors' then
        seed = getTickCount()       -- Allow vehicle colors to vary between players
    else
        outputWarning( 'Unknown setRandomSeedForMap type ' .. type )
    end
    for i,char in ipairs( { string.byte(g_MapInfo.name,1,g_MapInfo.name:len()) } ) do
        seed = math.mod( seed * 11 + char, 216943)
    end
    math.randomseed(seed)    
end



addEvent('onPlayerReachCheckpointInternal', true)
addEventHandler('onPlayerReachCheckpointInternal', g_Root,
	function(checkpointNum)
        if not stateAllowsCheckpoint() then
            return
        end
		local vehicle = g_Vehicles[source]
		local checkpoint = g_Checkpoints[checkpointNum]
		if checkpoint.vehicle then
			setVehicleID(vehicle, checkpoint.vehicle)
			clientCall(source, 'vehicleChanging')
			if checkpoint.paintjob or checkpoint.upgrades then
				setVehiclePaintjobAndUpgrades(vehicle, checkpoint.paintjob, checkpoint.upgrades)
			else
                if g_MapOptions.autopimp then
			        pimpVehicleRandom(vehicle)
                end
			end
		end
		
		local rank, time = g_CurrentRaceMode:onPlayerReachCheckpoint(source, checkpointNum)
		if checkpointNum < #g_Checkpoints then
			triggerEvent('onPlayerReachCheckpoint', source, checkpointNum, time)
		else
			triggerEvent('onPlayerFinish', source, rank, time)
		end
	end
)

addEvent('onPlayerPickUpRacePickup', true)
addEventHandler('onPlayerPickUpRacePickup', g_Root,
	function(pickupID, pickupType)
        if not stateAllowsPickup() then
            return
        end
		local pickup = g_Pickups[table.find(g_Pickups, 'id', pickupID)]
		local vehicle = g_Vehicles[source]
		if pickup.type == 'repair' then
			fixVehicle(vehicle)
		elseif pickup.type == 'nitro' then
			addVehicleUpgrade(vehicle, 1010)
		elseif pickup.type == 'vehiclechange' then
			setVehicleID(vehicle, pickup.vehicle)
			setVehiclePaintjobAndUpgrades(vehicle, pickup.paintjob, pickup.upgrades)
			clientCall(source, 'vehicleChanging', getTime())
		end
	end
)

addEventHandler('onPlayerWasted', g_Root,
	function()
		if g_CurrentRaceMode then
			if not g_CurrentRaceMode.startTick then
				local x, y, z = getElementPosition(source)
				spawnPlayer(source, x, y, z, 0, getElementModel(source))
				if g_Vehicles[source] then
					setTimer(warpPedIntoVehicle, 500, 10, source, g_Vehicles[source])
				end
			else
				g_CurrentRaceMode:onPlayerWasted(source)
			end
		end
	end
)


-- Called from:
--		g_RaceEndTimer = setTimer(raceTimeout, g_MapOptions.duration, 1)
function raceTimeout()
    gotoState('TimesUp')
	for i,player in pairs(g_Players) do
		if not isPlayerFinished(player) then
			showMessage('Time\'s up!')
		end
	end
	clientCall(g_Root, 'raceTimeout')
	g_RaceEndTimer = nil
    RaceMode.endMap()
end

-- Called from:
--      onGamemodeMapStart
--      onGamemodeMapStop
--      onResourceStop
function unloadAll()
	clientCall(g_Root, 'unloadAll')
	if g_RaceEndTimer then
		killTimer(g_RaceEndTimer)
		g_RaceEndTimer = nil
	end
	if g_RankTimer then
		killTimer(g_RankTimer)
		g_RankTimer = nil
	end

	Countdown.destroyAll()

	for i,player in pairs(g_Players) do
		setPlayerFinished(player, false)
		destroyMessage(player)
	end
	destroyMessage(g_Root)
	
	table.each(g_Vehicles, destroyElement)
	g_Vehicles = {}
	g_Spawnpoints = {}
	g_Checkpoints = {}
	g_Objects = {}
	g_Pickups = {}
	if g_CurrentRaceMode then
		g_CurrentRaceMode:destroy()
	end
	g_CurrentRaceMode = nil
end

addEventHandler('onGamemodeMapStop', g_Root,
	function(mapres)
        fadeCamera ( g_Root, false, 0.0, 0,0, 0 )
        gotoState('NoMap')
		unloadAll()
	end
)

-- Called from:
--      nowhere
addEventHandler('onPollDraw', g_Root,
	function()
		outputDebugString('Poll ended in a draw')
	end
)

local bCalledOnGamemodeStart = false

function resourceStartedTimeout()
    if not bCalledOnGamemodeStart then
        outputWarning( "Game mode 'Race' started incorrectly." )
        outputWarning( "Trying to restart with mapmanager..." )
        exports.mapmanager:changeGamemode( getResourceFromName('race') )
    end
end


addEventHandler('onResourceStart', g_ResRoot,
	function()
		outputDebugString('Resource starting')
		scoreboard.addScoreboardColumn('Race rank')
        setTimer(resourceStartedTimeout,900,1)
        cacheGameOptions()
	end
)

addEventHandler('onGamemodeStart', g_ResRoot,
    function()
	    outputDebugString('onGamemodeStart')
        bCalledOnGamemodeStart = true
        cacheGameOptions()
    end
)

addEventHandler('onResourceStop', g_ResRoot,
	function()
        gotoState( 'ResourceStopping' )
        fadeCamera ( g_Root, false, 0.0, 0,0, 0 )
		outputDebugString('Resource stopping')
		unloadAll()
		scoreboard.removeScoreboardColumn('Race rank')
	end
)

addEventHandler('onPlayerQuit', g_Root,
	function()
		destroyBlipsAttachedTo(source)
		table.removevalue(g_Players, source)
		if g_Vehicles[source] then
			destroyElement(g_Vehicles[source])
			g_Vehicles[source] = nil
		end
		if g_CurrentRaceMode then
			g_CurrentRaceMode:onPlayerQuit(source)
		end
		
		for i,player in pairs(g_Players) do
			if not isPlayerFinished(player) then
				return
			end
		end
		if #g_Players == 0 then
			outputDebugString('Stopping map')
			triggerEvent('onGamemodeMapStop', g_Root)
		else
            gotoState('EveryoneFinished')
            RaceMode.endMap()
		end
	end
)

addEventHandler('onVehicleDamage', g_Root,
	function()
		local player = table.find(g_Vehicles, source)
		if player then
			setElementHealth(player, getElementHealth(source)/10)
		end
	end
)

addEventHandler('onVehicleStartExit', g_Root, function() cancelEvent() end)

function getPlayerCurrentCheckpoint(player)
	return getElementData(player, 'race.checkpoint') or 1
end

function setPlayerCurrentCheckpoint(player, i)
	clientCall(player, 'setCurrentCheckpoint', i)
end

function setPlayerFinished(player, toggle)
	setElementData(player, 'race.finished', toggle)
end

function isPlayerFinished(player)
	return getElementData(player, 'race.finished') or false
end

function distanceFromPlayerToCheckpoint(player, i)
	local checkpoint = g_Checkpoints[i]
	local x, y, z = getElementPosition(player)
	return getDistanceBetweenPoints3D(x, y, z, unpack(checkpoint.position))
end

addCommandHandler('kill',
	function(player)
        if stateAllowsKillPlayer() then
		    killPed(player)
        end
	end
)

addCommandHandler('ghostmode',
	function(player)
		if not _TESTING and not isPlayerInACLGroup(player, 'Admin') then
			return
		end
		g_MapOptions.ghostmode = not g_MapOptions.ghostmode
		clientCall(g_Root, 'setGhostMode', g_MapOptions.ghostmode)
		if g_MapOptions.ghostmode then
			outputChatBox('Ghostmode enabled by ' .. getPlayerName(player), g_Root, 0, 240, 0)
		else
			outputChatBox('Ghostmode disabled by ' .. getPlayerName(player), g_Root, 240, 0, 0)
		end
	end
)

addCommandHandler('convrace',
	function(player, command, resname)
		local map = RaceMap.load(getResourceFromName(resname))
		if not map then
			return
		end
		if map:isDMFormat() then
			outputConsole('Map is already in deathmatch format.')
			return
		end
		map:convert()
		map:save()
		map:unload()
		outputConsole('Map converted successfully')
	end
)

------------------------
-- Exported functions

function getPlayerRank(player)
	if not g_CurrentRaceMode or not g_CurrentRaceMode:isRanked() then
		return false
	end
	return g_CurrentRaceMode:getPlayerRank(player)
end

function getTimePassed()
	if not g_CurrentRaceMode then
		return false
	end
	return g_CurrentRaceMode:getTimePassed()
end

