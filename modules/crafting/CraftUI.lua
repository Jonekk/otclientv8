CraftUI = CraftUI or { window=nil, list=nil, recipes={}, station='forge', indexToId={} }

craftingWindow = nil
recipesPanel = nil
radioTabs = nil
radioItems = nil
craftingPanel = nil
craftingCenterBox = nil
tabsBar = nil
initialized = false

selectedItem = nil

local function setActiveTab(btn)
  for _, child in ipairs(tabsBar:getChildren()) do
    child:setOn(child == btn)   -- "on" is the TabButton’s active state
    child:setChecked(child == btn) -- some skins use checked, this keeps both in sync
  end
end

function CraftUI.open(opts)
  craftingWindow = g_ui.displayUI('CraftWindow')
  craftingWindow:setVisible(false)

  recipesPanel = craftingWindow:recursiveGetChildById('recipesPanel')
  tabsBar = craftingWindow:getChildById('tabsBar')
  craftingPanel = craftingWindow:getChildById('craftingPanel')
  craftingCenterBox = craftingPanel:getChildById('craftingCenterBox')

  radioTabs = UIRadioGroup.create()
  radioTabs.onSelectionChange = onTradeTypeChange
  --buyTab = craftingWindow:getChildById('buyTab')
  --sellTab = craftingWindow:getChildById('sellTab')

  show()

  CraftNet.requestRecipesList()
  CraftNet.requestRecipesLegendList()
  CraftNet.requestPlayerState()
end

function onItemBoxChecked(widget)
  if widget:isChecked() then
    local item = widget.item
    selectedItem = item
  end
end

function onTradeTypeChange(radioTabs, selected, deselected)
  selected:setOn(true)
  if deselected then
    deselected:setOn(false)
  end
  refreshRecipesListUI()
end

function refreshRecipesListUI()
  local layout = recipesPanel:getLayout()
  layout:disableUpdates()
  recipesPanel:destroyChildren()

  if radioItems then
    radioItems:destroy()
  end
  radioItems = UIRadioGroup.create()

  local selectedCategoryTab = radioTabs:getSelectedWidget()
  local selectedCategoryId = selectedCategoryTab:getId()

  for _,item in pairs(CraftUI.recipes) do
    if item.category == selectedCategoryId then
      local subcategoryWidget = recipesPanel:getChildById(item.subcategory)
      if not subcategoryWidget then
        subcategoryWidget = g_ui.createWidget('SubcategoryWidget', recipesPanel)
        subcategoryWidget:setId(item.subcategory)
        subcategoryWidget.header:setText(item.subcategory)
      end

      local body   = subcategoryWidget:getChildById('body')
      local itemBox = g_ui.createWidget('CraftItemBox', body)

      local clientId, itemName = CraftData.getItemDecription(item.rid)
      local tempItem = Item.create(clientId)

      itemBox.item = item
      local itemWidget = itemBox:getChildById('item')
      print(item.rid, clientId, itemName)
      itemBox:setText(itemName)

      itemWidget:setItem(tempItem)
      itemWidget.onMouseRelease = itemPopup
      radioItems:addWidget(itemBox)
    end
  end
  layout:enableUpdates()
  layout:update()
end

function show()
  craftingWindow:show()
  craftingWindow:raise()
  craftingWindow:focus()
end

function CraftUI.onPlayerState(playerdata)
  CraftUI.recipes = CraftData.getRecipesForPlayer(playerdata)

  local categories = {}
  for _, r in ipairs(CraftUI.recipes) do

    if not table.exists(categories, r.category) then
      table.insert(categories, r.category)
    end
  end

  local fistVisible = nil
  for _, category in ipairs(categories) do
    local btn = g_ui.createWidget('CategoryButton', tabsBar)
    btn:setId(category)
    btn:setText(category)
    btn:setWidth(100)
    radioTabs:addWidget(btn)
    if not fistVisible then
      fistVisible = btn
      radioTabs:selectWidget(fistVisible)
    end
  end

  refreshRecipesListUI()
  addEvent(show)
end

function CraftUI.onRecipeChecked(selectedWidget)
  local clientId, itemName = CraftData.getItemDecription(selectedWidget.item.rid)
  local layout = craftingCenterBox:getLayout()
  layout:disableUpdates()
  craftingCenterBox:destroyChildren()

  for mId, materialInfo in pairs(selectedWidget.item.materials) do
    local materialWidget = g_ui.createWidget('MaterialWidget', craftingCenterBox)
    local itemWidget = materialWidget:getChildById('item')
    local countWidget = materialWidget:getChildById('itemCount')
    local nameWidget = materialWidget:getChildById('itemName')

    local mClientId, mItemName = CraftData.getItemDecription(mId)
    print("  material " .. mClientId .. " " .. mItemName)
    local tempItem = Item.create(mClientId)
    nameWidget:setText(mItemName)
    itemWidget:setItem(tempItem)
  end

  local materialsLabel = craftingPanel:getChildById('materialsLabel')
  materialsLabel:setVisible(true)
  layout:enableUpdates()
  layout:update()
end

function CraftUI.craftSelected()
  local r = CraftUI.selectedRow
  if not r then
    displayInfoBox("Crafting", "Select a recipe first.")
    return
  end
  CraftNet.requestCraft(r.id, CraftUI.station)
end
