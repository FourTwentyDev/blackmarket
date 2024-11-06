local isNearMarket = false
local currentMarket = nil

-- Initialize NUI callback
RegisterNUICallback('getPlayerItems', function(data, cb)
    local playerData = Bridge.GetPlayerData()
    local items = {}
    
    -- Adjust for different inventory structures between frameworks
    local inventory = playerData.inventory or playerData.items -- ESX uses inventory, QB uses items
    
    for k, v in pairs(inventory) do
        local count = v.count or v.amount -- ESX uses count, QB uses amount
        if count and count > 0 then
            table.insert(items, {
                name = v.name,
                label = v.label or v.name, -- QB might not have label
                count = count,
                type = v.type
            })
        end
    end
    
    cb(items)
end)

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

RegisterNUICallback('purchaseItem', function(data, cb)
    TriggerServerEvent('fourtwenty_blackmarket:purchaseItem', data.listingId)
    cb('ok')
end)

RegisterNUICallback('placeBid', function(data, cb)
    TriggerServerEvent('fourtwenty_blackmarket:placeBid', data.listingId, data.bidAmount)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('getListings', function(data, cb)
    TriggerServerEvent('fourtwenty_blackmarket:getListings')
    cb('ok')
end)

RegisterNetEvent('fourtwenty_blackmarket:receiveListings')
AddEventHandler('fourtwenty_blackmarket:receiveListings', function(listings)
    SendNUIMessage({
        type = "updateListings",
        listings = listings
    })
end)

RegisterNUICallback('getCurrentPlayer', function(data, cb)
    local playerData = Bridge.GetPlayerData()
    -- Handle different identifier formats between frameworks
    local identifier = playerData.identifier or playerData.citizenid -- ESX uses identifier, QB uses citizenid
    cb(identifier)
end)

-- Check for nearby markets
CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        isNearMarket = false
        
        for k, v in pairs(Config.Locations) do
            local distance = #(playerCoords - v.coords)
            if distance < 3.0 then
                isNearMarket = true
                currentMarket = k
                break
            end
        end
    end
end)

-- Draw marker and handle interaction
CreateThread(function()
    while true do
        Wait(0)
        if isNearMarket then
            local market = Config.Locations[currentMarket]
            DrawMarker(27, market.coords.x, market.coords.y, market.coords.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 200, 0, 0, 100, false, true, 2, false, nil, nil, false)
            
            if IsControlJustReleased(0, 38) then -- E key
                OpenBlackMarketUI()
            end
            
            DrawText3D(market.coords.x, market.coords.y, market.coords.z, translate("press_e"))
        end
    end
end)

-- Initialize blips
CreateThread(function()
    for k, v in pairs(Config.Locations) do
        if v.blip.enabled then
            local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(blip, v.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, v.blip.scale)
            SetBlipColour(blip, v.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

function OpenBlackMarketUI()
    -- Create a complete translations object
    local translations = {
        -- UI Headers and Navigation
        black_market = translate("black_market"),
        browse_listings = translate("browse_listings"),
        create_listing = translate("create_listing"),
        available_listings = translate("available_listings"),
        create_listing_header = translate("create_listing_header"),
        
        -- Form Labels
        select_item = translate("select_item"),
        amount = translate("amount"),
        price = translate("price"),
        listing_type = translate("listing_type"),
        duration = translate("duration"),
        
        -- Options and Placeholders
        instant_buy = translate("instant_buy"),
        auction = translate("auction"),
        choose_item = translate("choose_item"),
        enter_bid = translate("enter_bid"),
        minimum_price = translate("minimum_price"),
        items_available = translate("items_available"),

        -- Buttons and Actions
        create = translate("create"),
        buy_now = translate("buy_now"),
        place_bid = translate("place_bid"),
        close = translate("close"),
        
        -- Listing Information
        seller = translate("seller"),
        current_bid = translate("current_bid"),
        ends_at = translate("ends_at"),
        no_listings = translate("no_listings"),
        
        -- Currency
        currency_symbol = translate("currency_symbol")
    }

    -- Use Bridge callback
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

-- Refresh listings event handler
RegisterNetEvent('fourtwenty_blackmarket:refreshListings')
AddEventHandler('fourtwenty_blackmarket:refreshListings', function()
    if isNearMarket then
        TriggerServerEvent('fourtwenty_blackmarket:getListings')
    end
end)

-- Notification handler
RegisterNetEvent('fourtwenty_blackmarket:notify')
AddEventHandler('fourtwenty_blackmarket:notify', function(message, type)
    if Config.NotificationType == Config.Framework:lower() then
        Bridge.Notify(message, type)
    else
        Config.CustomNotification(message, type)
    end
end)

-- Resource stop cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    SetNuiFocus(false, false)
end)