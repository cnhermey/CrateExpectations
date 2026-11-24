# Changelog

## 0.3.0 (2026-11-24)
- New name: **Crate Expectations** (it was called Waylaid while in testing). The command is now `/crate`.
- Your settings and everything it learned carry over.

## 0.2.2 (2026-11-24)
- Artisan crates show 20 (white) and 40 (green) Merchant's Favor, from Wowhead's guide, instead of a "?".
- Filled crates ("Sealed Apprentice Crate" and so on) now get the Favor badge too, going by their white or green quality.
- A hand-in doubled by the Performance Bonus perk no longer changes the amount shown for that crate.

## 0.2.1 (2026-11-24)
- The Merchant's Favor badge now sits centered along the top of the crate icon, so it no longer covers the stack count.

## 0.2.0 (2026-11-24)
- Crates in your bags show the Merchant's Favor icon and how much Favor they give, in the bottom-left corner. Works in Blizzard's bags and EllesmereUI Bags.
- Crate tooltips get a "Merchant's Favor" line.
- Amounts start from player reports (Artisan marked "?" until confirmed). When you hand in a crate, the addon remembers the Favor you actually got and uses that from then on.
- New settings: "Show Favor on crate icons" and "Show Favor on crate tooltips".

## 0.1.0 (2026-11-24)
- First test version.
- Waylaid crate tooltips show what each bundle costs at the Auction House, from Auctionator's last scan.
- Shows the price of one item in gray, and the cheapest bundle in green.
- Says "unknown item" or "no price" instead of guessing.
- `/crate test` shows a sample crate tooltip; `/crate probe` gives a report to send back.
