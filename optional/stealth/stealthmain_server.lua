local getPlayerSpectatee = {}
resourceRoot = getResourceRootElement(getThisResource())

function teamstealthgamestart()
	killmessageRes = getResourceFromName"killmessages"
	call(getResourceFromName("scoreboard"), "addScoreboardColumn", "Score")
	call(getResourceFromName("scoreboard"), "addScoreboardColumn", "kills")
	call(getResourceFromName("scoreboard"), "addScoreboardColumn", "deaths")
	playingaround = 0
	selectTeamDisplay = textCreateDisplay()
	local stext = textCreateTextItem ( "Select your spawn", 0.502, 0.302, "low", 0, 0, 0, 255, 1.4 )
	local stext2 = textCreateTextItem ( "Press F1 to spawn RED", 0.501, 0.501, "low", 0, 0, 0, 255, 1.1 )
	local stext3 = textCreateTextItem ( "Press F2 to spawn BLUE", 0.501, 0.551, "low", 0, 0, 0, 255, 1.1 )
	local stext4 = textCreateTextItem ( "Press F3 to return to the spawn screen", 0.501, 0.601, "low", 0, 0, 0, 255, 1.1 )
	local text = textCreateTextItem ( "Select your spawn", 0.5, 0.3, "low", 255, 255, 255, 255, 1.4 )
	local text2 = textCreateTextItem ( "Press F1 to spawn RED", 0.5, 0.5, "low", 255, 255, 255, 255, 1.1 )
	local text3 = textCreateTextItem ( "Press F2 to spawn BLUE", 0.5, 0.55, "low", 255, 255, 255, 255, 1.1 )
	local text4 = textCreateTextItem ( "Press F3 to return to the spawn screen", 0.5, 0.6, "low", 255, 255, 255, 255, 1.1 )
	textDisplayAddText ( selectTeamDisplay, stext )
	textDisplayAddText ( selectTeamDisplay, stext2 )
	textDisplayAddText ( selectTeamDisplay, stext3 )
	textDisplayAddText ( selectTeamDisplay, stext4 )
	textDisplayAddText ( selectTeamDisplay, text )
	textDisplayAddText ( selectTeamDisplay, text2 )
	textDisplayAddText ( selectTeamDisplay, text3 )
	textDisplayAddText ( selectTeamDisplay, text4 )
	redwinsdisplay = textCreateDisplay()
	local redtext = textCreateTextItem ( "RED Team Wins the Match!", 0.5, 0.5, "low", 255, 0, 0, 255, 3, "center", "center" )
	textDisplayAddText ( redwinsdisplay, redtext )
	bluewinsdisplay = textCreateDisplay()
	local bluetext = textCreateTextItem ( "BLUE Team Wins the Match!", 0.5, 0.5, "low", 0, 0, 255, 255, 3, "center", "center" )
	textDisplayAddText ( bluewinsdisplay, bluetext )
	tiegamedisplay = textCreateDisplay()
	local tietext = textCreateTextItem ( "The Match was a Tie!", 0.5, 0.5, "low", 255, 255, 255, 255, 3, "center", "center" )
	textDisplayAddText ( tiegamedisplay, tietext )
	waitDisplay = textCreateDisplay()
	local waittext = textCreateTextItem ( "Wait for next round to spawn.", 0.5, 0.9, "low", 255, 255, 255, 255, 1.6, "center", "center" )
	textDisplayAddText ( waitDisplay, waittext )
	team1 = createTeam("RED",255,0,0)
	team2 = createTeam("BLUE",0,0,255)
	teamprotect = get("stealth.teamdamage")
	if teamprotect == 1 then	
		setTeamFriendlyFire( team1, false )
		setTeamFriendlyFire( team2, false )
	elseif teamprotect == 0 then
		setTeamFriendlyFire( team1, true )
		setTeamFriendlyFire( team2, true )
	end
	setElementData ( team1, "Score", 0 )
	setElementData ( team2, "Score", 0 )
	teamswap = 0
	local players = getElementsByType("player")
	for k,v in ipairs(players) do
		killPed(v)
		fadeCamera(v,true)
		thisplayer = v
		triggerClientEvent(v,"swaptoggle",getRootElement(), thisplayer, teamswap)
		setElementData ( v, "kills", 0 )
		setElementData ( v, "deaths", 0 )
		setPlayerNametagShowing ( v, false )
		bindKey ( v, "r", "down", spectateNext )
		bindKey ( v, "F3", "down", selectTeamKey )
	end
	--Enable laser sight
	setElementData(getRootElement(),"lasersight",get("stealth.lasersight"))
end

addEventHandler( "onGamemodeStart", resourceRoot, teamstealthgamestart )

function joinTeam( player, team )
	unbindKey ( player, "F1", "down", joinTeam1 )
	unbindKey ( player, "F2", "down", joinTeam2 )
	textDisplayRemoveObserver ( selectTeamDisplay, player )
	setPlayerTeam(player, team)
	if team == team1 then
		setPlayerNametagColor ( player, 255, 0, 0 )
	elseif team == team2 then
		setPlayerNametagColor ( player, 0, 0, 255 )
	end
end

function joinTeam1( source )
	if (countPlayersInTeam(team1) - countPlayersInTeam(team2) > balanceamount) then
		outputChatBox("Can't join RED too many players", source, 255, 69, 0)
	else
		joinTeam(source, team1)
	end
end

function joinTeam2( source )
	if (countPlayersInTeam(team2) - countPlayersInTeam(team1) > balanceamount) then
		outputChatBox("Can't join BLUE too many players", source, 255, 69, 0)
	else
		joinTeam(source, team2)
	end
end

function selectTeam( player )
	setPlayerTeam(player, nil)
	textDisplayAddObserver ( selectTeamDisplay, player )
	local thisplayer = player
	triggerClientEvent(player,"cameramode",getRootElement(), thisplayer)
	balanceamount = get("stealth.teambalance")
	tonumber(balanceamount)
	bindKey ( player, "F1", "down", joinTeam1 )
	bindKey ( player, "F2", "down", joinTeam2 )
end

function selectTeamKey(source)
	ishespawning = getElementData ( source, "cantchangespawns" )
	if ( isPedDead ( source ) ) and (ishespawning == 0) then
		selectTeam( source )
		getPlayerSpectatee[source] = nil
		triggerClientEvent(source,"showSpectateText",source,"",false)
		unbindKey ( source, "r", "down", spectateNext )
		setPlayerTeam(source, nil)
	else
		outputChatBox("You can only change teams when your dead.", source, 255, 69, 0)
	end
end

function onStealthPlayerJoin ()
	playersin = getPlayerCount()
	if playersin < 3 then
		if playingaround == 1 then
			outputChatBox("Not enough active players, restarting round.", player, 255, 69, 0)
			roundend = setTimer ( stealthroundended, 10000, 1, roundfinish, thisplayer )
			destroyMissionTimer ( roundfinish )
		end
	end
	selectTeam (source)
	setElementData ( source, "kills", 0 )
	setElementData ( source, "deaths", 0 )
	setPlayerNametagShowing ( source, false )
	bindKey ( source, "F3", "down", selectTeamKey )
	bindKey ( source, "r", "down", spectateNext )
	thisplayer = source
	triggerClientEvent(source,"cameramode",getRootElement(), thisplayer)
	destroyshield = setTimer ( destroyElement, 3000, 1, dummyshield )
	triggerClientEvent(source,"cameramode",getRootElement(), thisplayer)
	triggerClientEvent(source,"swaptoggle",getRootElement(), thisplayer, teamswap)
	textDisplayAddObserver ( waitDisplay, thisplayer )
	fadeCamera(thisplayer,true)
end

addEventHandler ( "onPlayerJoin", getRootElement(), onStealthPlayerJoin )

function teamstealthmapstart(startedMap)
	roundstart = setTimer ( startstealthround, 15000, 1, player )
	setElementData ( team1, "Score", 0 )
	setElementData ( team2, "Score", 0 )
	local stealthplayers = getElementsByType("player")
	for index, thisplayer in ipairs(stealthplayers) do
		fadeCamera(thisplayer,true)
		setElementData ( thisplayer, "kills", 0 )
		setElementData ( thisplayer, "deaths", 0 )
		triggerClientEvent(thisplayer,"cameramode",getRootElement(), thisplayer)
		selectTeam (thisplayer)
	end
	teamprotect = get("stealth.teamprotect")
	if teamprotect == 1 then	
		setTeamFriendlyFire( team1, false )
		setTeamFriendlyFire( team2, false )
	elseif teamprotect == 0 then
		setTeamFriendlyFire( team1, true )
		setTeamFriendlyFire( team2, true )
	end
	setElementData ( team1, "Score", 0 )
	setElementData ( team2, "Score", 0 )
	currentmap = call(getResourceFromName"mapmanager","getRunningGamemodeMap")
	local maptime = get(getResourceName(currentmap)..".#time")
	if maptime then
		local splitString = split(maptime, string.byte(':'))
		setTime(tonumber(splitString[1]),tonumber(splitString[2]))
	end
	local mapweather = get(getResourceName(currentmap)..".#weather")
	if mapweather then
		setWeather (mapweather)
	end
	local mapwaves = get(getResourceName(currentmap)..".#waveheight")
	if mapwaves then
		setWaveHeight ( mapwaves )
	end
	local mapspeed = get(getResourceName(currentmap)..".#gamespeed")
	if mapspeed then
		setGameSpeed ( mapspeed )
	end
	local mapgravity = get(getResourceName(currentmap)..".#gravity")
	if mapgravity then
		setGravity ( mapgravity )
	end	
end

addEventHandler( "onGamemodeMapStart", getRootElement(), teamstealthmapstart )

function teamstealthmapstop(startedMap)
	local alltheplayers = getElementsByType("player")
	playingaround = 0
	for index, thisplayer in ipairs(alltheplayers) do
		triggerClientEvent(thisplayer,"onClientGamemodeMapStop",getRootElement())
		setElementData ( thisplayer, "waitingtospawn", "nope" )
		local isplayercloaked =  getElementData ( thisplayer, "stealthmode" )
		if isplayercloaked == "on" then
			local player = thisplayer
			cloakstop(player)
		end
	end
	local timers = getTimers()
	for timerKey, timerValue in ipairs(timers) do
		if timerValue ~= keytimer then
	        killTimer ( timerValue )
		end
	end
	removeEventHandler ( "missionTimerActivated", getRootElement(), stealthroundended )
	destroyMissionTimer ( roundfinish )
	local objectlist = getElementsByType ( "object" )
	for index, object in ipairs(objectlist) do
		if ( getElementData ( object, "renew" ) == "1" ) then
			destroyElement(object)
		end
	end
end

addEventHandler( "onGamemodeMapStop", getRootElement(), teamstealthmapstop )

function startstealthround()
	local alltheplayers = getElementsByType("player") 
	for index, thisplayer in ipairs(alltheplayers) do
		triggerClientEvent(thisplayer,"swaptoggle",getRootElement(), thisplayer, teamswap)
		textDisplayRemoveObserver( redwinsdisplay, thisplayer )
		textDisplayRemoveObserver( bluewinsdisplay, thisplayer )
		textDisplayRemoveObserver( tiegamedisplay, thisplayer )
		textDisplayRemoveObserver( waitDisplay, thisplayer )
	end
	currentmap = call(getResourceFromName"mapmanager","getRunningGamemodeMap")
	local maptime = get(getResourceName(currentmap)..".#time")
	if maptime then
		local splitString = split(maptime, string.byte(':'))
		setTime(tonumber(splitString[1]),tonumber(splitString[2]))
	end
	playingaround = 1
	local players = getElementsByType("player")
	for index, player in ipairs(players) do
		setElementData ( player, "waitingtospawn", "indeed" )
		setElementData ( player, "cantchangespawns", 1 )
		triggerClientEvent(player,"Startround",getRootElement(),player)
	end
	stoptheidlers = setTimer ( idleblockstop, 30000, 1, player )
	rawroundlength = get("stealth.roundlimit")
	roundlength= rawroundlength*60
	if (roundfinish) then
		destroyMissionTimer ( roundfinish )
	end
	roundfinish = createMissionTimer ( player, roundlength, "<", 1.5, 0.5, 0.03, 255, 255, 255, true )
	addEventHandler ( "missionTimerActivated", getRootElement(), stealthroundended )
	startTimer ( roundfinish )
	freshround = 1
	moldyround = setTimer ( agetheround, 30000, 1 )
	roundnotover = 1
end

function agetheround()
	freshround = 0
	local everyone = getElementsByType("player")
	local playerCount = #everyone
	if playerCount > 1 then
		playerleftcount ()
	end
end

addEvent ("domercspawn", true )

function mercspawn(thisplayer)
	currentmap = call(getResourceFromName"mapmanager","getRunningGamemodeMap")
	local mapinterior = get(getResourceName(currentmap)..".#interior")
	if mapinterior == false then 
		mapinterior = 0
	end
	mercteamspawns = getElementByID("mercspawns")
	local mercpoints = getElementChildren ( mercteamspawns )
	local random = math.random ( 1, table.getn ( mercpoints ) )
	local posX = getElementData(mercpoints[random], "posX") 
	local posY = getElementData(mercpoints[random], "posY") 
	local posZ = getElementData(mercpoints[random], "posZ")
	local rot = getElementData(mercpoints[random], "rot")
	spawnPlayer ( thisplayer, posX, posY, posZ, rot, 285, mapinterior )
	--setCameraMode ( thisplayer, "player" )
	setCameraTarget ( thisplayer, thisplayer )
	setElementData ( thisplayer, "waitingtospawn", "nope" )
	getPlayerSpectatee[thisplayer] = nil
	triggerClientEvent(source,"showSpectateText",source,"",false)
	unbindKey ( source, "r", "down", spectateNext )
	giveWeapon ( thisplayer, 3, 1 )
	setPedFightingStyle ( thisplayer, 7 )
end

addEventHandler ( "domercspawn", getRootElement(), mercspawn )

addEvent ("dospyspawn", true )

function spyspawn(thisplayer)
	currentmap = call(getResourceFromName"mapmanager","getRunningGamemodeMap")
	local mapinterior = get(getResourceName(currentmap)..".#interior")
	if mapinterior == false then 
		mapinterior = 0
	end
	spyteamspawns = getElementByID("spyspawns")
	local spypoints = getElementChildren ( spyteamspawns )
	local random = math.random ( 1, table.getn ( spypoints ) )
	local posX = getElementData(spypoints[random], "posX") 
	local posY = getElementData(spypoints[random], "posY") 
	local posZ = getElementData(spypoints[random], "posZ")
	local rot = getElementData(spypoints[random], "rot")
	spawnPlayer ( thisplayer, posX, posY, posZ, rot, 163, mapinterior )
	setCameraTarget( thisplayer, thisplayer )
	--setCameraMode ( thisplayer, "player" )
	setElementData ( thisplayer, "waitingtospawn", "nope" )
	getPlayerSpectatee[source] = nil
	triggerClientEvent(source,"showSpectateText",source,"",false)
	unbindKey ( source, "r", "down", spectateNext )
	giveWeapon ( thisplayer, 4, 1 )
	setPedFightingStyle ( thisplayer, 6 )
end

addEventHandler ( "dospyspawn", getRootElement(), spyspawn )

addEvent ( "givetheguns",true )

function gearup (thisplayer, primarySelection, secondarySelection, throwableSelection, spygadgetSelection)
	setPedStat ( thisplayer, 69, 999 )
	setPedStat ( thisplayer, 70, 999 )
	setPedStat ( thisplayer, 71, 999 )
	setPedStat ( thisplayer, 72, 999 )
	setPedStat ( thisplayer, 74, 200 )
	setPedStat ( thisplayer, 75, 999 )
	setPedStat ( thisplayer, 76, 500 )
	setPedStat ( thisplayer, 77, 999 )
	setPedStat ( thisplayer, 78, 200 )
	setPedStat ( thisplayer, 79, 999 )
	setPedStat ( thisplayer, 225, 999 )
	local sx,sy,sz = getElementPosition( thisplayer )
	setElementAlpha ( thisplayer, 255 )
	local dummyshield = createObject ( 1631, sx, sy, -60 )
	triggerClientEvent(thisplayer,"Clientshieldload",getRootElement(), thisplayer)
	spazammo = get("stealth.spazammo")
	m4ammo = get("stealth.m4ammo")
	shotgunammo = get("stealth.shotgunammo")
	sniperammo = get("stealth.sniperammo")
	ak47ammo = get("stealth.ak47ammo")
	rifleammo = get("stealth.rifleammo")
	deserteagleammo = get("stealth.deserteagleammo")
	pistolammo = get("stealth.pistolammo")
	uziammo = get("stealth.uziammo")
	tec9ammo = get("stealth.tec9ammo")
	silencedammo = get("stealth.silencedammo")
	grenadeammo = get("stealth.grenadeammo")
	satchelammo = get("stealth.satchelammo")
	teargasammo = get("stealth.teargasammo")
	molatovammo = get("stealth.molatovammo")
	local skinnumber = getElementModel ( thisplayer )
	setElementData ( thisplayer, "playerskin", skinnumber )
	if primarySelection == "spaz-12" then
		teamprotect = get("stealth.teamdamage")
		giveWeapon ( thisplayer, 27, spazammo )
	end
	if primarySelection == "m4" then
		giveWeapon ( thisplayer, 31, m4ammo )
	end
	if primarySelection == "shotgun" then
		giveWeapon ( thisplayer, 25, shotgunammo )
	end
	if primarySelection == "sniper" then
		giveWeapon ( thisplayer, 34, sniperammo )
	end
	if primarySelection == "ak47" then
		giveWeapon ( thisplayer, 30, ak47ammo )
	end
	if primarySelection == "rifle" then
		giveWeapon ( thisplayer, 33, rifleammo )
	end
	if secondarySelection == "desert eagle" then
		giveWeapon ( thisplayer, 24, deserteagleammo )
	end
	if secondarySelection == "pistols" then
		giveWeapon ( thisplayer, 22, pistolammo )
	end
	if secondarySelection == "uzis" then
		giveWeapon ( thisplayer, 28, uziammo )
	end	
	if secondarySelection == "tec-9s" then
		giveWeapon ( thisplayer, 32, tec9ammo )
	end
	if secondarySelection == "silenced" then
		giveWeapon ( thisplayer, 23, silencedammo )
	end
	if throwableSelection == "grenade" then
		giveWeapon ( thisplayer, 16, grenadeammo )
	end
	if throwableSelection == "satchel" then
		giveWeapon ( thisplayer, 39, satchelammo )
	end
	if throwableSelection == "teargas" then
		giveWeapon ( thisplayer, 17, teargasammo )
	end
	if throwableSelection == "molotov" then
		giveWeapon ( thisplayer, 18, molatovammo )
	end
	if spygadgetSelection == "goggles" then
		giveWeapon ( thisplayer, 44, 1 )
	end
end

addEventHandler ( "givetheguns", getRootElement(), gearup )

function idleblockstop ()
	local alltheplayers = getElementsByType("player")
	for index, thisplayer in ipairs(alltheplayers) do
		setElementData ( thisplayer, "waitingtospawn", "nope" )
		if ( isPedDead ( thisplayer ) ) then
			setElementData ( thisplayer, "cantchangespawns", 0 )
		end
	end
end

function stealthplayerdied ( totalAmmo, killer, killerWeapon, bodypart )
	if playingaround == 1 then
		local playerdeaths = getElementData ( source, "deaths" )
		setElementData ( source, "deaths", playerdeaths+1  )
		if (killer) then
			if killer ~= source then
				local killersscore =  getElementData ( killer, "kills" )
				setElementData ( killer, "kills", killersscore+1  )
			end
		end
	end
	waittospec = setTimer ( spectateNext, 6000, 1, source )
	setElementData ( source, "cantchangespawns", 0 )
	textDisplayAddObserver ( waitDisplay, source )
	setElementData ( source, "legdamage", 0 )
	local isplayercloaked =  getElementData ( source, "stealthmode" )
	if isplayercloaked == "on" then
		local player = source
		local oldskin = getElementData ( player, "playerskin" )
		setElementModel ( thisplayer, oldskin )
		setElementAlpha ( thisplayer, 255 )
		cloakstop(player)
	end
	if playingaround == 1 then
		if freshround ~= 1 then
			local deadguysteam = getPlayerTeam ( source )
			local teammates = getPlayersInTeam ( deadguysteam ) 
			for playerKey, playerValue in ipairs(teammates) do
				local isDead = isPedDead(playerValue)
				if (isDead == false) then return end
			end
			local thisplayer = source
			if roundnotover == 1 then
				roundnotover = 0
				roundend = setTimer ( stealthroundended, 4000, 1, roundfinish, thisplayer )
				destroyMissionTimer ( roundfinish )
				triggerClientEvent(thisplayer,"cameramode",getRootElement(), thisplayer)
			end
		end
	end
end

addEventHandler( "onPlayerWasted", getRootElement(), stealthplayerdied )

function spectateNext (source) -- THIS IS THE FUNCTION USED TO SWICH WHO IS BEING SPECTATED BY PRESSING R
	if playingaround == 1 then  -- IF A ROUND IS IN PROGRESS
		if ( isPedDead ( source ) ) then --IF THE PLAYER IS DEAD
			local specPlayer = getPlayerSpectatee[source] -- gets the spectatee player
			if not specPlayer then 
				specPlayer = 1 
				bindKey ( source, "r", "down", spectateNext )
			end
			local deadplayerTeam = getPlayerTeam(source)
			local playersTable = getPlayersInTeam ( deadplayerTeam )
			playersTable = filterPlayersTable ( playersTable )
			--
			local playerCount = #playersTable
			if playerCount == 0 then
				outputSpectateMessage("Nobody to Spectate",player) -- IF ITS JUST THE 1 PLAYER, SPECTATING IS IMPOSSIBLE
			else
				specPlayer = specPlayer+1
				while isPedDead ( playersTable[specPlayer] ) do
					specPlayer = specPlayer+1
				end
				if specPlayer > playerCount then
					specPlayer = 1
				end
				--setCameraMode ( source, "player" )    
				setCameraTarget ( source, playersTable[specPlayer] )
				outputSpectateMessage("Now spectating "..getClientName(playersTable[specPlayer]),source)
				getPlayerSpectatee[source] = specPlayer
			end
		end
	end
end

function outputSpectateMessage(text,source)
	triggerClientEvent(source,"showSpectateText",source,text,true)
end

function filterPlayersTable ( playerTable ) --this function clears out useless players from spectators table
	for k,v in ipairs(playerTable) do
		if isPedDead ( v ) then
			table.remove(playerTable,k)
		end
	end
	return playerTable
end

function stealthroundended( timerID, player )
	if playingaround == 1 then
		if ( tostring(timerID) == tostring(roundfinish) ) then
			destroyMissionTimer ( timerID )
			if (roundend) then
				killTimer (roundend)
				roundend = nil
			end
			playingaround = 0
			if teamswap == 0 then
				teamswap = 1
			else
				teamswap = 0
			end
			local leftgadgetslist = getElementsByType ( "colshape" )
			for index, gadget in ipairs(leftgadgetslist) do
				if ( getElementData ( gadget, "type" ) == "alandmine" ) then
					destroyElement ( gadget ) --DESTROYS ALL LANDMINES AT THE END OF EVERY ROUND
				elseif ( getElementData ( gadget, "type" ) == "acamera" ) then
					destroyElement ( gadget ) --DESTROYS ALL CAMERAS AT THE END OF EVERY ROUND		
				end
			end
			local objectlist = getElementsByType ( "object" )
			for index, object in ipairs(objectlist) do
				if ( getElementData ( object, "renew" ) == "1" ) then
					local x,y,z = getElementPosition( object )
					local rx,ry,rz = getObjectRotation ( object )
					local obid = getElementModel ( object )
					destroyElement(object)
					local newobject = createObject ( obid, x, y, z, rx, ry, rz )
					setElementData ( newobject, "renew", "1"  )
				end
			end
			local team1survivers = 0
			local team2survivers = 0	
			local firstteam = getPlayersInTeam ( team1 )
			for index, thisplayer in ipairs(firstteam) do
				setElementData ( thisplayer, "waitingtospawn", "indeed" )
				triggerClientEvent(thisplayer,"cameramode",getRootElement(), thisplayer)
				triggerClientEvent(thisplayer,"swaptoggle",getRootElement(), thisplayer, teamswap)
				local isDead = isPedDead(thisplayer)
				if (isDead == false) then
					team1survivers = team1survivers +1
					killPed(thisplayer, thisplayer, 99, 99)
				end
			end	
			local secondteam = getPlayersInTeam ( team2 )
			for index, thisplayer in ipairs(secondteam) do
				setElementData ( thisplayer, "waitingtospawn", "indeed" )
				triggerClientEvent(thisplayer,"cameramode",getRootElement(), thisplayer)
				triggerClientEvent(thisplayer,"swaptoggle",getRootElement(), thisplayer, teamswap)
				local isDead = isPedDead(thisplayer)
				if (isDead == false) then
					team2survivers = team2survivers +1		
					killPed(thisplayer, thisplayer, 99, 99)
				end
			end
			local everyone = getElementsByType("player")
			for index, thisplayer in ipairs(everyone) do
				if (sitthisoneout) then
					killTimer (sitthisoneout)
					sitthisoneout = nil
				end
			end
			if team1survivers > team2survivers then
				local alltheplayers = getElementsByType("player")
				for index, thisplayer in ipairs(alltheplayers) do
					textDisplayAddObserver( redwinsdisplay, thisplayer )
				end
				local teampoints = getElementData ( team1, "Score" )
				setElementData ( team1, "Score", teampoints+1  )
			end	
			if team2survivers > team1survivers then
				local alltheplayers = getElementsByType("player")
				for index, thisplayer in ipairs(alltheplayers) do
					textDisplayAddObserver( bluewinsdisplay, thisplayer )
				end
				local teampoints = getElementData ( team2, "Score" )
				setElementData ( team2, "Score", teampoints+1  )
			end	
			if team2survivers == team1survivers then
				local alltheplayers = getElementsByType("player")
				for index, thisplayer in ipairs(alltheplayers) do
					textDisplayAddObserver( tiegamedisplay, thisplayer )
				end
			end
			roundstart = setTimer ( startstealthround, 7000, 1, player )
			roundcycle = setTimer ( roundtick, 3000, 1, player )
			removeEventHandler ( "missionTimerActivated", getRootElement(), stealthroundended )
		end
	end
end

addEvent ( "onPlayerKillMessage", true)

function checkforemokids (killer, weapon, bodypart)
	if weapon == 99 then
		cancelEvent()
	end
end

addEventHandler( "onPlayerKillMessage", getRootElement(), checkforemokids )

function roundtick()
	triggerEvent("onRoundFinished", getResourceRootElement(getThisResource()))
end

function stealthplayerleft (source)
	countplayers = setTimer ( playerleftcount, 2000, 1 )
end

addEventHandler( "onPlayerQuit", getRootElement(), stealthplayerleft )

function playerleftcount (source)
	if playingaround == 1 then
		livingteam1 = 0
		livingteam2 = 0
		local firstteam = getPlayersInTeam ( team1 )
		for playerKey, playerValue in ipairs(firstteam) do
			local isDead = isPedDead(playerValue)
			if (isDead == false) then
				livingteam1 = livingteam1+1
			end
		end
		local secondteam = getPlayersInTeam ( team2 )
		for playerKey, playerValue in ipairs(secondteam) do
			local isDead = isPedDead(playerValue)
			if (isDead == false) then
				livingteam2 = livingteam2+1
			end
		end
		if livingteam1 == 0 then
			roundend = setTimer ( stealthroundended, 4000, 1, roundfinish, thisplayer ) --THIS TRIGGERS THE ROUND ENDING
			destroyMissionTimer ( roundfinish )
		end
		if livingteam2 == 0 then
			roundend = setTimer ( stealthroundended, 4000, 1, roundfinish, thisplayer )
			destroyMissionTimer ( roundfinish )
		end
	end
end

function playerhurt ( attacker, weapon, bodypart, loss )--HEADSHOT INSTAKILL
	if (getPedArmor ( source )) == 0 then
		if ( bodypart == 9 ) then
		    killPed ( source, attacker, weapon, bodypart )
		end
	end
end

addEventHandler ( "onPlayerDamage", getRootElement (), playerhurt )

function outputHeadshotIcon (killer, weapon, bodypart)
	if bodypart == 9 then
		cancelEvent()
		local r2,g2,b2 = getTeamColor ( getPlayerTeam(killer) )
		local r1,g1,b1 = getTeamColor ( getPlayerTeam(source) )
		call(killmessageRes,"outputKillMessage",source,r1,g1,b1,killer,r2,g2,b2,256 )
	end
end

addEventHandler( "onPlayerKillMessage", getRootElement(), outputHeadshotIcon )

function teamstealthgamestop()
	call(getResourceFromName("scoreboard"), "removeScoreboardColumn", "Score")
	call(getResourceFromName("scoreboard"), "removeScoreboardColumn", "kills")
	call(getResourceFromName("scoreboard"), "removeScoreboardColumn", "deaths")
	local alltheplayers = getElementsByType("player")
	for index, thisplayer in ipairs(alltheplayers) do
		playSoundFrontEnd (thisplayer, 35 )
		setPlayerTeam(thisplayer, nil)
		setPlayerNametagShowing ( thisplayer, true )
		setPedFightingStyle ( thisplayer, 1 )
		--setCameraMode ( thisplayer, "player" )
		setCameraTarget ( thisplayer, thisplayer )
		textDisplayRemoveObserver( redwinsdisplay, thisplayer )
		textDisplayRemoveObserver( bluewinsdisplay, thisplayer )
		textDisplayRemoveObserver( tiegamedisplay, thisplayer )
		textDisplayRemoveObserver( waitDisplay, thisplayer )
		textDisplayRemoveObserver( selectTeamDisplay, thisplayer )
		unbindKey ( thisplayer, "F1", "down", joinTeam1 )	
		unbindKey ( thisplayer, "F2", "down", joinTeam2 )	
		unbindKey ( thisplayer, "F3", "down", selectTeamKey )	
	end
	local timers = getTimers()
	for timerKey, timerValue in ipairs(timers) do
        killTimer ( timerValue )
	end
	local objectlist = getElementsByType ( "object" )
	for index, object in ipairs(objectlist) do
		if ( getElementData ( object, "renew" ) == "1" ) then
			destroyElement(object)
		end
	end
end

addEventHandler( "onResourceStop", resourceRoot, teamstealthgamestop )