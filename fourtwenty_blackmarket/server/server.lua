-- Initialize database and create the black market table if it doesn't exist
CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `fourtwenty_blackmarket` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `seller` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
            `item_name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
            `amount` int(11) NOT NULL,
            `price` int(11) NOT NULL,
            `is_auction` tinyint(1) NOT NULL DEFAULT '0',
            `end_time` datetime DEFAULT NULL,
            `highest_bidder` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
            `highest_bid` int(11) DEFAULT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
    ]], {}, function(success)
        if success then
            print('^2[INFO]^7 Black market table created successfully')
        else
            print('^1[ERROR]^7 Failed to create black market table')
        end
    end)
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
            i.label as item_label,
            UNIX_TIMESTAMP(bm.end_time) as end_timestamp
        FROM fourtwenty_blackmarket bm
        LEFT JOIN items i ON bm.item_name = i.name
        WHERE (bm.is_auction = 0) 
           OR (bm.is_auction = 1 AND bm.end_time > NOW())
        ORDER BY bm.created_at DESC
        LIMIT 50
    ]], {}, function(listings)
        for i = 1, #listings do
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
                else
                    MySQL.Async.execute('INSERT INTO fourtwenty_blackmarket_payments (seller, amount) VALUES (@seller, @amount)', {
                        ['@seller'] = auction.seller,
                        ['@amount'] = sellerAmount
                    })
                end
                
                -- Remove the auction from the database
                MySQL.Async.execute('DELETE FROM fourtwenty_blackmarket WHERE id = @id', {
                    ['@id'] = auction.id
                })
            end
        end)
    end
end)
