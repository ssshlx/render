local HttpService = game:GetService("HttpService")

return function(player)
    local apiUrl = "https://depazzhub-api.onrender.com/log"
    
    local data = {
        username = player.Name,
        displayName = player.DisplayName,
        userId = player.UserId,
        gameId = game.PlaceId
    }
    
    local success, err = pcall(function()
        HttpService:PostAsync(apiUrl, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
    
    return success, err
end
