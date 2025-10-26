
-- AzerothJourney.lua
-- Through the Ages: Max-Level World Tour Addon

local ADDON_NAME = ...
local AJ = {}
AzerothJourney = AJ

AJ.state = { phase = 1, step = 1 }
AJ.defaults = { lock = false, scale = 1.0, transparency = 0.9 }
AJ.DB = AJ.DB or {}

local function p(...) DEFAULT_CHAT_FRAME:AddMessage("|cff4ae0ff[AzerothJourney]|r " .. table.concat({tostringall(...)}, " ")) end

-- Waypoint helpers
local function setBlizzardWaypoint(uiMapID, x, y, title)
  if not uiMapID or not x or not y then return end
  local wp = UiMapPoint.CreateFromCoordinates(uiMapID, x/100.0, y/100.0)
  C_Map.SetUserWaypoint(wp)
  if title then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
  p("Waypoint set:", title or "", string.format("(%.1f, %.1f)", x, y))
end

local function setTomTomWaypoint(uiMapID, x, y, title)
  if TomTom then
    TomTom:AddWaypoint(uiMapID, x/100.0, y/100.0, { title = title or "AzerothJourney" })
    p("TomTom waypoint:", title or "", string.format("(%.1f, %.1f)", x, y))
    return true
  end
  return false
end

function AJ:SetWaypoint(step)
  if not step then return end
  if not setTomTomWaypoint(step.uiMapID, step.x, step.y, step.title) then
    setBlizzardWaypoint(step.uiMapID, step.x, step.y, step.title)
  end
end

function AJ:GetCurrent()
  local phase = AzerothJourney_Data and AzerothJourney_Data.phases[AJ.state.phase]
  if not phase then return nil, nil end
  local step = phase.steps[AJ.state.step]
  return phase, step
end

function AJ:Next()
  local phase = AzerothJourney_Data.phases[AJ.state.phase]
  AJ.state.step = AJ.state.step + 1
  if AJ.state.step > #phase.steps then
    AJ.state.phase = math.min(AJ.state.phase + 1, #AzerothJourney_Data.phases)
    AJ.state.step = 1
  end
  AJ:RefreshUI()
end

function AJ:Prev()
  if AJ.state.step > 1 then
    AJ.state.step = AJ.state.step - 1
  elseif AJ.state.phase > 1 then
    AJ.state.phase = AJ.state.phase - 1
    AJ.state.step = #AzerothJourney_Data.phases[AJ.state.phase].steps
  end
  AJ:RefreshUI()
end

function AJ:Reset() AJ.state.phase, AJ.state.step = 1, 1; AJ:RefreshUI() end

-- UI Frame
local frame = CreateFrame("Frame", "AJ_MainFrame", UIParent, "BackdropTemplate")
frame:SetSize(420, 145)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) if not AJ.DB.lock then self:StartMoving() end end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 24,
  insets = { left = 8, right = 8, top = 8, bottom = 8 } })
frame:SetBackdropColor(0, 0, 0, AJ.defaults.transparency)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Through the Ages")

local phaseText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
phaseText:SetPoint("TOPRIGHT", -16, -20)

local stepText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
stepText:SetPoint("TOPLEFT", 16, -46)
stepText:SetJustifyH("LEFT")
stepText:SetWidth(380)

local btnPrev = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
btnPrev:SetPoint("BOTTOMLEFT", 16, 12); btnPrev:SetSize(80, 24); btnPrev:SetText("Prev")
btnPrev:SetScript("OnClick", function() AJ:Prev() end)

local btnWaypoint = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
btnWaypoint:SetPoint("BOTTOM", 0, 12); btnWaypoint:SetSize(120, 24); btnWaypoint:SetText("Set Waypoint")
btnWaypoint:SetScript("OnClick", function() local _, s = AJ:GetCurrent(); if s then AJ:SetWaypoint(s) end end)

local btnNext = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
btnNext:SetPoint("BOTTOMRIGHT", -16, 12); btnNext:SetSize(80, 24); btnNext:SetText("Next")
btnNext:SetScript("OnClick", function() AJ:Next() end)

function AJ:RefreshUI()
  local phase, step = AJ:GetCurrent()
  if not phase or not step then stepText:SetText("No steps loaded."); return end
  phaseText:SetText(string.format("Phase %d/%d  Step %d/%d", AJ.state.phase, #AzerothJourney_Data.phases, AJ.state.step, #phase.steps))
  local lines = { string.format("|cffffff00[%s]|r %s", phase.title, step.title or "") }
  if step.quest then table.insert(lines, "• Quest: " .. step.quest) end
  if step.note then table.insert(lines, "• " .. step.note) end
  if step.x and step.y then table.insert(lines, string.format("• Coords: %.1f, %.1f", step.x, step.y)) end
  stepText:SetText(table.concat(lines, "\n"))
end

-- Max level check
local function checkLevel()
  if UnitLevel("player") < 80 then
    AJ.locked = true; frame:Hide()
    p("Through the Ages is available at level 80+. Keep leveling!")
  else
    AJ.locked = false; frame:Show(); AJ:RefreshUI(); p("Welcome to Through the Ages!")
  end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LEVEL_UP")
ev:SetScript("OnEvent", function(_, e, n)
  if e=="ADDON_LOADED" and n==ADDON_NAME then
    AzerothJourneyDB = AzerothJourneyDB or {}
    AJ.DB = setmetatable(AzerothJourneyDB, { __index = AJ.defaults })
    C_Timer.After(0.1, checkLevel)
  elseif e=="PLAYER_LEVEL_UP" then
    checkLevel()
  end
end)

SLASH_AZEROTHJOURNEY1 = "/wtg"
SlashCmdList["AZEROTHJOURNEY"] = function(msg)
  if AJ.locked then p("Through the Ages unlocks at level 80.") return end
  msg = msg:lower()
  if msg=="next" then AJ:Next()
  elseif msg=="prev" then AJ:Prev()
  elseif msg=="reset" then AJ:Reset()
  elseif msg=="way" then local _, s=AJ:GetCurrent(); if s then AJ:SetWaypoint(s) end
  else p("Commands: /wtg next, prev, reset, way") end
end
