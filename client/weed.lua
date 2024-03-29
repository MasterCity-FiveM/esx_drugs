local spawnedWeeds = 0
local weedPlants = {}
local isPickingUp, isProcessing = false, false
local allowspawn = true

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(500)
		local coords = GetEntityCoords(PlayerPedId())
		local distance = GetDistanceBetweenCoords(coords, Config.CircleZones.WeedField.coords, true)
		if distance < 15 then
			SpawnWeedPlants()
			Citizen.Wait(2000)
		elseif distance > 30 then
			Citizen.Wait(10000)
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local distance = GetDistanceBetweenCoords(coords, Config.CircleZones.WeedProcessing.coords, true)
		if distance < 1 then
			if not isProcessing then
				--ESX.ShowHelpNotification(_U('weed_processprompt'))
				--TriggerClientEvent("pNotify:SendNotification", source, { text = _U('weed_processprompt'), type = "info", timeout = 2500, layout = "bottomCenter"})
				--exports.pNotify:SendNotification({text = _U('weed_processprompt'), type = "info", timeout = 2500})
				ShowMessage(_U('weed_processprompt'))
			end

			if IsControlJustReleased(0, 38) and not isProcessing then
				ESX.TriggerServerCallback('esx_drugs:cannabis_count', function(xCannabis)
					ProcessWeed(xCannabis)
				end)
			end
		elseif distance > 30 then
			Citizen.Wait(3000)
		else
			Citizen.Wait(500)
		end
	end
end)

function ProcessWeed(xCannabis)
	isProcessing = true
	--ESX.ShowNotification(_U('weed_processingstarted'))
	--TriggerClientEvent("pNotify:SendNotification", source, { text = _U('weed_processingstarted'), type = "info", timeout = 2500, layout = "bottomCenter"})
	exports.pNotify:SendNotification({text = _U('weed_processingstarted'), type = "info", timeout = 2500})
  TriggerServerEvent('esx_drugs:processCannabis')
	if(xCannabis <= 3) then
		xCannabis = 0
	end
  local timeLeft = (Config.Delays.WeedProcessing * xCannabis) / 1000
	local playerPed = PlayerPedId()

	while timeLeft > 0 do
		Citizen.Wait(1000)
		timeLeft = timeLeft - 1

		if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Config.CircleZones.WeedProcessing.coords, false) > 4 then
			--ESX.ShowNotification(_U('weed_processingtoofar'))
			exports.pNotify:SendNotification({text = _U('weed_processingtoofar'), type = "error", timeout = 2500})
			TriggerServerEvent('esx_drugs:cancelProcessing')
			TriggerServerEvent('esx_drugs:outofbound')
			break
		end
	end

	isProcessing = false
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)
		local nearbyObject, nearbyID
		local let_sleep = true
		
		for i=1, #weedPlants, 1 do
			local distance = GetDistanceBetweenCoords(coords, GetEntityCoords(weedPlants[i]), false)
			if distance < 1 then
				nearbyObject, nearbyID = weedPlants[i], i
				let_sleep = false
			elseif distance < 30 then
				let_sleep = false
			end
		end

		if nearbyObject and IsPedOnFoot(playerPed) then
			if not isPickingUp then
				--ESX.ShowHelpNotification(_U('weed_pickupprompt'))
				--TriggerClientEvent("pNotify:SendNotification", source, { text = _U('weed_pickupprompt'), type = "info", timeout = 2500, layout = "bottomCenter"})
				--exports.pNotify:SendNotification({text = _U('weed_pickupprompt'), type = "info", timeout = 2500})
				ShowMessage(_U('weed_pickupprompt'))
			end

			if IsControlJustReleased(0, 38) and not isPickingUp then
				isPickingUp = true

				ESX.TriggerServerCallback('esx_drugs:canPickUp', function(canPickUp)
					if canPickUp then
						TaskStartScenarioInPlace(playerPed, 'world_human_gardener_plant', 0, false)

						Citizen.Wait(2000)
						ClearPedTasks(playerPed)
						Citizen.Wait(1500)
		
						ESX.Game.DeleteObject(nearbyObject)
		
						table.remove(weedPlants, nearbyID)
						spawnedWeeds = spawnedWeeds - 1
		
						TriggerServerEvent('esx_drugs:pickedUpCannabis')
					else
						--ESX.ShowNotification(_U('weed_inventoryfull'))
						--TriggerClientEvent("pNotify:SendNotification", source, { text = _U('weed_inventoryfull'), type = "error", timeout = 2500, layout = "bottomCenter"})
						exports.pNotify:SendNotification({text = _U('weed_inventoryfull'), type = "error", timeout = 2500})
					end

					isPickingUp = false
				end, 'cannabis')
			end
		elseif let_sleep then
			Citizen.Wait(2500)
		else
			Citizen.Wait(500)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(weedPlants) do
			ESX.Game.DeleteObject(v)
		end
	end
end)

function SpawnWeedPlants()
	if not allowspawn then
		return false
	end
	
	Citizen.CreateThread(function()
		allowspawn = false
		tmp = spawnedWeeds
		while tmp < 25 do
			Citizen.Wait(0)
			local weedCoords = GenerateWeedCoords()
			ESX.Game.SpawnLocalObject('prop_weed_02', weedCoords, function(obj)
				PlaceObjectOnGroundProperly(obj)
				FreezeEntityPosition(obj, true)

				table.insert(weedPlants, obj)
				spawnedWeeds = spawnedWeeds + 1
				tmp = tmp + 1
			end)
		end
		
		Citizen.Wait(120000)
		allowspawn = true
	end)
end

function ValidateWeedCoord(plantCoord)
	if spawnedWeeds > 0 then
		local validate = true

		for k, v in pairs(weedPlants) do
			if GetDistanceBetweenCoords(plantCoord, GetEntityCoords(v), true) < 5 then
				validate = false
			end
		end

		if GetDistanceBetweenCoords(plantCoord, Config.CircleZones.WeedField.coords, false) > 50 then
			validate = false
		end

		return validate
	else
		return true
	end
end

function GenerateWeedCoords()
	while true do
		Citizen.Wait(1)

		local weedCoordX, weedCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-15, 15)

		Citizen.Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-15, 15)

		weedCoordX = Config.CircleZones.WeedField.coords.x + modX
		weedCoordY = Config.CircleZones.WeedField.coords.y + modY

		local coordZ = GetCoordZ(weedCoordX, weedCoordY)
		local coord = vector3(weedCoordX, weedCoordY, coordZ)

		if ValidateWeedCoord(coord) then
			return coord
		end
	end
end

function GetCoordZ(x, y)
	local groundCheckHeights = { 48.0, 49.0, 50.0, 51.0, 52.0, 53.0, 54.0, 55.0, 56.0, 57.0, 58.0 }

	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 43.0
end

-- Merc az Amin bara inke in codo too ye resource dg gozashte bod va paste kardam
local UnderShowMsg = false
function ShowMessage(message)
	Citizen.CreateThread(function()
		if UnderShowMsg == false then
			UnderShowMsg = true
			exports.pNotify:SendNotification({text = message, type = "info", timeout = 2500})
			Citizen.Wait(3300)
			UnderShowMsg = false
		end
	end)
end