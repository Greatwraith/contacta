// main.dart

//_______________________
// BAGIAN IMPORT DEPENDENSI | BERFUNGSI SEBAGAI PUSAT UNTUK MENGIMPOR LIBRARY DAN KONFIGURASI SISTEM
//_______________________

import 'package:bikin_crud/login_screen.dart'; // Mengimpor halaman LoginScreen untuk menetapkannya sebagai tampilan awal saat aplikasi pertama kali dijalankan
import 'package:flutter/material.dart'; // Mengimpor library utama Flutter Material Design untuk membangun arsitektur antarmuka dan komponen visual pengguna
import 'package:firebase_core/firebase_core.dart'; // Mengimpor library inti Firebase Core untuk menyediakan akses ke seluruh ekosistem layanan Firebase
import 'firebase_options.dart'; // Mengimpor berkas konfigurasi otomatis proyek Firebase yang menyesuaikan parameter keamanan dengan platform target

//_______________________
// BAGIAN FUNGSI UTAMA (MAIN) | BERFUNGSI SEBAGAI TITIK AWAL EKSEKUSI PROGRAM DAN INISIALISASI LAYANAN
//_______________________

void main() async { // Menggunakan modifier async karena metode ini memerlukan proses penantian (await) saat menginisialisasi layanan Firestore
  WidgetsFlutterBinding.ensureInitialized(); // Berfungsi untuk memastikan bahwa seluruh komponen pengikat mesin Flutter telah terpasang sempurna sebelum memproses konfigurasi luar

  await Firebase.initializeApp( // Melakukan proses inisialisasi koneksi awal aplikasi menuju server layanan Firebase secara asinkron
    options: DefaultFirebaseOptions.currentPlatform, // Menetapkan opsi parameter konfigurasi Firebase sesuai dengan sistem operasi perangkat yang digunakan
  );

  runApp(const MyApp()); // Mengeksekusi dan menjalankan struktur pohon widget utama aplikasi melalui class MyApp
}

//_______________________
// BAGIAN ROOT WIDGET (MYAPP) | BERFUNGSI SEBAGAI DEKLARASI KONFIGURASI GLOBAL DAN PENGATURAN TEMA APLIKASI
//_______________________

class MyApp extends StatelessWidget { // Menggunakan StatelessWidget karena widget root ini bersifat statis dan tidak mengalami perubahan status di tingkat global
  const MyApp({super.key}); // Constructor standar untuk melakukan inisialisasi awal objek MyApp dengan meneruskan parameter key ke parent class

  @override
  Widget build(BuildContext context) { // Metode utama untuk menyusun, merakit, dan mengembalikan seluruh konfigurasi pengaturan dasar antarmuka aplikasi
    return MaterialApp( // Mengembalikan objek MaterialApp sebagai fondasi utama yang mengatur alur navigasi, penamaan, dan pelokalan sistem
      title: 'Flutter Firebase CRUD', // Menetapkan judul formal aplikasi yang akan terbaca oleh sistem operasi perangkat
      debugShowCheckedModeBanner: false, // Menghilangkan spanduk penanda mode pengembangan (debug banner) yang berada di sudut kanan atas layar
      theme: ThemeData( // Mengatur dan menerapkan standarisasi desain visual serta pewarnaan global untuk seluruh halaman aplikasi
        primarySwatch: Colors.blue, // Menentukan warna primer dominan sistem menggunakan variasi palet warna biru
      ),

      home: const LoginScreen(), // Menetapkan komponen LoginScreen secara mutlak sebagai gerbang awal atau tampilan utama yang dimuat oleh sistem
    );
  }
}