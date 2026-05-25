// category_contact_tile.dart

import 'package:flutter/material.dart'; // Import Flutter Material untuk bisa pakai widget seperti Container, Row, Icon, Text, dll

// Widget ini berfungsi sebagai 1 baris/tile kontak yang tampil di dalam sebuah kategori.
// Bisa muncul dalam 2 kondisi:
//   - Mode normal  : hanya tampil nama + avatar
//   - Mode hapus   : tampil nama + avatar + tombol X merah di kanan
class CategoryContactTile extends StatelessWidget {

  final String name;           // Nama kontak yang akan ditampilkan di tile
  final bool showRemove;       // Penentu apakah tombol hapus (X) ditampilkan atau tidak
  final VoidCallback? onRemoveTap; // Fungsi yang dijalankan ketika tombol X ditekan
                                   // VoidCallback = fungsi tanpa parameter & tanpa return value
                                   // Tanda '?' artinya boleh null (tidak wajib diisi)

  const CategoryContactTile({
    super.key,
    required this.name,       // 'name' WAJIB diisi saat memanggil widget ini
    this.showRemove = false,  // 'showRemove' opsional, defaultnya false (tombol X tidak tampil)
    this.onRemoveTap,         // 'onRemoveTap' opsional, boleh tidak diisi jika showRemove = false
  });

  @override
  Widget build(BuildContext context) {

    // Container utama yang membungkus seluruh isi tile
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Jarak 12px di bawah tile agar antar tile tidak menempel
      padding: const EdgeInsets.symmetric(
        horizontal: 16, // Jarak kiri & kanan di dalam tile
        vertical: 14,   // Jarak atas & bawah di dalam tile
      ),
      decoration: BoxDecoration(
        color: Colors.white,                  // Background tile berwarna putih
        borderRadius: BorderRadius.circular(25), // Sudut tile dibuat membulat dengan radius 25
        border: Border.all(
          color: const Color(0xFF2196F3),    // Warna garis tepi tile: biru Material
          width: 1.5,                        // Ketebalan garis tepi 1.5px
        ),
      ),

      // Row menyusun isi tile secara horizontal dari kiri ke kanan:
      // [ Avatar ] ---> [ Nama Kontak ] ---> [ Tombol X (jika showRemove = true) ]
      child: Row(
        children: [

          // ───── BAGIAN 1: Avatar lingkaran biru dengan ikon orang ─────
          Container(
            width: 44,  // Lebar avatar 44px
            height: 44, // Tinggi avatar 44px (sama dengan lebar → berbentuk lingkaran sempurna)
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3), // Background avatar berwarna biru
              shape: BoxShape.circle,  // Bentuk container dibuat lingkaran penuh
            ),
            child: const Icon(
              Icons.person,        // Ikon siluet orang sebagai placeholder foto kontak
              color: Colors.white, // Warna ikon putih agar kontras dengan background biru
            ),
          ),

          const SizedBox(width: 14), // Spasi kosong 14px sebagai jarak antara avatar dan nama

          // ───── BAGIAN 2: Nama kontak ─────
          // Expanded membuat teks mengisi semua ruang yang tersisa di tengah
          // sehingga tombol X tetap berada di ujung kanan
          Expanded(
            child: Text(
              name, // Menampilkan nama kontak dari parameter yang dikirim
              overflow: TextOverflow.ellipsis, // Jika nama terlalu panjang, otomatis dipotong menjadi "Nama Kon..."
              style: const TextStyle(
                fontSize: 17,             // Ukuran teks nama
                fontWeight: FontWeight.w500, // Ketebalan teks: medium (antara normal dan bold)
                color: Colors.black87,    // Warna teks: hitam dengan sedikit transparansi (87%)
              ),
            ),
          ),

          // ───── BAGIAN 3: Tombol hapus (X merah) ─────
          // Blok 'if' ini hanya dirender jika showRemove bernilai true
          // Jika showRemove = false, bagian ini tidak ada sama sekali di layout
          if (showRemove)
            GestureDetector(
              onTap: onRemoveTap, // Jalankan fungsi 'onRemoveTap' ketika tombol X ditekan
              child: const Icon(
                Icons.close,      // Ikon silang/X untuk aksi hapus
                color: Colors.red, // Warna merah sebagai tanda peringatan/hapus
                size: 28,         // Ukuran ikon 28px
              ),
            ),

        ],
      ),
    );
  }
}