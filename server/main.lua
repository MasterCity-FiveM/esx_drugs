ESX = nil
local playersProcessingCannabis = {}
local outofbound = true
local alive = true

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx_drugs:sellDrug')
AddEventHandler('esx_drugs:sellDrug', function(itemName, amount)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_drugs:sellDrug', {itemName = itemName, amount = amount})
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local price = Config.DrugDealerItems[itemName]
	local xItem = xPlayer.getInventoryItem(itemName)

	if not price then
		print(('esx_drugs: %s attempted to sell an invalid drug!'):format(xPlayer.identifier))
		return
	end

	if xItem.count < amount then
		--xPlayer.showNotification(_U('dealer_notenough'))
		TriggerClientEvent("pNotify:SendNotification", _source, { text = _U('dealer_notenough'), type = "error", timeout = 2500, layout = "bottomCenter"})
		return
	end

	price = ESX.Math.Round(price * amount)

	if Config.GiveBlack then
		xPlayer.addAccountMoney('black_money', price)
	else
		xPlayer.addMoney(price)
	end

	xPlayer.removeInventoryItem(xItem.name, amount)
	--xPlayer.showNotification(_U('dealer_sold', amount, xItem.label, ESX.Math.GroupDigits(price)))
	TriggerClientEvent("pNotify:SendNotification", _source, { text = _U('dealer_sold', amount, xItem.label, ESX.Math.GroupDigits(price)), type = "success", timeout = 2500, layout = "bottomCenter"})
end)

ESX.RegisterServerCallback('esx_drugs:buyLicense', function(source, cb, licenseName)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_drugs:buyLicense', {licenseName = licenseName})
	local xPlayer = ESX.GetPlayerFromId(source)
	local license = Config.LicensePrices[licenseName]

	if license then
		if xPlayer.getMoney() >= license.price then
			xPlayer.removeMoney(license.price)

			TriggerEvent('esx_license:addLicense', source, licenseName, function()
				cb(true)
			end)
		else
			cb(false)
		end
	else
		print(('esx_drugs: %s attempted to buy an invalid license!'):format(xPlayer.identifier))
		cb(false)
	end
end)

RegisterServerEvent('esx_drugs:pickedUpCannabis')
AddEventHandler('esx_drugs:pickedUpCannabis', function()
	ESX.RunCustomFunction("anti_ddos", source, 'esx_drugs:pickedUpCannabis', {})
	local xPlayer = ESX.GetPlayerFromId(source)
	local cime = math.random(1,3)

	if xPlayer.canCarryItem('cannabis', cime) then
		xPlayer.addInventoryItem('cannabis', cime)
	else
		--xPlayer.showNotification(_U('weed_inventoryfull'))
		TriggerClientEvent("pNotify:SendNotification", source, { text = _U('weed_inventoryfull'), type = "error", timeout = 2500, layout = "bottomCenter"})
	end
end)

ESX.RegisterServerCallback('esx_drugs:canPickUp', function(source, cb, item)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_drugs:canPickUp', {item = item})
	local xPlayer = ESX.GetPlayerFromId(source)
	cb(xPlayer.canCarryItem(item, 1))
end)

RegisterServerEvent('esx_drugs:outofbound')
AddEventHandler('esx_drugs:outofbound', function()
	ESX.RunCustomFunction("anti_ddos", source, 'esx_drugs:outofbound', {})
	outofbound = true
end)

RegisterServerEvent('esx_drugs:quitprocess')
AddEventHandler('esx_drugs:quitprocess', function()
	ESX.RunCustomFunction("anti_ddos", source, 'esx_drugs:quitprocess', {})
	can = false
end)

ESX.RegisterServerCallback('esx_drugs:cannabis_count', function(source, cb)
	ESX.RunCustomFunction("anti_ddos", source, 'esx_drugs:cannabis_count', {})
	local xPlayer = ESX.GetPlayerFromId(source)
	local xCannabis = xPlayer.getInventoryItem('cannabis').count
	cb(xCannabis)
end)

RegisterServerEvent('esx_drugs:processCannabis')
AddEventHandler('esx_drugs:processCannabis', function()
	ESX.RunCustomFunction("anti_ddos", source, 'esx_drugs:processCannabis', {})
	if not playersProcessingCannabis[source] then
		local _source = source
		local xPlayer = ESX.GetPlayerFromId(_source)
		local xCannabis = xPlayer.getInventoryItem('cannabis')
		local can = true
		outofbound = false
		if xCannabis.count >= 1 then
			while outofbound == false and can do
				if playersProcessingCannabis[_source] == nil then
					playersProcessingCannabis[_source] = ESX.SetTimeout(Config.Delays.WeedProcessing , function()
						if xCannabis.count >= 1 then
							if xPlayer.canSwapItem('cannabis', 1, 'marijuana', 3) then
								xPlayer.removeInventoryItem('cannabis', 1)
								xPlayer.addInventoryItem('marijuana', 3)
								--xPlayer.showNotification(_U('weed_processed'))
								TriggerClientEvent("pNotify:SendNotification", _source, { text = _U('weed_processed'), type = "success", timeout = 2500, layout = "bottomCenter"})
							else
								can = false
								--xPlayer.showNotification(_U('weed_processingfull'))
								TriggerClientEvent("pNotify:SendNotification", _source, { text = _U('weed_processingfull'), type = "error", timeout = 2500, layout = "bottomCenter"})
								TriggerEvent('esx_drugs:cancelProcessing')
							end
						else						
							can = false
							--xPlayer.showNotification(_U('weed_processingenough'))
							TriggerClientEvent("pNotify:SendNotification", _source, { text = _U('weed_processingenough'), type = "error", timeout = 2500, layout = "bottomCenter"})
							TriggerEvent('esx_drugs:cancelProcessing')
						end

						playersProcessingCannabis[_source] = nil
					end)
				else
					Wait(Config.Delays.WeedProcessing)
				end	
			end
		else
			--xPlayer.showNotification(_U('weed_processingenough'))
			TriggerClientEvent("pNotify:SendNotification", _source, { text = _U('weed_processingenough'), type = "error", timeout = 2500, layout = "bottomCenter"})
			TriggerEvent('esx_drugs:cancelProcessing')
		end	
	else
		print(('esx_drugs: %s attempted to exploit weed processing!'):format(GetPlayerIdentifiers(_source)[1]))
	end
end)

function CancelProcessing(playerId)
	if playersProcessingCannabis[playerId] then
		ESX.ClearTimeout(playersProcessingCannabis[playerId])
		playersProcessingCannabis[playerId] = nil
	end
end

RegisterServerEvent('esx_drugs:cancelProcessing')
AddEventHandler('esx_drugs:cancelProcessing', function()
	ESX.RunCustomFunction("anti_ddos", source, 'esx_drugs:cancelProcessing', {})
	CancelProcessing(source)
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
	CancelProcessing(playerId)
end)

RegisterServerEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
	CancelProcessing(source)
end)
