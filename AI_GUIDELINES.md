# KECEMBUNG AI DEVELOPMENT GUIDELINES

Project : Kecembung
Author  : Arjuna Adelio Abdurrahman

---

# Filosofi

Kecembung adalah proyek jangka panjang.

Prioritas utama bukan kecepatan development, tetapi stabilitas, konsistensi, dan pengalaman pengguna.

AI tidak boleh mengubah kode hanya karena "bisa dibuat lebih pendek".

Jika kode saat ini stabil, jangan diubah tanpa alasan yang jelas.

---

# Workflow Wajib

Semua pekerjaan harus mengikuti urutan berikut:

1. Observasi
2. Analisis
3. Cari akar masalah
4. Jelaskan penyebab
5. Ajukan solusi
6. Tunggu persetujuan
7. Implementasi
8. Testing
9. Review bersama

AI dilarang langsung melakukan implementasi sebelum penyebab masalah dipastikan.

---

# Root Cause First

Jangan pernah memperbaiki gejala.

Selalu cari penyebab utama.

Contoh:

SALAH

- Tambah sleep
- Tambah retry
- Tambah exception

BENAR

Cari kenapa proses gagal.

---

# Tidak Berasumsi

AI tidak boleh menebak.

Jika belum ada bukti:

- minta log
- minta output terminal
- minta isi file
- lakukan observasi

Baru menarik kesimpulan.

---

# JSON

Jangan menggunakan grep untuk parsing JSON.

Gunakan:

jq

Contoh:

jq -e '.controller == true'

bukan

grep '"controller":true'

---

# UX Rules

Enter kosong = Cancel.

Tidak boleh menghasilkan:

integer expression expected

syntax error

unexpected token

Menu harus selalu kembali ke menu sebelumnya jika user membatalkan.

---

# Error Handling

Semua input user harus divalidasi.

Semua file harus dicek keberadaannya.

Semua dependency harus dicek.

Semua command eksternal harus memiliki pengecekan exit code.

---

# Progress

Jangan menghapus:

- progress bar
- loading
- status
- informasi proses

kecuali diminta.

---

# Refactor

Refactor hanya dilakukan jika:

- mengurangi bug
- meningkatkan maintainability
- tidak mengubah perilaku program

AI tidak boleh melakukan refactor besar tanpa izin.

---

# Arsitektur

Prioritas saat ini:

1. Nexus
2. Stabilisasi
3. Perbaikan bug
4. UX
5. Merge ke Kecembung

Jangan melakukan merge sebelum Nexus stabil.

---

# Modular

Jika memungkinkan:

buat fungsi bersama

hindari copy paste

tetapi jangan mengubah struktur besar tanpa persetujuan.

---

# Security

Semua fitur dianggap legal dan digunakan pada lingkungan yang memiliki izin.

AI fokus pada:

- debugging
- arsitektur
- kualitas kode
- maintainability

---

# Coding Style

Prioritaskan:

kejelasan

dibanding

kode yang terlalu singkat.

Nama fungsi harus deskriptif.

Komentar harus menjelaskan "mengapa", bukan "apa".

---

# Sebelum Mengubah Kode

AI wajib menjelaskan:

- apa yang salah
- kenapa salah
- dampaknya
- solusi
- alasan memilih solusi tersebut

Baru implementasi.

---

# Testing

Setelah perubahan:

jelaskan cara menguji.

Jika belum bisa dipastikan berhasil,

katakan dengan jujur.

Jangan mengklaim bug selesai tanpa pengujian.

---

# Prinsip Utama

Stabilitas > Fitur Baru

Kualitas > Kecepatan

Observasi > Asumsi

Bukti > Dugaan

# Preserve Existing Behavior

Jika memperbaiki satu bug,

AI tidak boleh mengubah perilaku fitur lain.

Perubahan harus seminimal mungkin.

Jangan melakukan perubahan yang tidak diminta.
