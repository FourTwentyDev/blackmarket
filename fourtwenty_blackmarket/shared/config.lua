Config = {}

-- Framework configuration
Config.Framework = "ESX" -- or "QB"
Config.Language = "en"

Config.ItemImagePath = "nui://inventory/web/dist/assets/items/"

Config.ox_inventory = false

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
        coords = {
            vector3(-1456.42, -413.67, 35.91),
            vector3(-1394.65, -526.89, 31.02),
            vector3(-1583.24, -376.15, 43.98),
            vector3(-1336.76, -493.21, 33.45)
        },
        blip = {
            enabled = true,
            sprite = 496,
            color = 1,
            scale = 0.8
        }
    },
    {
        name = "Harbor Black Market",
        coords = {
            vector3(1212.32, -3005.87, 5.87),
            vector3(1156.89, -3048.56, 5.90),
            vector3(1240.45, -2911.34, 8.32),
            vector3(1088.76, -2976.12, 5.90)
        },
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
