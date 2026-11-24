-- Crate Expectations: event dispatch, internal message bus, saved settings.
local addonName, ns = ...

---------------------------------------------------------------------------
-- One event frame, many handlers.
-- Events that may not exist on this client are registered with pcall.
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local handlers = {}

frame:SetScript("OnEvent", function(_, event, ...)
  local list = handlers[event]
  if not list then return end
  for i = 1, #list do
    list[i](event, ...)
  end
end)

function ns.On(event, fn)
  if not handlers[event] then
    handlers[event] = {}
    if not pcall(frame.RegisterEvent, frame, event) then
      ns.Debug("Event not available:", event)
    end
  end
  table.insert(handlers[event], fn)
end

---------------------------------------------------------------------------
-- Internal message bus (not WoW events).
---------------------------------------------------------------------------
local listeners = {}

function ns.Listen(msg, fn)
  listeners[msg] = listeners[msg] or {}
  table.insert(listeners[msg], fn)
end

function ns.Fire(msg, ...)
  local list = listeners[msg]
  if not list then return end
  for i = 1, #list do
    list[i](...)
  end
end

---------------------------------------------------------------------------
-- Saved settings (account-wide)
---------------------------------------------------------------------------
ns.DEFAULTS = {
  enabled = true,       -- add bundle costs to Waylaid crate tooltips
  showEach = true,      -- also show the price of one item, in gray
  markCheapest = true,  -- color the cheapest fully priced bundle green
  showBadge = true,     -- Favor icon + amount on crate icons in your bags
  showFavorTooltip = true, -- "Merchant's Favor" line on crate tooltips
  learned = nil,        -- item name (lowercase) -> item ID, learned in game
  favor = nil,          -- crate item ID -> Favor actually received at turn-in
  debug = false,
}

ns.On("ADDON_LOADED", function(_, name)
  if name ~= addonName then return end
  CrateExpectationsDB = CrateExpectationsDB or {}
  local db = CrateExpectationsDB
  for k, v in pairs(ns.DEFAULTS) do
    if db[k] == nil then db[k] = v end
  end
  if type(db.learned) ~= "table" then db.learned = {} end
  if type(db.favor) ~= "table" then db.favor = {} end
  db.schema = 1
  ns.db = db
  ns.Fire("INIT")
end)

ns.On("PLAYER_LOGIN", function()
  ns.loggedIn = true
  ns.Fire("LOGIN")
end)
