-- CrateExpectations: /crate. Style rules: Blizzard system-message look
-- (ns.Print / ns.PrintLine) and short phrases.
local _, ns = ...
local P = function(text) ns.PrintLine(text) end

local function Yes(v) return ns.UI.Wrap(ns.UI.GREEN, v) end
local function No(v) return ns.UI.Wrap(ns.UI.RED, v) end

local function Has(path)
  local v = _G
  for part in string.gmatch(path, "[^%.]+") do
    if type(v) ~= "table" then return false end
    v = v[part]
  end
  return v ~= nil
end

local function Names(set, limit)
  local list = {}
  for name in pairs(set) do list[#list + 1] = name end
  table.sort(list)
  local more = #list - limit
  for i = #list, limit + 1, -1 do list[i] = nil end
  local s = #list > 0 and table.concat(list, ", ") or "none"
  if more > 0 then s = s .. " +" .. more .. " more" end
  return s
end

-- Developer report: what this client offers, and what the addon has seen.
local function Probe()
  local build, _, _, iface = GetBuildInfo()
  ns.Print("Probe: build", build, "interface", iface, "version", ns.VERSION)
  local apis = {
    "Auctionator.API.v1.GetAuctionPriceByItemID", "Auctionator.Database",
    "TooltipDataProcessor.AddTooltipPostCall", "C_Item.GetItemInfoInstant",
    "C_Item.GetItemNameByID", "C_Item.RequestLoadItemDataByID", "C_Container.GetContainerItemInfo",
    "C_CurrencyInfo.GetCoinTextureString", "C_CurrencyInfo.GetCurrencyInfo", "EUI_Bags.RegisterItemOverlayIcon", "GetMoneyString", "issecretvalue",
    "Settings.RegisterCanvasLayoutCategory",
  }
  local line = {}
  for _, name in ipairs(apis) do
    line[#line + 1] = Has(name) and Yes(name) or No(name)
    if #line == 3 then P("  " .. table.concat(line, "  ")); line = {} end
  end
  if #line > 0 then P("  " .. table.concat(line, "  ")) end

  local C, I = ns.Crate, ns.Items
  local learned = 0
  for _ in pairs(ns.db.learned) do learned = learned + 1 end
  P("  Tooltip hook: " .. C.hook .. " · crate tooltips " .. C.crates .. " · bundles priced " .. C.priced)
  P("  Item names known " .. learned .. " · materials from game " .. I.seedLearned .. " (asked " .. I.seedAsked .. ")")

  local Fv = ns.Favor
  local seenFavor = 0
  for _ in pairs(ns.db.favor) do seenFavor = seenFavor + 1 end
  Fv:Icon()
  P("  Favor icon: " .. (Fv.iconFromGame and Yes("from game " .. tostring(Fv.icon)) or No("fallback")) .. " |T" .. Fv:Icon() .. ":0|t"
    .. " · bag hooks: " .. (#Fv.hooks > 0 and table.concat(Fv.hooks, ", ") or No("none"))
    .. " · badges painted " .. Fv.painted)
  P("  Favor amounts seen at turn-in: " .. seenFavor .. " (this session " .. Fv.learnedNow .. ")")

  -- Dream Dust as a sample: name -> ID -> price.
  local id = I:Lookup("Dream Dust")
  local each = id and C:UnitPrice(id)
  P("  Sample: Dream Dust -> ID " .. tostring(id or "unknown") .. " -> "
    .. (each and (C:Money(each) .. " each") or "no price"))
  P("  Unknown names: " .. Names(C.unknown, 6))
  P("  No Auctionator price: " .. Names(C.noPrice, 6))
end

local function Help()
  ns.Print("commands:")
  P("  /crate: open the settings")
  P("  /crate test: show a sample crate tooltip with real prices")
  P("  /crate on | off: turn crate costs on or off")
  P("  /crate probe: developer report")
end

SLASH_CRATEEXPECTATIONS1 = "/crate"
SLASH_CRATEEXPECTATIONS2 = "/crateexpectations"
SlashCmdList.CRATEEXPECTATIONS = function(msg)
  if not ns.db then return end
  local cmd = string.lower(string.match(msg or "", "^%s*(%S*)") or "")
  if cmd == "" or cmd == "settings" or cmd == "options" or cmd == "config" then
    ns.Options:Open()
  elseif cmd == "test" then
    ns.Crate:Test()
  elseif cmd == "on" or cmd == "off" then
    ns.Options:Set("enabled", cmd == "on")
    ns.Print(cmd == "on" and "On." or "Off.")
  elseif cmd == "probe" then
    Probe()
  else
    Help()
  end
end

ns.Listen("LOGIN", function()
  ns.Debug("v" .. ns.VERSION .. " loaded. /crate for the settings.")
end)
