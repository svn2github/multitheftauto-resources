RaceMode = {}
RaceMode.__index = RaceMode

RaceMode.registeredModes = {}
RaceMode.instances = {}

function RaceMode:register(name)
	RaceMode.registeredModes[name] = self
	self.name = name
end

function RaceMode.getApplicableMode()
	for modeName,mode in pairs(RaceMode.registeredModes) do
		if mode:isApplicable() then
			return mode
		end
	end
	return RaceMode
end

function RaceMode:getName()
	return self.name
end

function RaceMode.getCheckpoints()
	return g_Checkpoints
end

function RaceMode.getCheckpoint(i)
	return g_Checkpoints[i]
end

function RaceMode.getNumberOfCheckpoints()
	return #g_Checkpoints
end

function RaceMode.checkpointsExist()
	return #g_Checkpoints > 0
end

function RaceMode.getSpawnpoints()
	return g_Spawnpoints
end

function RaceMode.getNumberOfSpawnpoints()
	return #g_Spawnpoints
end

function RaceMode.getSpawnpoint(i)
	return g_Spawnpoints[i]
end

function RaceMode.getMapOption(option)
	return g_MapOptions[option]
end

function RaceMode.getPlayers()
	return g_Players
end

function RaceMode.setPlayerFinished(player)
	setPlayerFinished(player, true)
end

function RaceMode.isPlayerFinished(player)
	return isPlayerFinished(player)
end

function RaceMode.getPlayerVehicle(player)
	return g_Vehicles[player]
end

function RaceMode:setTimeLeft(timeLeft)
	if g_MapOptions.duration - self:getTimePassed() > timeLeft then
		g_MapOptions.duration = self:getTimePassed() + timeLeft
		killTimer(g_RaceEndTimer)
		g_RaceEndTimer = setTimer(raceTimeout, timeLeft, 1)
		clientCall(g_Root, 'setTimeLeft', timeLeft)
	end
end

function RaceMode.endRace()
    gotoState('PostRace')
    local text = g_GameOptions.randommaps and 'Next map starts in:' or 'Vote for next map starts in:'
    Countdown.create(5, RaceMode.startNextMapSelect, text, 255, 255, 255):start()
end

function RaceMode.startNextMapSelect()
    gotoState('NextMapSelect')
    Countdown.destroyAll()
    destroyAllMessages()
    if g_GameOptions.randommaps then
        startRandomMap()
    else
        local options = {
                adjustWidth = 50,
                skipDontChange = true,
            }
        votemanager.voteMap(getThisResource(),nil,options)
    end
end

-- Default functions

function RaceMode.isApplicable()
	return false
end

function RaceMode:create()
	local id = #RaceMode.instances + 1
	RaceMode.instances[id] = setmetatable(
		{
			id = id,
			checkpointBackups = {}  -- { player = { goingback = true/false, i = { vehicle = id, position = {x, y, z}, rotation = {x, y, z}, velocity = {x, y, z} } } }
		},
		self
	)
	return RaceMode.instances[id]
end

function RaceMode:launch()
	self.startTick = getTickCount()
	for i,spawnpoint in ipairs(RaceMode.getSpawnpoints()) do
		spawnpoint.used = nil
	end
end

function RaceMode:getTimePassed()
	if self.startTick then
		return getTickCount() - self.startTick
	else
		return 0
	end
end

function RaceMode:getTimeRemaining()
	if self.startTick then
		return self.startTick + g_MapOptions.duration - getTickCount()
	else
		return 0
	end
end

function RaceMode:isRanked()
	return true
end

function RaceMode:getPlayerRank(queryPlayer)
	local rank = 1
	local queryCheckpoint = getPlayerCurrentCheckpoint(queryPlayer)
	local checkpoint
	
	for i,player in ipairs(RaceMode.getPlayers()) do
		if player ~= queryPlayer then
			checkpoint = getPlayerCurrentCheckpoint(player)
			if RaceMode.isPlayerFinished(player) or checkpoint > queryCheckpoint then
				rank = rank + 1
			elseif checkpoint == queryCheckpoint then
				if distanceFromPlayerToCheckpoint(player, checkpoint) < distanceFromPlayerToCheckpoint(queryPlayer, checkpoint) then
					rank = rank + 1
				end
			end
		end
	end
	return rank
end

function RaceMode:onPlayerJoin(player, spawnpoint)
	self.checkpointBackups[player] = {}
	self.checkpointBackups[player][0] = { vehicle = spawnpoint.vehicle, position = spawnpoint.position, rotation = {0, 0, spawnpoint.rotation}, velocity = {0, 0, 0}, turnvelocity = {0, 0, 0}, geardown = true }
end

function RaceMode:onPlayerReachCheckpoint(player, checkpointNum)
	local rank = self:getPlayerRank(player)
	local time = self:getTimePassed()
	if checkpointNum < RaceMode.getNumberOfCheckpoints() then
		-- Regular checkpoint
		local vehicle = RaceMode.getPlayerVehicle(player)
		self.checkpointBackups[player][checkpointNum] = { vehicle = getElementModel(vehicle), position = { getElementPosition(vehicle) }, rotation = { getVehicleRotation(vehicle) }, velocity = { getElementVelocity(vehicle) }, turnvelocity = { getVehicleTurnVelocity(vehicle) }, geardown = getVehicleLandingGearDown(vehicle) or false }		
		
		self.checkpointBackups[player].goingback = true
		if self.checkpointBackups[player].timer then
			killTimer(self.checkpointBackups[player].timer)
		end
		self.checkpointBackups[player].timer = setTimer(lastCheckpointWasSafe, 5000, 1, self.id, player)
	else
		-- Finish reached
		RaceMode.setPlayerFinished(player)
		if rank == 1 then
            gotoState('SomeoneWon')
			showMessage('You have won the race!', 0, 255, 0, player)
			if self.rankingBoard then	-- Remove lingering labels
				self.rankingBoard:destroy()
			end
			self.rankingBoard = RankingBoard:create()
			if g_MapOptions.duration then
				self:setTimeLeft( g_GameOptions.timeafterfirstfinish )
			end
		else
			showMessage('You finished ' .. rank .. ( (rank < 10 or rank > 20) and ({ [1] = 'st', [2] = 'nd', [3] = 'rd' })[rank % 10] or 'th' ) .. '!', 0, 255, 0, player)
		end
		g_SToptimesManager:playerFinished( player, time)
		self.rankingBoard:add(player, time)
		if rank < getPlayerCount() then
			setTimer(clientCall, 5000, 1, player, 'startSpectate')
		else
            gotoState('EveryoneFinished')
            self:setTimeLeft( 0 )
			RaceMode.endRace()
		end
	end
	return rank, time
end

function lastCheckpointWasSafe(id, player)
	if not table.find(g_Players, player) then
		return
	end
	local self = RaceMode.instances[id]
	if self.checkpointBackups[player] then
		self.checkpointBackups[player].goingback = false
		self.checkpointBackups[player].timer = nil
	end
end

function RaceMode:onPlayerWasted(player)
	if not self.checkpointBackups[player] then
		return
	end
	if self.checkpointBackups[player].timer then
		killTimer(self.checkpointBackups[player].timer)
		self.checkpointBackups[player].timer = nil
	end
	if RaceMode.getMapOption('respawn') == 'timelimit' and not RaceMode.isPlayerFinished(source) then
        -- See if its worth doing a respawn
        local respawnTime       = RaceMode.getMapOption('respawntime')
        if self:getTimeRemaining() - respawnTime > 3000 then
            Countdown.create(respawnTime/1000, restorePlayer, 'You will respawn in:', 255, 255, 255, self.id, player):start(player)
        end
	    if RaceMode.getMapOption('respawntime') >= 10000 then
		    setTimer(clientCall, 2000, 1, player, 'startSpectate')
	    end
	end
end

function RaceMode:pickFreeSpawnpoint()
    g_SpawnpointCounter = g_SpawnpointCounter or 0
    g_SpawnpointCounter = g_SpawnpointCounter + 1
    if g_SpawnpointCounter > RaceMode.getNumberOfSpawnpoints() then
        g_SpawnpointCounter = 1
    end
	return RaceMode.getSpawnpoint(g_SpawnpointCounter)
end

function freeSpawnpoint(i)
	RaceMode.getSpawnpoint(i).used = nil
end

function restorePlayer(id, player)
	if not table.find(g_Players, player) then
		return
	end
	local self = RaceMode.instances[id]
	clientCall(player, 'remoteStopSpectateAndBlack')

	local checkpoint = getPlayerCurrentCheckpoint(player)
	if self.checkpointBackups[player].goingback and checkpoint > 1 then
		checkpoint = checkpoint - 1
		setPlayerCurrentCheckpoint(player, checkpoint)
	end
	self.checkpointBackups[player].goingback = true
	local bkp = self.checkpointBackups[player][checkpoint - 1]
	if not RaceMode.checkpointsExist() then
		local spawnpoint = self:pickFreeSpawnpoint()
		bkp.position = spawnpoint.position
		bkp.rotation = {0, 0, spawnpoint.rotation}
		bkp.geardown = true                 -- Fix landing gear state
		bkp.vehicle = spawnpoint.vehicle    -- Fix spawn'n'blow
		--setVehicleID(RaceMode.getPlayerVehicle(player), spawnpoint.vehicle)
	end
	spawnPlayer(player, bkp.position[1], bkp.position[2], bkp.position[3], 0, getElementModel(player))

	local vehicle = RaceMode.getPlayerVehicle(player)
	if vehicle then
		setElementPosition(vehicle, unpack(bkp.position))
		setVehicleRotation(vehicle, unpack(bkp.rotation))
		fixVehicle(vehicle)
		if getElementModel(vehicle) ~= bkp.vehicle then
			setVehicleID(vehicle, bkp.vehicle)
		end
		warpPedIntoVehicle(player, vehicle)
		--setTimer(warpPlayerIntoVehicle, 500, 5, player, vehicle)
		
        setVehicleLandingGearDown(vehicle,bkp.geardown)
		setVehicleFrozen(vehicle, true)
		setTimer(restorePlayerUnfreeze, 2000, 1, self.id, player)
	end
    setCameraTarget(player)
    clientCall(player, 'remoteSoonFadeIn')
end

function restorePlayerUnfreeze(id, player)
	if not table.find(g_Players, player) then
		return
	end
	local vehicle = RaceMode.getPlayerVehicle(player)
	setVehicleFrozen(vehicle, false)
	local bkp = RaceMode.instances[id].checkpointBackups[player][getPlayerCurrentCheckpoint(player)-1]
	setElementVelocity(vehicle, unpack(bkp.velocity))
	setVehicleTurnVelocity(g_Vehicles[player], unpack(bkp.turnvelocity))
end

function RaceMode:onPlayerQuit(player)
	self.checkpointBackups[player] = nil
end

function RaceMode:destroy()
	if self.rankingBoard then
		self.rankingBoard:destroy()
		self.rankingBoard = nil
	end 
    if self.checkpointBackups then      -- Stop timers
        for plr,bkp in pairs(self.checkpointBackups) do
            if bkp.timer then
                killTimer(bkp.timer)
                bkp.timer = nil
            end
        end
    end
	RaceMode.instances[self.id] = nil
end
