Config = {}

Config.Locale = 'en'

Config.Delays = {
	WeedProcessing = 1000 * 7
}

Config.DrugDealerItems = {
	marijuana = 5
}

Config.LicenseEnable = false -- enable processing licenses? The player will be required to buy a license in order to process drugs. Requires esx_license

Config.LicensePrices = {
	weed_processing = {label = _U('license_weed'), price = 15000}
}

Config.GiveBlack = false -- give black money? if disabled it'll give regular cash.

Config.CircleZones = {
	WeedField = {coords = vector3(2221.556, 5566.497, 53.71204), name = _U('blip_weedfield'), color = 25, sprite = 496, radius = 10.0},
	WeedProcessing = {coords = vector3(2329.02, 2571.29, 46.68), name = _U('blip_weedprocessing'), color = 25, sprite = 496},

	DrugDealer = {coords = vector3(-1172.02, -1571.98, 4.66), name = _U('blip_drugdealer'), color = 25, sprite = 465},
}