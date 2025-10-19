-- CraftNet.lua — OTClientV8 (OTAcademy) compatible
-- Uses ProtocolGame:sendExtendedOpcode via g_game.getProtocolGame()
-- Line format only: "VER:<v>;PAGE:<p>/<tot>\n<rows...>"
-- Auto-requests remaining pages and calls CraftUI.onRecipes(...) when done.

CraftNet = CraftNet or {
  opcode      = 120,
  _registered = false,
  collectors  = {},   -- key -> { version, total, rows={}, pagesReceived={} }
  requests    = {},   -- key -> base filters (without page)
  cache       = {}
}

-- ---------- helpers ----------

local function sendOpcode(op, payload)
  local pg = g_game.getProtocolGame and g_game.getProtocolGame() or nil
  if pg then
    pg:sendExtendedOpcode(op, payload or "")
  else
    -- queue if you prefer; for now just log
    print(string.format('[crafting] protocol not ready; skip opcode %d', op))
  end
end

local function makeKey(f)
  return string.format('station=%s|tag=%s|search=%s|per=%s',
    tostring(f.station or ''), tostring(f.tag or ''),
    tostring(f.search or ''), tostring(f.per or ''))
end

local function parseRecipesRow(line)
  local t = {}
  local rid, level, stamina, dura, matsStr, cat, subcat = line:match("([^;]+);([^;]+);([^;]+);([^;]+);([^;]*);([^;]*);([^;]*)")
  local mats = {}
  for id, count in matsStr:gmatch("(%d+)x(%d+)") do
    mats[tonumber(id)] = { count = tonumber(count) }
  end
  t = {
    rid = tonumber(rid),
    levelRequired = tonumber(level),
    staminaRequired = tonumber(stamina),
    durability = tonumber(dura),
    materials = mats,
    category = cat,
    subcategory = subcat
  }
  return t
end

local function collectAndDrive(pkt, key)
  local c = CraftNet.collectors[key]
  if not c or c.version ~= pkt.version then
    c = { version = pkt.version, total = pkt.total, rows = {}, pagesReceived = {} }
    CraftNet.collectors[key] = c
  end

  if not c.pagesReceived[pkt.page] then
    c.pagesReceived[pkt.page] = true
    for _,r in ipairs(pkt.rows) do c.rows[#c.rows+1] = r end
  end

  local got = 0
  for _ in pairs(c.pagesReceived) do got = got + 1 end

  if got < c.total then
    -- fetch first missing page
    local nextPage
    for p = 1, c.total do if not c.pagesReceived[p] then nextPage = p; break end end
    local base = CraftNet.requests[key]
    if nextPage and base then sendRecipesListRequest(base, nextPage) end
    return
  end

  table.sort(c.rows, function(a,b) return (a.id or 0) < (b.id or 0) end)
  CraftNet.cache[key .. '|ver=' .. tostring(c.version)] = { rows = c.rows }

  CraftData.setRecipesList(c.rows)
  if CraftUI and CraftUI.onRecipes then
    --CraftUI.onRecipes(c.rows, { version = c.version, pages = c.total })
  end
  CraftNet.collectors[key] = nil
end

local function parseRecipes(data)
  local lines = {}
  for s in data:gmatch('[^\n]+') do lines[#lines+1] = s end
  local msg = lines[1] or ''
  local hdr = lines[2] or ''
  local ver = tonumber(hdr:match('VER:(%d+)')) or 0
  local pCur, pTot = hdr:match('PAGE:(%d+)%/(%d+)')
  local page  = tonumber(pCur or '1') or 1
  local total = tonumber(pTot or '1') or 1

  local rows = {}
  for i = 3, #lines do
    rows[#rows+1] = parseRecipesRow(lines[i])
  end
  local key = _G.CraftCurrentKey or makeKey({})
  collectAndDrive({ version = ver, page = page, total = total, rows = rows }, key)
end

local function sendRecipesListRequest(per, page)
  local cmd = ('recipes page=%d per=%d'):format(page, per)
  sendOpcode(CraftNet.opcode, cmd)
end

local function sendRecipesLegendRequest(per, page)
  local cmd = 'legend'
  sendOpcode(CraftNet.opcode, cmd)
end

local function sendPlayerStateRequest(per, page)
  local cmd = 'player_state'
  sendOpcode(CraftNet.opcode, cmd)
end

local function parseRecipesLegend(data)
  local lines = {}
  for s in data:gmatch('[^\n]+') do lines[#lines+1] = s end
  local msg = lines[1] or ''
  local rows = {}
  for i = 2, #lines do
    local serverId, clientId, name = lines[i]:match("([^;]+);([^;]+);([^;]+)")
    rows[#rows+1] = { serverId = serverId, clientId = clientId, name = name }
  end
  CraftData.setRecipesLegend(rows)
end

function parsePlayerState(data)
  local lines = {}
  for s in data:gmatch('[^\n]+') do
    lines[#lines+1] = s
  end
  local msg = lines[1] or ''
  local playerdata = lines[2] or ''
  local craftingLevel = playerdata:match("([^;]+)")
  local rows = {}
  for i = 3, #lines do
    local serverId, count = lines[i]:match("([^;]+);([^;]+)")
    rows[#rows+1] = { serverId = serverId, count = count }
  end
  CraftUI.onPlayerState({ craftingLevel = craftingLevel, items = rows})
end

-- ---------- public API ----------

function CraftNet.requestRecipesList()
  sendRecipesListRequest(200, 1)
end

function CraftNet.requestRecipesLegendList()
  sendRecipesLegendRequest()
end

function CraftNet.requestPlayerState()
  sendPlayerStateRequest()
end

function CraftNet.requestCraft(id, station)
  sendOpcode(CraftNet.opcode, ('craft id=%d station=%s'):format(id, tostring(station or '')))
end

-- Some builds require the feature bit; harmless if already on.
function CraftNet.ensureFeature()
  if g_game.getFeature and not g_game.getFeature(GameExtendedOpcode) then
    if g_game.enableFeature then g_game.enableFeature(GameExtendedOpcode) end
  end
end

function CraftNet.registerOpcode()
  if CraftNet._registered then return end
  ProtocolGame.registerExtendedOpcode(CraftNet.opcode, function(_, _, data)
    local id = data:match("^MSG:(.-)\n")
    -- control replies
    -- if data:sub(1,3) == 'ERR' then
    --   displayErrorBox('Crafting', data); return
    -- end
    -- if data:sub(1,4) == 'DONE' then
    --   local id = tonumber(data:match('id=(%d+)') or '-1')
    --   displayInfoBox('Crafting', 'Crafted recipe #' .. id)
    --   if CraftUI and CraftUI.onCrafted then CraftUI.onCrafted(id) end
    --   return
    -- end
    -- page
    if id then
      if id == "recipes" then
        parseRecipes(data)
      elseif id == "legend" then
        parseRecipesLegend(data)
      elseif id == "player_state" then
        parsePlayerState(data)
      end
    end
  end)
  CraftNet._registered = true
end
