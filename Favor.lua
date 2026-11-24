-- Crate Expectations: Merchant's Favor per crate, shown as a badge on the crate's bag
-- icon (Favor icon + amount, top center) and as a line on its tooltip.
--
-- How much Favor a crate gives isn't in the game data addons can read, so we
-- use the published amounts (Wowhead's Forever supply-faction guides and
-- player reports, Nov 2026). They go by tier and quality:
--   White (gathered: Herbs, Ore, Textiles, Curiosities): 5 / 10 / 15 / 20
--   Green (crafted: Fabrics, Ingots, Parts):            10 / 20 / 30 / 40
--   for Apprentice / Journeyman / Expert / Artisan.
-- Filled crates are named like "Sealed Apprentice Crate" (no kind word), so
-- when the name has no kind we go by item quality: white or green.
-- When you hand a crate in, we see how much Favor you got and remember it for
-- that crate's item ID. The Legacy perk Performance Bonus sometimes doubles a
-- hand-in; a gain of exactly double isn't learned, so it can't stick.
--
-- Bags: EllesmereUI Bags has a public overlay hook (RegisterItemOverlayIcon);
-- Blizzard's bags get a post-hook on each container frame's update. Badges are
-- our own frames, kept in our own table, never fields on someone else's button.
local _, ns = ...

local F = {
  CURRENCY = 3402,                                   -- Merchant's Favor
  FALLBACK_ICON = "Interface\\Icons\\Racial_Dwarf_FindTreasure",
  painted = 0, learnedNow = 0, hooks = {},
}
ns.Favor = F

local TIERS = { apprentice = 1, journeyman = 2, expert = 3, artisan = 4 }
local KIND = {
  herbs = "gathered", ore = "gathered", textiles = "gathered", curiosities = "gathered",
  fabrics = "crafted", ingots = "crafted", parts = "crafted",
}
local REPORTED = { gathered = { 5, 10, 15, 20 }, crafted = { 10, 20, 30, 40 } }
local QUALITY_KIND = { [1] = "gathered", [2] = "crafted" } -- white, green

---------------------------------------------------------------------------
-- Favor for an item
---------------------------------------------------------------------------
local function NameOf(id, link)
  local n = link and ns.Str(link) and string.match(link, "%[(.-)%]")
  if n then return n end
  if id and C_Item and C_Item.GetItemNameByID then
    return ns.Str((ns.Try("GetItemNameByID", C_Item.GetItemNameByID, id)))
  end
  return nil
end

-- Tier and kind from names like "Waylaid Crate: Artisan Curiosities".
local function Parse(name)
  local lower = name and string.lower(name)
  if not lower or not string.find(lower, "crate", 1, true) then return nil end
  local tier, kind
  for word in string.gmatch(lower, "%a+") do
    tier = tier or TIERS[word]
    kind = kind or KIND[word]
  end
  return tier, kind
end

local function Quality(id)
  if not id then return nil end
  if C_Item and C_Item.GetItemQualityByID then
    local q = tonumber(ns.Clean((ns.Try("GetItemQualityByID", C_Item.GetItemQualityByID, id))))
    if q then return q end
  end
  local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  return tonumber(ns.Clean((select(3, ns.Try("GetItemInfo", getInfo, id)))))
end

-- The published amount for a crate, or nil.
function F:Reported(id, link)
  local tier, kind = Parse(NameOf(id, link))
  if not tier then return nil end
  kind = kind or QUALITY_KIND[Quality(id) or 0]
  if not kind then return nil end
  return REPORTED[kind][tier]
end

-- Returns amount, where it came from ("seen" | "reported"), or nil.
function F:ForItem(id, link)
  id = tonumber(ns.Clean(id))
  if not ns.db then return nil end
  if id and ns.db.favor[id] then return ns.db.favor[id], "seen" end
  local amount = self:Reported(id, link)
  if amount then return amount, "reported" end
  return nil
end

function F:IsCrate(id, link)
  local name = NameOf(id, link)
  return name ~= nil and string.find(string.lower(name), "crate", 1, true) ~= nil
end

-- Blizzard's Merchant's Favor icon, from the currency itself.
function F:Icon()
  if self.icon then return self.icon end
  if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
    local info = ns.Try("GetCurrencyInfo", C_CurrencyInfo.GetCurrencyInfo, self.CURRENCY)
    local icon = type(info) == "table" and ns.Clean(info.iconFileID)
    if icon then
      self.icon, self.iconFromGame = icon, true
      return icon
    end
  end
  return self.FALLBACK_ICON
end

function F:Text(amount)
  return tostring(amount)
end

---------------------------------------------------------------------------
-- Learn the real amount on turn-in: a Favor gain and one crate leaving your
-- bags within a few seconds of each other.
---------------------------------------------------------------------------
local lastCounts, gain, removed = nil, nil, nil
local WINDOW = 3

local function Match()
  if not (gain and removed) then return end
  local expected = F:Reported(removed.id)
  if math.abs(gain.t - removed.t) > WINDOW then
    -- not the same hand-in
  elseif expected and gain.amount == expected * 2 then
    ns.Debug("Performance Bonus doubled", expected, "Favor; not learned")
  else
    ns.db.favor[removed.id] = gain.amount
    F.learnedNow = F.learnedNow + 1
    ns.Debug("Learned", gain.amount, "Favor for crate", removed.id)
    ns.Fire("FAVOR_LEARNED")
  end
  gain, removed = nil, nil
end

local function CountCrates()
  local C = C_Container
  if not (C and C.GetContainerNumSlots and C.GetContainerItemInfo) then return nil end
  local counts = {}
  for bag = 0, (NUM_BAG_SLOTS or 4) + 1 do
    local slots = ns.Clean(ns.Try("GetContainerNumSlots", C.GetContainerNumSlots, bag)) or 0
    for slot = 1, slots do
      local info = ns.Try("GetContainerItemInfo", C.GetContainerItemInfo, bag, slot)
      local id = type(info) == "table" and tonumber(ns.Clean(info.itemID))
      if id and F:IsCrate(id, info.hyperlink) then
        counts[id] = (counts[id] or 0) + (ns.Clean(info.stackCount) or 1)
      end
    end
  end
  return counts
end

local function OnBags()
  local now = CountCrates()
  if not now then return end
  if lastCounts then
    local gone
    for id, n in pairs(lastCounts) do
      if (now[id] or 0) < n then
        if gone then gone = false break end -- more than one crate left: don't guess
        gone = id
      end
    end
    if gone then
      removed = { id = gone, t = GetTime() }
      Match()
    end
  end
  lastCounts = now
end
ns.Listen("LOGIN", OnBags)
ns.On("BAG_UPDATE_DELAYED", OnBags)

ns.On("CURRENCY_DISPLAY_UPDATE", function(_, id, _, change)
  id, change = tonumber(ns.Clean(id)), tonumber(ns.Clean(change))
  if id ~= F.CURRENCY or not change or change <= 0 then return end
  gain = { amount = change, t = GetTime() }
  Match()
end)

---------------------------------------------------------------------------
-- Badges on bag icons
---------------------------------------------------------------------------
local badges = setmetatable({}, { __mode = "k" })

local function GetBadge(btn, parent)
  local b = badges[btn]
  if b then return b end
  b = CreateFrame("Frame", nil, parent or btn)
  -- Top center: the stack count sits bottom-right, item level top-left.
  b:SetSize(12, 12)
  b:SetPoint("TOP", btn, "TOP", 0, -2)
  b:SetFrameLevel((parent or btn):GetFrameLevel() + 2)
  b.icon = b:CreateTexture(nil, "OVERLAY")
  b.icon:SetSize(12, 12)
  b.icon:SetPoint("LEFT", b, "LEFT", 0, 0)
  b.text = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  b.text:SetPoint("LEFT", b.icon, "RIGHT", 1, 0)
  b:Hide()
  badges[btn] = b
  return b
end

function F:Paint(btn, id, link, parent)
  if not btn then return end
  local amount, how
  if ns.db and ns.db.showBadge and id then amount, how = self:ForItem(id, link) end
  if not amount then
    local b = badges[btn]
    if b then b:Hide() end
    return
  end
  local b = GetBadge(btn, parent)
  b.icon:SetTexture(self:Icon())
  b.text:SetText(self:Text(amount))
  -- Size to icon + text so the pair stays centered.
  b:SetWidth(12 + 1 + math.ceil(b.text:GetStringWidth() or 0))
  b:Show()
  self.painted = self.painted + 1
end

-- EllesmereUI Bags: its public overlay hook runs for every painted slot.
local function HookEllesmere()
  if not (EUI_Bags and EUI_Bags.RegisterItemOverlayIcon) then return end
  EUI_Bags.RegisterItemOverlayIcon("CrateExpectations", function(btn, data)
    local info = data and data.info
    local id = type(info) == "table" and info.itemID
    F:Paint(btn, id, data.itemLink, btn._textOverlay)
  end)
  F.hooks[#F.hooks + 1] = "EllesmereUI Bags"
end

-- Blizzard bags: post-hook each container frame's item update.
local function PaintBlizzardButton(button)
  if not (button and button.GetBagID and button.GetID) then return end
  local bag, slot = button:GetBagID(), button:GetID()
  local info = C_Container and C_Container.GetContainerItemInfo
    and ns.Try("GetContainerItemInfo", C_Container.GetContainerItemInfo, bag, slot)
  local id = type(info) == "table" and info.itemID
  F:Paint(button, id, type(info) == "table" and info.hyperlink or nil)
end

local function HookBlizzard()
  local frames = { ContainerFrameCombinedBags }
  for i = 1, (NUM_CONTAINER_FRAMES or 13) do frames[#frames + 1] = _G["ContainerFrame" .. i] end
  local n = 0
  for _, frame in ipairs(frames) do
    if frame and frame.UpdateItems and frame.EnumerateValidItems then
      hooksecurefunc(frame, "UpdateItems", function(self)
        for _, button in self:EnumerateValidItems() do
          ns.Try("paint Blizzard bag", PaintBlizzardButton, button)
        end
      end)
      n = n + 1
    end
  end
  if n > 0 then F.hooks[#F.hooks + 1] = "Blizzard bags (" .. n .. ")" end
end

ns.Listen("INIT", function()
  if type(ns.db.favor) ~= "table" then ns.db.favor = {} end
  ns.Try("hook EllesmereUI Bags", HookEllesmere)
  ns.Try("hook Blizzard bags", HookBlizzard)
end)

-- Repaint open bags after a setting change or a newly learned amount.
local function Repaint()
  if EUI_Bags and EUI_Bags.IsShown and EUI_Bags:IsShown() and EUI_Bags.RefreshInventory then
    ns.Try("refresh EllesmereUI Bags", EUI_Bags.RefreshInventory, EUI_Bags)
  end
  local frames = { ContainerFrameCombinedBags }
  for i = 1, (NUM_CONTAINER_FRAMES or 13) do frames[#frames + 1] = _G["ContainerFrame" .. i] end
  for _, frame in ipairs(frames) do
    if frame and frame:IsShown() and frame.UpdateItems then
      ns.Try("refresh Blizzard bags", frame.UpdateItems, frame)
    end
  end
end
ns.Listen("FAVOR_LEARNED", function() ns.Debounce("repaint", 0.2, Repaint) end)
ns.Listen("SETTINGS_CHANGED", function(key)
  if key == "showBadge" then ns.Debounce("repaint", 0.2, Repaint) end
end)

---------------------------------------------------------------------------
-- Tooltip line (called from Crate.lua for every item tooltip)
---------------------------------------------------------------------------
function F:AddTooltipLine(tooltip, id, link)
  if not (ns.db and ns.db.showFavorTooltip) then return false end
  local amount, how = self:ForItem(id, link)
  if not amount then return false end
  local icon = "|T" .. self:Icon() .. ":0|t"
  local note = (how == "seen") and "" or " (published amount)"
  local UI = ns.UI
  tooltip:AddDoubleLine("Merchant's Favor" .. UI.Wrap(UI.GRAY, note), icon .. " " .. amount,
    UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 1, 1, 1)
  return true
end
