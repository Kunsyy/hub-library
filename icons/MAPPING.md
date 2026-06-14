# Icon Mapping — Kunsy Hub UI Library

Acuan icon buat UI library. Upload tiap icon ke Roblox (akun alt) sebagai **Image/Decal**,
ambil **asset id**-nya, isi di kolom `rbxassetid`. Nanti aku wire ke library.

## ⚠️ Aturan bikin icon (penting)
- **Monochrome PUTIH** (#FFFFFF) di **background transparan** (PNG) → biar library bisa tint
  warnanya (aktif = ungu/putih, nonaktif = abu). Jangan warna-warni.
- **Kotak** (mis. 256×256), objek di tengah, ada sedikit padding.
- Style **konsisten** (semua outline, atau semua filled — pilih satu).

---

## A. BRANDING (logo)
| Fungsi | File yg ada | rbxassetid |
|--------|-------------|-----------|
| Logo hub (sidebar atas, key screen, toggle button, watermark) | `logo.png` | `rbxassetid://` ____ |

> Logo boleh berwarna (nggak di-tint).

---

## B. TAB ICONS (sidebar) — kamu UDAH punya semua ✅
Pilih sesuai tab yang dipakai. Bikin versi PUTIH-nya kalau yg ada masih berwarna.
| Tujuan tab | File yg ada | rbxassetid |
|-----------|-------------|-----------|
| Main / Home | `home.png` | `rbxassetid://` ____ |
| Farm / Auto | `sword.png` | `rbxassetid://` ____ |
| Combat | `sword2.png` | `rbxassetid://` ____ |
| Shop / Store | `shop.png` | `rbxassetid://` ____ |
| Teleport | `location.png` | `rbxassetid://` ____ |
| Config / Settings | `settings.png` | `rbxassetid://` ____ |
| Rewards / Event | `gift.png` | `rbxassetid://` ____ |
| Stats / Leaderboard | `trophy.png` | `rbxassetid://` ____ |
| Scripts | `scroll.png` | `rbxassetid://` ____ |
| Inventory / Files | `folder.png` | `rbxassetid://` ____ |
| Premium / Misc | `diamond.png` | `rbxassetid://` ____ |

---

## C. FUNCTIONAL ICONS (dalam UI) — INI YANG KURANG, perlu dibikin ⭐
Yang bikin UI keliatan premium. Prioritas tinggi ditandai ⭐.
| Fungsi | Icon | Prioritas | rbxassetid |
|--------|------|-----------|-----------|
| Search bar | kaca pembesar (magnifier) | ⭐ wajib | `rbxassetid://` ____ |
| Tombol close window | X / silang | ⭐ wajib | `rbxassetid://` ____ |
| Dropdown buka/tutup | chevron (panah bawah) | ⭐ wajib | `rbxassetid://` ____ |
| Badge premium (kunci) | gembok (padlock) | ⭐ wajib | `rbxassetid://` ____ |
| Toggle/multi ON | centang (checkmark) | nice | `rbxassetid://` ____ |
| Export config | copy / 2 kertas | nice | `rbxassetid://` ____ |
| Refresh list | panah muter (reload) | nice | `rbxassetid://` ____ |
| Toast notif | lonceng (bell) | nice | `rbxassetid://` ____ |
| Bottom bar | logo Discord | nice | `rbxassetid://` ____ |
| Tier premium | mahkota (crown) | nice | `rbxassetid://` ____ |
| Key screen | kunci (key) | nice | `rbxassetid://` ____ |
| Fitur target player | orang (person) | opsional | `rbxassetid://` ____ |
| ESP / visual | mata (eye) | opsional | `rbxassetid://` ____ |

---

## Ringkasan "bikin icon baru"
Yang BELUM ada (bikin monochrome putih):
1. ⭐ magnifier (search)
2. ⭐ X (close)
3. ⭐ chevron (dropdown)
4. ⭐ padlock (premium lock)
5. checkmark
6. copy
7. reload/refresh
8. bell
9. Discord logo
10. crown
11. key
12. person (opsional)
13. eye (opsional)

Yang UDAH ada (tinggal bikin versi putih kalau perlu): logo + 11 tab icon di section B.

---

## Cara ambil asset id yang BENER (penting)
Pas upload Decal, ID yang muncul itu **Decal ID**, BUKAN Image ID yang dipakai `rbxassetid://`.
Cara dapet Image ID:
1. Upload Decal di create.roblox.com → Decals
2. Buka decal-nya → klik kanan gambar → atau pakai cara: paste Decal ID ke
   `rbxthumb` / atau test di Studio (`Decal.Texture`) → muncul `rbxassetid://<imageid>`
3. Yang dipakai di library = **image id** itu.
> Nanti aku bantu verifikasi ID-nya bener pas kamu kasih.
