# Project Brain - Grow a Garden 2 Auto-Farm Script Hub

Dokumen ini berfungsi sebagai pusat penyimpanan riwayat proyek, detail file, penemuan teknis, dan panduan troubleshooting agar Anda atau AI asisten berikutnya dapat langsung melanjutkan pengerjaan tanpa kebingungan.

---

## 1. Ringkasan Proyek & Status Saat Ini
*   **Target Game:** Roblox - *Grow a Garden 2*
*   **Target Executor:** **Delta Executor** (Mobile / Emulator Android)
*   **Tujuan Utama:** Membuat skrip otomatisasi pertanian (Auto-Plant, Auto-Harvest, Auto-Sell, Auto-Water, Auto-Spray) yang interaktif melalui panel GUI.
*   **Status Terbaru:** Skrip telah diperbarui ke **v2.7 Modular Fluent UI** dengan peningkatan performa, perbaikan bug, dan UI:
    1. **Renominalisasi:** Fitur *Auto Sell* diganti namanya menjadi *Auto sell all (semua buah d inventory)* agar lebih akurat merefleksikan fungsinya.
    2. **Antarmuka Toko Benih Dropdown:** Mengganti 27 sakelar benih yang memenuhi layar dengan satu menu pilihan ganda (*multi-select dropdown*) untuk 25 jenis benih game. Benih mutasi *Gold* dan *Rainbow* juga telah dihapus dari daftar karena dibeli/ditangani lewat event.
    3. **Peningkatan Deteksi Penanaman:** Menambahkan pencarian berlapis untuk tool benih di tas (polos, dengan akhiran ` Seed`, atau `Seed`) serta mengirimkan nama tool persis hasil deteksi ke event jaringan `PlantSeed`.
    4. **Bypass Caching CDN:** Memodifikasi `loader.lua` agar menggunakan `raw.githubusercontent.com` dan menambahkan parameter cache-buster `?t=os.time()` saat mengunduh berkas modular demi menjamin file yang dieksekusi selalu yang terbaru.
    5. **Transisi ke Fluent UI:** Mengubah pustaka UI bawaan (`v2/ui.lua`) menjadi wrapper untuk Fluent UI (dawid-scripts) yang modern, premium, dan mobile-friendly.
    6. **Perbaikan Loop Seleksi Benih:** Memperbaiki bug iterasi `ipairs` menjadi `pairs` pada `config.SelectedSeeds` (karena berupa dictionary/table hash) sehingga loop penanaman dan pembelian benih berjalan dengan benar.
    7. **Penyederhanaan Teks Dropdown:** Mengubah teks label dropdown pembelian benih dari `"Pilih Benih yang Ingin Dibeli & Ditanam"` menjadi `"Pilih Benih yang Ingin Dibeli"` guna menyederhanakan tampilan antarmuka.

---

## 2. Struktur File Proyek (`D:\RBX`)

### Skrip Utama (Auto-Farm Modular)
| Nama File / Jalur | Jenis | Peran / Deskripsi |
| :--- | :--- | :--- |
| **`loader.lua`** | Skrip Peluncur | Skrip masuk utama yang dijalankan di Delta Executor. Mendukung testing lokal (`USE_LOCAL = true`) via `readfile` dan mode produksi (`USE_LOCAL = false`) via raw GitHub. |
| `v2/config.lua` | Konfigurasi | Menyimpan status aktif fitur auto-farm dan modifikasi player (`shared.SpeedHubX.Config`). |
| `v2/utils.lua` | Utility | Utilitas interaksi ProximityPrompt/ClickDetector, deteksi plot, serta helper UICorner/UIStroke. |
| `v2/features.lua` | Fitur Loop | Menjalankan seluruh proses latar belakang (Auto Plant, Harvest, Sell, Water, Buy, Spray, AFK, dan Player Mods). |
| `v2/ui.lua` | UI Library | Library UI wrapper untuk Fluent UI (dawid-scripts) yang modern dan premium. |
| `v2/main.lua` | Main Render | Inisialisasi tab GUI, penambahan toggle/slider/dropdown, dan penghubung aksi ke modul konfigurasi. |
| **`README.md`** | Dokumentasi | Panduan instalasi utama dan pemanggil loadstring repositori GitHub untuk pengguna luar. |

### Alat Pendukung & Cadangan
| Nama File / Jalur | Jenis | Peran / Deskripsi |
| :--- | :--- | :--- |
| `grow_a_garden_2_complete.lua` | Cadangan | Salinan skrip lengkap monolitis (v2.2) sebelum pemisahan modul. |
| `grow_a_garden_2_complete.lua.bak` | Cadangan | Salinan GUI diagnostik lama sebelum perombakan total. |
| `remote_scanner.lua` | Alat Scan | Alat pemindai seluruh RemoteEvent game ke `hasil_remote.txt`. |
| `inspect_packet_gui.lua` | Alat Scan | Menampilkan daftar API Networking ke GUI di layar. |
| `hasil_remote.txt` | Output Scan | Hasil scan RemoteEvent game. |
| `hasil_inspect` | Output Scan | Hasil dekompilasi API Networking (daftar fungsi remote game). |
| `hasil_dump_tree` | Output Scan | Hasil dump struktur folder SharedModules game. |

---

## 3. Penemuan Teknis & Mekanisme Game

### A. Jaringan Biner (MessagePack/Luau Buffer)
*   Game ini mengirimkan instruksi ke server dalam bentuk biner terkompresi (`buffer`) ke satu RemoteEvent pusat. Membuat buffer secara manual sangat sulit dan rentan terdeteksi.
*   **Solusi:** Skrip menggunakan modul client bawaan game dengan memanggil `require(ReplicatedStorage.SharedModules.Networking)`. Modul ini otomatis mengkompilasi data menjadi buffer biner dan mengirimkannya secara aman.

### B. Hierarki Plot Kebun Pemain
*   Plot kebun pemain berada di: `workspace.Farm.[NamaPemain]` atau `workspace.Farms.[NamaPemain]`.
*   Kepemilikan plot diverifikasi melalui atribut atau objek data: `Important.Data.Owner.Value`.
*   Tanaman fisik berada di dalam folder: `Important.Plants_Physical`.
*   Ubin tanah menggunakan nama: `Dirt`, `PlotTile`, atau `Tile`.

### C. Kompatibilitas Delta Executor (Mobile)
*   Fungsi `game:HttpGet` di Delta Executor sering memblokir seluruh thread eksekusi jika terjadi jeda jaringan.
*   Mengakses `game:GetService("CoreGui")` dapat menyebabkan kegagalan senyap (silent crash) di Android.
*   **Masalah Double-Firing Klik:** Menghubungkan event `Activated` dan `MouseButton1Click` pada tombol yang sama secara bersamaan akan menyebabkan callback dipicu dua kali dalam satu kali klik pada platform/executor tertentu. Ini membatalkan aksi toggle (On -> Off instan) dan melipatgandakan callback dropdown/slider.
*   **Solusi:** Skrip GUI dipasang langsung ke `LocalPlayer.PlayerGui` dan menggunakan event `Activated` saja untuk menangani seluruh input klik/sentuh secara eksklusif.


---

## 4. Cara Menjalankan & Troubleshooting

### A. Cara Menjalankan Skrip Utama
1. Buka file [grow_a_garden_2_complete.lua](file:///D:/RBX/grow_a_garden_2_complete.lua).
2. Salin seluruh isi kodenya.
3. Buka Roblox, masuk ke game *Grow a Garden 2*, buka Delta Executor.
4. Klik **CLEAR**, lalu tempel kode dan tekan **EXECUTE**.

### B. Cara Membaca Panel Diagnostik (Jika GUI Tidak Muncul)
*   Di bagian tengah-kiri layar akan muncul kotak merah bertuliskan **"Speed Hub X - Diagnostic Console Logs"**.
*   Kotak ini akan mencatat log internal Roblox. Jika skrip mengalami error, tulisan berwarna merah berlabel `[ERROR]` akan muncul di dalam kotak tersebut.
*   Catat atau screenshot pesan error tersebut untuk diberikan ke asisten AI berikutnya agar langsung diketahui baris kode mana yang bermasalah.

> [!IMPORTANT]
> **CATATAN APABILA PANEL MASIH TIDAK BEKERJA / TIDAK MUNCUL:**
> Jika setelah dieksekusi kotak merah log diagnostik dan panel utama tetap sama sekali tidak muncul (layar bersih tanpa perubahan):
> 1. **Periksa Versi Delta Executor:** Pastikan Delta Executor Anda sudah versi paling update. Beberapa versi lama Delta memblokir total pembuatan UI (`Instance.new("ScreenGui")`) secara sepihak.
> 2. **Cek Konsol F9 Game:** Tekan tombol Roblox di pojok kiri atas -> Settings -> Developer Console (atau ketik `/console` di chat). Cari baris tulisan berwarna merah (Error) dan laporkan pesan error tersebut di sini.
> 3. **Buka di PC / Emulator Berbeda:** Coba jalankan skrip di emulator atau PC lain untuk memastikan apakah masalahnya ada di executor perangkat aktif Anda.

