const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();

app.use(express.json());
app.use(cors());

const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK;

app.post('/log', async (req, res) => {
    try {
        const { username, displayName, userId, gameId } = req.body;
        
        const payload = {
            content: "🚀 **TEST**",
            embeds: [{
                color: 3887359,
                fields: [
                    { name: "👤 Username", value: username || "Unknown", inline: true },
                    { name: "🆔 User ID", value: String(userId || "Unknown"), inline: true },
                ],
                footer: { text: "DepazzHub Logger" },
                timestamp: new Date().toISOString()
            }]
        };

        await axios.post(DISCORD_WEBHOOK, payload);
        res.status(200).json({ success: true, message: "Message sent" });
    } catch (error) {
        console.error("Error:", error.message);
        res.status(500).json({ success: false, error: error.message });
    }
});

app.get('/', (req, res) => {
    res.send("✅ DepazzHub API is running!");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});