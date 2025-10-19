-- Simple fishing: press random key from ASDFGHJKL within a time window.
fishingQTE = {}

-- ===== Config =====
local cfg = {

}

-- ===== State =====
local ui = nil
local running = false

local agilityPercent = 0
local agilityPercentGrow = true
local fishingPercent = 50
local fishingSuccessBonus = 0
local windowSize = 15
local windowMin = 0
local windowMax = 0

local function setOverlayRangePercent(testBarWrap, aPct, bPct)
  if not testBarWrap then return end
  local layer = testBarWrap:getChildById('overlayLayer')
  local range = layer and layer:getChildById('overlayRange') or nil
  if not (layer and range) then return end

  aPct = math.max(0, math.min(100, tonumber(aPct or 40)))
  bPct = math.max(0, math.min(100, tonumber(bPct or 60)))
  if bPct < aPct then aPct, bPct = bPct, aPct end

  local w = testBarWrap:getWidth()
  if w <= 0 then
    addEvent(function() setOverlayRangePercent(testBarWrap, aPct, bPct) end)
    return
  end

  local x1 = math.floor(w * (aPct / 100))
  local x2 = math.floor(w * (bPct / 100))
  local ww = math.max(2, x2 - x1)
  range:setWidth(ww)
  range:setMarginLeft(x1)
end

local function setBarPercent(testBarWrap, pct)
  if not testBarWrap then return end
  local bar    = testBarWrap:getChildById('bar')
  local cursor = testBarWrap:getChildById('cursor')
  pct = math.max(0, math.min(100, tonumber(pct or 0)))
  if bar and bar.setPercent then bar:setPercent(pct) end
  if cursor then
    local w = testBarWrap:getWidth()
    local x = math.floor(w * (pct / 100))
    cursor:setMarginLeft(x - math.floor(cursor:getWidth() / 2))
  end
end

local function attachTestBarAutoLayout(testBarWrap, aPct, bPct, currentPctGetter)
  if not testBarWrap then return end
  testBarWrap.onGeometryChange = function()
    setOverlayRangePercent(testBarWrap, aPct, bPct)
    if currentPctGetter then setBarPercent(testBarWrap, currentPctGetter()) end
  end
  setOverlayRangePercent(testBarWrap, aPct, bPct)
  if currentPctGetter then setBarPercent(testBarWrap, currentPctGetter()) end
end

local function setHitCursor(pct)
  local agilityBar = ui:getChildById('agilityBar')
  local bar = agilityBar:getChildById('bar')
  local cursor = agilityBar:getChildById('cursorHit')
  if cursor then
    cursor:show()
    local w = bar:getWidth()
    local x = math.floor(w * (pct / 100))
    cursor:setMarginLeft(x - math.floor(cursor:getWidth() / 2))
  end
end

-- ===== Small helpers =====
local function clearEvent(e) if e then removeEvent(e) end return nil end

local function setText(id, txt)
  if not ui then return end
  local w = ui:getChildById(id); if w then w:setText(txt or "") end
end

local function setColor(id, color)
  if not ui then return end
  local w = ui:getChildById(id); if w then w:setColor(color) end
end

local function setPercent(id, percent)
  if not ui then return end
  local w = ui:getChildById(id); if w then w:setPercent(percent) end
end

-- Flash effect (small visual feedback)
local function flash(id, flashColor, backColor, durationMs)
  if not ui then return end
  local w = ui:getChildById(id); if not w then return end
  local old = w:getColor()
  w:setColor(flashColor or backColor or old)
  scheduleEvent(function() w:setColor(backColor or old) end, durationMs or 120)
end

local function rollNewWindow(newWindowSize)
  if newWindowSize then
    windowSize = newWindowSize
  end
  windowMin = math.random(0, 100 - windowSize)
  windowMax = windowMin + windowSize

  local agilityBar = ui:getChildById('agilityBar')
  setOverlayRangePercent(agilityBar , windowMin, windowMax)
end

local function handleHit()
  local agilityBar = ui:getChildById('agilityBar')
  local cursorHit = agilityBar:getChildById('cursorHit')

  setHitCursor(agilityPercent)
  if agilityPercent >= windowMin and agilityPercent <= windowMax then
    fishingSuccessBonus = fishingSuccessBonus + 30
    cursorHit:setBackgroundColor('#05c005')
    if fishingPercent + fishingSuccessBonus >= 100 then
      return fishingQTE.finish(true)
    end
    rollNewWindow()
  else
    fishingSuccessBonus = fishingSuccessBonus - 20
    cursorHit:setBackgroundColor('#c20a0a')
  end
end

function fishingQTE.agilityTick()
  local fishingChange = 0
  if fishingSuccessBonus ~= 0 then
    local absBonus = math.abs(fishingSuccessBonus)
    local signPositive = fishingSuccessBonus > 0

    local change = 0
    if absBonus < 0.5 then
      fishingSuccessBonus = 0
    else
      fishingChange = fishingSuccessBonus / 10
      fishingSuccessBonus = fishingSuccessBonus - (fishingSuccessBonus / 10)
    end
  else
    fishingChange = - 0.04
  end

  fishingPercent = fishingPercent + fishingChange

  if agilityPercentGrow then
    agilityPercent = agilityPercent + 0.4 + (50 - math.abs(agilityPercent - 50)) / 400
    if agilityPercent >= 100 then
      agilityPercentGrow = false
    end
  else
    agilityPercent = agilityPercent - 0.4 - (50 - math.abs(agilityPercent - 50)) / 400
    if agilityPercent <= 0 then
      agilityPercentGrow = true
    end
  end

  local agilityBar = ui:getChildById('agilityBar')
  setBarPercent(agilityBar, agilityPercent)
  local fishingBar = ui:getChildById('fishingBar')
  setPercent('fishingBar', fishingPercent)

  if fishingPercent <= 0 then
    return fishingQTE.finish(false)
  elseif fishingPercent >= 100 then
    return fishingQTE.finish(true)
  end

  agiltyTickEvent = clearEvent(agiltyTickEvent)
  agiltyTickEvent = scheduleEvent(function() fishingQTE.agilityTick() end, 4)
end
-- ===== Public API =====
function fishingQTE.start(required)
  if running then return end
  running = true
  if tonumber(required) then cfg.requiredSuccesses = math.max(1, tonumber(required)) end

  if not ui then
    displayErrorBox('Fishing', 'UI not created — check .otui import.')
    running = false
    return
  end

  agilityPercent = 0
  agilityPercentGrow = true
  fishingPercent = 50
  fishingSuccessBonus = 0
  rollNewWindow()

  -- reset UI
  setText('title', 'Fishing')
  setText('prompt', 'Press space to catch')

  ui:show(); ui:raise(); ui:focus()
  ui:grabKeyboard()  -- <<< grab keyboard: block other in-game keys while active

  local agilityBar = ui:getChildById('agilityBar')
  attachTestBarAutoLayout(agilityBar, windowMin, windowMax, function() return agilityPercent end)
  local cursorHit = agilityBar:getChildById('cursorHit')
  cursorHit:hide()

  local fishingBar = ui:getChildById('fishingBar')
  setPercent('fishingBar', fishingPercent)

  testEvent = clearEvent(testEvent)
  testEvent = scheduleEvent(function() fishingQTE.agilityTick() end, 1000)
end

function fishingQTE.finish(success)
  if not running then return end
  running = false
  timeoutEvent = clearEvent(timeoutEvent)
  nextPromptEvent = clearEvent(nextPromptEvent)

  -- release keyboard + close
  if ui then
    ui:ungrabKeyboard()
    if success then
      setText('prompt', 'Fish caught!')
    else
      setText('title', 'Fishing cancelled')
      setText('prompt', 'Fishing cancelled!')
    end
    scheduleEvent(function() if ui then ui:hide() end end, 1000)
  end

  -- (optional) send result to server via extended opcode
  -- local OPCODE_FISHING_QTE = 112
  -- g_game.sendExtendedOpcode(OPCODE_FISHING_QTE, success and "done:1" or "done:0")
end

-- ===== Module lifecycle =====
local function importOk(path)
  local ok, err = pcall(function() g_ui.importStyle(path) end)
  if not ok then print('[fishing_qte] importStyle error:', err); return false end
  return true
end

local function createOk(style, parent)
  local ok, res = pcall(function() return g_ui.createWidget(style, parent) end)
  if not ok or not res then print('[fishing_qte] createWidget failed:', res); return nil end
  return res
end

function init()
  local function build()
    if not importOk('fishing_qte.otui') then return end
    if not g_ui.getStyle('FishingQTESimple') then importOk('/modules/fishing_qte/fishing_qte.otui') end
    if not g_ui.getStyle('FishingQTESimple') then
      print('[fishing_qte] style missing (FishingQTESimple)'); return
    end
    local root = g_ui.getRootWidget()
    if not root then return addEvent(build) end

    ui = createOk('FishingQTESimple', root)
    if not ui then return end
    ui:hide()

    -- Widget-level keyboard handling (so we can block others while grabbed)
    ui.onKeyDown = function(self, key)
      if not running then return true end

      -- ESC closes QTE
      if key == KeyEscape then
        fishingQTE.finish(false)
        return true
      end

      if key ~= KeySpace then
        return true
      end
      handleHit()

      return true  -- consume
    end

    -- Hotkeys for testing:
    g_keyboard.bindKeyDown('F1', function() fishingQTE.start(3) end)
    g_keyboard.bindKeyDown('F2', function() fishingQTE.finish(false) end)
  end
  build()
end

function terminate()
  if running then fishingQTE.finish(false) end
  if ui then ui:destroy(); ui = nil end
end
