// profile_screen.dart

//_______________________
// BAGIAN IMPORT DEPENDENSI | BERFUNGSI SEBAGAI TEMPAT MENGIMPOR LIBRARY DAN FILE YANG DIBUTUHKAN
//_______________________

import 'package:cloud_firestore/cloud_firestore.dart'; // Mengimpor library Cloud Firestore untuk melakukan operasi baca dan tulis data profil pengguna secara langsung ke dalam database NoSQL Firebase
import 'package:firebase_auth/firebase_auth.dart'; // Mengimpor Firebase Authentication untuk mengelola sesi pengguna, mengambil data pengguna yang sedang login, dan memperbarui kredensial seperti password
import 'package:flutter/material.dart'; // Mengimpor kerangka kerja antarmuka utama Flutter (Material Design) yang menyediakan komponen dasar seperti Scaffold, TextField, dan lain-lain
import 'package:shared_preferences/shared_preferences.dart'; // Mengimpor package Shared Preferences untuk menyimpan data-data ringan (seperti password sementara) secara lokal di memori perangkat agar persisten

import 'login_screen.dart'; // Mengimpor file login_screen.dart sebagai halaman tujuan navigasi ketika pengguna memutuskan untuk keluar (logout) dari aplikasi

//_______________________
// BAGIAN CLASS STATEFULWIDGET UTAMA | BERFUNGSI SEBAGAI DEKLARASI HALAMAN PROFIL
//_______________________

class ProfileScreen extends StatefulWidget { // Menggunakan StatefulWidget karena halaman ini memiliki status (state) yang dinamis, seperti peralihan antara mode lihat dan mode edit, serta status pemuatan data
  const ProfileScreen({super.key}); // Constructor standar yang digunakan oleh Flutter untuk menginisialisasi widget ini

  @override
  State<ProfileScreen> createState() => _ProfileScreenState(); // Menghubungkan widget ini dengan class state (_ProfileScreenState) yang akan menyimpan seluruh logika bisnis dan variabel pengontrol UI
}

//_______________________
// BAGIAN CLASS STATE — LOGIKA & VARIABEL | BERFUNGSI SEBAGAI PUSAT PENGENDALI DATA DAN FUNGSI HALAMAN
//_______________________

class _ProfileScreenState extends State<ProfileScreen> {
  
  //_______________________
  // BAGIAN INSTANCE & CONTROLLERS | BERFUNGSI UNTUK MENGAKSES LAYANAN DAN MENANGKAP INPUT PENGGUNA
  //_______________________

  final FirebaseAuth _auth = FirebaseAuth.instance; // Membuat instance tunggal dari FirebaseAuth untuk mengakses data pengguna yang saat ini sedang login di dalam aplikasi
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Membuat instance tunggal dari FirebaseFirestore untuk berkomunikasi dengan koleksi database di server

  final TextEditingController _nameController = TextEditingController(); // Membuat controller untuk memantau, menangkap, dan memanipulasi teks yang diketik pengguna pada kolom input Nama
  final TextEditingController _emailController = TextEditingController(); // Membuat controller untuk memantau, menangkap, dan memanipulasi teks yang diketik pengguna pada kolom input Email
  final TextEditingController _passwordController = TextEditingController(); // Membuat controller untuk memantau, menangkap, dan memanipulasi teks yang diketik pengguna pada kolom input Password

  //_______________________
  // BAGIAN VARIABEL STATE | BERFUNGSI SEBAGAI PENANDA STATUS UI (TAMPILAN) SAAT INI
  //_______________________

  bool _isEditing = false; // Variabel boolean untuk menentukan mode halaman. Jika false, halaman hanya menampilkan data. Jika true, halaman berubah menjadi form yang bisa diedit
  bool _isLoading = false; // Variabel boolean untuk menandai proses asinkron. Jika true, UI dapat menampilkan indikator pemuatan (loading spinner) dan menonaktifkan tombol simpan
  bool _obscurePassword = true; // Variabel boolean untuk mengatur visibilitas teks password. Jika true, teks akan disensor (berupa titik/bintang)

  String _originalName = ''; // Variabel untuk menyimpan cadangan (backup) nama asli dari database, digunakan untuk mengembalikan nilai jika pengguna membatalkan proses edit
  String _originalEmail = ''; // Variabel untuk menyimpan cadangan email asli dari database, berfungsi sama seperti _originalName

  //_______________________
  // BAGIAN SIKLUS HIDUP WIDGET (LIFECYCLE) | BERFUNGSI MENGATUR INISIALISASI AWAL DAN PENGHANCURAN WIDGET
  //_______________________

  @override
  void initState() { // Method bawaan yang dieksekusi secara otomatis HANYA SEKALI saat halaman pertama kali dibangun dan dimasukkan ke dalam memori
    super.initState();
    _loadUserData(); // Memanggil fungsi untuk mengambil data nama dan email pengguna dari server sesaat setelah halaman dibuka
  }

  @override
  void dispose() { // Method bawaan yang dieksekusi sesaat sebelum halaman ini dihancurkan/ditutup secara permanen untuk mengelola memori
    _nameController.dispose(); // Wajib melepaskan _nameController dari memori perangkat untuk mencegah kebocoran memori (memory leak) yang dapat membebani aplikasi
    _emailController.dispose(); // Wajib melepaskan _emailController dari memori perangkat
    _passwordController.dispose(); // Wajib melepaskan _passwordController dari memori perangkat
    super.dispose();
  }

  //_______________________
  // BAGIAN LOGIKA PENGAMBILAN DATA | BERFUNGSI UNTUK MENGAMBIL INFORMASI DARI SERVER MAUPUN LOKAL
  //_______________________

  Future<void> _loadUserData() async { // Fungsi asinkron untuk mengambil data profil pengguna dari Firestore
    final user = _auth.currentUser; // Memeriksa sesi aktif. Jika tidak ada pengguna yang login, variabel ini akan bernilai null
    if (user == null) return; // Menghentikan eksekusi fungsi secara langsung jika tidak ada pengguna yang terautentikasi

    try { // Memulai blok try-catch untuk menangani potensi kegagalan koneksi saat mengambil data dari database
      final doc = await _firestore.collection('users').doc(user.uid).get(); // Mengambil dokumen spesifik dari koleksi 'users' berdasarkan UID pengguna yang sedang login

      if (mounted) { // Memastikan bahwa widget masih aktif di layar sebelum memperbarui UI, mencegah error pembaruan state pada widget yang sudah ditutup
        setState(() { // Memperbarui state agar tampilan menyesuaikan dengan data yang baru ditarik
          _nameController.text = doc.data()?['name'] ?? user.displayName ?? ''; // Mengambil nama dari Firestore. Jika gagal, gunakan data dari objek Auth. Jika masih kosong, berikan string kosong
          _emailController.text = user.email ?? ''; // Mengambil alamat email yang terdaftar di sistem Autentikasi
          _originalName = _nameController.text; // Menyimpan cadangan nama untuk keperluan pembatalan (cancel)
          _originalEmail = _emailController.text; // Menyimpan cadangan email untuk keperluan pembatalan
        });
      }
    } catch (_) { // Blok fallback jika pengambilan data dari Firestore gagal (misal karena masalah jaringan)
      if (mounted) {
        setState(() {
          _nameController.text = user.displayName ?? ''; // Mengandalkan data bawaan dari objek Firebase Auth sebagai alternatif terakhir
          _emailController.text = user.email ?? '';
          _originalName = _nameController.text;
          _originalEmail = _emailController.text;
        });
      }
    }
  }

  Future<void> _loadSavedPassword() async { // Fungsi asinkron untuk membaca data password yang mungkin tersimpan secara lokal saat pengguna berpindah ke mode edit
    final prefs = await SharedPreferences.getInstance(); // Mendapatkan akses ke penyimpanan lokal perangkat
    final savedPassword = prefs.getString('user_password') ?? ''; // Mengambil data string dengan kunci 'user_password'. Jika tidak ditemukan, gunakan string kosong

    if (mounted) {
      _passwordController.text = savedPassword; // Mengisi kolom input password dengan data yang ditarik dari penyimpanan lokal
    }
  }

  //_______________________
  // BAGIAN LOGIKA UTILITAS & VALIDASI | BERFUNGSI SEBAGAI FUNGSI PENDUKUNG PROSES UTAMA
  //_______________________

  void _showSnackbar(String message, Color color) { // Fungsi modular untuk menampilkan notifikasi singkat (Snackbar) di bagian bawah layar
    ScaffoldMessenger.of(context).showSnackBar( // Mengakses root dari Scaffold untuk merender pesan popup
      SnackBar(content: Text(message), backgroundColor: color), // Membuat widget SnackBar dengan teks dan warna yang disesuaikan melalui parameter
    );
  }

  //_______________________
  // BAGIAN LOGIKA PENYIMPANAN DATA | BERFUNGSI UNTUK MEMVALIDASI DAN MENGIRIM PEMBARUAN KE SERVER
  //_______________________

  Future<void> _saveProfile() async { // Fungsi asinkron sentral untuk memproses penyimpanan perubahan data profil
    final sw = MediaQuery.of(context).size.width; // Mengambil ukuran lebar layar saat ini untuk keperluan penyesuaian dimensi dialog

    final newPass = _passwordController.text.trim(); // Mengambil input password dan menghapus spasi yang tidak disengaja (trim)
    final newEmail = _emailController.text.trim(); // Mengambil input email dan menghapus spasi

    if (newPass.isNotEmpty && newPass.length < 6) { // Validasi keamanan dasar: Jika field password diisi, panjang karakter tidak boleh kurang dari 6
      _showSnackbar('Password must be at least 6 characters', Colors.red); // Menampilkan pesan kesalahan jika validasi gagal
      return; // Menghentikan eksekusi fungsi agar tidak mengirim data yang tidak valid ke server
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$'); // Menyiapkan pola Regular Expression (Regex) standar untuk memvalidasi struktur penulisan email
    if (newEmail.isNotEmpty && !emailRegex.hasMatch(newEmail)) { // Memeriksa apakah input email sesuai dengan standar format email internasional
      _showSnackbar('Invalid email format', Colors.red); // Menampilkan pesan kesalahan format
      return; // Menghentikan eksekusi
    }

    final bool? confirm = await _showConfirmDialog( // Memanggil dialog konfirmasi secara asinkron dan menunggu keputusan (YES/NO) dari pengguna
      context: context,
      sw: sw,
      title: 'Save changes?', // Teks judul pada dialog konfirmasi
      yesColor: const Color(0xFF42AAFF), // Mengatur warna tombol YES menjadi biru, mengindikasikan tindakan konstruktif (menyimpan)
    );

    if (confirm != true) return; // Jika pengguna memilih NO atau menutup dialog, hentikan proses penyimpanan secara diam-diam

    setState(() => _isLoading = true); // Mengubah status menjadi proses memuat, yang akan memicu UI menampilkan indikator loading

    try { // Memulai proses pembaruan data ke server Firebase
      final user = _auth.currentUser; // Memastikan kembali bahwa objek pengguna tersedia
      if (user == null) return; // Tindakan pencegahan keamanan (fail-safe)

      await user.updateDisplayName(_nameController.text.trim()); // Mengirim instruksi ke Firebase Auth untuk memperbarui nama tampilan (Display Name)

      if (newPass.isNotEmpty) { // Hanya mengeksekusi pembaruan password jika pengguna memang mengisi kolom tersebut
        await user.updatePassword(newPass); // Menginstruksikan Firebase Auth untuk mengganti password lama dengan yang baru

        final prefs = await SharedPreferences.getInstance(); // Mengakses kembali penyimpanan lokal
        await prefs.setString('user_password', newPass); // Menimpa rekaman password lama di memori internal dengan yang baru agar konsisten
      }

      if (newEmail.isNotEmpty && newEmail != _originalEmail) { // Memeriksa apakah ada perubahan alamat email yang berbeda dari email sebelumnya
        await user.verifyBeforeUpdateEmail(newEmail); // Meminta Firebase mengirimkan tautan verifikasi ke email yang baru demi alasan keamanan
      }

      await _firestore.collection('users').doc(user.uid).set({ // Memperbarui atau membuat dokumen di koleksi 'users' pada Cloud Firestore
        'name': _nameController.text.trim(), // Menyimpan nama baru
        'email': newEmail, // Menyimpan email baru
        'updated_at': FieldValue.serverTimestamp(), // Menandai waktu modifikasi menggunakan stempel waktu server (lebih akurat daripada waktu lokal HP)
      }, SetOptions(merge: true)); // SetOptions(merge: true) memastikan bahwa kita tidak menimpa atau menghapus properti lain di dokumen tersebut (seperti foto profil, jika ada)

      if (mounted) { // Memeriksa eksistensi widget setelah proses asinkron yang panjang selesai
        setState(() {
          _isEditing = false; // Mengembalikan tampilan dari mode form (edit) ke mode baca (lihat)
          _originalName = _nameController.text; // Memperbarui cadangan dengan data yang baru saja berhasil disimpan
          _originalEmail = newEmail;
          _passwordController.clear(); // Mengosongkan field password demi keamanan setelah pembaruan selesai
        });

        _showSnackbar('Profile updated successfully', Colors.green); // Memberikan umpan balik positif kepada pengguna bahwa proses berhasil
      }
    } on FirebaseAuthException catch (e) { // Menangkap kegagalan (exception) spesifik dari Firebase Auth untuk memberikan umpan balik yang lebih terarah
      final message = switch (e.code) { // Menggunakan fitur switch expression Dart untuk menerjemahkan kode error Firebase menjadi kalimat yang mudah dipahami manusia
        'weak-password'        => 'Password must be at least 6 characters',
        'invalid-email'        => 'Invalid email format',
        'email-already-in-use' => 'Email is already in use',
        'requires-recent-login'=> 'Please login again before changing sensitive data', // Error keamanan ini terjadi jika sesi login pengguna sudah terlalu lama
        _                      => 'Error: ${e.message ?? e.code}', // Fallback untuk jenis error lain yang tidak terduga
      };

      if (mounted) _showSnackbar(message, Colors.red); // Menampilkan pesan error yang telah diterjemahkan
    } catch (e) { // Menangkap semua error lain di luar masalah Autentikasi (seperti gagal tulis ke Firestore)
      if (mounted) _showSnackbar('Failed to save: ${e.toString()}', Colors.red);
    }

    if (mounted) setState(() => _isLoading = false); // Memastikan status pemuatan (loading) dimatikan, terlepas dari apakah proses di atas berhasil atau gagal
  }

  //_______________________
  // BAGIAN LOGIKA OTENTIKASI KELUAR | BERFUNGSI UNTUK MENGAKHIRI SESI PENGGUNA
  //_______________________

  Future<void> _logout() async { // Fungsi asinkron untuk mengeluarkan pengguna dari sesi saat ini
    final sw = MediaQuery.of(context).size.width;

    final bool? confirm = await _showConfirmDialog( // Menampilkan dialog konfirmasi untuk mencegah logout yang tidak disengaja
      context: context,
      sw: sw,
      title: 'Are you sure you want to Logout?', // Pertanyaan konfirmasi
      yesColor: const Color(0xFFE53935), // Menggunakan warna merah untuk tombol YES sebagai indikator visual dari tindakan destruktif/mengakhiri sesi
    );

    if (confirm != true) return; // Membatalkan proses logout jika pengguna tidak memilih YES

    await _auth.signOut(); // Menghapus token autentikasi di perangkat dan memutus sesi aktif pengguna di Firebase

    if (mounted) {
      Navigator.pushAndRemoveUntil( // Mengarahkan pengguna kembali ke halaman Login sekaligus membersihkan tumpukan riwayat rute
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Kondisi false memastikan bahwa pengguna tidak bisa menekan tombol "Back" di sistem operasi untuk kembali ke halaman profil ini
      );
    }
  }

  void _cancelEdit() { // Fungsi sederhana untuk mengembalikan halaman ke mode baca dan me-reset semua input
    setState(() {
      _isEditing = false; // Mengembalikan antarmuka ke mode tidak dapat diedit
      _nameController.text = _originalName; // Memulihkan data nama yang lama
      _emailController.text = _originalEmail; // Memulihkan data email yang lama
      _passwordController.clear(); // Mengosongkan kolom password
    });
  }

  //_______________________
  // BAGIAN KOMPONEN UI: DIALOG | BERFUNGSI UNTUK MEMBANGUN POP-UP KONFIRMASI YANG DAPAT DIGUNAKAN ULANG
  //_______________________

  Future<bool?> _showConfirmDialog({ // Widget dialog modular yang dapat mengembalikan nilai boolean, dipisahkan agar kode lebih terstruktur dan dapat digunakan untuk berbagai kondisi
    required BuildContext context,
    required double sw,
    required String title, // Parameter teks untuk judul agar fleksibel
    required Color yesColor, // Parameter warna untuk membedakan antara tindakan konstruktif (biru) dan destruktif (merah)
  }) {
    final dialogWidth = sw * 0.72; // Menetapkan kalkulasi lebar dialog sebesar 72% dari total lebar perangkat layar aktif

    return showDialog<bool>( // Memanggil metode sistem Flutter untuk menampilkan overlay di atas lapisan halaman saat ini
      context: context,
      builder: (ctx) => Dialog( // Membangun struktur kardus dialog dasar
        insetPadding: EdgeInsets.symmetric( // Mengatur jarak luar dialog agar berada persis di tengah secara matematis
          horizontal: (sw - dialogWidth) / 2, 
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Memberikan kelengkungan (radius) pada setiap sudut kotak dialog
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20), // Memberikan jarak di dalam ruang kotak (kiri, atas, kanan, bawah)
          child: Column(
            mainAxisSize: MainAxisSize.min, // Menginstruksikan agar kolom ini tidak memenuhi tinggi layar penuh, melainkan hanya membungkus sebatas tinggi anaknya saja
            children: [
              Text(
                title, // Menampilkan parameter teks judul di bagian tengah atas
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6), // Ruang kosong vertikal sebagai pemisah elemen

              Row( // Menyusun tombol aksi secara horizontal (bersebelahan)
                children: [
                  Expanded( // Memerintahkan widget pembungkus ini untuk mengisi porsi lebar yang tersisa secara merata (50:50 dengan tombol sebelahnya)
                    child: GestureDetector( // Menambahkan kemampuan interaksi tap (sentuhan) pada container khusus ini
                      onTap: () => Navigator.pop(ctx, false), // Mengembalikan nilai `false` ke pemanggil awal ketika tombol disentuh
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0), // Memberikan latar belakang abu-abu netral untuk tombol pembatalan
                          borderRadius: BorderRadius.circular(50), // Membuat bentuk pil (bulat memanjang) pada tombol
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'NO',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10), // Jarak pemisah antar dua tombol

                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true), // Mengembalikan nilai `true` ke fungsi pemanggil ketika dikonfirmasi
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: yesColor, // Menerapkan warna dinamis dari parameter pemanggil
                          borderRadius: BorderRadius.circular(50),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'YES',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  //_______________________
  // BAGIAN KOMPONEN UI: DEKORASI INPUT | BERFUNGSI SEBAGAI TEMPLATE GAYA VISUAL UNTUK SEMUA KOLOM TEKS
  //_______________________

  InputDecoration _inputDecoration({ // Fungsi pembantu untuk menyeragamkan tampilan kolom TextField tanpa perlu menulis ulang properti desain yang sama berulang kali
    required String hint, // Teks samar sebagai petunjuk isi kolom
    required IconData icon, // Ikon indikator di sebelah kiri kolom
    Widget? suffixIcon, // Parameter opsional yang memungkinkan kita menyisipkan widget (seperti tombol visibilitas) di sudut kanan kolom teks
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16), // Memberikan warna abu-abu pada teks petunjuk (placeholder)
      prefixIcon: Icon(icon, color: Colors.grey[700], size: 22), // Ikon paten di awal baris kolom
      suffixIcon: suffixIcon, // Menyematkan widget tambahan (jika diberikan) pada akhir baris kolom
      filled: true, // Mengaktifkan mode pengisian latar belakang
      fillColor: Colors.white, // Memberikan warna latar belakang solid putih agar kolom menonjol
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2), // Memberikan kelonggaran batas internal untuk meletakkan teks secara ideal
      border: OutlineInputBorder( // Menyiapkan pengaturan batas (garis pinggir) default
        borderRadius: BorderRadius.circular(30), // Menghasilkan tepi dengan lengkungan ekstrem menyerupai sebuah kapsul
        borderSide: const BorderSide(color: Colors.black, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder( // Konfigurasi garis pinggir ketika kolom ini belum/tidak sedang di-tap oleh pengguna
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.black, width: 1.2), // Mempertahankan batas hitam tebal sebagai estetika kontras
      ),
      focusedBorder: OutlineInputBorder( // Konfigurasi warna garis pinggir khusus saat pengguna aktif mengetik (terfokus) di dalam kolom ini
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5), // Berubah menjadi aksen biru agar lebih interaktif
      ),
    );
  }

  //_______________________
  // BAGIAN KOMPONEN UI: PEMBUAT FIELD INPUT | BERFUNGSI SEBAGAI PEMBUNGKUS WIDGET TEXTFIELD
  //_______________________

  Widget _buildField({ // Membangun objek TextField lengkap dengan pengaturan logika kontrol dan desain gaya
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false, // Menentukan apakah kolom terkunci dari interaksi papan ketik (keyboard) atau tidak
    bool obscureText = false, // Mengaktifkan filter privasi pada input (digunakan untuk password)
    Widget? suffixIcon, 
    TextInputType? keyboardType, // Menyediakan opsi tipe keyboard (contoh: huruf saja, nomor saja, format email khusus, dll)
  }) {
    return TextField(
      controller: controller, // Mengikat widget ke controller sehingga data teks bisa diubah melalui kode atau dibaca oleh fungsi lain
      readOnly: readOnly, // Mengunci atau membuka interaksi field sesuai status
      obscureText: obscureText, // Menyensor teks yang masuk jika variabel disetel `true`
      keyboardType: keyboardType, // Membuka layout keyboard sistem operasi (Android/iOS) sesuai dengan kebutuhan field
      style: const TextStyle(fontSize: 16, color: Colors.black87), // Memastikan teks yang diketik pengguna dapat terbaca dengan jelas
      decoration: _inputDecoration( // Mengimplementasikan desain template dari fungsi sebelumnya
        hint: hint,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  //_______________________
  // BAGIAN KOMPONEN UI: TOMBOL LOGOUT | BERFUNGSI MEMBANGUN TOMBOL AKSI KELUAR DI MODE LIHAT
  //_______________________

  Widget _buildLogoutButton(double scale) {
    return GestureDetector(
      onTap: _logout, // Mengaitkan gestur ketukan dengan fungsi konfirmasi logout
      child: Container(
        width: double.infinity, // Mendorong elemen ini untuk merentang selebar mungkin mengikuti area parent terdekat
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Memberikan volume ruang di dalam tombol
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE), // Latar belakang bernuansa merah pudar sebagai bahasa desain dari tindakan peringatan
          borderRadius: BorderRadius.circular(30), // Desain konsisten bergaya kapsul
          border: Border.all(color: const Color(0xFFFF3B0A), width: 1.2), // Garis tegas penanda tombol aksi kritikal
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Mengatur kesejajaran tata letak agar bertumpu pada bagian kiri (awal)
          children: [
            const Icon(Icons.logout, color: Color(0xFFFF3B0A), size: 22),
            const SizedBox(width: 6), // Menambah celah pemisah antar ikon dan teks
            Text(
              'LOG OUT',
              style: TextStyle(
                color: const Color(0xFFFF3B0A),
                fontSize: 16 * scale, // Mengadaptasikan skala huruf agar responsif di layar perangkat yang berbeda-beda
                fontWeight: FontWeight.w900, // Ketebalan ekstrem agar tombol terbaca dengan jelas
                letterSpacing: -0.2, // Mengurangi jarak renggang antar karakter huruf agar lebih padat dan tegas
                height: 1, // Memusatkan teks secara presisi di ruang perbatasan line height
                shadows: const [
                  Shadow(color: Color(0xFFFF3B0A), offset: Offset(0.3, 0)), // Efek tipis untuk menambah dimensi pada huruf
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //_______________________
  // BAGIAN KOMPONEN UI: HEADER HALAMAN | BERFUNGSI SEBAGAI BAR NAVIGASI DAN KONTROL UTAMA HALAMAN PROFIL
  //_______________________

  Widget _buildHeader(double sw, double sh, double scale) {
    return Padding( // Membungkus keseluruhan menu navigasi dengan spasi tepi untuk jarak yang simetris
      padding: EdgeInsets.fromLTRB(sw * 0.055, sh * 0.018, sw * 0.055, 0), // Memberikan jarak dinamis yang menyesuaikan dimensi lebar perangkat (kiri, atas, kanan, bawah)
      child: Stack( // Menggunakan susunan Stack karena kita ingin menempatkan teks judul tepat di tengah kanvas, tanpa terpengaruh posisi tombol di sampingnya
        alignment: Alignment.center, // Memusatkan elemen berlapis yang berada di dalam tumpukan ini
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Mendorong tombol ke arah kutub yang berlawanan (kiri dan kanan)
            children: [

              SizedBox( // Mengunci ruang selebar 60 pixel di bagian kiri untuk menjamin keseimbangan layout meskipun tombol cancel menghilang saat mode lihat
                width: 60,
                child: _isEditing // Melakukan pemeriksaan (kondisi ternary). Jika sedang dalam mode edit (true), maka bangun tombol. Jika tidak (false), berikan ruang kosong
                    ? GestureDetector(
                        onTap: _cancelEdit, // Menautkan fungsi yang mengembalikan properti UI ke kondisi sebelum diedit
                        child: Container(
                          width: 42 * scale,
                          height: 42 * scale, // Dimensi tinggi dan lebar disamakan agar membentuk rasio persegi 1:1, yang kemudian...
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F1F1), // Warna dasar ikon batal berwarna abu-abu terang
                            shape: BoxShape.circle, // ...Diberikan perintah untuk memotong sudut secara geometris sehingga membentuk bujur lingkaran penuh
                          ),
                          child: Icon(Icons.close, size: 24 * scale, color: Colors.black),
                        ),
                      )
                    : const SizedBox(), // Menghasilkan widget kosong secara harfiah, guna menghemat memori jika tombol tidak diperlukan
              ),

              SizedBox(
                width: 90, // Menyediakan reservasi area pada sudut kanan layar
                child: Align( // Menempelkan widget anak ke batas kanan (alignment)
                  alignment: Alignment.centerRight,
                  child: _isEditing // Validasi ternary untuk peralihan dinamis dari tombol 'Edit' menjadi tombol 'Simpan'
                      ? GestureDetector(
                          onTap: _isLoading ? null : _saveProfile, // Mengatur agar fungsi simpan tidak bisa dipicu berulang kali jika sedang terjadi loading (null disables onTap)
                          child: Container(
                            width: 42 * scale,
                            height: 42 * scale,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDFF0FF), 
                              shape: BoxShape.circle, // Menjadikan wujud tombol simpan melingkar
                            ),
                            child: _isLoading // Pemeriksaan berlapis. Jika sedang loading, munculkan animasi putaran. Jika tidak, munculkan ikon checklist
                                ? const Padding(
                                    padding: EdgeInsets.all(10), // Memastikan indikator berputar tidak menyentuh dinding luar lingkarannya
                                    child: CircularProgressIndicator(strokeWidth: 2), // Menampilkan visual pemuatan animasi default material
                                  )
                                : Icon(Icons.check, color: const Color(0xFF1E5BFF), size: 26 * scale), // Menampilkan ikon centang konfirmasi untuk menyimpan
                          ),
                        )
                      : GestureDetector( // Apabila halaman dalam posisi mode baca (lihat)
                          onTap: () {
                            setState(() => _isEditing = true); // Memberitahu kerangka aplikasi bahwa status form kini dibuka (true), sehingga memicu UI di-render ulang
                            _loadSavedPassword(); // Mendatangkan password terenkripsi dari memori dan mengisi kotak password yang tertutup
                          },
                          child: Container(
                            width: 64 * scale,
                            height: 34 * scale,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E5E5), // Gaya desain netral untuk inisialisasi edit
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),

          if (_isEditing) // Pernyataan kondisional secara langsung pada daftar UI (Collection If), widget judul ini HANYA akan diproduksi jika halaman diubah ke fase edit
            Center( // Widget perata tengahan khusus untuk stack parent-nya
              child: Text(
                'Edit profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w600, // Menghasilkan teks dengan ketebalan (bold) semi-kuat
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  //_______________________
  // BAGIAN KOMPONEN UI: MODE BACA | BERFUNGSI SEBAGAI TAMPILAN STANDAR (VIEW MODE) TANPA BISA DIEDIT
  //_______________________

  Widget _buildViewMode(double sw, double sh, double scale) { // Mempersiapkan sekelompok widget yang mendefinisikan antarmuka profil dalam keadaan statis
    return Column(
      children: [
        SizedBox(height: sh * 0.02), // Membuat jarak pendorong elemen ke arah bawah secara proporsional dengan tinggi layar perangkat

        Text(
          _nameController.text.isEmpty ? 'User' : _nameController.text, // Melakukan validasi pengamanan, jika nama tidak ada atau proses memuat gagal, sajikan nama darurat 'User'
          style: TextStyle(fontSize: 26 * scale, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: sh * 0.04), // Jarak vertikal yang lebih besar sebagai struktur pembatas dari nama ke informasi identitas sensitif (email)

        _buildField( // Memanggil kembali cetakan formulir dari fungsi _buildField
          controller: _emailController,
          hint: 'Email',
          icon: Icons.email,
          readOnly: true, // Properti kunci yang menyegel field, mematikan pemanggilan keyboard sehingga email berfungsi sekadar tampilan label biasa
        ),

        const SizedBox(height: 10),

        _buildLogoutButton(scale), // Meletakkan widget eksekusi logout mandiri pada tingkat akhir daftar di bawah
      ],
    );
  }

  //_______________________
  // BAGIAN KOMPONEN UI: MODE EDIT | BERFUNGSI SEBAGAI TAMPILAN FORMULIR MASUKAN YANG INTERAKTIF
  //_______________________

  Widget _buildEditMode(double sh) { // Mempersiapkan rincian formulir saat fungsi edit telah diperintahkan (aktif)
    return Column(
      children: [
        SizedBox(height: sh * 0.05),

        _buildField(
          controller: _nameController, // Melekatkan kontrol identitas nama yang bersifat siap dimodifikasi
          hint: 'John Doe',
          icon: Icons.person,
        ),

        SizedBox(height: sh * 0.018),

        _buildField( // Bidang perantara untuk memperbarui nama email
          controller: _emailController,
          hint: 'myemail@gmail.com',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress, // Memicu sistem perangkat untuk secara spesifik memunculkan keyboard bernuansa email yang difasilitasi tombol "@" agar ramah pengguna
        ),

        SizedBox(height: sh * 0.018),

        _buildField( // Bidang perantara untuk manajemen kredensial password
          controller: _passwordController,
          hint: '********',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword, // Variabel kunci untuk memfungsikan penyensoran (mengganti huruf ketikan dengan ikon bulatan hitam)
          suffixIcon: IconButton( // Menyematkan widget tombol mekanis dengan kemampuan diklik di bagian paling akhir kolom text (kanan)
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword), // Ketika diklik, fungsi membalik nilai boolean tersebut (contoh: true disetel balik jadi false, begitu pun sebaliknya). Ini bertugas untuk memunculkan teks.
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility, // Mengubah wujud ikon visual tombol tersebut: 'Mata bersilang' atau 'Mata terbuka' bergantung pada kebenaran status boolean _obscurePassword.
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  //_______________________
  // BAGIAN ROOT WIDGET UTAMA (BUILD) | BERFUNGSI MENGGABUNGKAN SELURUH POTONGAN KOMPONEN MENJADI HALAMAN LENGKAP
  //_______________________

  @override
  Widget build(BuildContext context) { // Merupakan titik eksekusi utama (root node) saat merancang pohon komponen Flutter. Fungsi ini akan dipanggil otomatis setiap kali ada permintaan perubahan `setState`
    final mq    = MediaQuery.of(context); // Melakukan instansiasi sistem utilitas resolusi layar yang terpasang untuk mendeteksi informasi dimensi sistem
    final sw    = mq.size.width;  // Menyimpan parameter nilai lebar resolusi total fisik maupun logis per sekian pixel dalam variabel sw (Screen Width)
    final sh    = mq.size.height; // Menyimpan parameter nilai tinggi vertikal maksimum dengan presisi ke variabel sh (Screen Height)
    final scale = (sw / 390).clamp(0.85, 1.2); // Melakukan komputasi matematika dengan rasio 390 (standar lebar iPhone modern). Menggunakan klausa .clamp() untuk mengunci skala minimum (0.85) dan skala pembesaran maksimum (1.2) agar elemen UI tidak hancur atau terlihat raksasa di tablet
    final hPad  = sw * 0.055; // Mengkalkulasi formula batas padding margin kiri dan kanan dinamis (yakni sebesar 5.5% dari lebar perangkat secara konstan)
    final avatarSize     = sw * 0.31; // Merancang diameter dasar foto profil menjadi presisi setara 31% lebar bentangan layar
    final avatarIconSize = sw * 0.16; // Mengalokasikan skala ikon default wajah kosong sebesar 16% bentangan lebar 

    return Column( // Memilih pondasi kerangka penempatan linier dengan orientasi tegak lurus ke arah bawah
      children: [

        _buildHeader(sw, sh, scale), // Mencetak blok UI kepala halaman bagian atas yang statis

        Expanded( // Memerintahkan blok di bawah ini untuk mengambil dominasi penuh menyita semua spasi vertikal layar yang tersisa (fluid layout)
          child: SingleChildScrollView( // Mengaktifkan fungsi mekanika gulir (scroll) di dalam kontainer yang dibungkus, sangat krusial ketika pengguna berinteraksi dan memunculkan pop-up keyboard sehingga tata letak tidak error (overflow) karena mentok
            padding: EdgeInsets.symmetric(horizontal: hPad), // Mengaplikasikan margin internal ke arah kiri dan kanan menggunakan konstanta hPad sebelumnya
            child: Column( // Menyusun anak komponen dari tata letak bagian tubuh/area bergulir
              children: [
                SizedBox(height: sh * 0.045),

                Container( // Menciptakan model antarmuka geometris berbentuk kontainer persegi sebagai tempat menetap foto/avatar
                  width: avatarSize,
                  height: avatarSize,
                  decoration: const BoxDecoration(
                    color: Colors.black, // Memberikan kelir kontras solid di alasnya
                    shape: BoxShape.circle, // Membengkokkan kontainer persegi menjadi kanvas sirkular yang mulus dan bundar sempurna
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: avatarIconSize), // Menempatkan ikon material ilustrasi karakter di tengah kontainer. Berwarna putih untuk estetika perbandingan warna kontras yang dramatis dan elegan
                ),

                if (!_isEditing) _buildViewMode(sw, sh, scale), // Menyusun potongan blok mode baca secara eksklusif hanya terjadi bilamana state edit dinilai `false` (bukan dalam fase pengerjaan formulir)
                if (_isEditing)  _buildEditMode(sh), // Kebalikannya, membubuhkan daftar input yang kompleks bilamana kondisi _isEditing berubah valid (`true`)

                SizedBox(height: sh * 0.04), // Memberikan spasi cadangan vertikal pada dasar akhir kerangka. Ini memastikan masih ada ruang tersisa dan konten tidak menempel kaku dan patah dengan sudut bawah layar HP, menaikkan kualitas pengalaman penggunaan (UX)
              ],
            ),
          ),
        ),
      ],
    );
  }
}