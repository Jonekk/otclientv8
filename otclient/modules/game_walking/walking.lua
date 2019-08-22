smartWalkDirs = {}
smartWalkDir = nil
wsadWalking = false
nextWalkDir = nil
lastWalkDir = nil
lastFinishedStep = 0
autoWalkEvent = nil
firstStep = true
walkLock = 0
lastWalk = 0
lastTurn = 0
lastTurnDirection = 0

function init()
  connect(LocalPlayer, {
    onPositionChange = onPositionChange,
    onWalk = onWalk,
    onTeleport = onTeleport,
    onWalkFinish = onWalkFinish
  })

  modules.game_interface.getRootPanel().onFocusChange = stopSmartWalk
  bindKeys()
end

function terminate()
  disconnect(LocalPlayer, {
    onPositionChange = onPositionChange,
    onWalk = onWalk,
    onTeleport = onTeleport,
    onWalkFinish = onWalkFinish
  })
  removeEvent(autoWalkEvent)
  stopSmartWalk()
  unbindKeys()
  disableWSAD()
end

function bindKeys()
  bindWalkKey('Up', North)
  bindWalkKey('Right', East)
  bindWalkKey('Down', South)
  bindWalkKey('Left', West)
  bindWalkKey('Numpad8', North)
  bindWalkKey('Numpad9', NorthEast)
  bindWalkKey('Numpad6', East)
  bindWalkKey('Numpad3', SouthEast)
  bindWalkKey('Numpad2', South)
  bindWalkKey('Numpad1', SouthWest)
  bindWalkKey('Numpad4', West)
  bindWalkKey('Numpad7', NorthWest)

  bindTurnKey('Ctrl+Up', North)
  bindTurnKey('Ctrl+Right', East)
  bindTurnKey('Ctrl+Down', South)
  bindTurnKey('Ctrl+Left', West)
  bindTurnKey('Ctrl+Numpad8', North)
  bindTurnKey('Ctrl+Numpad6', East)
  bindTurnKey('Ctrl+Numpad2', South)
  bindTurnKey('Ctrl+Numpad4', West)
end

function unbindKeys()
  unbindWalkKey('Up', North)
  unbindWalkKey('Right', East)
  unbindWalkKey('Down', South)
  unbindWalkKey('Left', West)
  unbindWalkKey('Numpad8', North)
  unbindWalkKey('Numpad9', NorthEast)
  unbindWalkKey('Numpad6', East)
  unbindWalkKey('Numpad3', SouthEast)
  unbindWalkKey('Numpad2', South)
  unbindWalkKey('Numpad1', SouthWest)
  unbindWalkKey('Numpad4', West)
  unbindWalkKey('Numpad7', NorthWest)

  unbindTurnKey('Ctrl+Up', North)
  unbindTurnKey('Ctrl+Right', East)
  unbindTurnKey('Ctrl+Down', South)
  unbindTurnKey('Ctrl+Left', West)
  unbindTurnKey('Ctrl+Numpad8', North)
  unbindTurnKey('Ctrl+Numpad6', East)
  unbindTurnKey('Ctrl+Numpad2', South)
  unbindTurnKey('Ctrl+Numpad4', West)
end

function enableWSAD()
  if wsadWalking then
    return
  end
  wsadWalking = true  
  local player = g_game.getLocalPlayer()
  if player then
    player:lockWalk(100) -- 100 ms walk lock for all directions    
  end

  bindWalkKey("W", North)
  bindWalkKey("D", East)
  bindWalkKey("S", South)
  bindWalkKey("A", West)

  bindTurnKey("Ctrl+W", North)
  bindTurnKey("Ctrl+D", East)
  bindTurnKey("Ctrl+S", South)
  bindTurnKey("Ctrl+A", West)

  bindWalkKey("E", NorthEast)
  bindWalkKey("Q", NorthWest)
  bindWalkKey("C", SouthEast)
  bindWalkKey("Z", SouthWest)
end

function disableWSAD()
  if not wsadWalking then
    return
  end
  wsadWalking = false

  unbindWalkKey("W")
  unbindWalkKey("D")
  unbindWalkKey("S")
  unbindWalkKey("A")

  unbindTurnKey("Ctrl+W")
  unbindTurnKey("Ctrl+D")
  unbindTurnKey("Ctrl+S")
  unbindTurnKey("Ctrl+A")

  unbindWalkKey("E")
  unbindWalkKey("Q")
  unbindWalkKey("C")
  unbindWalkKey("Z")
end

function bindWalkKey(key, dir)
  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyDown(key, function() changeWalkDir(dir) end, gameRootPanel, true)
  g_keyboard.bindKeyUp(key, function() changeWalkDir(dir, true) end, gameRootPanel, true)
  g_keyboard.bindKeyPress(key, function() smartWalk(dir) end, gameRootPanel)
end

function unbindWalkKey(key)
  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.unbindKeyDown(key, gameRootPanel)
  g_keyboard.unbindKeyUp(key, gameRootPanel)
  g_keyboard.unbindKeyPress(key, gameRootPanel)
end

function bindTurnKey(key, dir)
  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyDown(key, function() turn(dir, false) end, gameRootPanel)
  g_keyboard.bindKeyPress(key, function() turn(dir, true) end, gameRootPanel)
end

function unbindTurnKey(key)
  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.unbindKeyDown(key, gameRootPanel)
  g_keyboard.unbindKeyPress(key, gameRootPanel)
end

function stopSmartWalk()
  smartWalkDirs = {}
  smartWalkDir = nil
end

function changeWalkDir(dir, pop)
  while table.removevalue(smartWalkDirs, dir) do end
  if pop then
    if #smartWalkDirs == 0 then
      stopSmartWalk()
      return
    end
  else
    table.insert(smartWalkDirs, 1, dir)
  end

  smartWalkDir = smartWalkDirs[1]
  if modules.client_options.getOption('smartWalk') and #smartWalkDirs > 1 then
    for _,d in pairs(smartWalkDirs) do
      if (smartWalkDir == North and d == West) or (smartWalkDir == West and d == North) then
        smartWalkDir = NorthWest
        break
      elseif (smartWalkDir == North and d == East) or (smartWalkDir == East and d == North) then
        smartWalkDir = NorthEast
        break
      elseif (smartWalkDir == South and d == West) or (smartWalkDir == West and d == South) then
        smartWalkDir = SouthWest
        break
      elseif (smartWalkDir == South and d == East) or (smartWalkDir == East and d == South) then
        smartWalkDir = SouthEast
        break
      end
    end
  end
end

function smartWalk(dir)
  if g_keyboard.getModifiers() == KeyboardNoModifier then
    local direction = smartWalkDir or dir
    walk(direction)
    return true
  end
  return false
end

function canChangeFloorDown(pos)
  pos.z = pos.z + 1
  toTile = g_map.getTile(pos)
  return toTile and toTile:hasElevation(3)
end

function canChangeFloorUp(pos)
  pos.z = pos.z - 1
  toTile = g_map.getTile(pos)
  return toTile and toTile:isWalkable()
end

function onPositionChange(player, newPos, oldPos)

end

function onWalk(player, newPos, oldPos)

end

function onTeleport(player, newPos, oldPos)
  -- floor change is also teleport
  if math.abs(newPos.x - oldPos.x) >= 3 or math.abs(newPos.y - oldPos.y) >= 3 or math.abs(newPos.z - oldPos.z) >= 2 then  
    -- far teleport, lock walk for 100ms
    walkLock = g_clock.millis() + g_settings.getNumber('walkTeleportDelay')
  else
    walkLock = g_clock.millis() + g_settings.getNumber('walkStairsDelay')
  end
  nextWalkDir = nil -- cancel autowalk
end

function onWalkFinish(player)
  lastFinishedStep = g_clock.millis()
  if nextWalkDir ~= nil then
    removeEvent(autoWalkEvent)
    autoWalkEvent = addEvent(function() if nextWalkDir ~= nil then walk(nextWalkDir) end end, false)
  end
end

function walk(dir) 
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  if g_game.isFollowing() then
    g_game.cancelFollow()
  end

  if player:isAutoWalking() or player:isServerWalking() then
    if player:isAutoWalking() then
      player:stopAutoWalk()
    end
    g_game.stop()
  end
  
  if player:isWalkLocked() then
    return
  end
  
  local ticksToNextWalk = player:getStepTicksLeft()
  if not player:canWalk(dir) then -- canWalk return false when previous  walk is not finished or not confirmed by server
    if ticksToNextWalk < 500 and lastWalkDir ~= dir then
      nextWalkDir = dir
    end
    if ticksToNextWalk < 20 and lastFinishedStep + 400 > g_clock.millis() and nextWalkDir == nil then -- clicked walk 20 ms too early, try to execute again as soon possible to keep smooth walking
      nextWalkDir = dir
    end
    return
  end

  if nextWalkDir ~= nil and nextWalkDir ~= lastWalkDir then 
    dir = nextWalkDir
  end

  local toPos = player:getNewPreWalkingPosition(true)
  if dir == North then
    toPos.y = toPos.y - 1
  elseif dir == East then
    toPos.x = toPos.x + 1
  elseif dir == South then
    toPos.y = toPos.y + 1
  elseif dir == West then
    toPos.x = toPos.x - 1
  elseif dir == NorthEast then
    toPos.x = toPos.x + 1
    toPos.y = toPos.y - 1
  elseif dir == SouthEast then
    toPos.x = toPos.x + 1
    toPos.y = toPos.y + 1
  elseif dir == SouthWest then
    toPos.x = toPos.x - 1
    toPos.y = toPos.y + 1
  elseif dir == NorthWest then
    toPos.x = toPos.x - 1
    toPos.y = toPos.y - 1
  end
  local toTile = g_map.getTile(toPos)

  if walkLock >= g_clock.millis() and lastWalkDir == dir then
    return
  end

  if firstStep and lastWalkDir == dir and lastWalk + g_settings.getNumber('walkFirstStepDelay') > g_clock.millis() then
    firstStep = false
    walkLock = lastWalk + g_settings.getNumber('walkFirstStepDelay')
    return
  end

  firstStep = not player:isWalking() and lastFinishedStep + 100 < g_clock.millis() and walkLock + 100 < g_clock.millis()
  nextWalkDir = nil
  removeEvent(autoWalkEvent)
  autoWalkEvent = nil

  local preWalked = false
  if toTile and toTile:isWalkable() then
    if g_game.getFeature(GameNewWalking) then
      player:newPreWalk(dir)
    else
      player:preWalk(dir)
    end
    preWalked = true
  else
    local playerTile = player:getTile()
    if (playerTile and playerTile:hasElevation(3) and canChangeFloorUp(toPos)) or canChangeFloorDown(toPos) or (toTile and toTile:isEmpty() and not toTile:isBlocking()) then
      player:lockWalk(100)
    else
      return
    end
  end
  
  g_game.callOnWalk(dir)
  g_game.forceWalk(dir, preWalked)  
  
  if not firstStep and lastWalkDir ~= dir then
    walkLock = g_clock.millis() + g_settings.getNumber('walkTurnDelay')    
  end
  
  lastWalkDir = dir
  lastWalk = g_clock.millis()
end

function turn(dir, repeated)
  if not repeated or (lastTurnDirection == dir and lastTurn + 50 < g_clock.millis()) then
    g_game.turn(dir)
    changeWalkDir(dir)
    lastTurn = g_clock.millis()
    if not repeated then
      lastTurn = g_clock.millis() + 100
    end
    lastTurnDirection = dir
  end
end
