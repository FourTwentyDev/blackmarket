-- Check if the player is near a market and initialize market reference
local isNearMarket = false
local currentMarket = nil
local marketLocations = {}

-- Request current market locations when resource starts
CreateThread(function()
    TriggerServerEvent('fourtwenty_blackmarket:requestLocations')
end)

-- Receive market locations from server
RegisterNetEvent('fourtwenty_blackmarket:receiveLocations')
AddEventHandler('fourtwenty_blackmarket:receiveLocations', function(locations)
    marketLocations = locations
end)

RegisterNUICallback('getPlayerItems', function(data, cb)
    local items = {}
    
    if Config.ox_inventory then
        local playerItems = exports.ox_inventory:GetPlayerItems()
        
        for _, v in pairs(playerItems) do
            if v.count > 0 then
                table.insert(items, {
                    name = v.name,
                    label = exports.ox_inventory:Items()[v.name].label,
                    count = v.count,
                    type = v.type or 'item'
                })
            end
        end
    else
        local playerData = Bridge.GetPlayerData()
        local inventory = playerData.inventory or playerData.items

        for _, v in pairs(inventory) do
            local count = v.count or v.amount
            if count and count > 0 then
                table.insert(items, {
                    name = v.name,
                    label = v.label or v.name,
                    count = count,
                    type = v.type
                })
            end
        end
    end
    
    cb(items)
end)

-- NUI callback to create a new listing
RegisterNUICallback('createListing', function(data, cb)
    TriggerServerEvent('fourtwenty_blackmarket:createListing', {
        itemName = data.itemName,
        amount = data.amount,
        price = data.price,
        isAuction = data.isAuction,
        duration = data.duration
    })
    cb('ok')
end)

-- NUI callback to remove a listing
RegisterNUICallback('removeListing', function(data, cb)
    TriggerServerEvent('fourtwenty_blackmarket:removeListing', data.listingId)
    cb('ok')
end)

-- NUI callback to purchase an item
RegisterNUICallback('purchaseItem', function(data, cb)
    TriggerServerEvent('fourtwenty_blackmarket:purchaseItem', data.listingId)
    cb('ok')
end)

-- NUI callback to place a bid
RegisterNUICallback('placeBid', function(data, cb)
    TriggerServerEvent('fourtwenty_blackmarket:placeBid', data.listingId, data.bidAmount)
    cb('ok')
end)

-- NUI callback to close the UI
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- NUI callback to request listings
RegisterNUICallback('getListings', function(data, cb)
    TriggerServerEvent('fourtwenty_blackmarket:getListings')
    cb('ok')
end)

-- Handle listings data received from server
RegisterNetEvent('fourtwenty_blackmarket:receiveListings')
AddEventHandler('fourtwenty_blackmarket:receiveListings', function(listings)
    SendNUIMessage({
        type = "updateListings",
        listings = listings
    })
end)

-- NUI callback to get the current player identifier
RegisterNUICallback('getCurrentPlayer', function(data, cb)
    local playerData = Bridge.GetPlayerData()
    local identifier = playerData.identifier or playerData.citizenid -- Handle ESX/QB variations
    cb(identifier)
end)

-- Thread to check proximity to market locations
CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        isNearMarket = false
        
        for k, coords in pairs(marketLocations) do
            local distance = #(playerCoords - coords)
            if distance < 3.0 then
                isNearMarket = true
                currentMarket = k
                break
            end
        end
    end
end)

-- Draw markers and interact when near a market
CreateThread(function()
    while true do
        Wait(0)
        if isNearMarket and marketLocations[currentMarket] then
            local coords = marketLocations[currentMarket]
            DrawMarker(27, coords.x, coords.y, coords.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 200, 0, 0, 100, false, true, 2, false, nil, nil, false)
            
            if IsControlJustReleased(0, 38) then -- E key for interaction
                OpenBlackMarketUI()
            end
            
            DrawText3D(coords.x, coords.y, coords.z, translate("press_e"))
        end
    end
end)

-- Initialize blips for market locations
CreateThread(function()
    while true do
        Wait(1000)
        -- Wait until we have received the market locations from the server
        if next(marketLocations) then
            for k, coords in pairs(marketLocations) do
                if Config.Locations[k].blip.enabled then
                    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                    SetBlipSprite(blip, Config.Locations[k].blip.sprite)
                    SetBlipDisplay(blip, 4)
                    SetBlipScale(blip, Config.Locations[k].blip.scale)
                    SetBlipColour(blip, Config.Locations[k].blip.color)
                    SetBlipAsShortRange(blip, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString(Config.Locations[k].name)
                    EndTextCommandSetBlipName(blip)
                end
            end
            break -- Exit the loop once blips are created
        end
    end
end)

-- Function to open the black market UI
function OpenBlackMarketUI()
    local translations = {
        black_market = translate("black_market"),
        browse_listings = translate("browse_listings"),
        create_listing = translate("create_listing"),
        available_listings = translate("available_listings"),
        create_listing_header = translate("create_listing_header"),
        select_item = translate("select_item"),
        amount = translate("amount"),
        price = translate("price"),
        listing_type = translate("listing_type"),
        duration = translate("duration"),
        instant_buy = translate("instant_buy"),
        auction = translate("auction"),
        choose_item = translate("choose_item"),
        enter_bid = translate("enter_bid"),
        minimum_price = translate("minimum_price"),
        items_available = translate("items_available"),
        create = translate("create"),
        buy_now = translate("buy_now"),
        place_bid = translate("place_bid"),
        close = translate("close"),
        seller = translate("seller"),
        current_bid = translate("current_bid"),
        ends_at = translate("ends_at"),
        no_listings = translate("no_listings"),
        currency_symbol = translate("currency_symbol"),
        time_remaining = translate("time_remaining"),
        remove_listing = translate("remove_listing")
    }

    Bridge.TriggerCallback('fourtwenty_blackmarket:getListings', function(listings)
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "openUI",
            market = Config.Locations[currentMarket].name,
            listings = listings,
            config = {
                MinimumPrice = Config.MinimumPrice,
                MaxAuctionTime = Config.MaxAuctionTime,
                ItemImagePath = Config.ItemImagePath,
                translations = translations
            }
        })
    end)
end

-- Function to draw 3D text in the world
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
    end
end

-- Event to refresh listings when updated
RegisterNetEvent('fourtwenty_blackmarket:refreshListings')
AddEventHandler('fourtwenty_blackmarket:refreshListings', function()
    if isNearMarket then
        TriggerServerEvent('fourtwenty_blackmarket:getListings')
    end
end)

-- Event for custom notifications
RegisterNetEvent('fourtwenty_blackmarket:notify')
AddEventHandler('fourtwenty_blackmarket:notify', function(message, type)
    if Config.NotificationType == Config.Framework:lower() then
        Bridge.Notify(message, type)
    else
        Config.CustomNotification(message, type)
    end
end)

-- Cleanup when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    SetNuiFocus(false, false)
end)
