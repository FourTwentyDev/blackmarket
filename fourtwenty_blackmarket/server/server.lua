-- Initialize database and create all required tables if they don't exist
local selectedLocations = {}

-- Function to randomly select coordinates for each location
local function initializeRandomLocations()
    for locationIndex, location in pairs(Config.Locations) do
        -- Select a random coordinate from the available coordinates
        local randomIndex = math.random(1, #location.coords)
        selectedLocations[locationIndex] = location.coords[randomIndex]
        print(string.format("^2[INFO]^7 Selected coordinates for %s: %s", location.name, tostring(selectedLocations[locationIndex])))
    end
end

-- Initialize random locations when resource starts
CreateThread(function()
    -- Initialize random seed
    math.randomseed(os.time())
    -- Select random locations
    initializeRandomLocations()
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `fourtwenty_blackmarket` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `seller` VARCHAR(50) COLLATE utf8mb4_general_ci NOT NULL,
            `item_name` VARCHAR(50) COLLATE utf8mb4_general_ci NOT NULL,
            `amount` INT(11) NOT NULL,
            `price` INT(11) NOT NULL,
            `is_auction` TINYINT(1) NOT NULL DEFAULT 0,
            `end_time` DATETIME DEFAULT NULL,
            `highest_bidder` VARCHAR(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
            `highest_bid` INT(11) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]], {}, function(success)
        if success then
            print('^2[INFO]^7 Table `fourtwenty_blackmarket` created successfully.')
        else
            print('^1[ERROR]^7 Failed to create table `fourtwenty_blackmarket`.')
        end
    end)

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `fourtwenty_blackmarket_payments` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `seller` VARCHAR(50) COLLATE utf8mb4_general_ci NOT NULL,
            `amount` INT(11) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `paid` TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]], {}, function(success)
        if success then
            print('^2[INFO]^7 Table `fourtwenty_blackmarket_payments` created successfully.')
        else
            print('^1[ERROR]^7 Failed to create table `fourtwenty_blackmarket_payments`.')
        end
    end)

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `fourtwenty_blackmarket_pending` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `player` VARCHAR(50) COLLATE utf8mb4_general_ci NOT NULL,
            `item_name` VARCHAR(50) COLLATE utf8mb4_general_ci NOT NULL,
            `amount` INT(11) NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `delivered` TINYINT(1) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]], {}, function(success)
        if success then
            print('^2[INFO]^7 Table `fourtwenty_blackmarket_pending` created successfully.')
        else
            print('^1[ERROR]^7 Failed to create table `fourtwenty_blackmarket_pending`.')
        end
    end)
end)

-- Event to send current market locations to clients
RegisterNetEvent('fourtwenty_blackmarket:requestLocations')
AddEventHandler('fourtwenty_blackmarket:requestLocations', function()
    local source = source
    TriggerClientEvent('fourtwenty_blackmarket:receiveLocations', source, selectedLocations)
end)

-- Create a new listing
RegisterNetEvent('fourtwenty_blackmarket:createListing')
AddEventHandler('fourtwenty_blackmarket:createListing', function(data)
    local source = source
    local xPlayer = Bridge.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    -- Retrieve inventory and find the specified item
    local inventory = Bridge.GetItems(source)
    local item = nil
    for _, invItem in pairs(inventory) do
        if invItem.name == data.itemName then
            item = invItem
            break
        end
    end
    
    -- Ensure the player has enough of the item
    if not item or item.count < data.amount then
        Bridge.Notify(source, translate("no_items"), "error")
        return
    end
    
    -- Ensure the price is above the minimum
    if data.price < Config.MinimumPrice then
        Bridge.Notify(source, translate("invalid_price"), "error")
        return
    end
    
    -- Remove the item from the player's inventory
    Bridge.RemoveItem(source, data.itemName, data.amount)
    
    -- Set auction end time if applicable
    local endTime = nil
    if data.isAuction then
        endTime = os.date("%Y-%m-%d %H:%M:%S", os.time() + (data.duration * 3600))
    end
    
    -- Insert the new listing into the database
    MySQL.Async.insert('INSERT INTO fourtwenty_blackmarket (seller, item_name, amount, price, is_auction, end_time) VALUES (@seller, @item_name, @amount, @price, @is_auction, @end_time)', {
        ['@seller'] = xPlayer.identifier,
        ['@item_name'] = data.itemName,
        ['@amount'] = data.amount,
        ['@price'] = data.price,
        ['@is_auction'] = data.isAuction,
        ['@end_time'] = endTime
    }, function(listingId)
        if listingId > 0 then
            Bridge.Notify(source, translate("listing_created"), "success")
            TriggerClientEvent('fourtwenty_blackmarket:refreshListings', -1)
        end
    end)
end)

-- Remove a listing
RegisterNetEvent('fourtwenty_blackmarket:removeListing')
AddEventHandler('fourtwenty_blackmarket:removeListing', function(listingId)
    local source = source
    local xPlayer = Bridge.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    MySQL.Async.fetchAll('SELECT * FROM fourtwenty_blackmarket WHERE id = @id AND seller = @seller', {
        ['@id'] = listingId,
        ['@seller'] = xPlayer.identifier
    }, function(result)
        if #result > 0 then
            local listing = result[1]
            
            -- Return the item to the seller
            Bridge.AddItem(source, listing.item_name, listing.amount)
            
            -- If it's an auction with bids, return the money to the highest bidder
            if listing.is_auction == 1 and listing.highest_bidder then
                local highestBidder = Bridge.GetPlayerFromIdentifier(listing.highest_bidder)
                if highestBidder then
                    Bridge.AddMoney(highestBidder.source, listing.highest_bid)
                    Bridge.Notify(highestBidder.source, translate("auction_cancelled_refund"), "info")
                else
                    -- Queue the refund for when they come online
                    MySQL.Async.execute('INSERT INTO fourtwenty_blackmarket_payments (seller, amount) VALUES (@seller, @amount)', {
                        ['@seller'] = listing.highest_bidder,
                        ['@amount'] = listing.highest_bid
                    })
                end
            end
            
            -- Remove the listing
            MySQL.Async.execute('DELETE FROM fourtwenty_blackmarket WHERE id = @id', {
                ['@id'] = listingId
            })
            
            Bridge.Notify(source, translate("listing_removed"), "success")
            TriggerClientEvent('fourtwenty_blackmarket:refreshListings', -1)
        else
            Bridge.Notify(source, translate("not_your_listing"), "error")
        end
    end)
end)

-- Handle item purchase
RegisterNetEvent('fourtwenty_blackmarket:purchaseItem')
AddEventHandler('fourtwenty_blackmarket:purchaseItem', function(listingId)
    local source = source
    local xPlayer = Bridge.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    MySQL.Async.fetchAll('SELECT * FROM fourtwenty_blackmarket WHERE id = @id', {
        ['@id'] = listingId
    }, function(result)
        if #result > 0 then
            local listing = result[1]
            
            -- Ensure the item is not an auction
            if listing.is_auction == 1 then
                Bridge.Notify(source, translate("cannot_buy_auction"), "error")
                return
            end
            
            -- Ensure the player has enough money
            local playerMoney = xPlayer.getMoney()
            if playerMoney < listing.price then
                Bridge.Notify(source, translate("not_enough_money"), "error")
                return
            end
            
            -- Process payment
            Bridge.RemoveMoney(source, listing.price)
            local taxAmount = math.floor(listing.price * Config.TaxRate)
            local sellerAmount = listing.price - taxAmount
            
            -- Pay the seller or queue the payment if offline
            local xSeller = Bridge.GetPlayerFromIdentifier(listing.seller)
            if xSeller then
                Bridge.AddMoney(xSeller.source, sellerAmount)
                Bridge.Notify(xSeller.source, translate("item_sold"), "success")
            else
                MySQL.Async.execute('INSERT INTO fourtwenty_blackmarket_payments (seller, amount) VALUES (@seller, @amount)', {
                    ['@seller'] = listing.seller,
                    ['@amount'] = sellerAmount
                })
            end
            
            -- Deliver the item to the buyer
            Bridge.AddItem(source, listing.item_name, listing.amount)
            
            -- Remove the listing
            MySQL.Async.execute('DELETE FROM fourtwenty_blackmarket WHERE id = @id', {
                ['@id'] = listingId
            })
            
            Bridge.Notify(source, translate("item_purchased"), "success")
            TriggerClientEvent('fourtwenty_blackmarket:refreshListings', -1)
        else
            Bridge.Notify(source, translate("listing_not_found"), "error")
        end
    end)
end)

-- Place a bid on an auction
RegisterNetEvent('fourtwenty_blackmarket:placeBid')
AddEventHandler('fourtwenty_blackmarket:placeBid', function(listingId, bidAmount)
    local source = source
    local xPlayer = Bridge.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    MySQL.Async.fetchAll('SELECT * FROM fourtwenty_blackmarket WHERE id = @id', {
        ['@id'] = listingId
    }, function(result)
        if #result == 0 then
            Bridge.Notify(source, translate("listing_not_found"), "error")
            return
        end

        local listing = result[1]
        
        -- Ensure it is an auction
        if not listing.is_auction then
            Bridge.Notify(source, translate("not_auction_listing"), "error")
            return
        end
        
        -- Ensure the auction hasn't ended
        if listing.end_time and os.time() > os.time(os.date("!*t", listing.end_time)) then
            Bridge.Notify(source, translate("auction_ended"), "error")
            return
        end
        
        -- Ensure the bid is higher than the current highest bid
        local minimumBid = listing.highest_bid or listing.price
        if bidAmount <= minimumBid then
            Bridge.Notify(source, string.format(translate("bid_too_low"), minimumBid), "error")
            return
        end
        
        -- Ensure the player has enough money
        local playerMoney = xPlayer.getMoney()
        if playerMoney < bidAmount then
            Bridge.Notify(source, translate("not_enough_money"), "error")
            return
        end
        
        -- Refund the previous highest bidder
        if listing.highest_bidder then
            local previousBidder = Bridge.GetPlayerFromIdentifier(listing.highest_bidder)
            if previousBidder then
                Bridge.AddMoney(previousBidder.source, listing.highest_bid)
                Bridge.Notify(previousBidder.source, translate("auction_outbid"), "info")
            end
        end
        
        -- Deduct money from the new bidder
        Bridge.RemoveMoney(source, bidAmount)
        
        -- Update the listing with the new highest bid
        MySQL.Async.execute('UPDATE fourtwenty_blackmarket SET highest_bidder = @bidder, highest_bid = @bid WHERE id = @id', {
            ['@bidder'] = xPlayer.identifier,
            ['@bid'] = bidAmount,
            ['@id'] = listingId
        }, function()
            Bridge.Notify(source, translate("bid_placed"), "success")
            TriggerClientEvent('fourtwenty_blackmarket:refreshListings', -1)
        end)
    end)
end)

-- Function to fetch current listings
function FetchListings(source, cb)
    MySQL.Async.fetchAll([[
        SELECT 
            bm.*,
            UNIX_TIMESTAMP(bm.end_time) as end_timestamp
        FROM fourtwenty_blackmarket bm
        WHERE (bm.is_auction = 0) 
           OR (bm.is_auction = 1 AND bm.end_time > NOW())
        ORDER BY bm.created_at DESC
        LIMIT 50
    ]], {}, function(listings)
        for i = 1, #listings do
            -- Get item label
            local itemName = listings[i].item_name
            
            if Config.ox_inventory then
                local item = exports.ox_inventory:Items()[itemName]
                listings[i].item_label = item and item.label or itemName
            else
                listings[i].item_label = Bridge.GetItemLabel(itemName)
            end
            
            listings[i].is_auction = listings[i].is_auction == 1 or listings[i].is_auction == true
            listings[i].seller_name = "Anonymous"
            if listings[i].end_timestamp then
                listings[i].end_time = os.date("%Y-%m-%d %H:%M:%S", listings[i].end_timestamp)
            end
        end
        
        if cb then
            cb(listings)
        else
            TriggerClientEvent('fourtwenty_blackmarket:receiveListings', source, listings)
        end
    end)
end

-- Fetch listings for a player
RegisterNetEvent('fourtwenty_blackmarket:getListings')
AddEventHandler('fourtwenty_blackmarket:getListings', function()
    local source = source
    local xPlayer = Bridge.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    FetchListings(source)
end)

-- Register callback to fetch listings
Bridge.RegisterCallback('fourtwenty_blackmarket:getListings', function(source, cb)
    local xPlayer = Bridge.GetPlayerFromId(source)
    
    if not xPlayer then return cb({}) end
    
    FetchListings(source, cb)
end)

-- Periodically check for expired auctions
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        -- Check expired auctions with bids
        MySQL.Async.fetchAll('SELECT * FROM fourtwenty_blackmarket WHERE is_auction = 1 AND end_time < NOW() AND highest_bidder IS NOT NULL', {}, function(auctions)
            for _, auction in ipairs(auctions) do
                -- Handle winning bid
                local winner = Bridge.GetPlayerFromIdentifier(auction.highest_bidder)
                if winner then
                    Bridge.AddItem(winner.source, auction.item_name, auction.amount)
                    Bridge.Notify(winner.source, translate("auction_won"), "success")
                else
                    MySQL.Async.execute('INSERT INTO fourtwenty_blackmarket_pending (player, item_name, amount) VALUES (@player, @item, @amount)', {
                        ['@player'] = auction.highest_bidder,
                        ['@item'] = auction.item_name,
                        ['@amount'] = auction.amount
                    })
                end
                
                -- Pay the seller
                local taxAmount = math.floor(auction.highest_bid * Config.TaxRate)
                local sellerAmount = auction.highest_bid - taxAmount
                
                local seller = Bridge.GetPlayerFromIdentifier(auction.seller)
                if seller then
                    Bridge.AddMoney(seller.source, sellerAmount)
                    Bridge.Notify(seller.source, translate("auction_completed"), "success")
                else
                    MySQL.Async.execute('INSERT INTO fourtwenty_blackmarket_payments (seller, amount) VALUES (@seller, @amount)', {
                        ['@seller'] = auction.seller,
                        ['@amount'] = sellerAmount
                    })
                end
                
                -- Remove the auction
                MySQL.Async.execute('DELETE FROM fourtwenty_blackmarket WHERE id = @id', {
                    ['@id'] = auction.id
                })
            end
        end)

        -- Check expired auctions without bids
        MySQL.Async.fetchAll('SELECT * FROM fourtwenty_blackmarket WHERE is_auction = 1 AND end_time < NOW() AND highest_bidder IS NULL', {}, function(auctions)
            for _, auction in ipairs(auctions) do
                -- Return items to seller if online
                local seller = Bridge.GetPlayerFromIdentifier(auction.seller)
                if seller then
                    Bridge.AddItem(seller.source, auction.item_name, auction.amount)
                    Bridge.Notify(seller.source, translate("auction_expired_items_returned"), "info")
                else
                    -- Queue items for return to seller when they come online
                    MySQL.Async.execute('INSERT INTO fourtwenty_blackmarket_pending (player, item_name, amount) VALUES (@player, @item, @amount)', {
                        ['@player'] = auction.seller,
                        ['@item'] = auction.item_name,
                        ['@amount'] = auction.amount
                    })
                end
                
                -- Remove the expired auction
                MySQL.Async.execute('DELETE FROM fourtwenty_blackmarket WHERE id = @id', {
                    ['@id'] = auction.id
                })
            end
        end)
        
        -- Check pending payments
        MySQL.Async.fetchAll('SELECT * FROM fourtwenty_blackmarket_payments WHERE paid = 0', {}, function(payments)
            for _, payment in ipairs(payments) do
                local seller = Bridge.GetPlayerFromIdentifier(payment.seller)
                if seller then
                    Bridge.AddMoney(seller.source, payment.amount)
                    Bridge.Notify(seller.source, translate("delayed_payment_received"), "success")
                    
                    -- Mark payment as completed
                    MySQL.Async.execute('UPDATE fourtwenty_blackmarket_payments SET paid = 1 WHERE id = @id', {
                        ['@id'] = payment.id
                    })
                end
            end
        end)

        -- Check pending deliveries
        MySQL.Async.fetchAll('SELECT * FROM fourtwenty_blackmarket_pending WHERE delivered = 0', {}, function(deliveries)
            for _, delivery in ipairs(deliveries) do
                local player = Bridge.GetPlayerFromIdentifier(delivery.player)
                if player then
                    Bridge.AddItem(player.source, delivery.item_name, delivery.amount)
                    Bridge.Notify(player.source, translate("delayed_item_received"), "success")
                    
                    -- Mark delivery as completed
                    MySQL.Async.execute('UPDATE fourtwenty_blackmarket_pending SET delivered = 1 WHERE id = @id', {
                        ['@id'] = delivery.id
                    })
                end
            end
        end)
    end
end)
