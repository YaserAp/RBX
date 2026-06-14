# Speed Hub X - Grow a Garden 2 Script Hub 🚀

Sebuah Script Hub modular Roblox untuk game **Grow a Garden 2** yang dirancang khusus dan dioptimalkan secara penuh untuk **Delta Executor** (Mobile Android & PC).

---

## 📖 Cara Menggunakan (Loadstring)

Salin kode di bawah ini dan jalankan di executor Anda:

```lua
loadstring(game:HttpGet("https://raw.githack.com/YaserAp/RBX/main/loader.lua?t=" .. tick()))()
```

> [!TIP]
> Skrip di atas menggunakan penyedia CDN bebas cache (`githack.com`) sehingga setiap pembaruan kode yang Anda lakukan di GitHub akan langsung ter-update di game tanpa penundaan cache.

---

## ✨ Fitur Utama

### 🌾 1. Auto Farm Tab
*   **Auto Plant (Tanam):** Menanam benih yang dipilih secara otomatis pada plot kosong.
*   **Auto Harvest (Panen):** Memanen buah matang secara instan menggunakan bypass jaringan internal.
*   **Auto Water (Siram):** Menyiram tanah secara otomatis ketika kelembapan berada di bawah 80%.
*   **Auto sell all (semua buah d inventory):** Menjual seluruh hasil panen secara otomatis ke NPC Merchant secara instan.

### 🛒 2. Toko Benih Tab
*   **Auto Beli Benih (Global):** Sakelar utama untuk mengaktifkan pembelian otomatis secara massal.
*   **Daftar Sakelar Benih:** Memilih secara bebas satu atau lebih benih sekaligus (multi-select) dari 27 jenis benih game menggunakan sakelar (toggle) individu.

### 🧪 3. Auto Spray Tab
*   **Auto Spray (Mutasi):** Otomatis menyemprot tanaman yang menghasilkan mutasi langka.
*   **Filter Mutasi:** Memilih jenis mutasi target (Choc, Overgrown, Gold, Rainbow, dll).

### 🏃 4. Player Mods Tab
*   **WalkSpeed:** Mengubah kecepatan lari karakter (16 - 150).
*   **JumpPower:** Mengubah kekuatan lompatan karakter (50 - 300).
*   **Infinite Jump:** Mengaktifkan lompatan tanpa batas di udara.

### 🖥️ 5. Diagnostics & Logs Tab
*   **System Logs:** Menampilkan live developer console log secara langsung di dalam game untuk memudahkan pelacakan error.

---

## 📁 Struktur Kode Modular

Repositori ini menggunakan struktur kode modular `v2` agar pemeliharaan kode lebih mudah dan tidak berantakan:

*   [`loader.lua`](loader.lua) — Skrip masuk utama (Main entrypoint).
*   [`v2/config.lua`](v2/config.lua) — Penyimpanan konfigurasi state fitur.
*   [`v2/utils.lua`](v2/utils.lua) — Fungsi pembantu (Plot finder, network fire, dll).
*   [`v2/features.lua`](v2/features.lua) — Loop background pengerjaan fitur otomatis.
*   [`v2/ui.lua`](v2/ui.lua) — Library UI Wrapper untuk Fluent UI (dawid-scripts) yang modern dan premium.
*   [`v2/main.lua`](v2/main.lua) — Inisialisasi tab UI dan callback aksi.

---

*Dibuat dengan 💻 oleh YaserAp & Antigravity AI.*
