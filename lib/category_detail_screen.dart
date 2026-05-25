// category_detail_screen.dart

// ════════════════════════════════════════════════════════════════
// BAGIAN IMPORTS & DEPENDENCIES
// Mengimpor library Flutter, Firebase, dan model internal aplikasi.
// ════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart'; // Mengimpor package Cloud Firestore untuk melakukan operasi database (baca, hapus, stream data)
import 'package:firebase_auth/firebase_auth.dart'; // Mengimpor package Firebase Auth untuk mengambil UID pengguna yang sedang masuk/login
import 'package:flutter/material.dart'; // Mengimpor package Material Design Flutter untuk membangun komponen antarmuka (UI Widget)

import 'category_model.dart'; // Mengimpor file model kategori untuk menggunakan struktur data dari objek CategoryModel
import 'select_contacts_screen.dart'; // Mengimpor file layar select_contacts_screen untuk navigasi saat menekan tombol 'ADD'


// ════════════════════════════════════════════════════════════════
// BAGIAN 1: LAYAR DETAIL KONTAK (READ ONLY)
// Class internal _ContactDetailScreen untuk menampilkan rincian data kontak.
// ════════════════════════════════════════════════════════════════

class _ContactDetailScreen extends StatelessWidget { // Membuat class internal _ContactDetailScreen bersifat StatelessWidget karena hanya menampilkan data (read-only)
  final Map<String, dynamic> data; // Deklarasi variabel data berupa Map untuk menampung data mentah detail kontak dari Firestore
  final String categoryName; // Deklarasi variabel string untuk menyimpan nama kategori dari kontak tersebut

  const _ContactDetailScreen({ // Constructor untuk class _ContactDetailScreen dengan parameter yang wajib diisi (required)
    required this.data, // Parameter data kontak wajib disertakan saat memanggil class ini
    required this.categoryName, // Parameter nama kategori wajib disertakan saat memanggil class ini
  });


  // ════════════════════════════════════════════════════════
  // HELPER METHOD: DEKORASI FIELD
  // Mendesain dekorasi input field agar seragam dan read-only.
  // ════════════════════════════════════════════════════════

  InputDecoration _fieldDecoration({required IconData icon}) { // Method helper untuk membuat dekorasi input text field agar seragam
    return InputDecoration( // Mengembalikan objek InputDecoration untuk mengatur gaya visual text field
      prefixIcon: Icon(icon, color: Colors.grey[700], size: 22), // Mengatur ikon di bagian awal field dengan warna abu-abu gelap ukuran 22
      filled: true, // Mengaktifkan warna latar belakang di dalam field
      fillColor: Colors.white, // Mengatur warna latar belakang field menjadi putih
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Memberi jarak dalam field (horizontal 20, vertikal 16)
      border: OutlineInputBorder( // Mengatur garis tepi default berbentuk kotak membulat
        borderRadius: BorderRadius.circular(25), // Mengatur radius kelengkungan sudut sebesar 25 pixel
        borderSide: const BorderSide(color: Colors.black, width: 1.2), // Mengatur warna garis tepi hitam dengan ketebalan 1.2
      ),
      enabledBorder: OutlineInputBorder( // Mengatur garis tepi ketika field dalam keadaan aktif/bisa digunakan
        borderRadius: BorderRadius.circular(25), // Mengatur radius kelengkungan sudut aktif sebesar 25 pixel
        borderSide: const BorderSide(color: Colors.black, width: 1.2), // Mengatur warna garis tepi aktif menjadi hitam
      ),
      disabledBorder: OutlineInputBorder( // Mengatur garis tepi ketika field dalam keadaan dinonaktifkan (read-only)
        borderRadius: BorderRadius.circular(25), // Mengatur radius kelengkungan sudut tidak aktif sebesar 25 pixel
        borderSide: const BorderSide(color: Colors.black, width: 1.2), // Mengatur warna garis tepi tidak aktif tetap hitam
      ),
    );
  }


  // ════════════════════════════════════════════════════════════════
  // METHOD BUILD: UI LAYAR DETAIL KONTAK
  // Membangun pohon widget untuk menampilkan informasi lengkap kontak.
  // ════════════════════════════════════════════════════════════════

  @override // Menandakan bahwa kita menulis ulang (override) method build dari parent class StatelessWidget
  Widget build(BuildContext context) { // Method utama untuk membangun struktur komponen UI pada layar detail kontak
    final String name = data['name'] ?? ''; // Mengambil data nama dari Map, jika bernilai null maka diganti dengan string kosong
    final String phone = data['phone'] ?? ''; // Mengambil data nomor telepon dari Map, jika null diganti string kosong
    final String email = data['email'] ?? ''; // Mengambil data email dari Map, jika null diganti string kosong
    final String notes = data['notes'] ?? ''; // Mengambil data catatan dari Map, jika null diganti string kosong

    return Scaffold( // Mengembalikan widget Scaffold sebagai struktur dasar halaman
      backgroundColor: Colors.white, // Mengatur warna latar belakang halaman menjadi putih
      appBar: AppBar( // Membuat komponen bar bagian atas layar
        backgroundColor: Colors.white, // Mengatur warna latar belakang AppBar menjadi putih
        elevation: 0, // Menghilangkan efek bayangan di bawah AppBar
        leadingWidth: 80, // Mengatur lebar ruang khusus untuk tombol kembali di sebelah kiri
        leading: Padding( // Memberikan jarak di sekeliling tombol leading
          padding: const EdgeInsets.only(left: 24, top: 6, bottom: 6), // Jarak spesifik: kiri 24, atas 6, bawah 6
          child: GestureDetector( // Widget untuk mendeteksi sentuhan/tap dari pengguna
            onTap: () => Navigator.pop(context), // Ketika ditap, layar akan ditutup dan kembali ke halaman sebelumnya
            child: Container( // Container berbentuk lingkaran sebagai tombol close
              width: 42, // Mengatur lebar container tombol 42 pixel
              height: 42, // Mengatur tinggi container tombol 42 pixel
              decoration: const BoxDecoration( // Mengatur dekorasi visual container
                color: Color(0xFFF5F5F5), // Warna latar belakang abu-abu sangat muda
                shape: BoxShape.circle, // Mengubah bentuk container menjadi lingkaran sempurna
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 26), // Menampilkan ikon silang berwarna hitam ukuran 26
            ),
          ),
        ),
        centerTitle: true, // Mengatur posisi judul AppBar agar berada tepat di tengah
        title: const Text( // Menampilkan teks judul pada AppBar
          'Contact Detail', // Teks yang ditampilkan
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black), // Gaya teks: ukuran 20, semi-bold, warna hitam
        ),
      ),
      body: SingleChildScrollView( // Membuat area konten di bawah AppBar bisa digulir jika ukurannya melebihi layar
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Memberikan padding halaman (horizontal 20, vertikal 24)
        child: Column( // Menyusun komponen detail secara vertikal dari atas ke bawah
          children: [ // Daftar widget di dalam Column
            // AVATAR
            Container( // Container untuk menampilkan bingkai foto/avatar profil
              width: 120, // Lebar bingkai avatar 120 pixel
              height: 120, // Tinggi bingkai avatar 120 pixel
              decoration: BoxDecoration( // Mengatur dekorasi bingkai
                shape: BoxShape.circle, // Bentuk lingkaran
                border: Border.all(color: Colors.black, width: 2), // Memberikan garis tepi hitam dengan ketebalan 2 pixel
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.black), // Menampilkan ikon orang bawaan di tengah lingkaran
            ),

            const SizedBox(height: 16), // Memberikan jarak vertikal sebesar 16 pixel

            // NAME
            Text( // Widget untuk menampilkan nama kontak
              name, // String nama hasil ekstraksi data di atas
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black), // Gaya teks nama: ukuran 22, tebal, warna hitam
            ),

            const SizedBox(height: 32), // Memberikan jarak vertikal sebesar 32 pixel sebelum masuk ke form fields

            // PHONE
            TextFormField( // Field teks untuk menampilkan nomor telepon
              initialValue: phone, // Mengisi nilai awal field dengan nomor telepon kontak
              readOnly: true, // Mengatur field menjadi hanya bisa dibaca (tidak bisa diketik/diedit)
              keyboardType: TextInputType.phone, // Mengatur tipe keyboard khusus nomor telepon (jika aktif)
              style: const TextStyle(fontSize: 16), // Mengatur ukuran font teks di dalam field sebesar 16
              decoration: _fieldDecoration(icon: Icons.phone), // Memanggil fungsi dekorasi dengan ikon telepon
            ),

            const SizedBox(height: 12), // Memberikan spasi vertikal sebesar 12 pixel antar field

            // EMAIL
            TextFormField( // Field teks untuk menampilkan email kontak
              initialValue: email, // Mengisi nilai awal field dengan email kontak
              readOnly: true, // Mengatur field menjadi hanya bisa dibaca
              keyboardType: TextInputType.emailAddress, // Mengatur tipe keyboard khusus alamat email
              style: const TextStyle(fontSize: 16), // Mengatur ukuran font teks sebesar 16
              decoration: _fieldDecoration(icon: Icons.email), // Memanggil fungsi dekorasi dengan ikon email
            ),

            const SizedBox(height: 12), // Memberikan spasi vertikal sebesar 12 pixel


            // ════════════════════════════════════════════════════════
            // SUB-BAGIAN: NOTES & KATEGORI
            // Menampilkan catatan multiline kustom dan badge kategori.
            // ════════════════════════════════════════════════════════

            // NOTES
            Stack( // Menggunakan Stack untuk menumpuk label teks di atas field catatan kustom
              children: [ // Daftar widget di dalam Stack
                TextFormField( // Field teks untuk menampilkan catatan/notes kontak
                  initialValue: notes, // Mengisi nilai awal field dengan catatan kontak
                  readOnly: true, // Mengatur field menjadi hanya bisa dibaca
                  maxLines: 5, // Mengatur tinggi field agar muat hingga 5 baris teks
                  style: const TextStyle(fontSize: 16, color: Colors.black), // Mengatur gaya teks catatan
                  decoration: InputDecoration( // Membuat dekorasi kustom khusus untuk catatan
                    filled: true, // Mengaktifkan warna latar belakang
                    fillColor: Colors.white, // Warna latar putih
                    contentPadding: const EdgeInsets.fromLTRB(16, 68, 16, 16), // Jarak teks dalam field: kiri 16, atas 68 (memberi ruang untuk label), kanan 16, bawah 16
                    border: OutlineInputBorder( // Gaya garis tepi default notes
                      borderRadius: BorderRadius.circular(20), // Radius sudut kelengkungan sebesar 20 pixel
                      borderSide: const BorderSide(color: Colors.black, width: 1.2), // Warna hitam tebal 1.2
                    ),
                    enabledBorder: OutlineInputBorder( // Garis tepi saat notes aktif
                      borderRadius: BorderRadius.circular(20), // Radius kelengkungan 20 pixel
                      borderSide: const BorderSide(color: Colors.black, width: 1.2), // Warna hitam tebal 1.2
                    ),
                    disabledBorder: OutlineInputBorder( // Garis tepi saat notes tidak aktif (read-only)
                      borderRadius: BorderRadius.circular(20), // Radius kelengkungan 20 pixel
                      borderSide: const BorderSide(color: Colors.black, width: 1.2), // Warna hitam tebal 1.2
                    ),
                  ),
                ),
                Positioned( // Menempatkan label teks kustom secara statis di posisi tertentu di atas field
                  top: 12, // Jarak 12 pixel dari sisi atas container Stack
                  left: 16, // Jarak 16 pixel dari sisi kiri container Stack
                  child: Text( // Widget teks untuk label penanda judul catatan
                    'Notes..', // Teks label
                    style: TextStyle(color: Colors.grey[400], fontSize: 16), // Gaya teks: warna abu-abu terang, ukuran 16
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12), // Memberikan spasi vertikal sebesar 12 pixel sebelum komponen kategori

            // ASSIGNED TO
            Container( // Container kotak informasi status penempatan kategori kontak
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Padding dalam box: horizontal 16, vertikal 14
              decoration: BoxDecoration( // Mengatur dekorasi box informasi kategori
                color: Colors.white, // Warna background putih
                borderRadius: BorderRadius.circular(25), // Membuat sudut membulat dengan radius 25 pixel
                border: Border.all(color: Colors.black, width: 1.2), // Garis tepi hitam setebal 1.2
              ),
              child: Row( // Menyusun ikon dan teks informasi kategori secara horizontal
                children: [ // Daftar widget di dalam Row
                  Icon(Icons.people_alt_rounded, color: Colors.grey[700], size: 22), // Menampilkan ikon sekelompok orang berwarna abu-abu gelap ukuran 22
                  const SizedBox(width: 12), // Memberikan jarak horizontal sebesar 12 pixel sebelum teks
                  Column( // Menyusun teks label dan nama kategori secara vertikal ke bawah
                    crossAxisAlignment: CrossAxisAlignment.start, // Mengatur teks agar rata kiri di dalam kolom
                    children: [ // Daftar widget di dalam Column teks
                      Text('Assigned to', style: TextStyle(fontSize: 13, color: Colors.grey[600])), // Menampilkan teks label kecil 'Assigned to' berwarna abu-abu
                      const SizedBox(height: 4), // Spasi vertikal kecil 4 pixel antar teks
                      Container( // Container kecil berbentuk badge pil untuk menampilkan nama kategori
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Jarak dalam badge: horizontal 12, vertikal 4
                        decoration: BoxDecoration( // Dekorasi badge kategori
                          color: const Color(0xFFE0E0E0), // Warna latar badge abu-abu muda
                          borderRadius: BorderRadius.circular(20), // Membuat sudut badge membulat penuh seperti pil
                        ),
                        child: Text( // Widget teks untuk menampilkan nama kategori utama halaman ini
                          categoryName, // Variabel string nama kategori
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87), // Gaya teks kategori: ukuran 14, medium, warna hitam samar
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════
// BAGIAN 2: LAYAR UTAMA DETAIL KATEGORI (STATEFUL)
// Class utama untuk mengelola daftar kontak di dalam kategori tertentu.
// ════════════════════════════════════════════════════════════════

class CategoryDetailScreen extends StatefulWidget { // Membuat class layar utama Detail Kategori dengan sifat StatefulWidget karena datanya dinamis (bisa cari & hapus)
  final CategoryModel category; // Deklarasi properti objek data kategori yang sedang dibuka datanya
  final void Function(int) onRequestTabChange; // Deklarasi callback fungsi untuk meminta perubahan tab pada navigasi utama jika dibutuhkan

  const CategoryDetailScreen({ // Constructor untuk class CategoryDetailScreen
    super.key, // Meneruskan key parameter ke parent class StatefulWidget
    required this.category, // Membawa data objek kategori yang wajib dikirim dari halaman sebelumnya
    required this.onRequestTabChange, // Membawa callback fungsi tab change yang wajib dikirim
  });

  @override // Menandakan penulisan ulang pembuatan State halaman
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState(); // Membuat dan mengaitkan objek State kustom halaman ini
}


// ════════════════════════════════════════════════════════════════
// BAGIAN 3: STATE MANAGEMENT DETAIL KATEGORI
// Mengatur variabel, sinkronisasi data, dan komponen UI dinamis.
// ════════════════════════════════════════════════════════════════

class _CategoryDetailScreenState extends State<CategoryDetailScreen> { // Class State utama, tempat seluruh logika kontrol data kategori dijalankan
  final uid = FirebaseAuth.instance.currentUser!.uid; // Mengambil dan menyimpan UID pengguna aktif langsung dari Firebase Auth saat inisialisasi state

  final TextEditingController _searchController = TextEditingController(); // Membuat controller untuk memanipulasi teks pencarian pada input search bar

  String _searchQuery = ''; // Variabel state untuk menyimpan kata kunci pencarian yang diketik pengguna secara real-time
  bool _isRemoveMode = false; // Variabel penanda status mode hapus, bernilai true jika user mengaktifkan mode hapus kontak dari kategori

  late final CollectionReference contactsCollection = FirebaseFirestore.instance // Inisialisasi referensi sub-koleksi kontak di dalam dokumen kategori tertentu
      .collection('users') // Mengarah ke koleksi utama 'users'
      .doc(uid) // Masuk ke dokumen user berdasarkan UID aktif
      .collection('categories') // Masuk ke sub-koleksi 'categories' milik user tersebut
      .doc(widget.category.id) // Masuk ke dokumen kategori spesifik berdasarkan ID kategori yang dikirim dari widget
      .collection('contacts'); // Masuk ke sub-koleksi 'contacts' yang berisi daftar kontak dalam kategori ini

  late final CollectionReference _mainKontakCollection = FirebaseFirestore.instance // Inisialisasi referensi koleksi kontak utama milik user untuk sinkronisasi data
      .collection('users') // Mengarah ke koleksi utama 'users'
      .doc(uid) // Masuk ke dokumen user berdasarkan UID aktif
      .collection('kontak'); // Mengarah ke sub-koleksi utama bernama 'kontak'


  // ════════════════════════════════════════════════════════
  // SIKLUS HIDUP WIDGET (LIFECYCLE)
  // Menginisialisasi dan membersihkan resource memori.
  // ════════════════════════════════════════════════════════

  @override // Menandakan penulisan ulang method siklus hidup inisialisasi state awal
  void initState() { // Method yang otomatis dijalankan satu kali saat halaman pertama kali dibangun
    super.initState(); // Menjalankan fungsionalitas dasar initState milik parent class
    _syncDeletedContacts(); // Memanggil fungsi async untuk menyinkronkan data kontak yang mungkin sudah dihapus di daftar utama
  }

  @override // Menandakan penulisan ulang method siklus hidup penghancuran state
  void dispose() { // Method yang otomatis berjalan ketika halaman ditutup/dihapus selamanya untuk menghemat memori
    _searchController.dispose(); // Menghapus instansiasi pencarian teks controller dari memori untuk menghindari kebocoran memori (memory leak)
    super.dispose(); // Menjalankan fungsionalitas dispose milik parent class
  }


  // ════════════════════════════════════════════════════════
  // OPERASI LOGIKA & FIREBASE METHODS
  // Menangani sinkronisasi data, dialog konfirmasi, dan hapus kontak.
  // ════════════════════════════════════════════════════════

  // SNACKBAR
  void _showSnackbar(String message, Color color) { // Method helper untuk memunculkan snackbar berisi info status sukses/gagal di bagian bawah layar
    ScaffoldMessenger.of(context).showSnackBar( // Memerintahkan manajer scaffold messenger untuk menampilkan bar pesan cetak
      SnackBar(content: Text(message), backgroundColor: color), // Membuat objek SnackBar dengan string pesan dan warna latar kustom
    );
  }

  // SYNC DELETE CONTACTS
  Future<void> _syncDeletedContacts() async { // Method async untuk membersihkan kontak usang di dalam kategori jika kontak tersebut sudah dihapus dari kontak utama
    try { // Blok pengaman try untuk menangkap kendala jaringan atau kegagalan query database
      final categorySnap = await contactsCollection.get(); // Mengambil seluruh snapshot dokumen data kontak yang ada di kategori saat ini dari Firestore

      for (final doc in categorySnap.docs) { // Melakukan perulangan urutan memeriksa satu per satu dokumen kontak yang berhasil diambil
        final mainDoc = await _mainKontakCollection.doc(doc.id).get(); // Memeriksa apakah ID kontak tersebut masih eksis di dalam koleksi kontak utama
        if (!mainDoc.exists) { // Kondisi jika dokumen kontak di daftar utama ternyata sudah tidak ditemukan lagi (telah terhapus)
          await doc.reference.delete(); // Menghapus secara otomatis dokumen referensi kontak usang tersebut dari dalam sub-koleksi kategori ini
        }
      }
    } catch (_) {} // Blok catch dikosongkan agar jika terjadi error sync, aplikasi tidak crash dan gagal diam-diam
  }

  // CONFIRM DIALOG
  Future<bool?> _showConfirmDialog() { // Method untuk memunculkan popup kotak dialog konfirmasi pembatalan/penghapusan kontak, mengembalikan sinyal boolean
    return showDialog<bool>( // Menampilkan widget pop-up dialog bawaan Flutter ke layar dengan tipe data pengembalian bool
      context: context, // Menggunakan context aktif untuk menempatkan dialog di atas halaman
      barrierDismissible: false, // Menghalangi pengguna menutup dialog secara acak dengan mengetuk area kosong di luar kotak popup
      builder: (ctx) => Dialog( // Membangun struktur kustom tampilan kotak dialog menggunakan context lokal dialog (ctx)
        backgroundColor: Colors.white, // Mengatur latar kotak dialog berwarna putih
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // Mengatur sudut siku kotak dialog menjadi membulat mulus sebesar 28 pixel
        child: Padding( // Memberikan spasi padding di dalam kotak dialog
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24), // Sisi padding: kiri 24, atas 28, kanan 24, bawah 24
          child: Column( // Menyusun susunan judul pertanyaan dan tombol pilihan aksi secara vertikal ke bawah
            mainAxisSize: MainAxisSize.min, // Memaksa ukuran tinggi kolom menciut seminimal mungkin mengikuti isi teks kontennya
            children: [ // Daftar widget komponen isi dialog
              const Text( // Widget teks berupa string pertanyaan konfirmasi hapus kontak
                'Remove this contact from category?', // Isi pesan pertanyaan teks konfirmasi
                textAlign: TextAlign.center, // Mengatur tulisan pertanyaan agar rata tengah teks
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Gaya teks pertanyaan: font ukuran 20, tebal
              ),
              const SizedBox(height: 20), // Jarak spasi vertikal setinggi 20 pixel sebelum tombol aksi pilihan diletakkan
              Row( // Menyusun tombol NO dan YES sejajar secara horizontal ke samping kiri-kanan
                children: [ // Daftar widget tombol aksi pilihan di dalam Row
                  Expanded( // Membungkus tombol pertama agar ukurannya memanjang elastis mengisi setengah porsi lebar baris ruang kosong yang tersedia
                    child: GestureDetector( // Mendeteksi ketukan sentuhan jari user pada area area tombol NO
                      onTap: () => Navigator.pop(ctx, false), // Saat area ditap, tutup dialog popup dan kirimkan data nilai balik berupa logika 'false'
                      child: Container( // Wadah pembentuk tampilan desain visual tombol NO berbentuk pil abu-abu
                        padding: const EdgeInsets.symmetric(vertical: 14), // Ketebalan area tombol dari dalam secara vertikal sebesar 14 pixel
                        decoration: BoxDecoration( // Mengatur dekorasi kontainer tombol NO
                          color: const Color(0xFFE0E0E0), // Warna latar tombol abu-abu netral penanda batal
                          borderRadius: BorderRadius.circular(50), // Membulatkan sudut tepi container penuh sebesar 50 pixel berbentuk kapsul/pil
                        ),
                        alignment: Alignment.center, // Menaruh posisi teks label berada presisi di tengah-tengah wadah tombol
                        child: const Text('NO', style: TextStyle(fontWeight: FontWeight.bold)), // Teks bertuliskan 'NO' berkarakter tebal
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), // Memberikan jarak celah horizontal sejauh 12 pixel di antara tombol NO dan tombol YES
                  Expanded( // Membungkus tombol kedua agar ukurannya memanjang elastis mengisi sisa porsi baris ruang kosong
                    child: GestureDetector( // Mendeteksi ketukan sentuhan jari user pada area area tombol YES
                      onTap: () => Navigator.pop(ctx, true), // Saat area ditap, tutup dialog popup dan kirimkan data nilai balik berupa logika 'true'
                      child: Container( // Wadah pembentuk tampilan desain visual tombol YES berbentuk pil biru cerah
                        padding: const EdgeInsets.symmetric(vertical: 14), // Ketebalan tombol dari dalam secara vertikal sebesar 14 pixel
                        decoration: BoxDecoration( // Mengatur dekorasi kontainer tombol YES
                          color: Color(0xFF42AAFF), // Warna latar biru cerah sebagai penanda setuju hapus data
                          borderRadius: BorderRadius.circular(50), // Membulatkan sudut tepi container penuh sebesar 50 pixel berbentuk kapsul
                        ),
                        alignment: Alignment.center, // Menaruh posisi teks berada presisi di tengah-tengah wadah tombol
                        child: const Text( // Widget komponen teks label tombol YES
                          'YES', // Teks bertuliskan 'YES'
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Gaya teks: warna putih kontras, cetak tebal
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // REMOVE CONTACT
  Future<void> _removeContact(String id) async { // Method async untuk menghapus relasi kontak dari sub-koleksi kategori berdasarkan ID kontak yang dikirim
    final confirm = await _showConfirmDialog(); // Menjalankan dialog konfirmasi dan merekam nilai baliknya (true/false) ke variabel confirm
    if (confirm != true) return; // Jika pengguna memilih batal atau menekan NO (nilai bukan true), hentikan eksekusi fungsi secara instan

    try { // Blok try untuk menangani operasi penghapusan dokumen database Firestore
      await contactsCollection.doc(id).delete(); // Mengakses dokumen kontak tertentu berdasarkan ID di sub-koleksi kategori lalu menghapusnya secara permanen
      if (mounted) _showSnackbar('Contact removed from category', Colors.green); // Jika widget halaman masih terpasang, tampilkan snackbar sukses berwarna hijau
    } catch (e) { // Blok catch untuk menangkap kendala tak terduga saat proses hapus dari Firestore gagal dilakukan
      if (mounted) _showSnackbar('Failed to remove contact', Colors.red); // Jika gagal dan widget masih ada, tampilkan pesan gagal berwarna merah kustom
    }
  }

  void _showContactDetail(Map<String, dynamic> data) { // Method pembantu untuk membuka layar rincian detail kontak read-only dengan melemparkan data kontak terkait
    Navigator.push( // Memerintahkan objek navigator untuk menumpuk halaman baru ke atas layar aktif saat ini
      context, // Menggunakan context aplikasi saat ini untuk menjalankan perpindahan navigasi route
      MaterialPageRoute( // Membuat rute animasi halaman baru berbasis Material Design Flutter
        builder: (_) => _ContactDetailScreen( // Membangun halaman internal _ContactDetailScreen
          data: data, // Menyertakan parameter isi dokumen Map data kontak yang dipilih user
          categoryName: widget.category.name, // Menyertakan string nama kategori dari widget stateful utama ke halaman detail
        ),
      ),
    );
  }


  // ════════════════════════════════════════════════════════
  // WIDGET BUILDER HELPERS
  // Kumpulan fungsi pembuat komponen UI kustom (Tombol Pil, Search Bar, List Tile).
  // ════════════════════════════════════════════════════════

  // FIX: Added `disabled` parameter to properly support greying out the button
  Widget _buildPillButton({ // Komponen widget kustom pembentuk tombol berbentuk pil elastis multifungsi (bisa aktif, nonaktif, atau abu-abu)
    required Widget child, // Parameter komponen widget anak yang wajib disisipkan di dalam tombol pil (bisa berupa teks atau ikon)
    required VoidCallback onTap, // Parameter callback fungsi fungsi kosong yang wajib dieksekusi saat tombol pil tersentuh jari
    bool isActive = false, // Properti opsional penanda status aktif tombol pil, nilai awal diatur bawaan salah (false)
    bool disabled = false, // Properti opsional penanda status nonaktif/tidak bisa diklik (tambahan perbaikan), nilai bawaan salah (false)
  }) {
    return GestureDetector( // Menggunakan pendeteksi sentuhan GestureDetector untuk membungkus area visual tombol pil
      onTap: disabled ? null : onTap, // Logika seleksi: jika status disabled true maka fungsi tap dinonaktifkan (null), jika tidak jalankan callback onTap
      child: Container( // Wadah utama pendesain bentuk fisik visual tombol pil luar-dalam
        height: 46, // Menetapkan tinggi patokan kontainer tombol pil sebesar 46 pixel
        padding: const EdgeInsets.symmetric(horizontal: 20), // Memberikan batas ketebalan ruang tombol bagian dalam sisi kiri-kanan sebesar 20 pixel
        decoration: BoxDecoration( // Mengatur manajemen dekorasi visual pembungkus kotak tombol pil
          color: disabled // Logika penentuan warna latar tombol pil berdasarkan parameter status:
              ? const Color(0xFFF5F5F5)   // Jika tombol berstatus disabled, berikan corak warna latar abu-abu redup samar
              : isActive // Saringan kedua: jika status tombol aktif (true)
                  ? const Color(0xFFDDF1FF) // Berikan corak warna latar biru muda transparan penanda sedang aktif digunakan
                  : Colors.white, // Opsi bawaan jika normal: berikan warna latar putih bersih
          borderRadius: BorderRadius.circular(23), // Membulatkan kelengkungan sudut penuh sebesar 23 pixel (setengah dari tinggi 46) membentuk kapsul pil sempurna
          border: Border.all( // Mengatur gaya visual warna dan ketebalan garis tepi terluar tombol pil
            color: disabled // Logika penentuan warna garis tepi luar tombol pil:
                ? Colors.grey.shade400     // Jika berstatus disabled, warnai garis luar dengan warna abu-abu pudar tipis
                : isActive // Saringan kedua: jika status tombol aktif digunakan
                    ? const Color(0xFF2196F3) // Warnai garis luar dengan warna biru tegas komersial
                    : Colors.black87, // Opsi bawaan normal: garis luar diwarnai hitam legam pekat samar
            width: 1.1, // Ketebalan konstan garis tepi luar tombol pil sebesar 1.1 pixel
          ),
        ),
        child: Center(child: child), // Menaruh widget anak (child) berada presisi lurus di bagian tengah-tengah ruang tombol pil kustom
      ),
    );
  }

  Widget _buildSearchBar() { // Method kustom pembentuk kolom komponen bilah kolom pencarian teks kontak (Search Bar)
    return Container( // Wadah container luar pelindung bentuk visual search bar kustom
      height: 52, // Menentukan tinggi fisik kolom bar pencarian teks sebesar 52 pixel
      decoration: BoxDecoration( // Mengatur gaya dekorasi luar wadah search bar
        borderRadius: BorderRadius.circular(30), // Kelengkungan sudut membulat penuh di sisi tepi kanan-kiri bar sebesar 30 pixel
        border: Border.all(color: Colors.black87, width: 1.1), // Garis pembatas terluar tipis berwarna hitam pekat samar berkekuatan tebal 1.1 pixel
      ),
      child: TextField( // Widget input teks TextField tempat user mengetik huruf kata kunci pencarian nama kontak
        controller: _searchController, // Menyambungkan field input ketikan dengan controller penampung teks _searchController di atas
        onChanged: (value) { // Callback event otomatis yang mendeteksi setiap kali ada perubahan ketikan karakter huruf baru di kolom search bar
          setState(() => _searchQuery = value.trim().toLowerCase()); // Memperbarui state query pencarian dengan teks ketikan baru tanpa spasi ujung, berformat huruf kecil semua
        },
        decoration: InputDecoration( // Mengatur hiasan tata letak ikon placeholder internal di dalam kolom input TextField
          hintText: 'Search...', // Mengisi teks petunjuk samar bertuliskan 'Search...' sebelum user mulai mengetik sesuatu
          border: InputBorder.none, // Menghilangkan garis bawah default bawaan asli widget TextField agar tidak merusak visual dekorasi container luar
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.black87), // Menampilkan simbol dekorasi ikon kaca pembesar berwarna hitam samar di posisi pangkal kiri
          contentPadding: const EdgeInsets.symmetric(vertical: 14), // Ketebalan jarak baris ketikan bagian dalam secara vertikal sebesar 14 pixel agar simetris
          hintStyle: TextStyle(color: Colors.grey[400]), // Mengatur corak warna teks petunjuk 'Search...' menjadi abu-abu pudar samar
        ),
      ),
    );
  }

  Widget _buildContactTile({ // Method helper pembuat template satu baris bar kotak daftar data nama kontak (List Tile) kustom
    required String id, // Parameter wajib pembawa string ID unik dokumen kontak dari database Firestore
    required Map<String, dynamic> data, // Parameter wajib berisi Map pasangan field objek data data kontak (nama, nomor, dll)
  }) {
    return GestureDetector( // Menggunakan pendeteksi ketukan sentuh untuk area list tile kontak agar bisa merespon interaksi user
      onTap: () { // Callback aksi tap yang dipicu saat baris salah satu kotak nama kontak disentuh
        if (!_isRemoveMode) { // Logika penyaring mode: Jika aplikasi saat ini SEDANG TIDAK dalam mode hapus data kontak (_isRemoveMode bernilai false)
          _showContactDetail(data); // Eksekusi method pembuka layar pop-up detail rincian kontak data tersebut secara utuh (mode read-only)
        }
      },
      child: Container( // Wadah utama pendesain visual fisik kotak baris penampung nama kontak tunggal
        margin: const EdgeInsets.only(bottom: 12), // Memberikan spasi jarak renggang luar khusus di sisi bawah kotak sejauh 12 pixel agar antar baris tidak menempel
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Jarak spasi ruang dalam kotak baris kontak: horizontal 16, vertikal 12 pixel
        decoration: BoxDecoration( // Mengatur dekorasi komponen kotak baris kontak kustom
          color: Colors.white, // Mengatur warna dasar dalam kotak kontak menjadi putih bersih
          borderRadius: BorderRadius.circular(25), // Kelengkungan sudut-sudut siku tepi kotak kontak dihaluskan sebesar 25 pixel
          border: Border.all(color: const Color(0xFF2196F3), width: 1.0), // Garis pembatas tepi kotak diwarnai biru komersial dengan ketebalan standar 1.0 pixel
        ),
        child: Row( // Menyusun susunan ikon profil, teks nama, dan tombol aksi hapus (jika aktif) secara horizontal ke samping dalam satu baris
          children: [ // Daftar urutan widget di dalam Row baris kontak
            const Icon(Icons.person, color: Color(0xFF2196F3), size: 24), // Menampilkan ikon lambang orang berwarna biru kokoh berukuran standar 24 pixel di sisi awal kiri
            const SizedBox(width: 14), // Memberikan celah kosong horizontal sejauh 14 pixel di antara ikon profil orang dan letak teks nama kontak
            Expanded( // Membungkus widget teks nama agar ukuran lebarnya fleksibel elastis menghabiskan sisa ruang baris tanpa memicu error layout menyundul batas kanan
              child: Text( // Widget teks untuk mencetak nama kontak di layar aplikasi
                data['name'] ?? '', // Menampilkan string nama dari data Map, jika null otomatis diganti string kosong agar aman dari crash
                overflow: TextOverflow.ellipsis, // Menghalangi kerusakan visual jika nama terlalu panjang dengan memotong teks diganti tanda titik-titik tiga (...) di ujung baris
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black87), // Mengatur gaya font teks nama: ukuran 17, tebal medium, hitam pekat samar
              ),
            ),
            if (_isRemoveMode) // Kondisi percabangan UI: JIKA status mode hapus aktif (_isRemoveMode bernilai logika true), maka munculkan widget berikut:
              GestureDetector( // Pendeteksi ketukan sentuh terisolasi khusus area tombol aksi hapus silang merah
                onTap: () => _removeContact(id), // Saat tombol silang ditap, jalankan method penghapus kontak dari kategori berdasarkan parameter ID dokumen terkait
                child: const Padding( // Memberikan bantalan jarak sentuh aman di sekeliling ikon tombol silang merah
                  padding: EdgeInsets.only(left: 8), // Memberikan celah pembatas khusus di sisi kiri ikon silang sebesar 8 pixel agar tidak terlalu rapat dengan teks nama
                  child: Icon(Icons.close_rounded, color: Colors.red, size: 24), // Menampilkan simbol ikon silang tajam (close) berwarna merah menyala dengan ukuran diameter 24
                ),
              ),
          ],
        ),
      ),
    );
  }


  // ════════════════════════════════════════════════════════════════
  // METHOD BUILD UTAMA: STRUKTUR UI HALAMAN DETAIL KATEGORI
  // Merender seluruh susunan tata letak halaman dan stream database.
  // ════════════════════════════════════════════════════════════════

  @override // Menandakan penulisan ulang method utama build penentu arsitektur tampilan UI halaman detail kategori secara keseluruhan
  Widget build(BuildContext context) { // Method utama perancang pohon hierarki widget (Widget Tree) halaman detail kategori
    return Scaffold( // Mengembalikan pondasi widget Scaffold pembangun utama struktur halaman detail kategori
      backgroundColor: Colors.white, // Menetapkan warna dasar latar belakang halaman detail kategori menjadi putih bersih seluruhnya
      body: SafeArea( // Membungkus konten utama agar posisi layout otomatis bergeser menghindari area poni layar, notch, atau status bar perangkat hp
        child: Column( // Menyusun komponen susunan bagian halaman (Header, Action Button, Search Bar, List Data) secara berurutan vertikal ke bawah
          children: [ // Daftar baris komponen utama di dalam susunan Column halaman
            const SizedBox(height: 10), // Jarak spasi vertikal setinggi 10 pixel dari batas atas SafeArea sebelum baris judul dipasang

            Padding( // Memberikan jarak bantalan di sekeliling area komponen Baris Judul halaman (Header Halaman)
              padding: const EdgeInsets.symmetric(horizontal: 20), // Jarak renggang pembatas kiri-kanan baris judul sebesar 20 pixel dari tepi layar hp
              child: Row( // Menyusun tombol lingkaran kembali dan judul teks nama kategori secara horizontal beriringan ke samping kiri-kanan
                children: [ // Daftar komponen di dalam baris Row Header halaman
                  GestureDetector( // Mendeteksi interaksi ketukan sentuhan jari user pada area tombol lingkaran kembali (Back Button)
                    onTap: () => Navigator.pop(context), // Ketika area lingkaran disentuh, tutup halaman aktif ini dan mundurkan layar kembali ke halaman sebelumnya
                    child: Container( // Wadah pembentuk fisik tombol navigasi kembali berupa bulatan lingkaran abu-abu ringan kustom
                      width: 46, // Menetapkan lebar bulat kontainer tombol kembali sebesar 46 pixel
                      height: 46, // Menetapkan tinggi bulat kontainer tombol kembali sebesar 46 pixel
                      decoration: const BoxDecoration( // Mengatur gaya dekorasi bulatan tombol kembali kustom
                        color: Color(0xFFEAEAEA), // Mengatur warna latar bulatan tombol menjadi abu-abu muda netral kontras ringan
                        shape: BoxShape.circle, // Mengubah bentuk fisik container kotak default menjadi bentuk lingkaran bulat sempurna
                      ),
                      child: const Icon(Icons.arrow_back_rounded), // Menaruh simbol ikon anak panah melengkung kembali (Back) tepat di titik poros tengah lingkaran
                    ),
                  ),
                  Expanded( // Membungkus area judul teks tengah agar lebarnya fleksibel meluas secara dinamis menyeimbangkan ruang sisa baris
                    child: Center( // Memaksa posisi kedudukan teks nama judul kategori agar tegak lurus berada tepat di tengah-tengah ruang baris header
                      child: Text( // Widget komponen teks untuk mencetak judul nama kategori utama halaman aktif ini
                        widget.category.name, // Memanggil string nama data kategori yang diwarisi dari properti parameter widget stateful utama di atas
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600), // Gaya tulisan judul kategori: ukuran huruf besar 22, ketebalan semi-bold kuat
                      ),
                    ),
                  ),
                  const SizedBox(width: 46), // Membuat kotak celah kosong tiruan statis selebar 46 pixel di paling kanan untuk mengimbangi lebar tombol kembali agar teks judul tetap simetris di tengah
                ],
              ),
            ),

            const SizedBox(height: 20), // Spasi jarak jeda vertikal setinggi 20 pixel di bawah komponen header sebelum masuk ke area tombol kendali aksi

            Padding( // Memberikan jarak bantalan di sekeliling wilayah baris sepasang Tombol Aksi (Tombol Mode Hapus dan Tombol Tambah Kontak)
              padding: const EdgeInsets.symmetric(horizontal: 20), // Menghalangi area sepasang tombol aksi menempel ke tepi layar dengan pembatas kiri-kanan sejauh 20 pixel
              child: Row( // Menyusun tombol aksi hapus (kiri) dan tombol aksi tambah data (kanan) sejajar horizontal dalam satu baris sampingan
                children: [ // Daftar widget tombol aksi di dalam komponen Row pengendali tombol
                  _buildPillButton( // Memanggil method kustom tombol pil untuk mencetak Tombol Saklar Mode Hapus (Toggle Delete Mode Button)
                    isActive: _isRemoveMode, // Mengikat status aktif warna tombol pil mengikuti status boolean dinamika variabel _isRemoveMode
                    onTap: () => setState(() => _isRemoveMode = !_isRemoveMode), // Mengubah status logika variabel _isRemoveMode berbalik (true ke false / sebaliknya) lalu memperbarui tampilan UI lewat setState
                    child: Icon( // Menyisipkan anak widget (child) berupa simbol ikon tong sampah ke dalam bagian tengah tombol pil kustom
                      Icons.delete_rounded, // Tipe bentuk ikon berupa gambar tong sampah bersudut halus melengkung kustom
                      size: 21, // Ukuran kekuatan diameter ikon tong sampah diatur sebesar 21 pixel
                      color: _isRemoveMode ? const Color(0xFF1976D2) : Colors.black87, // Seleksi warna ikon: jika mode hapus aktif warnai ikon dengan biru tua, jika normal hitam pekat samar
                    ),
                  ),
                  const Spacer(), // Widget pendorong otomatis yang menghabiskan seluruh sisa sela ruang kosong baris di tengah agar tombol ADD terdorong mentok ke posisi paling ujung kanan baris
                  _buildPillButton( // Memanggil method kustom tombol pil untuk mencetak Tombol Navigasi Tambah Data Kontak (ADD Button)
                    disabled: _isRemoveMode, // Mengunci parameter perbaikan tombol: jika mode hapus aktif (true), ubah tampilan tombol ADD menjadi mati/abu-abu (disabled)
                    onTap: () { // Callback fungsi navigasi yang dieksekusi saat tombol pil bertulisan teks 'ADD' tersentuh ketukan jari
                      Navigator.push( // Menumpuk layar baru ke atas halaman aktif untuk berpindah ke layar seleksi penambahan kontak baru
                        context, // Context aplikasi aktif untuk memicu peluncuran perpindahan navigasi halaman
                        MaterialPageRoute( // Membuat transisi perpindahan rute halaman bergaya Material Design Flutter standar hp
                          builder: (_) => SelectContactsScreen( // Membangun halaman tujuan baru bernama SelectContactsScreen
                            categoryId: widget.category.id, // Mengirimkan parameter ID unik kategori aktif ke halaman seleksi kontak agar sistem tahu kemana kontak baru akan disematkan
                          ),
                        ),
                      );
                    },
                    child: Text( // Menyisipkan anak widget berupa teks label instruksi aksi ke dalam tengah-tengah tombol pil kustom kanan
                      'ADD', // Teks string berlabel 'ADD' cetak kapital
                      style: TextStyle( // Mengatur gaya tulisan teks label tombol aksi 'ADD'
                        fontSize: 15, // Ukuran huruf label teks ADD sebesar 15 pixel
                        fontWeight: FontWeight.bold, // Karakter huruf diatur tercetak tebal bertenaga (bold)
                        color: _isRemoveMode ? Colors.grey : Colors.black, // Seleksi warna teks label: jika mode hapus menyala teks berubah abu-abu mati, jika normal teks hitam legam
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16), // Jarak spasi vertikal setinggi 16 pixel di bawah baris tombol aksi sebelum wilayah search bar dimulai

            Padding( // Memberikan jarak renggang di sekeliling penempatan bilah kotak Search Bar ketikan pencarian kontak
              padding: const EdgeInsets.symmetric(horizontal: 20), // Batas celah pengaman search bar agar tidak menempel mentok ke dinding tepi layar kiri-kanan sejauh 20 pixel
              child: _buildSearchBar(), // Memanggil method kustom pembangun rangkaian komponen search bar ketikan pencarian nama kontak (_buildSearchBar)
            ),

            const SizedBox(height: 10), // Jarak jeda vertikal setinggi 10 pixel di bawah search bar sebelum garis tipis pemisah diletakkan

            const Divider(height: 1, thickness: 1, color: Colors.black12), // Menampilkan garis horizontal (garis pembatas) super tipis setebal 1 pixel berwarna hitam pudar transparan abu-abu sebagai batas pemisah konten atas dan bawah

            const SizedBox(height: 8), // Jarak jeda vertikal setinggi 8 pixel di bawah garis pembatas divider sebelum memulai render daftar list data utama kontak

            Expanded( // Membungkus area tersisa paling bawah dengan widget Expanded agar daftar list data kontak dari StreamBuilder memanjang menghabiskan sisa tinggi layar hp secara proporsional
              child: StreamBuilder<QuerySnapshot>( // Widget jembatan khusus StreamBuilder yang memantau aliran data realtime (Stream) koleksi database Cloud Firestore secara otomatis setiap kali ada perubahan data di cloud
                stream: contactsCollection.orderBy('addedAt', descending: true).snapshots(), // Mengalirkan data snapshot dari Firestore secara real-time, diurutkan berdasarkan field waktu 'addedAt' secara terbalik dari yang terbaru masuk (descending: true)
                builder: (context, snapshot) { // Fungsi pembangun UI (builder) yang otomatis mendengarkan arus data snapshot terbaru yang mengalir masuk
                  if (!snapshot.hasData) { // Kondisi penyaring awal: JIKA data snapshot perdana masih kosong atau sedang dalam proses loading awal memuat jaringan dari Firestore cloud
                    return const Center(child: CircularProgressIndicator()); // Kembalikan widget indikator loading lingkaran berputar (loading spinner) tepat di tengah-tengah layar kosong
                  }

                  final docs = snapshot.data!.docs; // Ekstraksi sukses: Mengambil daftar list seluruh dokumen data kontak yang berhasil ditangkap dalam bentuk objek List dari snapshot data Firestore

                  final filtered = docs.where((doc) { // Operasi penyaringan data (Client-side Filtering): Menyaring daftar dokumen berdasarkan kata kunci pencarian teks dari search bar aktif
                    final data = doc.data() as Map<String, dynamic>; // Mengubah data mentah dokumen Firestore hasil iterasi menjadi tipe objek Map pasangan key-value kustom
                    final name = (data['name'] ?? '').toLowerCase(); // Mengambil field nilai 'name' kontak, jika null diganti string kosong, lalu dikonversi paksa menjadi format huruf kecil semua agar pencarian fleksibel
                    return name.contains(_searchQuery); // Mengembalikan nilai kecocokan logika true jika string kata kunci ketikan pada variabel _searchQuery terkandung di dalam teks nama kontak tersebut
                  }).toList(); // Mengubah kembali seluruh hasil filter seleksi penyaringan kontak menjadi bentuk objek List baru yang siap pakai pada ListView

                  if (filtered.isEmpty) { // Kondisi seleksi data hasil filter: JIKA hasil daftar list filter ternyata kosong (tidak ada nama kontak yang cocok dengan kata kunci ketikan pencarian)
                    return const Center(child: Text('No contacts found')); // Kembalikan widget teks pemberitahuan bertuliskan 'No contacts found' tepat di bagian tengah layar kosong aplikasi
                  }

                  return ListView.builder( // Mengembalikan widget ListView.builder untuk merender daftar kotak baris kontak secara super efisien hanya pada item-item data yang terlihat di layar hp saja (lazy loading)
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), // Mengatur bantalan jarak gulir list data bagian dalam sisi: kiri 20, atas 8, kanan 20, bawah batas aman scrolling 24 pixel
                    itemCount: filtered.length, // Menentukan total jumlah baris item list yang wajib dirender di layar hp mengikuti jumlah total list data kontak hasil penyaringan (filtered)
                    itemBuilder: (context, index) { // Fungsi callback internal pembangun baris item daftar kontak satu per satu berdasarkan nomor urut indeks perulangan list
                      final data = filtered[index].data() as Map<String, dynamic>; // Mengekstraksi dokumen data kontak tunggal pada nomor urut indeks tertentu dari list filter menjadi objek Map pasangan data

                      return _buildContactTile( // Memanggil method helper kustom pembuat baris list tile kotak data nama kontak kustom (_buildContactTile)
                        id: filtered[index].id, // Mengirimkan parameter ID unik dokumen dari data kontak indeks terpilih ke method pembuat list tile kotak kontak
                        data: data, // Mengirimkan parameter objek Map data rincian kontak indeks terpilih ke method pembuat list tile kotak kontak
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}