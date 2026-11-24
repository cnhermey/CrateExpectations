# CurseForge listing for Crate Expectations

Copy these into the CurseForge project form (Author Console → Create Project).

- **Name:** Crate Expectations
- **Game / flavor:** World of Warcraft → Forever
- **Summary** (one line): Earn Merchant's Favor fast: every Waylaid Crate tooltip shows what each bundle costs at the Auction House and marks the cheapest one to buy, using Auctionator prices.
- **Main category:** Auction & Economy
- **Extra categories:** Tooltip, Bags & Inventory
- **Required dependency:** Auctionator
- **License:** All Rights Reserved (matches LICENSE)
- **Logo:** `.github/curseforge-logo.png` (400×400)
- **Source / issues:** https://github.com/cnhermey/CrateExpectations

## Description (Markdown)

**Crate Expectations** is the quick way to earn Merchant's Favor in WoW: Forever: buy the cheapest bundle on the Auction House, fill your Waylaid Crate, and turn it in. Hover a crate to see what every bundle costs, and see at a glance in your bags how much Favor each crate is worth.

No windows, no extra buttons: just a few lines on the crate's tooltip and a small badge on its icon.

---

### Know the cheapest bundle before you buy
A Waylaid Crate lists several bundles, and you only need to fill one. Crate Expectations prices every bundle from your Auctionator scans and marks the cheapest, so you know exactly what to buy:

> **Bundle costs (Auctionator estimate)**
> 20 Dream Dust (17s each) ... 3g 40s
> 4 Greater Nether Essence ... 2g 80s
> **6 Small Brilliant Shard (35s each) ... 2g 10s** ← cheapest, in green
> 2 Large Brilliant Shard ... no price

- **Total for the whole bundle**, not just one item.
- **Price each** in gray, to compare against what you'd pay per item.
- **Cheapest bundle in green.**
- **Never guesses.** An item you haven't scanned says "no price"; an item it can't identify yet says "unknown item".

### Know what each crate pays
Every read or filled crate in your bags shows the **Merchant's Favor icon and the amount it gives**, centered along the top of its icon, clear of the stack count. The crate's tooltip gets a Merchant's Favor line too, so you can weigh the cost of a bundle against the Favor it brings in.

| Tier | White crates (Herbs, Ore, Textiles, Curiosities) | Green crates (Fabrics, Ingots, Parts) |
|---|---|---|
| Apprentice | 5 | 10 |
| Journeyman | 10 | 20 |
| Expert | 15 | 30 |
| Artisan | 20 | 40 |

**It learns the real number.** When you hand in a crate, Crate Expectations notes how much Favor you actually received and shows that for that crate from then on. A hand-in doubled by the Performance Bonus Legacy perk doesn't count, so a lucky turn-in won't change the number.

Works in **Blizzard's bags** and **EllesmereUI Bags**.

### Looks like part of the game
Plain tooltip lines in Blizzard's colors, with the game's own coin icons and its real Merchant's Favor icon. Settings are a normal page in Esc > Options > AddOns > Crate Expectations, where you can turn off each part:
- Show bundle costs
- Show price each
- Mark the cheapest bundle
- Show Favor on crate icons
- Show Favor on crate tooltips

### Requires Auctionator
Crate Expectations reads prices from **Auctionator**, so install it too. Do a full scan at the Auction House, or just search for the materials you need, and the prices appear on your crates.

---

### Good to know
- **Prices are estimates.** It uses the cheapest listing times the amount you need. If fewer are listed at that price, the rest cost more.
- **Unread crates** ("Waylaid Crate" before you read its label) don't have a tier yet, so they get no Favor badge.
- **"Unknown item"** goes away once you've seen the item: hover it anywhere or have it in your bags. Common crafting materials are known from the start.
- **Favor amounts** come from published guides until you've handed in that kind of crate yourself; the tooltip says "published amount" until then.
- **English game client** for now.

### Commands
- `/crate`: settings
- `/crate test`: show a sample crate tooltip with your own prices
- `/crate on` / `off`: turn bundle costs on or off
- `/crate probe`: a report to paste into bug reports

### Install
Install with the CurseForge app or WoWUp, or extract the `CrateExpectations` folder into `World of Warcraft\_forever_\Interface\AddOns\` and restart the game.

Bug reports and ideas: https://github.com/cnhermey/CrateExpectations/issues
