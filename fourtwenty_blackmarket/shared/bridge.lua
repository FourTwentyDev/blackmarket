Bridge = {}

-- ESX Framework Implementation
if Config.Framework == "ESX" then
    local ESX = exports["es_extended"]:getSharedObject()
    
    if IsDuplicityVersion() then -- Server-side
        -- Player Management
        Bridge.GetPlayerFromId = function(source)
            return ESX.GetPlayerFromId(source)
        end
        
        Bridge.GetPlayerFromIdentifier = function(identifier)
            return ESX.GetPlayerFromIdentifier(identifier)
        end
        
        -- Inventory Management
        Bridge.GetItems = function(source)
            local xPlayer = Bridge.GetPlayerFromId(source)
            if xPlayer then
                return xPlayer.getInventory()
            end
            return {}
        end
        
        Bridge.AddItem = function(source, item, count)
            local xPlayer = Bridge.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.addInventoryItem(item, count)
            end
        end
        
        Bridge.RemoveItem = function(source, item, count)
            local xPlayer = Bridge.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.removeInventoryItem(item, count)
            end
        end

        Bridge.GetItemLabel = function(itemName)
            local item = ESX.Items[itemName]
            return item and item.label or itemName
        end
        
        -- Money Management
        Bridge.AddMoney = function(source, amount)
            local xPlayer = Bridge.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.addMoney(amount)
            end
        end
        
        Bridge.RemoveMoney = function(source, amount)
            local xPlayer = Bridge.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.removeMoney(amount)
            end
        end
        
        -- UI/Notifications
        Bridge.Notify = function(source, message, type)
            if Config.NotificationType == "esx" then
                TriggerClientEvent('esx:showNotification', source, message)
            else
                Config.CustomNotification(source, type, message)
            end
        end
        
        -- Callbacks
        Bridge.RegisterCallback = function(name, cb)
            ESX.RegisterServerCallback(name, cb)
        end
        
    else -- Client-side
        Bridge.GetPlayerData = function()
            return ESX.GetPlayerData()
        end

        Bridge.TriggerCallback = function(name, cb, ...)
            ESX.TriggerServerCallback(name, cb, ...)
        end

        Bridge.Notify = function(message, type)
            if Config.NotificationType == "esx" then
                ESX.ShowNotification(message)
            else
                Config.CustomNotification(message, type)
            end
        end

        Bridge.ShowHelpNotification = function(msg)
            ESX.ShowHelpNotification(msg)
        end

        Bridge.ShowTextUI = function(msg)
            ESX.TextUI(msg)
        end

        Bridge.HideTextUI = function()
            ESX.HideUI()
        end
    end
end

-- QB Framework Implementation
if Config.Framework == "QB" then
    local QBCore = exports['qb-core']:GetCoreObject()
    
    if IsDuplicityVersion() then -- Server-side
        -- Player Management
        Bridge.GetPlayerFromId = function(source)
            return QBCore.Functions.GetPlayer(source)
        end
        
        Bridge.GetPlayerFromIdentifier = function(identifier)
            return QBCore.Functions.GetPlayerByCitizenId(identifier)
        end
        
        -- Inventory Management
        Bridge.GetItems = function(source)
            local Player = Bridge.GetPlayerFromId(source)
            if Player then
                return Player.PlayerData.items
            end
            return {}
        end
        
        Bridge.AddItem = function(source, item, count)
            local Player = Bridge.GetPlayerFromId(source)
            if Player then
                Player.Functions.AddItem(item, count)
            end
        end
        
        Bridge.RemoveItem = function(source, item, count)
            local Player = Bridge.GetPlayerFromId(source)
            if Player then
                Player.Functions.RemoveItem(item, count)
            end
        end

        Bridge.GetItemLabel = function(itemName)
            local item = QBCore.Shared.Items[itemName]
            return item and item.label or itemName
        end
        
        -- Money Management
        Bridge.AddMoney = function(source, amount)
            local Player = Bridge.GetPlayerFromId(source)
            if Player then
                Player.Functions.AddMoney('cash', amount)
            end
        end
        
        Bridge.RemoveMoney = function(source, amount)
            local Player = Bridge.GetPlayerFromId(source)
            if Player then
                Player.Functions.RemoveMoney('cash', amount)
            end
        end
        
        -- UI/Notifications
        Bridge.Notify = function(source, message, type)
            if Config.NotificationType == "qb" then
                TriggerClientEvent('QBCore:Notify', source, message, type)
            else
                Config.CustomNotification(source, type, message)
            end
        end
        
        -- Callbacks
        Bridge.RegisterCallback = function(name, cb)
            QBCore.Functions.CreateCallback(name, cb)
        end
        
    else -- Client-side
        Bridge.GetPlayerData = function()
            return QBCore.Functions.GetPlayerData()
        end

        Bridge.TriggerCallback = function(name, cb, ...)
            QBCore.Functions.TriggerCallback(name, cb, ...)
        end

        Bridge.Notify = function(message, type)
            if Config.NotificationType == "qb" then
                QBCore.Functions.Notify(message, type)
            else
                Config.CustomNotification(message, type)
            end
        end

        Bridge.ShowHelpNotification = function(msg)
            QBCore.Functions.Notify(msg, "primary", 5000)
        end

        Bridge.ShowTextUI = function(msg)
            exports['qb-core']:DrawText(msg, 'left')
        end

        Bridge.HideTextUI = function()
            exports['qb-core']:HideText()
        end
    end
end

-- Shared utility functions (available to both client and server)
Bridge.Round = function(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end

Bridge.TableContains = function(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

Bridge.GetFramework = function()
    return Config.Framework
end

Bridge.Debug = function(msg)
    if Config.Debug then
        print('^3[Bridge Debug]^7 ' .. tostring(msg))
    end
end

return Bridge