# FourTwenty Black Market 🏴‍☠️

A sophisticated black market system for FiveM servers featuring a modern UI, dynamic listings, auctions, and seamless framework integration with both ESX and QB-Core.

## Features 💎

- **Modern UI System**: 
  - Sleek, responsive design
  - Real-time updates
  - Smooth animations
  - Mobile-friendly layout
  - Dark theme with accent colors

- **Dual Framework Support**: 
  - ESX Framework integration
  - QB-Core Framework integration
  - Framework-agnostic bridge system
  - Automatic framework detection

- **Advanced Market Features**: 
  - Instant buy listings
  - Timed auctions
  - Real-time bidding
  - Tax system
  - Multiple market locations
  - Custom blips

- **Auction System**:
  - Configurable auction duration
  - Automatic bid processing
  - Outbid notifications
  - Automatic winner selection
  - Bid refund system

## Dependencies 📦

- ESX Framework or QB-Core Framework
- MySQL Async
- FiveM Server Build 2802 or higher

## Installation 💿

1. Clone/download this resource to your server's `resources` directory
2. Import the included SQL:
```sql
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
```
3. Add `ensure fourtwenty_blackmarket` to your `server.cfg`
4. Configure using `config.lua`
5. Start/restart your server

## Configuration Guide 🔧

### Core Settings
```lua
Config = {
    Framework = "ESX",     -- or "QB"
    Language = "en",       -- Available: 'en', 'de'
    Debug = false         -- Enable debug mode
}
```

### Market Settings
```lua
Config.MaxListings = 50        -- Maximum active listings per player
Config.MaxAuctionTime = 72     -- Maximum auction duration in hours
Config.MinimumPrice = 100      -- Minimum listing price
Config.TaxRate = 0.05         -- 5% tax on sales
```

### Customizable Elements

1. **Market Locations**:
   - Configure multiple black market locations
   - Customize blip settings for each location
   - Example:
     ```lua
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
         }
     }
     ```

2. **Notification System**:
   - Support for ESX, QB-Core, and custom notifications
   - Configurable notification type:
     ```lua
     Config.NotificationType = "esx" -- or "qb" or "custom"
     Config.CustomNotification = function(source, type, message)
         -- Custom notification implementation
     end
     ```

## Localization 🌍

The system includes full localization support. Add or modify languages in `locale.lua`:
```lua
Locales["en"] = {
    ["black_market"] = "BLACK MARKET",
    ["browse_listings"] = "BROWSE",
    ["create_listing"] = "SELL",
    -- Add more translations
}
```

Currently supported languages:
- English (en)
- German (de)

## Features In-Depth 🔍

### Listing System
- Create instant-buy listings
- Set up timed auctions
- Configure minimum prices
- Set maximum auction durations
- View active listings
- Track your sales

### Auction System
- Place bids on items
- Automatic outbid notifications
- Automatic bid refunds
- Winner selection system
- Configurable auction duration

### UI Features
- Modern, responsive design
- Real-time updates
- Dynamic item preview
- Easy-to-use interface
- Mobile-friendly layout
- Smooth animations
- Framework-specific styling

## Framework Bridge 🌉

The system includes a sophisticated framework bridge that:
- Automatically detects and adapts to your framework
- Provides consistent API across frameworks
- Handles inventory management
- Manages money transactions
- Processes notifications
- Handles player data

## Support 💡

For support:
1. Join our [Discord](https://discord.gg/fourtwenty)
2. Visit [fourtwenty.dev](https://fourtwenty.dev)
3. Create an issue on GitHub

## License 📄

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

---
Made with ❤️ by [FourTwentyDev](https://fourtwenty.dev)
