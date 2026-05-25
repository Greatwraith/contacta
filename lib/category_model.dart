// category_model.dart

// ════════════════════════════════════════════════════════════════
// BAGIAN IMPORTS
// Mengimpor library yang dibutuhkan untuk tipe data khusus Firebase.
// ════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart'; // Mengimpor package Cloud Firestore agar dapat menggunakan tipe data Timestamp dan DocumentSnapshot


// ════════════════════════════════════════════════════════════════
// BAGIAN CLASS MODEL
// Mendefinisikan struktur cetak biru (blueprint) untuk objek Kategori.
// ════════════════════════════════════════════════════════════════

class CategoryModel { // Membuat class CategoryModel sebagai representasi struktur data kategori di dalam aplikasi
  final String id; // Deklarasi properti id bertipe String (bersifat final/tidak bisa diubah setelah diinisialisasi) untuk menyimpan ID unik dokumen dari Firestore
  final String name; // Deklarasi properti name bertipe String untuk menyimpan nama atau judul kategori
  final Timestamp? createdAt; // Deklarasi properti createdAt bertipe Timestamp (bisa bernilai null/opsional) untuk merekam waktu kapan kategori ini pertama kali dibuat
  final Timestamp? updatedAt; // Deklarasi properti updatedAt bertipe Timestamp (bisa bernilai null/opsional) untuk merekam waktu kapan data kategori ini terakhir kali diperbarui


  // ════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // Fungsi inisialisasi awal saat objek CategoryModel dibuat.
  // ════════════════════════════════════════════════════════

  CategoryModel({ // Membuat constructor utama untuk class CategoryModel menggunakan named parameters (parameter bernama)
    required this.id, // Parameter id bersifat wajib diisi (required) saat membuat objek kategori baru
    required this.name, // Parameter name bersifat wajib diisi (required) saat membuat objek kategori baru
    this.createdAt, // Parameter createdAt bersifat opsional (tidak wajib diisi)
    this.updatedAt, // Parameter updatedAt bersifat opsional (tidak wajib diisi)
  });


  // ════════════════════════════════════════════════════════
  // FACTORY CONSTRUCTOR
  // Fungsi bantuan untuk mengubah data mentah Firestore menjadi objek Dart.
  // ════════════════════════════════════════════════════════

  factory CategoryModel.fromDocument(DocumentSnapshot doc) { // Membuat factory constructor bernama 'fromDocument' yang menerima parameter berupa satu dokumen mentah (DocumentSnapshot) dari Firestore
    final data = doc.data() as Map<String, dynamic>; // Mengonversi (casting) isi data mentah dokumen tersebut menjadi format Map (kamus pasangan kunci-nilai) bertipe String dan dynamic
    return CategoryModel( // Mengembalikan sebuah instansiasi objek CategoryModel yang baru dengan data yang sudah diekstrak
      id: doc.id, // Mengisi properti id dengan ID unik bawaan langsung dari dokumen Firestore
      name: data['name'] ?? '', // Mengambil nilai dari kunci 'name' di dalam Map data, jika nilainya tidak ada (null), maka gunakan string kosong ('') secara otomatis untuk mencegah error
      createdAt: data['createdAt'], // Mengambil nilai dari kunci 'createdAt' di dalam Map data dan memasukkannya ke properti createdAt
      updatedAt: data['updatedAt'], // Mengambil nilai dari kunci 'updatedAt' di dalam Map data dan memasukkannya ke properti updatedAt
    );
  }
}