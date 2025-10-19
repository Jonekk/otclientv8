local _f3Bound = false

function CraftBootstrap()
  local function ready()
    if not ProtocolGame or not g_ui or not g_game then return addEvent(ready) end
    CraftNet.registerOpcode()
    -- optional: CraftNet.ensureFeature()
    if not _f3Bound then
      g_keyboard.bindKeyDown('F3', function() CraftUI.open({ station = 'forge', per = 200 }) end)
      _f3Bound = true
    end
  end
  ready()
end

function CraftShutdown()
  if _f3Bound then g_keyboard.unbindKeyDown('F3'); _f3Bound = false end
  if CraftUI and CraftUI.window then CraftUI.window:destroy(); CraftUI.window = nil end
end
