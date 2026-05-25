// kontak_model.dart

// ════════════════════════════════════════════════════════════════
// BAGIAN IMPORTS
// Mengimpor library Firestore karena model ini perlu mengenali
// tipe data khusus dari Firebase seperti DocumentSnapshot dan Timestamp.
// ════════════════════════════════════════════════════════════════
import 'package:cloud_firestore/cloud_firestore.dart';

// ════════════════════════════════════════════════════════════════
// KELAS MODEL: Kontak
// Kelas ini berfungsi sebagai "cetak biru" (blueprint) untuk objek kontak.
// Daripada melempar data berbentuk Map mentah yang rawan typo, 
// kita membungkusnya menjadi objek 'Kontak' yang terstruktur rapi.
// ════════════════════════════════════════════════════════════════
class Kontak {
  // Properti-properti (variabel) yang dimiliki oleh setiap satu data Kontak.
  // Semuanya ditandai 'final' karena setelah objek ini dibuat, 
  // datanya tidak boleh diubah-ubah secara langsung (immutable data flow).
  final String id; // Menyimpan ID unik dokumen dari Firestore (bukan data di dalam field, tapi nama dokumennya)
  final String name; // Menyimpan nama kontak
  final String phone; // Menyimpan nomor telepon
  final String email; // Menyimpan alamat email
  final String notes; // Menyimpan catatan tambahan untuk kontak tersebut

  // ✅ TAMBAHAN
  // Menyimpan daftar kategori yang dimiliki oleh kontak ini.
  // Berbentuk List of String (array) karena satu kontak bisa masuk ke lebih dari satu kategori (misal: "Keluarga", "VIP").
  final List<String> categories; 

  // Menyimpan waktu kapan data dibuat dan kapan terakhir diperbarui.
  // Boleh bernilai null (?) karena saat membuat kontak baru di lokal, waktu dari server belum didapatkan.
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  // ════════════════════════════════════════════════════════════════
  // CONSTRUCTOR UTAMA
  // Fungsi yang dipanggil pertama kali saat kita ingin membuat
  // objek Kontak baru di dalam kode (misal: Kontak(name: 'Budi', ...)).
  // ════════════════════════════════════════════════════════════════
  Kontak({
    required this.id, // Wajib diisi (required)
    required this.name,
    required this.phone,
    required this.email,
    required this.notes,

    // ✅ TAMBAHAN
    required this.categories,

    this.createdAt, // Tidak wajib diisi (opsional) karena bisa null
    this.updatedAt, // Tidak wajib diisi (opsional) karena bisa null
  });

  // ════════════════════════════════════════════════════════════════
  // FACTORY CONSTRUCTOR: fromDocument (DESERIALIZATION)
  // Fungsi khusus untuk "menerjemahkan" data mentah yang baru saja
  // didownload dari Firestore (DocumentSnapshot) menjadi objek 'Kontak' di Flutter.
  // ════════════════════════════════════════════════════════════════
  factory Kontak.fromDocument(DocumentSnapshot doc) {
    // Mengonversi isi dokumen Firestore menjadi bentuk Map/Dictionary (Key-Value)
    final data = doc.data() as Map<String, dynamic>;

    // Mengembalikan (return) sebuah cetakan objek Kontak yang sudah diisi data dari database
    return Kontak(
      id: doc.id, // ID diambil langsung dari metadata dokumen Firestore, bukan dari isi field datanya
      
      // Mengambil data dari Map. 
      // Tanda '??' (Null-coalescing operator) artinya: "Jika datanya kosong/null dari database, berikan nilai default String kosong '' agar aplikasi tidak crash".
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      notes: data['notes'] ?? '',

      // ✅ AMBIL categories dari firestore
      // Karena data dari Firestore berupa tipe dinamik (dynamic list),
      // kita harus memaksanya (casting) menjadi bentuk List<String> murni yang dikenali Dart.
      // Jika field 'categories' tidak ada (null), maka gunakan list kosong [].
      categories: List<String>.from(
        data['categories'] ?? [],
      ),

      // Mengambil data waktu. Tidak perlu '??' karena properti ini memang mengizinkan nilai null.
      createdAt: data['created_at'],
      updatedAt: data['updated_at'],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // METODE: toMap (SERIALIZATION)
  // Kebalikan dari fromDocument. Fungsi ini menerjemahkan objek 'Kontak' 
  // yang ada di Flutter menjadi bentuk Map mentah. 
  // Firestore HANYA menerima data dalam bentuk Map, jadi fungsi ini 
  // wajib dipanggil sebelum melakukan operasi .add() atau .update().
  // ════════════════════════════════════════════════════════════════
  Map<String, dynamic> toMap() {
    return {
      'name': name, // Memasukkan variabel 'name' ke field key 'name'
      'phone': phone,
      'email': email,
      'notes': notes,

      // ✅ SIMPAN categories
      // Firestore secara otomatis mengenali List Dart dan akan menyimpannya sebagai tipe Array di database
      'categories': categories,

      // Logika Waktu Pembuatan (Create):
      // Jika createdAt sudah ada isinya (saat edit), gunakan waktu lama.
      // Jika kosong (saat tambah kontak baru), perintahkan server Firestore untuk mencatat waktu persis saat data masuk.
      'created_at':
          createdAt ??
              FieldValue.serverTimestamp(),

      // Logika Waktu Pembaruan (Update):
      // Selalu perintahkan server Firestore untuk mencetak stempel waktu terbaru setiap kali fungsi ini dipanggil (misal saat edit).
      'updated_at':
          FieldValue.serverTimestamp(),
    };
  }
}