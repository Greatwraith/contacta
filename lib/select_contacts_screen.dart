// select_contacts_screen.dart
// File utama untuk layar pemilihan kontak yang akan dimasukkan ke dalam kategori

import 'package:cloud_firestore/cloud_firestore.dart'; // Import library Firestore untuk database cloud
import 'package:firebase_auth/firebase_auth.dart'; // Import library Firebase Auth untuk autentikasi pengguna
import 'package:flutter/material.dart'; // Import library Flutter Material untuk komponen UI

// Mendefinisikan widget StatefulWidget bernama SelectContactsScreen
class SelectContactsScreen extends StatefulWidget {
  final String categoryId; // Variabel untuk menyimpan ID kategori yang dipilih (tidak bisa diubah)

  const SelectContactsScreen({ // Constructor dengan parameter wajib categoryId
    super.key, // Meneruskan key ke parent class
    required this.categoryId, // categoryId wajib diisi saat membuat widget ini
  });

  @override
  State<SelectContactsScreen> createState() =>
      _SelectContactsScreenState(); // Membuat objek state untuk widget ini
}

// Class state yang mengelola semua logika dan data layar ini
class _SelectContactsScreenState
    extends State<SelectContactsScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid; // Mengambil UID pengguna yang sedang login

  final Set<String> _selectedIds = {}; // Set kosong untuk menyimpan ID kontak yang dipilih (tidak duplikat)

  bool _isLoadingSelected = true; // Status loading awal = true (sedang memuat data)
  bool _isInserting = false; // Status proses insert = false (belum ada proses insert)

  String _searchQuery = ''; // String kosong untuk menyimpan kata kunci pencarian
  final TextEditingController _searchController =
      TextEditingController(); // Controller untuk mengelola input teks pada field pencarian

  // Referensi ke koleksi 'kontak' milik pengguna di Firestore
  late final CollectionReference kontakCollection =
      FirebaseFirestore.instance
          .collection('users') // Menuju koleksi 'users'
          .doc(uid) // Menuju dokumen dengan UID pengguna
          .collection('kontak'); // Menuju subkoleksi 'kontak'

  // Referensi ke subkoleksi 'contacts' di dalam kategori tertentu
  late final CollectionReference categoryContacts =
      FirebaseFirestore.instance
          .collection('users') // Menuju koleksi 'users'
          .doc(uid) // Menuju dokumen pengguna
          .collection('categories') // Menuju subkoleksi 'categories'
          .doc(widget.categoryId) // Menuju dokumen kategori yang dipilih
          .collection('contacts'); // Menuju subkoleksi 'contacts' dalam kategori

  @override
  void initState() { // Dipanggil pertama kali saat widget dibuat
    super.initState(); // Memanggil initState dari parent class
    _loadAlreadyInsertedContacts(); // Memuat kontak yang sudah ada di kategori ini
  }

  @override
  void dispose() { // Dipanggil saat widget dihancurkan/dihapus dari layar
    _searchController.dispose(); // Membersihkan controller agar tidak bocor memori
    super.dispose(); // Memanggil dispose dari parent class
  }

  // Fungsi helper untuk menampilkan pesan snackbar di bagian bawah layar
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar( // Menggunakan ScaffoldMessenger untuk tampilkan snackbar
      SnackBar(content: Text(message), backgroundColor: color), // Membuat SnackBar dengan isi pesan dan warna latar
    );
  }

  // Fungsi untuk memuat daftar kontak yang sudah dimasukkan ke kategori ini sebelumnya
  Future<void> _loadAlreadyInsertedContacts() async {
    try { // Mencoba mengeksekusi kode berikut
      final snapshot = await categoryContacts.get(); // Mengambil semua dokumen dari subkoleksi contacts kategori

      for (final doc in snapshot.docs) { // Iterasi setiap dokumen yang ditemukan
        _selectedIds.add(doc.id); // Menambahkan ID dokumen ke Set _selectedIds agar tampil sudah terpilih
      }
    } catch (e) { // Menangkap error jika terjadi kesalahan
      debugPrint('_loadAlreadyInsertedContacts error: $e'); // Mencetak pesan error ke konsol debug
    }

    setState(() { // Memperbarui tampilan UI setelah selesai memuat
      _isLoadingSelected = false; // Mengubah status loading menjadi false (selesai loading)
    });
  }

  // Fungsi untuk menampilkan dialog konfirmasi sebelum menyimpan kontak ke kategori
  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>( // Menampilkan dialog dan mengembalikan nilai bool (true/false)
      context: context, // Konteks dari widget saat ini
      barrierDismissible: false, // Dialog tidak bisa ditutup dengan tap di luar area dialog
      builder: (ctx) => Dialog( // Membangun tampilan dialog
        backgroundColor: Colors.white, // Warna latar dialog = putih
        shape: RoundedRectangleBorder( // Bentuk dialog dengan sudut membulat
          borderRadius: BorderRadius.circular(28), // Radius sudut sebesar 28 piksel
        ),
        child: Padding( // Memberikan jarak dalam di semua sisi
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24), // Jarak: kiri 24, atas 28, kanan 24, bawah 24
          child: Column( // Tata letak vertikal untuk isi dialog
            mainAxisSize: MainAxisSize.min, // Ukuran kolom menyesuaikan kontennya (tidak penuh)
            children: [
              const Text( // Widget teks untuk judul dialog
                'Insert this contact?', // Teks pertanyaan konfirmasi
                textAlign: TextAlign.center, // Rata tengah horizontal
                style: TextStyle( // Gaya teks
                  fontSize: 20, // Ukuran font 20
                  fontWeight: FontWeight.bold, // Tebal
                ),
              ),
              const SizedBox(height: 20), // Jarak vertikal 20 piksel
              Row( // Tata letak horizontal untuk tombol NO dan YES
                children: [
                  Expanded( // Mengisi ruang yang tersedia secara proporsional
                    child: GestureDetector( // Mendeteksi ketukan pengguna
                      onTap: () => Navigator.pop(ctx, false), // Saat ditekan: tutup dialog, kembalikan false
                      child: Container( // Kotak tombol NO
                        padding: const EdgeInsets.symmetric(vertical: 14), // Jarak dalam atas-bawah 14
                        decoration: BoxDecoration( // Dekorasi kotak
                          color: const Color(0xFFE0E0E0), // Warna abu-abu muda
                          borderRadius: BorderRadius.circular(50), // Sudut sangat membulat (seperti kapsul)
                        ),
                        alignment: Alignment.center, // Teks di tengah kotak
                        child: const Text( // Teks tombol
                          'NO', // Label tombol penolakan
                          style: TextStyle(fontWeight: FontWeight.bold), // Teks tebal
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), // Jarak horizontal 12 piksel antara dua tombol
                  Expanded( // Mengisi ruang yang tersedia secara proporsional
                    child: GestureDetector( // Mendeteksi ketukan pengguna
                      onTap: () => Navigator.pop(ctx, true), // Saat ditekan: tutup dialog, kembalikan true
                      child: Container( // Kotak tombol YES
                        padding: const EdgeInsets.symmetric(vertical: 14), // Jarak dalam atas-bawah 14
                        decoration: BoxDecoration( // Dekorasi kotak
                          color: const Color(0xFF42AAFF), // Warna biru muda
                          borderRadius: BorderRadius.circular(50), // Sudut sangat membulat (seperti kapsul)
                        ),
                        alignment: Alignment.center, // Teks di tengah kotak
                        child: const Text( // Teks tombol
                          'YES', // Label tombol konfirmasi
                          style: TextStyle(
                            color: Colors.white, // Warna teks putih
                            fontWeight: FontWeight.bold, // Teks tebal
                          ),
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

  // Fungsi utama untuk menyimpan kontak terpilih ke dalam kategori di Firestore
  Future<void> _insertSelectedContacts(
      List<QueryDocumentSnapshot> docs) async { // Menerima daftar semua dokumen kontak
    if (_isInserting) return; // Jika sedang dalam proses insert, hentikan agar tidak dobel

    final confirm = await _showConfirmDialog(); // Tampilkan dialog dan tunggu jawaban pengguna
    if (confirm != true) return; // Jika pengguna menekan NO atau menutup dialog, batalkan proses

    setState(() => _isInserting = true); // Ubah status menjadi sedang insert, perbarui UI

    final messenger = ScaffoldMessenger.of(context); // Simpan referensi messenger sebelum async
    final navigator = Navigator.of(context); // Simpan referensi navigator sebelum async

    try { // Mencoba menjalankan proses insert
      for (final doc in docs) { // Iterasi setiap dokumen kontak yang ada
        if (_selectedIds.contains(doc.id)) { // Cek apakah kontak ini terpilih
          final data = doc.data() as Map<String, dynamic>; // Ambil data dokumen sebagai Map

          await categoryContacts.doc(doc.id).set({ // Simpan kontak ke subkoleksi contacts kategori
            'name': data['name'] ?? '', // Simpan nama, gunakan string kosong jika null
            'phone': data['phone'] ?? '', // Simpan nomor telepon, gunakan string kosong jika null
            'email': data['email'] ?? '', // Simpan email, gunakan string kosong jika null
            'notes': data['notes'] ?? '', // Simpan catatan, gunakan string kosong jika null
            'addedAt': FieldValue.serverTimestamp(), // Simpan waktu penambahan dari server Firestore
          });
        }
      }

      messenger.showSnackBar( // Tampilkan notifikasi berhasil
        const SnackBar(
          content: Text('Contact added to category successfully'), // Pesan berhasil
          backgroundColor: Color.fromRGBO(76, 175, 80, 1), // Warna hijau untuk sukses
        ),
      );

      navigator.pop(); // Kembali ke layar sebelumnya setelah berhasil menyimpan
    } catch (e) { // Menangkap error jika ada yang gagal
      debugPrint('_insertSelectedContacts error: $e'); // Cetak error ke konsol debug

      if (mounted) { // Pastikan widget masih ada di layar sebelum update UI
        _showSnackbar('Failed to insert contact to category', Colors.red); // Tampilkan pesan gagal berwarna merah
      }
    } finally { // Selalu dijalankan setelah try/catch selesai
      if (mounted) { // Pastikan widget masih ada sebelum memanggil setState
        setState(() => _isInserting = false); // Ubah status insert kembali ke false
      }
    }
  }

  @override
  Widget build(BuildContext context) { // Fungsi utama untuk membangun tampilan UI
    return Scaffold( // Kerangka utama layar Flutter
      backgroundColor: Colors.white, // Warna latar belakang layar = putih
      body: SafeArea( // Memastikan konten tidak tertutup notch/status bar
        child: _isLoadingSelected
            ? const Center(child: CircularProgressIndicator()) // Jika masih loading, tampilkan indikator putar
            : Column( // Jika sudah selesai loading, tampilkan kolom berisi semua konten
                children: [
                  const SizedBox(height: 10), // Jarak atas sebesar 10 piksel

                  // --- BAGIAN HEADER ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20), // Jarak kiri-kanan 20 piksel
                    child: Row( // Baris horizontal untuk ikon back, judul, dan spacer
                      children: [
                        GestureDetector( // Mendeteksi ketukan pada tombol kembali
                          onTap: () => Navigator.pop(context), // Kembali ke layar sebelumnya saat ditekan
                          child: Container( // Kotak lingkaran untuk ikon panah kembali
                            width: 46, // Lebar kotak 46 piksel
                            height: 46, // Tinggi kotak 46 piksel
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAEAEA), // Warna abu-abu terang
                              shape: BoxShape.circle, // Bentuk lingkaran penuh
                            ),
                            child: const Icon(Icons.arrow_back), // Ikon panah ke kiri
                          ),
                        ),
                        const Expanded( // Mengisi sisa ruang horizontal di tengah
                          child: Center( // Memusatkan teks
                            child: Text(
                              'My Contacts', // Judul halaman
                              style: TextStyle(
                                fontSize: 22, // Ukuran font 22
                                fontWeight: FontWeight.w600, // Ketebalan semi-bold
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 46, height: 46), // Spacer kosong untuk menyeimbangkan tombol back
                      ],
                    ),
                  ),

                  const SizedBox(height: 28), // Jarak vertikal 28 piksel setelah header

                  const Text( // Teks petunjuk di bawah header
                    'Add to a category', // Keterangan tujuan layar ini
                    style: TextStyle(fontSize: 18), // Ukuran font 18
                  ),

                  const SizedBox(height: 20), // Jarak vertikal 20 piksel setelah teks petunjuk

                  // --- BAGIAN FIELD PENCARIAN ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20), // Jarak kiri-kanan 20 piksel
                    child: Container( // Kotak pembungkus field pencarian
                      height: 52, // Tinggi kotak 52 piksel
                      decoration: BoxDecoration( // Dekorasi kotak
                        borderRadius: BorderRadius.circular(30), // Sudut membulat 30 piksel
                        border: Border.all( // Garis tepi kotak
                          color: Colors.black, // Warna garis tepi = hitam
                          width: 1.2, // Ketebalan garis 1.2 piksel
                        ),
                      ),
                      child: TextField( // Widget input teks pencarian
                        controller: _searchController, // Menghubungkan dengan controller pencarian
                        onChanged: (value) { // Dipanggil setiap kali teks berubah
                          setState(() { // Memperbarui UI saat teks berubah
                            _searchQuery = value.trim().toLowerCase(); // Simpan kata kunci dalam huruf kecil tanpa spasi
                          });
                        },
                        decoration: InputDecoration( // Dekorasi tampilan TextField
                          hintText: 'Search...', // Teks placeholder
                          border: InputBorder.none, // Hilangkan garis bawah default TextField
                          prefixIcon: const Icon( // Ikon di sisi kiri field
                            Icons.search, // Ikon kaca pembesar
                            color: Colors.black, // Warna ikon = hitam
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14), // Jarak dalam atas-bawah 14
                          hintStyle: TextStyle(color: Colors.grey[400]), // Warna teks placeholder = abu-abu
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16), // Jarak vertikal 16 piksel setelah field pencarian

                  // --- BAGIAN DAFTAR KONTAK + TOMBOL AKSI ---
                  Expanded( // Mengisi sisa ruang vertikal yang tersedia
                    child: StreamBuilder<QuerySnapshot>( // Widget yang mendengarkan perubahan data Firestore secara realtime
                      stream: kontakCollection.snapshots(), // Stream data dari koleksi kontak pengguna
                      builder: (context, snapshot) { // Fungsi builder dipanggil setiap data berubah
                        if (!snapshot.hasData) { // Jika data belum tersedia
                          return const Center(
                              child: CircularProgressIndicator()); // Tampilkan indikator loading
                        }

                        final allDocs = snapshot.data!.docs; // Ambil semua dokumen dari snapshot

                        // Filter dokumen berdasarkan kata kunci pencarian
                        final docs = _searchQuery.isEmpty
                            ? allDocs // Jika tidak ada pencarian, tampilkan semua
                            : allDocs.where((doc) { // Jika ada pencarian, filter berdasarkan nama
                                final data =
                                    doc.data() as Map<String, dynamic>; // Ambil data sebagai Map
                                final name = (data['name'] ?? '')
                                    .toString()
                                    .toLowerCase(); // Ambil nama dalam huruf kecil
                                return name.contains(_searchQuery); // Kembalikan true jika nama mengandung kata kunci
                              }).toList(); // Ubah hasil filter menjadi List

                        return Column( // Kolom berisi daftar kontak dan tombol di bawah
                          children: [
                            Expanded( // Mengisi ruang yang tersisa untuk daftar kontak
                              child: docs.isEmpty // Cek apakah hasil pencarian/daftar kosong
                                  ? Center( // Jika kosong, tampilkan pesan di tengah layar
                                      child: Text(
                                        _searchQuery.isEmpty
                                            ? 'No contacts yet' // Pesan jika belum ada kontak sama sekali
                                            : 'Contact not found', // Pesan jika pencarian tidak menemukan hasil
                                        style: TextStyle(
                                          fontSize: 16, // Ukuran font 16
                                          color: Colors.grey[500], // Warna teks abu-abu
                                        ),
                                      ),
                                    )
                                  : ListView.builder( // Jika ada data, tampilkan daftar yang bisa discroll
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20), // Jarak kiri-kanan daftar 20 piksel
                                      itemCount: docs.length, // Jumlah item = jumlah dokumen
                                      itemBuilder: (context, index) { // Fungsi pembuat tiap item daftar
                                        final data = docs[index].data()
                                            as Map<String, dynamic>; // Ambil data kontak ke-index

                                        final selected =
                                            _selectedIds.contains(
                                                docs[index].id); // Cek apakah kontak ini sudah terpilih

                                        return GestureDetector( // Mendeteksi ketukan pada item kontak
                                          onTap: () { // Dipanggil saat item ditekan
                                            setState(() { // Perbarui UI
                                              if (selected) { // Jika sudah terpilih
                                                _selectedIds.remove(
                                                    docs[index].id); // Hapus dari Set (batalkan pilihan)
                                              } else { // Jika belum terpilih
                                                _selectedIds.add(
                                                    docs[index].id); // Tambahkan ke Set (pilih kontak)
                                              }
                                            });
                                          },
                                          child: Container( // Kotak item kontak
                                            margin: const EdgeInsets.only(
                                                bottom: 12), // Jarak bawah antar item 12 piksel
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16, // Jarak dalam kiri-kanan 16 piksel
                                              vertical: 14, // Jarak dalam atas-bawah 14 piksel
                                            ),
                                            decoration: BoxDecoration( // Dekorasi kotak item
                                              borderRadius:
                                                  BorderRadius.circular(25), // Sudut membulat 25 piksel
                                              border: Border.all( // Garis tepi kotak
                                                color:
                                                    const Color(0xFF2196F3), // Warna biru Material
                                                width: 1.5, // Ketebalan garis 1.5 piksel
                                              ),
                                            ),
                                            child: Row( // Baris horizontal: ikon + nama kontak
                                              children: [
                                                Icon( // Ikon status pilihan
                                                  selected
                                                      ? Icons.check_circle // Ikon centang jika terpilih
                                                      : Icons
                                                          .radio_button_unchecked, // Ikon lingkaran kosong jika belum dipilih
                                                  color:
                                                      const Color(0xFF2196F3), // Warna ikon = biru
                                                ),
                                                const SizedBox(width: 14), // Jarak antara ikon dan teks 14 piksel
                                                Expanded( // Mengisi sisa ruang horizontal
                                                  child: Text(
                                                    data['name'] ?? '', // Tampilkan nama kontak, kosong jika null
                                                    overflow:
                                                        TextOverflow.ellipsis, // Potong dengan "..." jika terlalu panjang
                                                    style: const TextStyle(
                                                        fontSize: 17), // Ukuran font nama 17
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            // --- TOMBOL TAMBAH KONTAK DI BAWAH ---
                            Padding(
                              padding: const EdgeInsets.all(20), // Jarak 20 piksel di semua sisi
                              child: SizedBox(
                                width: double.infinity, // Lebar tombol = lebar penuh
                                height: 52, // Tinggi tombol 52 piksel
                                child: ElevatedButton( // Tombol dengan bayangan (elevated)
                                  onPressed: (_selectedIds.isEmpty ||
                                          _isInserting)
                                      ? null // Nonaktifkan tombol jika tidak ada yang dipilih atau sedang insert
                                      : () => _insertSelectedContacts(allDocs), // Panggil fungsi insert saat ditekan
                                  style: ElevatedButton.styleFrom( // Gaya tampilan tombol
                                    backgroundColor:
                                        const Color(0xFF2196F3), // Warna latar tombol aktif = biru
                                    disabledBackgroundColor:
                                        const Color(0xFFB0D4F5), // Warna latar tombol nonaktif = biru muda pucat
                                    shape: RoundedRectangleBorder( // Bentuk tombol
                                      borderRadius:
                                          BorderRadius.circular(18), // Sudut membulat 18 piksel
                                    ),
                                  ),
                                  child: _isInserting // Cek apakah sedang dalam proses insert
                                      ? const SizedBox( // Jika sedang insert, tampilkan loading kecil
                                          width: 22, // Lebar indikator 22 piksel
                                          height: 22, // Tinggi indikator 22 piksel
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5, // Ketebalan garis indikator 2.5 piksel
                                            color: Colors.white, // Warna indikator = putih
                                          ),
                                        )
                                      : const Text( // Jika tidak sedang insert, tampilkan teks tombol
                                          'ADD CONTACTS', // Label tombol
                                          style: TextStyle(
                                            color: Colors.white, // Warna teks = putih
                                            fontWeight: FontWeight.bold, // Teks tebal
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
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