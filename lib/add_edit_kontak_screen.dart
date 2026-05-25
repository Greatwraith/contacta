// add_edit_kontak_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Mengimpor package Cloud Firestore untuk operasi database (simpan, baca, update data)
import 'package:firebase_auth/firebase_auth.dart'; // Mengimpor package Firebase Auth untuk autentikasi pengguna (mendapatkan UID user yang login)
import 'package:flutter/material.dart'; // Mengimpor package Material Design Flutter untuk widget UI seperti Scaffold, AppBar, TextFormField, dll

import 'kontak_model.dart'; // Mengimpor file model Kontak yang berisi class/struktur data kontak

class AddEditKontakScreen extends StatefulWidget { // Membuat class layar Add/Edit Kontak yang bersifat StatefulWidget (bisa berubah state-nya)
  final Kontak? kontak; // Deklarasi variabel kontak bertipe Kontak (nullable), digunakan untuk membedakan mode tambah (null) atau edit/detail (ada isinya)

  const AddEditKontakScreen({super.key, this.kontak}); // Constructor dengan parameter opsional kontak dan key untuk identifikasi widget

  @override
  State<AddEditKontakScreen> createState() => _AddEditKontakScreenState(); // Membuat dan mengembalikan objek State untuk widget ini
}

class _AddEditKontakScreenState extends State<AddEditKontakScreen> { // Class State untuk AddEditKontakScreen, tempat logika dan variabel disimpan
  final _formKey = GlobalKey<FormState>(); // Membuat GlobalKey untuk Form, digunakan untuk validasi form secara programatik

  late TextEditingController _nameController; // Deklarasi controller untuk field nama (late = akan diinisialisasi nanti di initState)
  late TextEditingController _phoneController; // Deklarasi controller untuk field nomor telepon
  late TextEditingController _emailController; // Deklarasi controller untuk field email
  late TextEditingController _notesController; // Deklarasi controller untuk field catatan/notes

  late final CollectionReference kontakCollection = FirebaseFirestore.instance // Mengambil instance Firestore dan membuat referensi ke koleksi kontak milik user
      .collection('users') // Mengarah ke koleksi 'users' di Firestore
      .doc(FirebaseAuth.instance.currentUser!.uid) // Mengarah ke dokumen user berdasarkan UID user yang sedang login
      .collection('kontak'); // Mengarah ke sub-koleksi 'kontak' milik user tersebut

  final uid = FirebaseAuth.instance.currentUser!.uid; // Menyimpan UID user yang sedang login ke variabel uid untuk digunakan berulang kali

  bool isEditing = false; // Variabel penanda apakah layar sedang dalam mode edit (true) atau mode lihat detail (false)
  bool _isLoading = false; // Variabel penanda apakah sedang ada proses loading (misal: menyimpan data ke Firestore)

  bool get isDetailMode => widget.kontak != null && !isEditing; // Getter: mengembalikan true jika sedang dalam mode detail (ada kontak & tidak sedang edit)

  List<String> assignedCategories = []; // Daftar nama kategori yang sudah ditetapkan/assigned ke kontak ini

  @override
  void initState() { // Method yang dipanggil pertama kali saat widget dibuat, untuk inisialisasi awal
    super.initState(); // Memanggil initState dari parent class (wajib dipanggil)

    _nameController = TextEditingController(text: widget.kontak?.name ?? ''); // Inisialisasi controller nama, isi dengan nama kontak jika ada, atau string kosong
    _phoneController = TextEditingController(text: widget.kontak?.phone ?? ''); // Inisialisasi controller telepon, isi dengan nomor kontak jika ada, atau string kosong
    _emailController = TextEditingController(text: widget.kontak?.email ?? ''); // Inisialisasi controller email, isi dengan email kontak jika ada, atau string kosong
    _notesController = TextEditingController(text: widget.kontak?.notes ?? ''); // Inisialisasi controller notes, isi dengan catatan kontak jika ada, atau string kosong

    isEditing = widget.kontak == null; // Jika kontak null berarti mode tambah baru (isEditing = true), jika ada kontak berarti mode detail (isEditing = false)

    if (widget.kontak != null) { // Mengecek apakah ada data kontak yang dikirim (mode edit/detail)
      _loadAssignedCategories(); // Jika iya, muat daftar kategori yang sudah di-assign ke kontak ini
    }
  }

  Future<void> _loadAssignedCategories() async { // Method async untuk memuat kategori yang di-assign ke kontak dari Firestore
    try { // Blok try untuk menangani error yang mungkin terjadi saat mengambil data
      final categoriesSnapshot = await FirebaseFirestore.instance // Mengambil semua dokumen dari koleksi 'categories' milik user
          .collection('users') // Mengarah ke koleksi 'users'
          .doc(uid) // Mengarah ke dokumen user berdasarkan UID
          .collection('categories') // Mengarah ke sub-koleksi 'categories'
          .get(); // Mengeksekusi query dan mengambil hasilnya

      List<String> temp = []; // Membuat list sementara untuk menyimpan nama-nama kategori yang ditemukan

      for (final categoryDoc in categoriesSnapshot.docs) { // Melakukan perulangan untuk setiap dokumen kategori yang ditemukan
        final contactDoc = await FirebaseFirestore.instance // Mengecek apakah kontak ini ada di dalam sub-koleksi 'contacts' dari kategori tersebut
            .collection('users') // Mengarah ke koleksi 'users'
            .doc(uid) // Mengarah ke dokumen user berdasarkan UID
            .collection('categories') // Mengarah ke sub-koleksi 'categories'
            .doc(categoryDoc.id) // Mengarah ke dokumen kategori yang sedang diiterasi
            .collection('contacts') // Mengarah ke sub-koleksi 'contacts' dalam kategori tersebut
            .doc(widget.kontak!.id) // Mengarah ke dokumen kontak berdasarkan ID kontak yang sedang dibuka
            .get(); // Mengeksekusi query dan mengambil hasilnya

        if (contactDoc.exists) { // Mengecek apakah dokumen kontak ditemukan di dalam kategori ini
          final categoryName = categoryDoc.data()['name']; // Mengambil nilai field 'name' dari dokumen kategori

          if (categoryName != null) { // Mengecek apakah nama kategori tidak null sebelum ditambahkan
            temp.add(categoryName); // Menambahkan nama kategori ke list sementara
          }
        }
      }

      if (mounted) { // Mengecek apakah widget masih terpasang di tree (untuk menghindari error setState setelah dispose)
        setState(() { // Memanggil setState untuk memperbarui UI dengan data terbaru
          assignedCategories = temp; // Mengisi assignedCategories dengan list kategori yang berhasil dimuat
        });
      }
    } catch (e) { // Blok catch untuk menangkap error yang terjadi
      debugPrint('_loadAssignedCategories error: $e'); // Mencetak pesan error ke konsol untuk keperluan debugging
    }
  }

  @override
  void dispose() { // Method yang dipanggil saat widget dihapus dari tree, untuk membersihkan resource
    _nameController.dispose(); // Menghapus controller nama dari memori untuk mencegah memory leak
    _phoneController.dispose(); // Menghapus controller telepon dari memori
    _emailController.dispose(); // Menghapus controller email dari memori
    _notesController.dispose(); // Menghapus controller notes dari memori
    super.dispose(); // Memanggil dispose dari parent class (wajib dipanggil)
  }

  void _showSnackbar(String message, Color color) { // Method untuk menampilkan pesan snackbar di bagian bawah layar
    ScaffoldMessenger.of(context).showSnackBar( // Menggunakan ScaffoldMessenger untuk menampilkan SnackBar
      SnackBar(content: Text(message), backgroundColor: color), // Membuat SnackBar dengan isi pesan teks dan warna background yang ditentukan
    );
  }

  bool _hasUnsavedChanges() { // Method untuk mengecek apakah ada perubahan yang belum disimpan oleh user
    if (widget.kontak == null) { // Jika ini adalah mode tambah kontak baru (kontak belum ada)
      return _nameController.text.trim().isNotEmpty || // Kembalikan true jika salah satu field sudah diisi (ada perubahan)
          _phoneController.text.trim().isNotEmpty || // Mengecek apakah field telepon tidak kosong
          _emailController.text.trim().isNotEmpty || // Mengecek apakah field email tidak kosong
          _notesController.text.trim().isNotEmpty; // Mengecek apakah field notes tidak kosong
    }

    return _nameController.text != widget.kontak!.name || // Kembalikan true jika nama berubah dari data awal
        _phoneController.text != widget.kontak!.phone || // Kembalikan true jika telepon berubah dari data awal
        _emailController.text != widget.kontak!.email || // Kembalikan true jika email berubah dari data awal
        _notesController.text != widget.kontak!.notes; // Kembalikan true jika notes berubah dari data awal
  }

  Future<bool?> _showConfirmDialog(String title) { // Method untuk menampilkan dialog konfirmasi dengan judul tertentu, mengembalikan true/false/null
    return showDialog<bool>( // Menampilkan dialog dan menunggu respons berupa bool
      context: context, // Memberikan context agar dialog tahu di mana harus ditampilkan
      builder: (context) { // Builder function yang membangun tampilan dialog
        return Dialog( // Widget Dialog sebagai container utama popup
          shape: RoundedRectangleBorder( // Mengatur bentuk dialog dengan sudut membulat
            borderRadius: BorderRadius.circular(28), // Radius sudut sebesar 28 pixel
          ),
          backgroundColor: Colors.white, // Warna background dialog putih
          child: Padding( // Menambahkan padding di dalam dialog
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24), // Padding: kiri 24, atas 28, kanan 24, bawah 24
            child: Column( // Menyusun widget secara vertikal di dalam dialog
              mainAxisSize: MainAxisSize.min, // Ukuran kolom menyesuaikan kontennya (tidak memenuhi seluruh layar)
              children: [
                Text( // Widget teks untuk menampilkan judul dialog
                  title, // Isi judul dari parameter yang dikirim ke method ini
                  textAlign: TextAlign.center, // Rata tengah teks
                  style: const TextStyle( // Styling teks judul
                    fontSize: 20, // Ukuran font 20
                    fontWeight: FontWeight.bold, // Tebal
                    color: Colors.black, // Warna hitam
                  ),
                ),
                const SizedBox(height: 20), // Spasi vertikal 20 pixel antara judul dan tombol
                Row( // Menyusun tombol NO dan YES secara horizontal berdampingan
                  children: [
                    Expanded( // Tombol NO mengisi setengah ruang yang tersedia
                      child: GestureDetector( // Mendeteksi tap/sentuhan pada area tombol NO
                        onTap: () => Navigator.pop(context, false), // Saat diklik, tutup dialog dan kembalikan nilai false
                        child: Container( // Container sebagai tampilan tombol NO
                          padding: const EdgeInsets.symmetric(vertical: 14), // Padding atas-bawah 14 pixel
                          decoration: BoxDecoration( // Dekorasi tampilan container
                            color: const Color(0xFFE0E0E0), // Warna abu-abu muda untuk tombol NO
                            borderRadius: BorderRadius.circular(50), // Sudut sangat membulat (bentuk pil)
                          ),
                          alignment: Alignment.center, // Teks di tengah container
                          child: const Text( // Teks di dalam tombol NO
                            'NO', // Label tombol
                            style: TextStyle( // Styling teks tombol NO
                              fontSize: 16, // Ukuran font 16
                              fontWeight: FontWeight.bold, // Tebal
                              color: Colors.black, // Warna hitam
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Spasi horizontal 12 pixel antara tombol NO dan YES
                    Expanded( // Tombol YES mengisi setengah ruang yang tersedia
                      child: GestureDetector( // Mendeteksi tap/sentuhan pada area tombol YES
                        onTap: () => Navigator.pop(context, true), // Saat diklik, tutup dialog dan kembalikan nilai true
                        child: Container( // Container sebagai tampilan tombol YES
                          padding: const EdgeInsets.symmetric(vertical: 14), // Padding atas-bawah 14 pixel
                          decoration: BoxDecoration( // Dekorasi tampilan container
                            color: const Color(0xFF42AAFF), // Warna biru untuk tombol YES
                            borderRadius: BorderRadius.circular(50), // Sudut sangat membulat (bentuk pil)
                          ),
                          alignment: Alignment.center, // Teks di tengah container
                          child: const Text( // Teks di dalam tombol YES
                            'YES', // Label tombol
                            style: TextStyle( // Styling teks tombol YES
                              fontSize: 16, // Ukuran font 16
                              fontWeight: FontWeight.bold, // Tebal
                              color: Colors.white, // Warna putih
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
        );
      },
    );
  }

  Future<void> _saveContact() async { // Method async untuk menyimpan data kontak ke Firestore
    if (_isLoading) return; // Jika sedang loading, hentikan eksekusi agar tidak dobel proses

    if (_nameController.text.trim().isEmpty) { // Mengecek apakah field nama kosong setelah trim spasi
      _showSnackbar('Contact name cannot be empty', Colors.red); // Tampilkan pesan error jika nama kosong
      return; // Hentikan eksekusi karena validasi gagal
    }

    if (_formKey.currentState!.validate()) { // Menjalankan validasi semua field di dalam Form
      final bool? confirm = await _showConfirmDialog( // Menampilkan dialog konfirmasi dan menunggu jawaban user
        widget.kontak != null ? 'Save changes?' : 'Add this Contact?', // Judul dialog berbeda tergantung mode (edit atau tambah baru)
      );

      if (confirm != true) return; // Jika user memilih NO atau menutup dialog, hentikan proses simpan

      setState(() => _isLoading = true); // Mengaktifkan state loading untuk menampilkan indikator

      try { // Blok try untuk menangani error yang mungkin terjadi saat menyimpan ke Firestore
        if (widget.kontak != null) { // Mengecek apakah ini mode edit (ada data kontak sebelumnya)
          await kontakCollection.doc(widget.kontak!.id).update({ // Update dokumen kontak yang sudah ada berdasarkan ID-nya
            'name': _nameController.text.trim(), // Menyimpan nama yang sudah di-trim dari spasi
            'phone': _phoneController.text.trim(), // Menyimpan nomor telepon yang sudah di-trim
            'email': _emailController.text.trim(), // Menyimpan email yang sudah di-trim
            'notes': _notesController.text.trim(), // Menyimpan catatan yang sudah di-trim
            'updated_at': FieldValue.serverTimestamp(), // Menyimpan waktu update menggunakan timestamp server Firestore
          });
        } else { // Jika bukan mode edit, berarti mode tambah kontak baru
          await kontakCollection.add({ // Menambahkan dokumen baru ke koleksi kontak (ID dibuat otomatis oleh Firestore)
            'name': _nameController.text.trim(), // Menyimpan nama kontak baru
            'phone': _phoneController.text.trim(), // Menyimpan nomor telepon kontak baru
            'email': _emailController.text.trim(), // Menyimpan email kontak baru
            'notes': _notesController.text.trim(), // Menyimpan catatan kontak baru
            'created_at': FieldValue.serverTimestamp(), // Menyimpan waktu pembuatan menggunakan timestamp server
            'updated_at': FieldValue.serverTimestamp(), // Menyimpan waktu update awal (sama dengan waktu pembuatan)
          });
        }

        if (context.mounted) { // Mengecek apakah widget masih ada di tree sebelum melakukan aksi UI
          _showSnackbar( // Menampilkan pesan sukses
            widget.kontak != null // Menentukan pesan berdasarkan mode
                ? 'Contact updated successfully' // Pesan jika mode edit berhasil
                : 'Contact added successfully', // Pesan jika mode tambah baru berhasil
            const Color.fromRGBO(76, 175, 80, 1), // Warna hijau untuk pesan sukses
          );

          Navigator.pop(context); // Kembali ke layar sebelumnya setelah berhasil menyimpan
        }
      } catch (e) { // Blok catch untuk menangkap error saat menyimpan ke Firestore
        debugPrint('_saveContact error: $e'); // Cetak error ke konsol untuk debugging

        if (mounted) { // Mengecek apakah widget masih ada di tree
          _showSnackbar('Failed to save: ${e.toString()}', Colors.red); // Tampilkan pesan error ke user
        }
      } finally { // Blok finally selalu dijalankan, baik sukses maupun gagal
        if (mounted) { // Mengecek apakah widget masih ada sebelum setState
          setState(() => _isLoading = false); // Menonaktifkan state loading setelah proses selesai
        }
      }
    }
  }

  Future<void> _handleClose() async { // Method async untuk menangani aksi tombol close/tutup
    if (isEditing && _hasUnsavedChanges()) { // Mengecek jika sedang mode edit dan ada perubahan yang belum disimpan
      final bool? confirm = await _showConfirmDialog('Discard changes?'); // Tampilkan dialog konfirmasi buang perubahan
      if (confirm != true) return; // Jika user memilih NO, batalkan penutupan layar
    }

    if (widget.kontak != null && isEditing) { // Jika ada kontak dan sedang dalam mode edit (bukan mode tambah baru)
      setState(() { // Memperbarui state untuk kembali ke mode detail
        isEditing = false; // Nonaktifkan mode edit, kembali ke mode detail
        _nameController.text = widget.kontak!.name; // Kembalikan teks nama ke nilai awal sebelum diedit
        _phoneController.text = widget.kontak!.phone; // Kembalikan teks telepon ke nilai awal
        _emailController.text = widget.kontak!.email; // Kembalikan teks email ke nilai awal
        _notesController.text = widget.kontak!.notes; // Kembalikan teks notes ke nilai awal
      });
      return; // Hentikan eksekusi (tidak perlu pop karena hanya kembali ke mode detail)
    }

    if (context.mounted) Navigator.pop(context); // Jika bukan mode edit kontak, tutup layar dan kembali ke layar sebelumnya
  }

  InputDecoration _inputDecoration({ // Method untuk membuat dekorasi/styling seragam pada semua field input
    required String hint, // Parameter wajib: teks placeholder yang ditampilkan saat field kosong
    required IconData icon, // Parameter wajib: ikon yang ditampilkan di sebelah kiri field
  }) {
    return InputDecoration( // Mengembalikan objek InputDecoration dengan styling yang sudah ditentukan
      hintText: hint, // Mengatur teks placeholder sesuai parameter
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16), // Styling teks placeholder: abu-abu, ukuran 16
      prefixIcon: Icon(icon, color: Colors.grey[700], size: 22), // Ikon di kiri field: warna abu-abu gelap, ukuran 22
      filled: true, // Mengaktifkan warna background pada field
      fillColor: Colors.white, // Warna background field putih
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Padding konten field: horizontal 20, vertikal 16
      border: OutlineInputBorder( // Border default field
        borderRadius: BorderRadius.circular(25), // Sudut membulat radius 25
        borderSide: const BorderSide(color: Colors.black, width: 1.2), // Garis border hitam dengan tebal 1.2
      ),
      enabledBorder: OutlineInputBorder( // Border saat field dalam keadaan aktif tapi tidak difokus
        borderRadius: BorderRadius.circular(25), // Sudut membulat radius 25
        borderSide: const BorderSide(color: Colors.black, width: 1.2), // Garis border hitam dengan tebal 1.2
      ),
      focusedBorder: OutlineInputBorder( // Border saat field sedang difokus/diklik user
        borderRadius: BorderRadius.circular(25), // Sudut membulat radius 25
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5), // Garis border biru dengan tebal 1.5
      ),
    );
  }

  Widget _buildTextField({ // Method untuk membangun widget TextFormField dengan konfigurasi standar
    required TextEditingController controller, // Parameter wajib: controller untuk mengelola teks field
    required String hint, // Parameter wajib: teks placeholder
    required IconData icon, // Parameter wajib: ikon kiri field
    int maxLines = 1, // Jumlah baris maksimal (default 1 baris)
    TextInputType? keyboardType, // Tipe keyboard yang muncul (opsional, misal: angka, email)
    String? Function(String?)? validator, // Fungsi validasi opsional yang dipanggil saat form divalidasi
  }) {
    return TextFormField( // Mengembalikan widget TextFormField yang terintegrasi dengan Form
      controller: controller, // Menghubungkan field dengan controller yang diberikan
      readOnly: !isEditing, // Field hanya bisa dibaca jika TIDAK dalam mode edit
      maxLines: maxLines, // Mengatur jumlah baris maksimal sesuai parameter
      keyboardType: keyboardType, // Mengatur tipe keyboard sesuai parameter
      validator: validator, // Menghubungkan fungsi validasi ke field
      decoration: _inputDecoration(hint: hint, icon: icon), // Menerapkan dekorasi standar dengan hint dan ikon yang diberikan
    );
  }

  Widget _buildNotesField() { // Method khusus untuk membangun field Notes dengan tampilan berbeda (label di atas)
    return Stack( // Menggunakan Stack agar label "Notes.." bisa diposisikan di atas field input
      children: [
        TextFormField( // Widget input teks untuk field notes
          controller: _notesController, // Menghubungkan dengan controller notes
          readOnly: !isEditing, // Field hanya bisa dibaca jika tidak dalam mode edit
          maxLines: 5, // Maksimal 5 baris teks (field lebih tinggi dari field biasa)
          style: const TextStyle(fontSize: 16, color: Colors.black), // Styling teks yang diketik user
          decoration: InputDecoration( // Dekorasi khusus untuk field notes (berbeda dari field lain)
            filled: true, // Mengaktifkan warna background
            fillColor: Colors.white, // Background putih
            contentPadding: const EdgeInsets.fromLTRB(16, 68, 16, 16), // Padding atas lebih besar (68) agar teks tidak tertimpa label "Notes.."
            border: OutlineInputBorder( // Border default
              borderRadius: BorderRadius.circular(20), // Sudut membulat radius 20
              borderSide: const BorderSide(color: Colors.black, width: 1.2), // Garis border hitam tebal 1.2
            ),
            enabledBorder: OutlineInputBorder( // Border saat field aktif tidak difokus
              borderRadius: BorderRadius.circular(20), // Sudut membulat radius 20
              borderSide: const BorderSide(color: Colors.black, width: 1.2), // Garis border hitam tebal 1.2
            ),
            focusedBorder: OutlineInputBorder( // Border saat field difokus
              borderRadius: BorderRadius.circular(20), // Sudut membulat radius 20
              borderSide: const BorderSide( // Garis border biru
                color: Color(0xFF2196F3), // Warna biru Material
                width: 1.5, // Tebal garis 1.5
              ),
            ),
          ),
        ),
        Positioned( // Widget untuk memposisikan label "Notes.." secara absolute di dalam Stack
          top: 16, // Jarak dari atas sebesar 16 pixel
          left: 16, // Jarak dari kiri sebesar 16 pixel
          child: Text( // Teks label "Notes.."
            'Notes..', // Teks yang ditampilkan sebagai label
            style: TextStyle(color: Colors.grey[400], fontSize: 16), // Styling: abu-abu muda, ukuran 16
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) { // Method build yang dipanggil setiap kali UI perlu diperbarui
    return Scaffold( // Widget dasar yang menyediakan struktur halaman (appBar, body, dll)
      backgroundColor: Colors.white, // Warna background seluruh layar putih

      appBar: AppBar( // Widget AppBar di bagian atas layar
        backgroundColor: Colors.white, // Background AppBar putih
        elevation: 0, // Tidak ada bayangan di bawah AppBar
        leadingWidth: 80, // Lebar area leading (kiri AppBar) sebesar 80 pixel
        leading: Padding( // Widget kiri AppBar (tombol close)
          padding: const EdgeInsets.only(left: 24, top: 6, bottom: 6), // Padding kiri 24, atas-bawah 6
          child: GestureDetector( // Mendeteksi tap pada tombol close
            onTap: _isLoading ? null : _handleClose, // Jika loading, nonaktifkan tap; jika tidak, panggil _handleClose
            child: Container( // Container berbentuk lingkaran untuk tombol close
              width: 42, // Lebar container 42 pixel
              height: 42, // Tinggi container 42 pixel
              decoration: const BoxDecoration( // Dekorasi container tombol close
                color: Color(0xFFF5F5F5), // Warna abu-abu sangat muda
                shape: BoxShape.circle, // Bentuk lingkaran penuh
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 26), // Ikon silang/close berwarna hitam ukuran 26
            ),
          ),
        ),
        centerTitle: true, // Judul AppBar berada di tengah
        title: Text( // Widget teks untuk judul AppBar
          widget.kontak == null // Mengecek mode layar
              ? 'Add Contact' // Judul jika mode tambah kontak baru
              : isEditing // Jika ada kontak, cek apakah mode edit
                  ? 'Edit Contact' // Judul jika mode edit kontak
                  : 'Contact Detail', // Judul jika mode lihat detail kontak
          style: const TextStyle( // Styling teks judul AppBar
            fontSize: 20, // Ukuran font 20
            fontWeight: FontWeight.w600, // Semi-bold
            color: Colors.black, // Warna hitam
          ),
        ),
        actions: [ // Daftar widget di sisi kanan AppBar
          if (isDetailMode) // Tampilkan tombol Edit hanya jika sedang dalam mode detail
            Padding( // Padding untuk tombol Edit
              padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10), // Padding kanan 16, atas-bawah 10
              child: GestureDetector( // Mendeteksi tap pada tombol Edit
                onTap: _isLoading // Jika loading nonaktifkan, jika tidak aktifkan mode edit
                    ? null
                    : () {
                        setState(() { // Memperbarui state saat tombol Edit diklik
                          isEditing = true; // Mengaktifkan mode edit
                        });
                      },
                child: Container( // Container untuk tampilan tombol Edit
                  width: 92, // Lebar tombol Edit 92 pixel
                  alignment: Alignment.center, // Teks di tengah container
                  decoration: BoxDecoration( // Dekorasi tombol Edit
                    color: const Color(0xFFF1F1F1), // Warna abu-abu muda
                    borderRadius: BorderRadius.circular(18), // Sudut membulat radius 18
                  ),
                  child: const Text( // Teks di dalam tombol Edit
                    'Edit', // Label tombol
                    style: TextStyle( // Styling teks tombol Edit
                      color: Colors.black, // Warna hitam
                      fontSize: 16, // Ukuran font 16
                      fontWeight: FontWeight.w700, // Bold
                    ),
                  ),
                ),
              ),
            ),

          if (isEditing) // Tampilkan tombol Simpan (centang) hanya jika sedang dalam mode edit
            Padding( // Padding untuk tombol Simpan
              padding: const EdgeInsets.only(right: 16, top: 6, bottom: 6), // Padding kanan 16, atas-bawah 6
              child: GestureDetector( // Mendeteksi tap pada tombol Simpan
                onTap: _isLoading ? null : _saveContact, // Jika loading nonaktifkan, jika tidak panggil _saveContact
                child: Container( // Container berbentuk lingkaran untuk tombol Simpan
                  width: 62, // Lebar container 62 pixel
                  height: 62, // Tinggi container 62 pixel
                  decoration: const BoxDecoration( // Dekorasi container tombol Simpan
                    color: Color(0xFFE3F2FD), // Warna biru muda
                    shape: BoxShape.circle, // Bentuk lingkaran
                  ),
                  child: _isLoading // Menampilkan indikator loading atau ikon centang tergantung state
                      ? const Padding( // Jika loading, tampilkan CircularProgressIndicator
                          padding: EdgeInsets.all(16), // Padding 16 di semua sisi
                          child: CircularProgressIndicator( // Widget indikator loading melingkar
                            strokeWidth: 2, // Tebal garis loading 2 pixel
                            color: Color(0xFF2196F3), // Warna biru Material
                          ),
                        )
                      : const Icon( // Jika tidak loading, tampilkan ikon centang
                          Icons.check, // Ikon centang
                          color: Color(0xFF2196F3), // Warna biru Material
                          size: 32, // Ukuran ikon 32 pixel
                        ),
                ),
              ),
            ),
        ],
      ),

      body: SingleChildScrollView( // Widget yang memungkinkan konten bisa di-scroll jika melebihi layar
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Padding konten: horizontal 20, vertikal 24
        child: Form( // Widget Form untuk mengelompokkan field input dan validasi
          key: _formKey, // Menghubungkan Form dengan GlobalKey untuk validasi programatik
          child: Column( // Menyusun semua widget secara vertikal
            children: [
              Container( // Container untuk foto profil/avatar kontak
                width: 120, // Lebar container 120 pixel
                height: 120, // Tinggi container 120 pixel
                decoration: BoxDecoration( // Dekorasi container avatar
                  shape: BoxShape.circle, // Bentuk lingkaran
                  border: Border.all(color: Colors.black, width: 2), // Garis border hitam tebal 2
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.black), // Ikon orang sebagai placeholder foto, ukuran 60, warna hitam
              ),

              if (isDetailMode) ...[ // Jika mode detail, tampilkan nama kontak di bawah avatar
                const SizedBox(height: 16), // Spasi vertikal 16 pixel antara avatar dan nama

                Text( // Menampilkan nama kontak dalam mode detail
                  _nameController.text, // Mengambil teks nama dari controller
                  style: const TextStyle( // Styling teks nama
                    fontSize: 22, // Ukuran font 22
                    fontWeight: FontWeight.bold, // Tebal/bold
                    color: Colors.black, // Warna hitam
                  ),
                ),

                const SizedBox(height: 32), // Spasi vertikal 32 pixel setelah nama sebelum field lainnya
              ] else ...[ // Jika bukan mode detail (mode tambah/edit), tampilkan field nama
                const SizedBox(height: 40), // Spasi vertikal 40 pixel antara avatar dan field nama

                _buildTextField( // Membangun field input nama menggunakan method yang sudah dibuat
                  controller: _nameController, // Menggunakan controller nama
                  hint: 'Full name.....', // Placeholder teks untuk field nama
                  icon: Icons.person, // Ikon orang di kiri field
                ),

                const SizedBox(height: 12), // Spasi vertikal 12 pixel antara field nama dan telepon
              ],

              _buildTextField( // Membangun field input nomor telepon
                controller: _phoneController, // Menggunakan controller telepon
                hint: 'Phone number.....', // Placeholder teks untuk field telepon
                icon: Icons.phone, // Ikon telepon di kiri field
                keyboardType: TextInputType.phone, // Keyboard angka/telepon saat field ini diklik
              ),

              const SizedBox(height: 12), // Spasi vertikal 12 pixel antara field telepon dan email

              _buildTextField( // Membangun field input email
                controller: _emailController, // Menggunakan controller email
                hint: 'Email.....', // Placeholder teks untuk field email
                icon: Icons.email, // Ikon email di kiri field
                keyboardType: TextInputType.emailAddress, // Keyboard email saat field ini diklik
              ),

              const SizedBox(height: 12), // Spasi vertikal 12 pixel antara field email dan notes

              _buildNotesField(), // Membangun field notes dengan tampilan khusus (label di atas)

              const SizedBox(height: 12), // Spasi vertikal 12 pixel antara field notes dan bagian kategori

              Container( // Container untuk menampilkan informasi kategori yang di-assign ke kontak
                padding: const EdgeInsets.symmetric( // Padding di dalam container kategori
                  horizontal: 16, // Padding kiri-kanan 16 pixel
                  vertical: 14, // Padding atas-bawah 14 pixel
                ),
                decoration: BoxDecoration( // Dekorasi container kategori
                  color: Colors.white, // Background putih
                  borderRadius: BorderRadius.circular(25), // Sudut membulat radius 25
                  border: Border.all(color: Colors.black, width: 1.2), // Garis border hitam tebal 1.2
                ),
                child: Row( // Menyusun ikon dan konten kategori secara horizontal
                  crossAxisAlignment: CrossAxisAlignment.start, // Ikon dan konten rata atas
                  children: [
                    Icon( // Ikon kelompok/kategori di kiri
                      Icons.people_alt_rounded, // Ikon orang-orang
                      color: Colors.grey[700], // Warna abu-abu gelap
                      size: 22, // Ukuran ikon 22 pixel
                    ),
                    const SizedBox(width: 12), // Spasi horizontal 12 pixel antara ikon dan konten teks
                    Expanded( // Konten teks mengisi sisa ruang yang tersedia
                      child: Column( // Menyusun label dan daftar kategori secara vertikal
                        crossAxisAlignment: CrossAxisAlignment.start, // Rata kiri
                        children: [
                          Text( // Label "Assigned to"
                            'Assigned to', // Teks label
                            style: TextStyle( // Styling label
                              fontSize: 15, // Ukuran font 15
                              color: Colors.grey[600], // Warna abu-abu sedang
                            ),
                          ),
                          const SizedBox(height: 6), // Spasi vertikal 6 pixel antara label dan chip kategori
                          assignedCategories.isEmpty // Mengecek apakah ada kategori yang di-assign
                              ? Text( // Jika tidak ada kategori, tampilkan teks "No category"
                                  'No category', // Teks yang ditampilkan
                                  style: TextStyle(color: Colors.grey[500]), // Warna abu-abu muda
                                )
                              : Wrap( // Jika ada kategori, tampilkan chip-chip kategori yang bisa melingkari
                                  spacing: 8, // Jarak horizontal antar chip 8 pixel
                                  runSpacing: 8, // Jarak vertikal antar baris chip 8 pixel
                                  children: assignedCategories // Mengiterasi daftar nama kategori
                                      .map( // Mengubah setiap nama kategori menjadi widget chip
                                        (category) =>
                                            _AssignedChip(text: category), // Membuat chip dengan nama kategori
                                      )
                                      .toList(), // Mengubah hasil map menjadi List widget
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignedChip extends StatelessWidget { // Widget khusus untuk menampilkan satu chip kategori (StatelessWidget karena tidak ada state)
  final String text; // Variabel untuk menyimpan nama kategori yang ditampilkan di chip

  const _AssignedChip({required this.text}); // Constructor dengan parameter wajib text untuk nama kategori

  @override
  Widget build(BuildContext context) { // Method build untuk membuat tampilan chip
    return Container( // Container sebagai tampilan visual chip kategori
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), // Padding chip: horizontal 12, vertikal 5
      decoration: BoxDecoration( // Dekorasi chip kategori
        color: const Color(0xFFE3F2FD), // Warna background chip: biru sangat muda
        borderRadius: BorderRadius.circular(20), // Sudut membulat radius 20 (bentuk pil)
      ),
      child: Text( // Teks nama kategori di dalam chip
        text, // Isi teks dari parameter yang diterima
        style: const TextStyle( // Styling teks chip kategori
          fontSize: 14, // Ukuran font 14
          fontWeight: FontWeight.w500, // Medium weight
          color: Color(0xFF1976D2), // Warna biru tua Material
        ),
      ),
    );
  }
}