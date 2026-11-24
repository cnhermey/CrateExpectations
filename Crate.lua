-- CrateExpectations: adds Auction House costs to Waylaid crate tooltips.
--
-- A crate's tooltip lists bundles like "- 20 Dream Dust". For each bundle we
-- look up Auctionator's last-scanned price for one item and multiply by the
-- amount. That's the cheapest listing times the amount: if fewer are listed
-- at that price, buying them all costs more, so the header says "estimate".
--
-- Forever notes: we only post-hook tooltips (TooltipDataProcessor) and add
-- lines; we never change Blizzard's lines or write fields on the tooltip.
-- Tooltip text is checked with ns.Str in case the game hands back a secret.
local _, ns = ...

local C = {
  crates = 0,        -- crate tooltips we added costs to
  priced = 0,        -- bundle lines with a price
  noPrice = {},      -- item name -> true: known item, no Auctionator price
  unknown = {},      -- item name -> true: name we couldn't turn into an ID
  hook = "none",
}
ns.Crate = C

-- English tooltip text. Other languages: see README "Needs in-game verification".
local CRATE_HINT = "Fill the crate"
local CRATE_NAME = "^Waylaid"

---------------------------------------------------------------------------
-- Prices and money text
---------------------------------------------------------------------------
-- Price of one item in copper from Auctionator, or nil.
function C:UnitPrice(id)
  local api = Auctionator and Auctionator.API and Auctionator.API.v1
  if not (api and api.GetAuctionPriceByItemID and id) then return nil end
  local p = ns.Try("Auctionator price", api.GetAuctionPriceByItemID, ns.ADDON_NAME, id)
  p = tonumber(p)
  if p and p > 0 then return p end
  return nil
end

-- Blizzard's coin text with icons, like Auctionator's own tooltip lines.
function C:Money(copper)
  copper = math.floor(copper + 0.5)
  if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
    local s = ns.Try("GetCoinTextureString", C_CurrencyInfo.GetCoinTextureString, copper)
    if s then return s end
  end
  if GetMoneyString then
    local s = ns.Try("GetMoneyString", GetMoneyString, copper, true)
    if s then return s end
  end
  local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
  if g > 0 then return string.format("%dg %ds %dc", g, s, c) end
  if s > 0 then return string.format("%ds %dc", s, c) end
  return string.format("%dc", c)
end

---------------------------------------------------------------------------
-- Reading the tooltip
---------------------------------------------------------------------------
-- Bundles from the tooltip's text lines: { { count = 20, name = "Dream Dust" }, ... }
-- Returns nil if this isn't a crate that lists bundles.
function C:Parse(texts)
  local isCrate = false
  for i, t in ipairs(texts) do
    if string.find(t, CRATE_HINT, 1, true) or (i == 1 and string.find(t, CRATE_NAME)) then
      isCrate = true
      break
    end
  end
  if not isCrate then return nil end
  local bundles = {}
  for _, t in ipairs(texts) do
    -- One tooltip line can hold several bundle lines separated by newlines.
    for part in string.gmatch(t .. "\n", "(.-)\r?\n") do
      local n, name = string.match(part, "^%s*%-%s*(%d+)%s+(.-)%s*$")
      n = tonumber(n)
      if n and n > 0 and name and name ~= "" then
        bundles[#bundles + 1] = { count = n, name = name }
      end
    end
  end
  if #bundles == 0 then return nil end
  return bundles
end

---------------------------------------------------------------------------
-- Adding the lines
---------------------------------------------------------------------------
function C:AddCosts(tooltip, bundles)
  local UI = ns.UI
  local cheapest, cheapestTotal, pricedCount = nil, nil, 0
  for _, b in ipairs(bundles) do
    b.id = ns.Items:Lookup(b.name)
    b.each = b.id and self:UnitPrice(b.id)
    if b.each then
      b.total = b.each * b.count
      pricedCount = pricedCount + 1
      if not cheapestTotal or b.total < cheapestTotal then
        cheapest, cheapestTotal = b, b.total
      end
    end
  end
  if not ns.db.markCheapest or pricedCount < 2 then cheapest = nil end

  tooltip:AddLine("Bundle costs (Auctionator estimate)", UI.GOLD.r, UI.GOLD.g, UI.GOLD.b)
  for _, b in ipairs(bundles) do
    local left = b.count .. " " .. b.name
    local right
    if b.total then
      right = self:Money(b.total)
      if ns.db.showEach and b.count > 1 then
        left = left .. " " .. UI.Wrap(UI.GRAY, "(" .. self:Money(b.each) .. " each)")
      end
      self.priced = self.priced + 1
    elseif b.id then
      right = UI.Wrap(UI.GRAY, "no price")
      self.noPrice[b.name] = true
    else
      right = UI.Wrap(UI.GRAY, "unknown item")
      self.unknown[b.name] = true
    end
    local c = (b == cheapest) and UI.GREEN or UI.WHITE
    tooltip:AddDoubleLine(left, right, c.r, c.g, c.b, 1, 1, 1)
  end
  self.crates = self.crates + 1
end

-- Text of every left line, from tooltip data when there is some, else from
-- the tooltip's own font strings.
local function Texts(tooltip, data)
  local out = {}
  if type(data) == "table" and type(data.lines) == "table" then
    for _, line in ipairs(data.lines) do
      local t = ns.Str(line.leftText)
      if t then out[#out + 1] = t end
    end
  end
  if #out == 0 and tooltip.GetName and tooltip.NumLines then
    local name = tooltip:GetName()
    if name then
      for i = 1, tooltip:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local t = fs and ns.Str(fs:GetText())
        if t then out[#out + 1] = t end
      end
    end
  end
  return out
end

function C:OnItemTooltip(tooltip, data)
  if not ns.db or not tooltip or not tooltip.AddDoubleLine then return end
  if tooltip.IsForbidden and tooltip:IsForbidden() then return end
  local texts = Texts(tooltip, data)
  local id = type(data) == "table" and tonumber(ns.Clean(data.id))
  ns.Items:FromTooltip(id, texts[1])
  self:AddLines(tooltip, id, texts)
end

-- Our block under the item text: Favor line, then bundle costs.
-- `id` can be nil (test tooltip); the item name in texts[1] is used then.
function C:AddLines(tooltip, id, texts)
  local nameLink = texts[1] and ("[" .. texts[1] .. "]")
  local favor = ns.db.showFavorTooltip and ns.Favor:ForItem(id, nameLink)
  local bundles = ns.db.enabled and self:Parse(texts)
  if not (favor or bundles) then return end
  tooltip:AddLine(" ")
  if favor then ns.Favor:AddTooltipLine(tooltip, id, nameLink) end
  if bundles then self:AddCosts(tooltip, bundles) end
  tooltip:Show() -- resize to fit the new lines
end

local function Hook()
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
     and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      ns.Try("crate tooltip", C.OnItemTooltip, C, tooltip, data)
    end)
    C.hook = "TooltipDataProcessor"
    return
  end
  -- Older clients: hook the two tooltips players see items in.
  for _, tip in ipairs({ GameTooltip, ItemRefTooltip }) do
    if tip and tip.HookScript then
      pcall(tip.HookScript, tip, "OnTooltipSetItem", function(self)
        local _, link = self:GetItem()
        local id = link and tonumber(string.match(link, "item:(%d+)"))
        ns.Try("crate tooltip", C.OnItemTooltip, C, self, { id = id })
      end)
      C.hook = "OnTooltipSetItem"
    end
  end
end
ns.Listen("INIT", Hook)

---------------------------------------------------------------------------
-- Test: the crate from the README screenshot, with real prices.
---------------------------------------------------------------------------
function C:Test()
  local tip = GameTooltip
  tip:SetOwner(UIParent, "ANCHOR_NONE")
  tip:ClearAllPoints()
  tip:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
  tip:SetText("Waylaid Crate: Artisan Curiosities (test)", 1, 1, 1)
  local use = "Use: Fill the crate with any bundle from the following list:\n"
    .. "- 20 Dream Dust\n- 4 Greater Nether Essence\n- 6 Small Brilliant Shard\n- 2 Large Brilliant Shard"
  tip:AddLine(use, 0.1, 1, 0.1, true)
  self:AddLines(tip, nil, { "Waylaid Crate: Artisan Curiosities (test)", use })
  tip:Show()
  C_Timer.After(20, function()
    if tip:IsShown() and tip:GetOwner() == UIParent then tip:Hide() end
  end)
  ns.Print("Test tooltip shown. It closes when another tooltip opens, or in 20 seconds.")
end
