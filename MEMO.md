# MEMO — Kunsy Hub Library

> Catatan perjalanan development, fitur yang udah jalan, dan next step.

---

## Stack

- **UI**: Obsidian V2 (local, bukan CDN)
- **Loader**: `loader.lua` → fetch game script dari GitHub CDN
- **Game script**: `games/cook_and_sell.lua`
- **Addons**: SaveManager, ThemeManager
- **Deploy**: push ke branch `main` → loadstring otomatis dapet versi terbaru

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Kunsyy/hub-library/main/loader.lua"))()
```

---

## Fitur yang Udah Jalan ✅

### Tab Farm (Cashier)
- **Auto Cashier + Collect Cash** — deteksi customer di QueuePosition 1, scan bag satu-satu via `ManualCheckoutProgress`, auto collect uang dari register. Fix: double-process bug pakai `customerCooldown` per instance.

### Tab Farm (Kitchen)
- **Auto Manage (Claim)** — claim hasil masak dari KitchenCounter & CookingPot via ProximityPrompt
- **Auto Place** — taruh tool dari inventory ke slot counter display (`PlaceDownItem` remote). Tidak ikut disave oleh SaveManager (selalu mulai OFF).
- **Auto Upgrade** — auto beli upgrade pot, checkout, dan shop fixture

### Tab Shop
- **Buy Shop Item** — dropdown item + tombol Order 1 / Order 5

### Tab Cook
- **Select Recipe (multi-select)** — pilih beberapa resep sekaligus, siklus otomatis 1→2→3→ulang, skip kalau stock habis
- **Auto Cook** — masak otomatis pakai `StartCooking` → `AddIngredient` loop → tunggu `ReadyToClaim` → `ClaimDessert`
- **Pantry (realtime stock)** — tampil di kanan, update tiap 0.5s, highlight resep yang lagi dipilih, warning kalau stock ≤ 3

### Tab Misc
- **Auto Daily Reward** — claim reward harian otomatis
- **Auto Pay Loan** — bayar loan otomatis

### Settings
- Theme manager (preset + custom)
- Save/load config otomatis (per session)
- Auto Execute, Auto Reconnect, Keybind menu
- Footer custom: *"ayank auliaa yg manis cantik dan kesayangan nya aku, wkwkwk"*

### Mobile
- Floating K button (drag + toggle UI)
- Toggle/Lock button Obsidian disembunyikan (`ShowMobileButtons = false`)
- Anti-AFK otomatis

---

## Bug yang Udah Di-fix 🔧

| Bug | Root Cause | Fix |
|-----|-----------|-----|
| Auto Cashier kadang gagal | Nunggu folder `Bags` yang ga pernah populate | Pakai `#replica.Data.Cart` langsung |
| Customer diproses 2-5x | Lock lepas sebelum customer pergi, `processingCustomers[c] = nil` terlalu cepat | Tambah `customerCooldown` per instance (8 detik) |
| Auto Place nyala sendiri | SaveManager load config lama yang AutoPlace=true | `SaveManager:SetIgnoreIndexes({"AutoPlace"})` |
| `idToName` nil di refreshCookList | Lua upvalue capture — `idToName` dideklarasi SETELAH fungsi yang pakai | Pindahin deklarasi `idToName` ke atas `refreshCookList` |
| Stock label error `.Label` nil | Obsidian Label pakai `:SetText()`, bukan `.Label` property | Ganti ke method yang bener |
| Toggle/Lock muncul di HP | Bawaan Obsidian mobile default ON | `ShowMobileButtons = false` di CreateWindow |

---

## Known Quirks Obsidian V2 ⚠️

- `AddToggle` / `AddDropdown` return `self` (Groupbox), **bukan** element → jangan chain `:OnChanged()`
- Toggle → pakai `Callback` di options table
- Dropdown → akses via `Library.Options.X:OnChanged()`
- `Library.Options` hanya nyimpen Dropdown/Input/Keybind, **tidak** Toggle
- `Label:SetText(text)` — bukan `.Label` property

---

## Next Step 🚀

- [ ] Support multi-game (daftarin game lain di `games/index.lua`)
- [ ] Auto restock bahan masak (beli ingredient otomatis kalau stock < threshold)
- [ ] Notifikasi Roblox kalau customer numpuk / cashier error
- [ ] Key validation backend (sekarang DEV MODE bypass di `loader.lua` line ~265)
- [ ] UI versi HP lebih compact (font/ukuran menyesuaikan layar kecil)
- [ ] Auto serve customer yang di queue 2, 3 kalau queue 1 kosong
