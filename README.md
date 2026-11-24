# Crate Expectations (v0.3.0)

A small WoW: Forever addon (formerly Waylaid) that shows what each Waylaid crate bundle costs at the Auction House, using Auctionator's prices, and how much Merchant's Favor each crate gives.

- **Bundle costs on the crate tooltip.** Hover a Waylaid crate and each bundle it asks for gets a price: "20 Dream Dust ... 3g 40s".
- **Price each.** The price of one item shows in gray next to the amount.
- **Cheapest bundle in green.** You only need to fill one bundle, so the cheapest one stands out.
- **Merchant's Favor on your crates.** In your bags, each crate shows the Merchant's Favor icon and how much Favor it gives, centered along the top of its icon. Its tooltip gets a "Merchant's Favor" line too. Works in Blizzard's bags and EllesmereUI Bags.
- **Learns the real amount.** When you hand in a crate, Crate Expectations sees how much Favor you got and uses that number for that crate from then on.
- **Never guesses.** Items Crate Expectations can't identify say "unknown item"; items Auctionator hasn't scanned say "no price".

Needs **Auctionator**. Prices are from your last Auctionator scan: the cheapest listing times the amount. If fewer are listed at that price than you need, buying them all costs more, so the header says "estimate".

### Looks like Blizzard's UI
The costs are ordinary tooltip lines in Blizzard's colors with the game's own coin icons. The settings page is a normal Esc > Options > AddOns page with Blizzard checkboxes.

### Merchant's Favor amounts
The game doesn't tell addons how much Favor a crate gives, so Crate Expectations uses the published amounts (Wowhead's Forever supply-faction guides and player reports):

| Tier | White crates (gathered: Herbs, Ore, Textiles, Curiosities) | Green crates (crafted: Fabrics, Ingots, Parts) |
|---|---|---|
| Apprentice | 5 | 10 |
| Journeyman | 10 | 20 |
| Expert | 15 | 30 |
| Artisan | 20 | 40 |

Read crates are matched by the kind in their name; filled crates ("Sealed Apprentice Crate") by their quality, white or green. The tooltip says "published amount" until you've handed in that crate yourself. The Legacy perk Performance Bonus sometimes doubles a hand-in; Crate Expectations shows the normal amount and doesn't learn a doubled one. Unread crates ("Waylaid Crate" with no label) get no badge.

### Item names
Crate tooltips only show item names, and the game only finds an item by name once it has seen it. Crate Expectations learns names from a list of common crafting materials (names come from the game, not the addon), from your bags, and from every item tooltip you see, and remembers them. If a bundle says "unknown item", hover or loot that item once.

## Install
1. Copy the `CrateExpectations` folder into `World of Warcraft\_forever_\Interface\AddOns\`. Copy it; don't symlink it (symlinked folders lose their settings).
2. Make sure Auctionator is installed and turned on.
3. Restart the game or type `/reload`.

Built for Interface 16001. Check yours with `/run print(select(4, GetBuildInfo()))`.

## First in-game test (solo)
1. Do an Auctionator scan at the Auction House (or search for a few crate materials).
2. Type `/crate test`. A sample crate tooltip appears with real prices.
3. Open your bags. Each read crate should show the Merchant's Favor icon and a number along the top.
4. Hover a real Waylaid crate. The Merchant's Favor line and bundle costs should appear under the item text.
5. Hand in a sealed crate, then hover another of the same kind: the "from player reports" note should be gone.
6. Type `/crate probe` and send the output.

## Commands
| Command | What it does |
|---|---|
| `/crate` | Open the settings |
| `/crate test` | Show a sample crate tooltip with real prices |
| `/crate on` / `off` | Turn crate costs on or off |
| `/crate probe` | Developer report |

## How it works
| File | Role |
|---|---|
| `Util.lua` | Shared helpers: secret-value guards, safe calls, chat output, timers |
| `Core.lua` | Events, internal messages, saved settings (`CrateExpectationsDB`) |
| `UI_Common.lua` | Blizzard colors and sounds |
| `Items.lua` | Turns item names into item IDs and remembers them |
| `Crate.lua` | Reads crate tooltips, looks up Auctionator prices, adds the cost lines |
| `Favor.lua` | Merchant's Favor per crate: amounts, learning at turn-in, bag badges, tooltip line |
| `Options.lua` | Settings page |
| `Commands.lua` | `/crate` and the probe report |

The Favor icon comes from the currency itself (`C_CurrencyInfo.GetCurrencyInfo(3402)`). Bag badges use EllesmereUI Bags' public overlay hook (`EUI_Bags.RegisterItemOverlayIcon`) and a post-hook on Blizzard's container frames.

Prices come from Auctionator's public API, `Auctionator.API.v1.GetAuctionPriceByItemID`. Crate Expectations only adds lines after the game builds a tooltip (`TooltipDataProcessor`); it never changes Blizzard's lines.

## Needs in-game verification
- Crate tooltips are found by the text "Fill the crate" or an item name starting with "Waylaid" (English client only for now).
- The bundle list arrives in the tooltip data as one line with line breaks, as in the screenshot; Crate Expectations also handles one bundle per line.
- `C_Item.GetItemNameByID` and `RequestLoadItemDataByID` fill in the known materials at login (probe: "materials from game").
- The crafting materials keep their classic item IDs on Forever (Dream Dust 11176; probe "Sample" line).
- Auctionator keys plain materials by item ID, so `GetAuctionPriceByItemID` finds them.
- Merchant's Favor is currency 3402 and its icon comes back from `GetCurrencyInfo` (probe: "Favor icon: from game").
- Read crates are named "Waylaid Crate: <Tier> <Kind>".
- Turn-in learning: the Favor gain (`CURRENCY_DISPLAY_UPDATE`) and the crate leaving your bags happen within 3 seconds (probe: "Favor amounts seen at turn-in").
- Favor amounts: Artisan 20 / 40 comes from Wowhead's guide; no in-game report yet.
- Filled crates are named "Sealed <Tier> Crate" and are white or green like the crate they came from.
