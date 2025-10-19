function init()
  -- add manually your shaders from /data/shaders

  -- map shaders
  g_shaders.createShader("map_default", "/shaders/map_default_vertex", "/shaders/map_default_fragment")  

  g_shaders.createShader("map_rainbow", "/shaders/map_rainbow_vertex", "/shaders/map_rainbow_fragment")
  g_shaders.addTexture("map_rainbow", "/images/shaders/rainbow.png")
  
  g_shaders.createShader("map_snow", "/shaders/map_snow_vertex", "/shaders/map_snow_fragment")
  g_shaders.addTexture("map_snow", "/images/shaders/snow.png")

  -- use modules.game_interface.gameMapPanel:setShader("map_rainbow") to set shader

  -- outfit shaders
  g_shaders.createOutfitShader("outfit_default", "/shaders/outfit_default_vertex", "/shaders/outfit_default_fragment")

  g_shaders.createOutfitShader("outfit_rainbow", "/shaders/outfit_rainbow_vertex", "/shaders/outfit_rainbow_fragment")
  g_shaders.addTexture("outfit_rainbow", "/images/shaders/rainbow.png")

  g_shaders.createShader("map_nightvision", "/shaders/map_default_vertex", "/shaders/map_nightvision_fragment")
  -- Bind hotkey (for example, F9)
  g_keyboard.bindKeyDown('F9', function()
    local gameMapPanel = modules.game_interface.getMapPanel()
    local mapPanel = modules.game_interface.gameMapPanel
    if mapPanel:getShader() == "map_nightvision" then
      mapPanel:setShader("map_default")
      gameMapPanel:setDrawLights(true)
      g_game.talk('Night vision off')
    else
      mapPanel:setShader("map_nightvision")
      g_game.talk('Night vision on')
      gameMapPanel:setDrawLights(false)
    end
  end)
  -- you can use creature:setOutfitShader("outfit_rainbow") to set shader

end

function terminate()
end


