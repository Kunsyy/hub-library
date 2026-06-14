/**
 * Daftarin slash command ke Discord (jalanin sekali / tiap ubah command).
 *
 * Cara pakai:
 *   APP_ID=xxx BOT_TOKEN=yyy node register-commands.js
 *
 * APP_ID    = Application ID (Discord Dev Portal -> General Information)
 * BOT_TOKEN = Bot Token      (Discord Dev Portal -> Bot -> Reset Token)
 */

const APP_ID = process.env.APP_ID;
const BOT_TOKEN = process.env.BOT_TOKEN;

if (!APP_ID || !BOT_TOKEN) {
  console.error("Set APP_ID dan BOT_TOKEN dulu. Contoh:");
  console.error("  APP_ID=123 BOT_TOKEN=abc node register-commands.js");
  process.exit(1);
}

const commands = [
  { name: "getkey", description: "Get your free Kunsy Hub key (1 day, 1 device)" },
  {
    name: "resethwid",
    description: "Reset the device lock on your key",
    options: [{ name: "key", description: "Your key", type: 3, required: true }],
  },
  {
    name: "keyinfo",
    description: "Check a key's tier, devices and expiry",
    options: [{ name: "key", description: "Your key", type: 3, required: true }],
  },
];

const url = `https://discord.com/api/v10/applications/${APP_ID}/commands`;

fetch(url, {
  method: "PUT",
  headers: {
    "Authorization": `Bot ${BOT_TOKEN}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify(commands),
})
  .then(async (r) => {
    const txt = await r.text();
    if (r.ok) console.log("✅ Commands registered:\n", txt);
    else console.error("❌ Failed (" + r.status + "):\n", txt);
  })
  .catch((e) => console.error("Error:", e));
