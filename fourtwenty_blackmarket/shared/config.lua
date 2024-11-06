Config = {}

-- Framework configuration
Config.Framework = "ESX" -- or "QB"
Config.Language = "en"

Config.ItemImagePath = "nui://inventory/web/dist/assets/items/"

-- Database table name
Config.DatabaseTable = "fourtwenty_blackmarket"

-- General settings
Config.MaxListings = 50 -- Maximum number of active listings per player
Config.MaxAuctionTime = 72 -- Maximum auction time in hours
Config.MinimumPrice = 100 -- Minimum price for listings
Config.TaxRate = 0.05 -- 5% tax on sales

-- Locations configuration
Config.Locations = {
    {
        name = "Downtown Black Market",
        coords = vector3(-1456.42, -413.67, 35.91),
        blip = {
            enabled = true,
            sprite = 496,
            color = 1,
            scale = 0.8
        }
    },
    {
        name = "Harbor Black Market",
        coords = vector3(1212.32, -3005.87, 5.87),
        blip = {
            enabled = true,
            sprite = 496,
            color = 1,
            scale = 0.8
        }
    }
}

Config.Debug = false

-- Notification settings
Config.NotificationType = "esx" -- or "qb" or "custom"
Config.CustomNotification = function(source, type, message)
    -- Custom notification function
end