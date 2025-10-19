CraftData = CraftData or {recipesList = {}, recipesLegend = {} }

recipesList = {}
recipesLegend = {}

function CraftData.setRecipesList(recipesList)
    CraftData.recipesList = recipesList
end

function CraftData.setRecipesLegend(recipesLegend)
    CraftData.recipesLegend = recipesLegend
end

function CraftData.getRecipesForPlayer(playerState)
    -- todo dodać filtrowanie
    return CraftData.recipesList
end

function CraftData.getItemDecription(serverId)
    for _, item in ipairs(CraftData.recipesLegend) do
        if tonumber(item.serverId) == serverId then
            return tonumber(item.clientId), item.name
        end
    end
    return nil, nil
end