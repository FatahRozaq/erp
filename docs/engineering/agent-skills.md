# Skill agent untuk ERP

**Inventaris diverifikasi: 3 November 2026.** Skill terpasang pada mesin pengembang, bukan dependency aplikasi atau CI. Clone repository pada mesin lain tidak memasang skill otomatis. Requirement dan acceptance ERP selalu lebih tinggi daripada saran skill.

## Inventaris dan sumber

| Skill | Status | Sumber / revisi terpasang | Kegunaan |
|---|---|---|---|
| `caveman` | Sudah tersedia di `~/.agents/skills/caveman/` | Instalasi pengguna sebelumnya; `SKILL.md` diperiksa, revisi upstream tidak diasumsikan | Laporan ringkas tanpa kehilangan fakta, bukti dan gap |
| `ponytail` | Baru dipasang | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail/tree/96608e078b2d5ea607c5c3b8b5a54d1c1fba6846/skills/ponytail), `96608e078b2d5ea607c5c3b8b5a54d1c1fba6846` | Reuse dan perubahan minimum yang menyelesaikan scope |
| `ui-ux-pro-max` | Baru dipasang; nama yang dimaksud oleh permintaan `ui-ux-max` | [UI UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill/tree/713eef51b04efc98d6fa565323b495f7c9c89fd4/.claude/skills/ui-ux-pro-max), `713eef51b04efc98d6fa565323b495f7c9c89fd4` | Panduan UI/UX lokal untuk Next.js/shadcn dan Flutter |
| `context7-cli` | Baru dipasang | [Upstash Context7](https://github.com/upstash/context7/tree/6d15033fdb9264f29d4935f380b5cb1b7dd62a31/skills/context7-cli), `6d15033fdb9264f29d4935f380b5cb1b7dd62a31` | Ambil dokumentasi library sesuai versi; CLI `ctx7@0.9.0` |
| `vercel-react-best-practices` | Baru dipasang | [Vercel agent-skills](https://github.com/vercel-labs/agent-skills/tree/1a2c79d4e6c4a2283dc2c614b6538cbe1ed5ca62/skills/react-best-practices), `1a2c79d4e6c4a2283dc2c614b6538cbe1ed5ca62` | Performance React/Next.js, fetching dan bundle |
| `security-best-practices` | Baru dipasang | [OpenAI skills](https://github.com/openai/skills/tree/49f948faa9258a0c61caceaf225e179651397431/skills/.curated/security-best-practices), `49f948faa9258a0c61caceaf225e179651397431` | Secure coding/review sesuai Go atau JS/TS; bukan panduan Flutter |

Lima skill baru berada di `~/.codex/skills/<nama>/`. `migration`, `lean-build`, `investigate-first`, `surgical-patch`, `safe-refactor`, dan `verify-and-stop` sudah tersedia di `~/.agents/skills/`; tidak dipasang ulang. Postman tersedia sebagai plugin. Tidak ada pemasangan gateway telemetry, akun berbayar, atau dependency produk melalui pekerjaan skill ini.

## Pemilihan dan hemat konteks

1. Baca slice dan scope terlebih dahulu. Coding memakai `ponytail`; tambahkan satu workflow yang tepat (migration/debug/fix/refactor/verification). Selesaikan seluruh acceptance, bukan sekadar diff pendek.
2. Baca hanya referensi bahasa, rule, atau hasil pencarian yang berkaitan dengan perubahan. Jangan memuat kumpulan rule Vercel, seluruh katalog UI, atau seluruh dokumen roadmap sekaligus.
3. Gunakan `rg` untuk menemukan pemilik kode. Periksa versi aktual dari `go.mod`, `package-lock.json`, dan `pubspec.lock` sebelum mencari dokumentasi. Context7 tidak mengotorisasi upgrade dependency otomatis.
4. Pertahankan kode readable, nama eksplisit, komentar alasan, error handling, security, dan tes yang relevan. Gaya ringkas caveman berlaku untuk komunikasi; dokumen dan bukti harus tetap lengkap.
5. Hasil akhir menyebut file, pemeriksaan yang dijalankan, hasil, gap, dan pekerjaan berikutnya. Jangan mengklaim hemat token secara terukur tanpa pengukuran.

## Kualitas UI ERP

- Acuan tetap shadcn-admin MIT yang diadaptasi ke Next.js; Flutter mengikuti standar mobile. Skill UI bukan template pengganti atau alasan menambah dependensi animasi.
- Utamakan tugas operator: tabel yang terbaca, hierarchy tindakan, filter, form/validasi, density konsisten, status bisnis dan aksesibilitas. Hindari hero pemasaran, gradient/glass/ornamen, emoji sebagai ikon, atau animasi tanpa fungsi yang diminta.
- Gunakan token desain dan komponen yang ada. Rekomendasi skill harus ditinjau terhadap FSD; jangan menyalin design system generik atau menimpa keputusan desain yang sudah diterima.
- Verifikasi responsive dan keyboard/focus; state loading, empty, error, success, disabled/permission. Mobile juga text scaling, touch target, semantics, safe area dan offline/pending. Screenshot/review nyata diperlukan bila UI berubah; instalasi skill sendiri tidak membuktikan kualitas layar.

Pencarian lokal UI memakai path skill terpasang (contoh Codex berikut), bukan mengasumsikan `CLAUDE_PLUGIN_ROOT`:

```sh
python3 "$HOME/.codex/skills/ui-ux-pro-max/scripts/search.py" 'keyboard focus modal' --domain ux -n 2
python3 "$HOME/.codex/skills/ui-ux-pro-max/scripts/search.py" 'table loading state' --stack nextjs
```

Smoke pencarian pertama berhasil menghasilkan dua panduan focus dari dataset lokal. Tidak ada file desain aplikasi yang diubah dalam B-02.1.

## Context7 dan instalasi ulang

Integrasi yang dipasang adalah skill **CLI**, bukan klaim koneksi MCP aktif. Smoke `ctx7 library pgx` dan `ctx7 docs /jackc/pgx/v5.11.0` berhasil tanpa login baru pada 3 November 2026; dokumentasi rollback sesuai versi module berhasil diterima. Resolve library dengan `ctx7 library <nama> <query>`, lalu `ctx7 docs <id-hasil> <query>`. Cocokkan versi; hasil indeks terbaru belum tentu cocok dengan dependency ERP. Gunakan dokumentasi resmi bila library/versi tidak tersedia atau layanan menolak akses. Jangan kirim kode privat, credential atau data tenant dalam query; login/key hanya bila diperlukan dan diberikan melalui mekanisme aman.

Untuk mesin baru, gunakan skill-installer Codex: `install-skill-from-github.py --repo <owner/repo> --ref <SHA-tabel> --path <path-sumber>`. Vercel menggunakan `--name vercel-react-best-practices`; UI memakai path `.claude/skills/ui-ux-pro-max`. Pasang direktori lengkap beserta references/data/scripts, lalu periksa `SKILL.md` dan smoke tool yang relevan. `npm install -g ctx7@0.9.0 --ignore-scripts` menyediakan CLI yang diverifikasi saat inventaris ini dibuat. Review perubahan upstream sebelum memperbarui pin. Skill baru tersedia pada turn berikutnya; jangan menimpa instalasi pengguna secara otomatis.
