-- Crate Expectations: turns an item name from a crate tooltip ("Dream Dust") into an
-- item ID, which is what Auctionator's price lookup needs.
--
-- Crate tooltips only show names, and the game only finds an item by name
-- once it has that item's data. So we learn names three ways and remember
-- them in CrateExpectationsDB.learned:
--   1. Known crate materials (SEED below): we ask the game for each ID's
--      name at login. The name always comes from the game, never from this
--      file, so a wrong ID here can't map a name to the wrong item.
--   2. Items in your bags.
--   3. Any item tooltip you see.
-- If a name is still unknown, the tooltip says so instead of guessing.
local _, ns = ...

local I = { seen = 0, seedAsked = 0, seedLearned = 0 }
ns.Items = I

-- Classic trade goods that Waylaid crates are likely to ask for.
local SEED = {
  -- Enchanting: dust, essences, shards
  10940, 11083, 11137, 11176, 16204,
  10938, 10939, 10998, 11082, 11134, 11135, 11174, 11175, 16202, 16203,
  10978, 11084, 11138, 11139, 11177, 11178, 14343, 14344, 20725,
  -- Cloth and bolts
  2589, 2592, 4306, 4338, 14047, 14256, 2996, 2997, 4305, 4339, 14048,
  -- Ore and bars
  2770, 2771, 2772, 2775, 2776, 3858, 7911, 10620,
  2840, 3576, 2841, 3575, 3859, 2842, 3577, 3860, 6037, 12359,
  -- Leather
  2318, 2319, 4234, 4304, 8170,
  -- Herbs
  765, 785, 2447, 2449, 2450, 2452, 2453, 3355, 3356, 3357, 3358, 3818, 3820,
  3821, 4625, 8831, 8836, 8838, 8839, 8845, 8846, 13463, 13464, 13465, 13466,
  13467, 13468,
}
local seedSet = {}
for _, id in ipairs(SEED) do seedSet[id] = true end

-- Lowercase, trimmed. Names can contain spaces; only trim the ends.
function I:Key(name)
  name = ns.Str(name)
  if not name then return nil end
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%s+$", "")
  if name == "" then return nil end
  return string.lower(name)
end

function I:Learn(id, name)
  local key = self:Key(name)
  id = tonumber(ns.Clean(id))
  if not key or not id or not ns.db then return end
  if ns.db.learned[key] ~= id then
    ns.db.learned[key] = id
    self.seen = self.seen + 1
  end
end

local function IDFromLink(link)
  link = ns.Str(link)
  return link and tonumber(string.match(link, "item:(%d+)"))
end

local function NameFromLink(link)
  link = ns.Str(link)
  return link and string.match(link, "%[(.-)%]")
end

-- The item ID for a name, or nil if we don't know it yet.
function I:Lookup(name)
  local key = self:Key(name)
  if not key or not ns.db then return nil end
  local id = ns.db.learned[key]
  if id then return id end
  -- The game finds names it already has data for.
  if C_Item and C_Item.GetItemInfoInstant then
    id = tonumber(ns.Clean((ns.Try("GetItemInfoInstant", C_Item.GetItemInfoInstant, name))))
  end
  if not id then
    local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local _, link = ns.Try("GetItemInfo", getInfo, name)
    id = IDFromLink(link)
  end
  if id then self:Learn(id, name) end
  return id
end

---------------------------------------------------------------------------
-- 1. Known materials: ask the game for each name.
---------------------------------------------------------------------------
local function NameByID(id)
  if C_Item and C_Item.GetItemNameByID then
    local n = ns.Str((ns.Try("GetItemNameByID", C_Item.GetItemNameByID, id)))
    if n then return n end
  end
  local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  return ns.Str((ns.Try("GetItemInfo", getInfo, id)))
end

local function LearnSeed()
  for _, id in ipairs(SEED) do
    local name = NameByID(id)
    if name then
      I:Learn(id, name)
      I.seedLearned = I.seedLearned + 1
    elseif C_Item and C_Item.RequestLoadItemDataByID then
      I.seedAsked = I.seedAsked + 1
      ns.Try("RequestLoadItemDataByID", C_Item.RequestLoadItemDataByID, id)
    end
  end
end
ns.Listen("LOGIN", LearnSeed)

ns.On("GET_ITEM_INFO_RECEIVED", function(_, id, ok)
  id = tonumber(ns.Clean(id))
  if not id or not seedSet[id] or ok == false then return end
  local name = NameByID(id)
  if name then
    I:Learn(id, name)
    I.seedLearned = I.seedLearned + 1
  end
end)

---------------------------------------------------------------------------
-- 2. Bags
---------------------------------------------------------------------------
local function ScanBags()
  local C = C_Container
  if not (C and C.GetContainerNumSlots and C.GetContainerItemInfo) then return end
  for bag = 0, (NUM_BAG_SLOTS or 4) + 1 do
    local slots = ns.Clean(ns.Try("GetContainerNumSlots", C.GetContainerNumSlots, bag)) or 0
    for slot = 1, slots do
      local info = ns.Try("GetContainerItemInfo", C.GetContainerItemInfo, bag, slot)
      if type(info) == "table" then
        local link = info.hyperlink
        I:Learn(info.itemID or IDFromLink(link), NameFromLink(link))
      end
    end
  end
end
ns.Listen("LOGIN", ScanBags)
ns.On("BAG_UPDATE_DELAYED", function()
  ns.Debounce("bags", 1, ScanBags)
end)

---------------------------------------------------------------------------
-- 3. Any item tooltip (called from Crate.lua's tooltip hook)
---------------------------------------------------------------------------
function I:FromTooltip(id, firstLine)
  if id and firstLine then self:Learn(id, firstLine) end
end
