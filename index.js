const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();

app.use(express.json());
app.use(cors({
    origin: '*',
    methods: ['POST', 'GET', 'OPTIONS'],
    allowedHeaders: ['Content-Type']
}));

const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK;

// Endpoint para recibir logs
app.post('/log', async (req, res) => {
    try {
        const { username, displayName, userId, gameId } = req.body;
        
        if (!username) {
            return res.status(400).json({ error: "Missing username" });
        }
        
        const payload = {
            content: "🚀 **testb**",
            embeds: [{
                color: 3887359,
                fields: [
                    { name: "👤 Username", value: username, inline: true },
                    { name: "🆔 User ID", value: String(userId || "N/A"), inline: true },
                ],
                footer: { text: "DepazzHub Logger" },
                timestamp: new Date().toISOString()
            }]
        };

        await axios.post(DISCORD_WEBHOOK, payload);
        res.status(200).json({ success: true, message: "Sent to Discord" });
    } catch (error) {
        console.error("Error sending to Discord:", error.message);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Health check
app.get('/', (req, res) => {
    res.json({ 
        status: "✅ API is running!", 
        endpoint: "/log (POST only)",
        webhookConfigured: !!DISCORD_WEBHOOK
    });
});

// Manejar OPTIONS para CORS
app.options('/log', (req, res) => {
    res.sendStatus(200);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
