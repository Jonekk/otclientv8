filename =  nil
loaded = false

function init()
  connect(g_game, { onClientVersionChange = load })
end

function terminate()
  disconnect(g_game, { onClientVersionChange = load })
end

function setFileName(name)
  filename = name
end

function isLoaded()
  return loaded
end

function load()
  local version = g_game.getClientVersion()
  local things = g_settings.getNode('things')
  
  local datPath, sprPath
  if things["data"] ~= nil and things["sprites"] ~= nil then
    datPath = '/data/things/' .. things["data"]
    if G.hdSprites and things["sprites_hd"] then
      sprPath = '/data/things/' .. things["sprites_hd"]    
    else
      sprPath = '/data/things/' .. things["sprites"]
    end
  else  
    if filename then
      datPath = resolvepath('/things/' .. filename)
      sprPath = resolvepath('/things/' .. filename)
      if G.hdSprites then
        local hdsprPath = resolvepath('/things/' .. filename .. '_hd')      
        if g_resources.fileExists(hdsprPath) then
          sprPath = hdsprPath
        end
      end
    else
      datPath = resolvepath('/things/' .. version .. '/Tibia')
      sprPath = resolvepath('/things/' .. version .. '/Tibia')
      if G.hdSprites then
        local hdsprPath = resolvepath('/things/' .. version .. '/Tibia_hd')      
        if g_resources.fileExists(hdsprPath) then
          sprPath = hdsprPath
        end
      end
    end
  end

  local errorMessage = ''
  if not g_things.loadDat(datPath) then
    errorMessage = errorMessage .. tr("Unable to load dat file, please place a valid dat in '%s'", datPath) .. '\n'
  end
  if not g_sprites.loadSpr(sprPath, G.hdSprites or false) then
    errorMessage = errorMessage .. tr("Unable to load spr file, please place a valid spr in '%s'", sprPath)
  end

  loaded = (errorMessage:len() == 0)

  if errorMessage:len() > 0 then
    local messageBox = displayErrorBox(tr('Error'), errorMessage)
    addEvent(function() messageBox:raise() messageBox:focus() end)

    disconnect(g_game, { onClientVersionChange = load })
    g_game.setClientVersion(0)
    g_game.setProtocolVersion(0)
    connect(g_game, { onClientVersionChange = load })
  end
end
