Locales = {}

function translate(key, ...)
    local lang = Config.Language or "en"
    if Locales[lang] and Locales[lang][key] then
        -- Only use string.format if there are additional arguments
        local args = {...}
        if #args > 0 then
            return string.format(Locales[lang][key], ...)
        else
            return Locales[lang][key]
        end
    end
    return key
end

--[[
    ENGLISH LOCALE
    Add or modify translations below. Make sure to add any new keys to all other languages as well.
    
    Categories:
    1. UI Labels - Text for buttons, headers, and general interface
    2. Messages - System notifications and status updates
    3. Auction - Auction-specific text
    4. Errors - Error messages
    5. Currency - Currency-related formatting
]]

Locales["en"] = {
    -- UI Labels
    ["black_market"] = "BLACK MARKET",
    ["browse_listings"] = "BROWSE",
    ["create_listing"] = "SELL",
    ["create_listing_header"] = "CREATE LISTING",
    ["available_listings"] = "AVAILABLE LISTINGS",
    ["select_item"] = "SELECT ITEM",
    ["amount"] = "AMOUNT",
    ["price"] = "PRICE",
    ["listing_type"] = "LISTING TYPE",
    ["duration"] = "DURATION (HOURS)",
    ["create"] = "CREATE",
    ["close"] = "X",
    ["buy_now"] = "Buy Now",
    ["choose_item"] = "Choose an item",
    ["items_available"] = "available",
    ["seller"] = "Seller",
    ["instant_buy"] = "Instant Buy",
    ["press_e"] = "Press ~INPUT_CONTEXT~ to access black market",
    
    -- Messages
    ["listing_created"] = "Listing created successfully",
    ["item_purchased"] = "Item purchased successfully",
    ["no_items"] = "You don't have any items to sell",
    ["inventory_full"] = "Your inventory is full",
    ["no_listings"] = "No listings available",
    ["item_sold"] = "An item has been sold on the blackmarket",
    ["bid_placed"] = "Bid has been placed",

    -- Auction
    ["auction"] = "Auction",
    ["auction_created"] = "Auction created successfully",
    ["auction_won"] = "Congratulations! You won the auction",
    ["auction_outbid"] = "You have been outbid!",
    ["auction_ended"] = "This auction has already ended",
    ["current_bid"] = "Current Bid",
    ["ends_at"] = "Ends",
    ["place_bid"] = "Place Bid",
    ["enter_bid"] = "Enter bid amount",
    ["your_bid"] = "Your Highest Bid",
    ["already_highest"] = "You are already the highest bidder",
    
    -- Errors
    ["not_enough_money"] = "Not enough money",
    ["invalid_price"] = "Invalid price",
    ["invalid_duration"] = "Invalid auction duration",
    ["invalid_bid_amount"] = "Invalid bid amount",
    ["not_auction_listing"] = "This is not an auction listing",
    ["bid_too_low"] = "Bid must be higher than $%s",
    ["bid_error"] = "An error occurred while placing your bid",
    ["cannot_buy_auction"] = "Cannot buy auction listings directly",
    ["listing_not_found"] = "Listing not found",
    
    -- Currency
    ["currency_symbol"] = "$",
    ["minimum_price"] = "Minimum $%d"
}

--[[
    GERMAN LOCALE
    Deutsche Übersetzung - Fügen Sie neue Übersetzungen in der gleichen Reihenfolge wie im Englischen hinzu
]]

Locales["de"] = {
    -- UI Labels
    ["black_market"] = "SCHWARZMARKT",
    ["browse_listings"] = "DURCHSUCHEN",
    ["create_listing"] = "VERKAUFEN",
    ["create_listing_header"] = "ANGEBOT ERSTELLEN",
    ["available_listings"] = "VERFÜGBARE ANGEBOTE",
    ["select_item"] = "ITEM AUSWÄHLEN",
    ["amount"] = "ANZAHL",
    ["price"] = "PREIS",
    ["listing_type"] = "ANGEBOTSTYP",
    ["duration"] = "DAUER (STUNDEN)",
    ["create"] = "ERSTELLEN",
    ["close"] = "X",
    ["buy_now"] = "Jetzt kaufen",
    ["choose_item"] = "Wähle ein Item",
    ["items_available"] = "verfügbar",
    ["seller"] = "Verkäufer",
    ["instant_buy"] = "Sofortkauf",
    ["press_e"] = "Drücke ~INPUT_CONTEXT~ um den Schwarzmarkt zu öffnen",
    
    -- Messages
    ["listing_created"] = "Angebot erfolgreich erstellt",
    ["item_purchased"] = "Item erfolgreich gekauft",
    ["no_items"] = "Du hast keine Items zum Verkaufen",
    ["inventory_full"] = "Dein Inventar ist voll",
    ["no_listings"] = "Keine Angebote verfügbar",
    ["item_sold"] = "Ein Item wurde im Schwarzmarkt verkauft",
    ["bid_placed"] = "Gebot abgegeben",

    -- Auction
    ["auction"] = "Auktion",
    ["auction_created"] = "Auktion erfolgreich erstellt",
    ["auction_won"] = "Glückwunsch! Du hast die Auktion gewonnen",
    ["auction_outbid"] = "Du wurdest überboten!",
    ["auction_ended"] = "Diese Auktion ist bereits beendet",
    ["current_bid"] = "Aktuelles Gebot",
    ["ends_at"] = "Endet",
    ["place_bid"] = "Gebot abgeben",
    ["enter_bid"] = "Gebotsumme eingeben",
    ["your_bid"] = "Ihr Höchstgebot",
    ["already_highest"] = "Sie sind bereits Höchstbietender",
    
    -- Errors
    ["not_enough_money"] = "Nicht genug Geld",
    ["invalid_price"] = "Ungültiger Preis",
    ["invalid_duration"] = "Ungültige Auktionsdauer",
    ["invalid_bid_amount"] = "Ungültiger Gebotsbetrag",
    ["not_auction_listing"] = "Dies ist keine Auktion",
    ["bid_too_low"] = "Gebot muss höher als %s€ sein",
    ["bid_error"] = "Fehler beim Platzieren des Gebots",
    ["cannot_buy_auction"] = "Auktionen können nicht direkt gekauft werden",
    ["listing_not_found"] = "Angebot nicht gefunden",
    
    -- Currency
    ["currency_symbol"] = "€",
    ["minimum_price"] = "Minimum %d€"
}

--[[
    To add a new language:
    1. Copy the entire English (en) section
    2. Change "en" to your language code (e.g., "fr" for French)
    3. Translate all values while keeping the keys the same
    4. Make sure to maintain the same categories and order
    
    Example:
    Locales["fr"] = {
        ["black_market"] = "MARCHÉ NOIR",
        -- ... translate all other keys ...
    }
]]