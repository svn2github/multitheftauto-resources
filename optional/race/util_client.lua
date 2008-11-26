addEvent('onClientCall', true)
addEventHandler('onClientCall', getRootElement(),
	function(fnName, ...)
		local fn = _G
		local path = fnName:split('.')
		for i,pathpart in ipairs(path) do
			fn = fn[pathpart]
		end
		fn(...)
	end
)

function showHUD(show)
	for i,name in ipairs({ 'ammo', 'area_name', 'armour', 'breath', 'clock', 'health', 'money', 'vehicle_name', 'weapon' }) do
		showPlayerHudComponent(name, show)
	end
end

function showGUIComponents(...)
	for i,name in ipairs({...}) do
		if type(g_GUI[name]) == 'table' then
			g_GUI[name]:show()
		else
			guiSetVisible(g_GUI[name], true)
		end
	end
end

function hideGUIComponents(...)
	for i,name in ipairs({...}) do
		if type(g_GUI[name]) == 'table' then
			g_GUI[name]:hide()
		else
			guiSetVisible(g_GUI[name], false)
		end
	end
end

function setGUIComponentsVisible(settings)
	for name,visible in pairs(settings) do
		if type(g_GUI[name]) == 'table' then
			g_GUI[name][visible and 'show' or 'hide'](g_GUI[name])
		else
			guiSetVisible(g_GUI[name], visible)
		end
	end
end

function msToTimeStr(ms)
	if not ms then
		return ''
	end
	local centiseconds = tostring(math.floor(math.fmod(ms, 1000)/10))
	if #centiseconds == 1 then
		centiseconds = '0' .. centiseconds
	end
	local s = math.floor(ms / 1000)
	local seconds = tostring(math.fmod(s, 60))
	if #seconds == 1 then
		seconds = '0' .. seconds
	end
	local minutes = tostring(math.floor(s / 60))
	return minutes .. ':' .. seconds .. ':' .. centiseconds
end

function resAdjust(num)
	if not g_ScreenWidth then
		g_ScreenWidth, g_ScreenHeight = guiGetScreenSize()
	end
	if g_ScreenWidth < 1280 then
		return math.floor(num*g_ScreenWidth/1280)
	else
		return num
	end
end

function loadCustomModel(id, name)
	if not g_CustomModelPreloads then
		g_CustomModelPreloads = {}
	end
	local x, y, z = getElementPosition(g_Me)
	local object = createObject(id, x, y, z-50)
	table.insert(g_CustomModelPreloads, { id = id, name = name, object = object })
	addEventHandler('onClientElementStreamIn', object, customModelPreloaded, false)
end

function customModelPreloaded()
	local i = table.find(g_CustomModelPreloads, 'object', source)
	if i then
		local preload = g_CustomModelPreloads[i]
		local txd = engineLoadTXD(('model/%s.txd'):format(preload.name))
		engineImportTXD(txd, preload.id)
		local dff = engineLoadDFF(('model/%s.dff'):format(preload.name), 0)
		engineReplaceModel(dff, preload.id)
		destroyElement(source)
		table.remove(g_CustomModelPreloads, i)
		if #g_CustomModelPreloads == 0 then
			g_CustomModelPreloads = nil
		end
	end
end

function setCameraBehindVehicle(vehicle)
	local x, y, z = getElementPosition(vehicle)
	local rx, ry, rz = getVehicleRotation(vehicle)
	setCameraMatrix(x - 4*math.cos(math.rad(rz + 90)), y - 4*math.sin(math.rad(rz + 90)), z + 1, x, y, z + 1)
	setTimer(setCameraTarget, 100, 1, g_Me)
end

function alignVehicleToGround(vehicle)
	if not g_AlignToGroundTimer then
		g_AlignToGroundTimer = setTimer(alignVehicleToGround, 200, 0, vehicle)
		g_AlignToGroundTriesLeft = 50
	else
		local x, y, z = getElementPosition(vehicle)
		local hit, hitX, hitY, groundZ = processLineOfSight(x, y, z + 5, x, y, z - 20, true, false)
		g_AlignToGroundTriesLeft = g_AlignToGroundTriesLeft - 1
		if not hit and g_AlignToGroundTriesLeft > 0 then
			return
		end
		killTimer(g_AlignToGroundTimer)
		g_AlignToGroundTimer = nil
		g_AlignToGroundTriesLeft = nil
		if hit then
			local waterZ = getWaterLevel(x, y, z + 5)
			if not waterZ or groundZ > waterZ then
				server.setElementPosition(vehicle, x, y, groundZ + getElementDistanceFromCentreOfMassToBaseOfModel(vehicle))
			end
		end
	end
end

function createServerCallInterface()
	return setmetatable(
		{},
		{
			__index = function(t, k)
				t[k] = function(...) triggerServerEvent('onServerCall', g_Me, k, ...) end
				return t[k]
			end
		}
	)
end

function createShadowedLabel(x, y, width, height, text, align)
	local shadow = guiCreateLabel(x + 1, y + 1, width, height, text, false)
	guiLabelSetColor(shadow, 0, 0, 0)
	local label = guiCreateLabel(x, y, width, height, text, false)
	guiLabelSetColor(label, 255, 255, 255)
	if align then
		guiLabelSetHorizontalAlign(shadow, align)
		guiLabelSetHorizontalAlign(label, align)
	end
	return label, shadow
end

-----------------------------
-- Table extensions

function table.find(tableToSearch, index, value)
	if not value then
		value = index
		index = false
	elseif value == '[nil]' then
		value = nil
	end
	for k,v in pairs(tableToSearch) do
		if index then
			if v[index] == value then
				return k
			end
		elseif v == value then
			return k
		end
	end
	return false
end

function table.removevalue(t, val)
	for i,v in ipairs(t) do
		if v == val then
			table.remove(t, i)
			return i
		end
	end
	return false
end

function table.each(t, index, callback, ...)
	if type(index) == 'function' then
		table.insert(arg, 1, callback)
		callback = index
		index = false
	end
	for k,v in pairs(t) do
		callback(index and v[index] or v, unpack(arg))
	end
	return t
end

function table.create(keys, vals)
	local result = {}
	if type(vals) == 'table' then
		for i,k in ipairs(keys) do
			result[k] = vals[i]
		end
	else
		for i,k in ipairs(keys) do
			result[k] = vals
		end
	end
	return result
end

-----------------------------
-- String extensions

function string:split(separator)
	if separator == '.' then
		separator = '%.'
	end
	local result = {}
	for part in self:gmatch('(.-)' .. separator) do
		result[#result+1] = part
	end
	result[#result+1] = self:match('.*' .. separator .. '(.*)$') or self
	return result
end
