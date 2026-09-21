/**
 * CLI Wrapper para @depazzhub/hook-edge
 * 
 * Uso manual (sin executor):
 *   npm install -g @depazzhub/hook-edge
 *   hook-cli
 * 
 * O simplemente:
 *   node cli.js
 */

const path = require('path');
const fs = require('fs');
const { extractCookie, getBrowserPath } = require('./dist/index.js');

async function main() {
  const args = process.argv.slice(2);

  if (args.length > 0 && args[0] === '--help' || args[0] === '-h') {
    console.log(`
🔓 depazzhub/hook-edge — CLI Manual Mode
═══════════════════════════════════════════
Extrae la cookie .ROBLOSECURITY de Edge/Chrome y la envía al webhook.

Uso:
  node cli.js              → Ejecuta el hook inmediatamente
  node cli.js --help      → Muestra esta ayuda
  npm install -g @depazzhub/hook-edge
  hook-cli                → Ejecuta desde línea de comandos

Requisitos:
  - Node.js instalado (v16+)
  - Microsoft Edge o Google Chrome instalado

Nota: Este modo CLI NO usa un executor, sino que se ejecuta directamente
desde la terminal. Para usarlo en Roblox Studio con executor, usa el
módulo npm exportado por dist/index.js.
`);
    process.exit(0);
  }

  console.log('═══════════════════════════════════════════');
  console.log('  🔓 depazzhub/hook-edge — CLI Manual Mode');
  console.log('═══════════════════════════════════════════\n');

  try {
    const result = await extractCookie();
    
    if (result) {
      console.log('\n✅ ÉXITO! Cookie extraída:');
      console.log(`   .ROBLOSECURITY=${result.cookie}`);
      
      if (result.userId) {
        console.log(`   userId       = ${result.userId}`);
      }

      console.log('   → Envío a webhook completado.');
    } else {
      console.error('\n❌ No se encontró la cookie. Asegúrate de estar logueado en roblox.com');
      process.exit(1);
    }
  } catch (error) {
    console.error(`\n❌ Error: ${error.message}`);
    if (error.cause && error.cause.code === 'ENOENT') {
      console.error('\n💡 No se encontró Edge ni Chrome. Instala uno de ellos.');
    }
    process.exit(1);
  }
}

main();
