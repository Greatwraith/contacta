// register_screen.dart

//_______________________
// BAGIAN IMPORT DEPENDENSI | BERFUNGSI SEBAGAI TEMPAT MENGIMPOR LIBRARY DAN FILE YANG DIBUTUHKAN
//_______________________

import 'package:flutter/material.dart'; // Mengimpor library utama Flutter (Material Design) untuk merancang komponen antarmuka pengguna seperti Scaffold, TextField, dan tombol
import 'package:firebase_auth/firebase_auth.dart'; // Mengimpor Firebase Authentication untuk mengurus proses pendaftaran akun baru secara langsung ke server Firebase

import 'login_screen.dart'; // Mengimpor file login_screen.dart untuk mengarahkan pengguna kembali ke halaman login setelah proses registrasi berhasil

//_______________________
// BAGIAN CLASS STATEFULWIDGET UTAMA | BERFUNGSI SEBAGAI DEKLARASI HALAMAN REGISTRASI
//_______________________

class RegisterScreen extends StatefulWidget { // Menggunakan StatefulWidget karena halaman ini mengelola status dinamis seperti animasi pemuatan (loading) dan penampilan pesan kesalahan (error)
  const RegisterScreen({super.key}); // Constructor standar untuk inisialisasi awal widget RegisterScreen

  @override
  State<RegisterScreen> createState() => _RegisterScreenState(); // Menghubungkan widget dengan class State yang menyimpan seluruh logika dan variabel pengontrol halaman
}

//_______________________
// BAGIAN CLASS STATE — LOGIKA & VARIABEL | BERFUNGSI SEBAGAI PUSAT PENGENDALI DATA DAN FUNGSI HALAMAN
//_______________________

class _RegisterScreenState extends State<RegisterScreen> {
  
  //_______________________
  // BAGIAN INSTANCE & CONTROLLERS | BERFUNGSI UNTUK MENGAKSES LAYANAN DAN MENANGKAP INPUT PENGGUNA
  //_______________________

  final FirebaseAuth _auth = FirebaseAuth.instance; // Membuat instance tunggal dari FirebaseAuth untuk memanggil metode pembuatan akun baru di server Firebase

  final TextEditingController _nameController     = TextEditingController(); // Membuat controller untuk memantau, menangkap, dan memanipulasi input teks pada kolom Nama Lengkap
  final TextEditingController _emailController    = TextEditingController(); // Membuat controller untuk memantau, menangkap, dan memanipulasi input teks pada kolom Alamat Email
  final TextEditingController _passwordController = TextEditingController(); // Membuat controller untuk memantau, menangkap, dan memanipulasi input teks pada kolom Kata Sandi (Password)

  //_______________________
  // BAGIAN VARIABEL STATE | BERFUNGSI SEBAGAI PENANDA STATUS UI SAAT PROSES BERJALAN
  //_______________________

  bool isLoading     = false; // Variabel boolean untuk menandai proses asinkron. Jika true, UI akan menampilkan indikator pemuatan dan menonaktifkan interaksi tombol
  String errorMessage = '';   // Variabel string untuk menyimpan pesan kesalahan validasi atau kegagalan server yang akan ditampilkan ke layar pengguna

  //_______________________
  // BAGIAN SIKLUS HIDUP WIDGET (LIFECYCLE) | BERFUNGSI MENGATUR PENGHANCURAN WIDGET DAN MANAJEMEN MEMORI
  //_______________________

  @override
  void dispose() { // Method bawaan yang dieksekusi secara otomatis tepat sebelum halaman ini dihancurkan atau ditutup secara permanen
    _nameController.dispose(); // Wajib menghapus _nameController dari memori sistem guna mencegah terjadinya kebocoran memori (memory leak)
    _emailController.dispose(); // Wajib menghapus _emailController dari memori sistem
    _passwordController.dispose(); // Wajib menghapus _passwordController dari memori sistem
    super.dispose();
  }

  //_______________________
  // BAGIAN LOGIKA VALIDASI | BERFUNGSI UNTUK MEMERIKSA FORMAT INPUT PENGGUNA
  //_______________________

  bool _isValidEmail(String email) { // Fungsi untuk memvalidasi apakah struktur teks yang dimasukkan memenuhi standar penulisan email
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email); // Menggunakan Regular Expression (Regex) untuk memeriksa keberadaan karakter '@' dan domain '.' pada posisi yang benar
  }

  //_______________________
  // BAGIAN LOGIKA REGISTRASI AKUN | BERFUNGSI UNTUK MEMPROSES PENDAFTARAN KE SERVER FIREBASE
  //_______________________

  Future<void> _register() async { // Fungsi asinkron utama untuk memproses seluruh rangkaian pendaftaran akun baru
    final name     = _nameController.text.trim();     // Mengambil teks dari input nama dan menghapus spasi kosong di awal maupun di akhir teks (trim)
    final email    = _emailController.text.trim();    // Mengambil teks dari input email dan menghapus spasi kosong yang tidak disengaja
    final password = _passwordController.text.trim(); // Mengambil teks dari input password dan menghapus spasi kosong

    // ── Validasi lokal sebelum melakukan request ke server Firebase ──────────────────────────────

    if (name.isEmpty) { // Memeriksa apakah kolom input nama lengkap masih kosong
      setState(() => errorMessage = 'Please enter your full name'); // Mengisi pesan kesalahan dan memicu pembaruan UI
      return; // Menghentikan eksekusi fungsi agar tidak melanjutkan proses pendaftaran
    }

    if (email.isEmpty) { // Memeriksa apakah kolom input email masih kosong
      setState(() => errorMessage = 'Please enter your email'); // Mengisi pesan kesalahan email kosong
      return; // Menghentikan eksekusi fungsi
    }

    if (!_isValidEmail(email)) { // Memanggil fungsi regex untuk memeriksa keabsahan format email pengguna
      setState(() => errorMessage = 'Invalid email format'); // Mengisi pesan kesalahan jika format email salah
      return; // Menghentikan eksekusi fungsi
    }

    if (password.isEmpty) { // Memeriksa apakah kolom input password masih kosong
      setState(() => errorMessage = 'Please enter a password'); // Mengisi pesan kesalahan password kosong
      return; // Menghentikan eksekusi fungsi
    }

    if (password.length < 6) { // Memeriksa kepatuhan batas minimum keamanan password (minimal 6 karakter)
      setState(() => errorMessage = 'Password must be at least 6 characters'); // Mengisi pesan kesalahan jika password terlalu pendek
      return; // Menghentikan eksekusi fungsi
    }

    // Mengosongkan sisa kesalahan sebelumnya dan mengaktifkan animasi pemuatan jika semua validasi lokal terpenuhi
    setState(() {
      isLoading     = true; // Mengubah status menjadi true untuk memicu tampilan indikator loading spinner
      errorMessage  = '';   // Menghapus rekaman pesan error lama
    });

    try { // Membuka blok penanganan error untuk proses komunikasi data ke server Firebase
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword( // Meminta server Firebase Auth untuk membuat kredensial pengguna baru
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name); // Memperbarui properti nama tampilan (displayName) pada objek user yang baru saja terbentuk di Firebase Auth

      await _auth.signOut(); // Memutus sesi login otomatis bawaan Firebase setelah register, agar pengguna diarahkan untuk masuk secara manual demi keamanan

      if (context.mounted) { // Memastikan widget masih terpasang pada pohon elemen sebelum menampilkan komponen dialog baru
        _showSuccessPopup(); // Memanggil fungsi untuk menampilkan pop-up sukses registrasi
      }
    } on FirebaseAuthException catch (e) { // Menangkap kegagalan spesifik dari server Firebase Authentication
      final message = switch (e.code) { // Menggunakan switch expression untuk memetakan kode error server menjadi pesan yang komunikatif
        'invalid-email'         => 'Invalid email format',
        'email-already-in-use'  => 'Email is already in use', // Terjadi jika alamat email tersebut sudah terdaftar pada database Firebase aplikasi ini
        'weak-password'         => 'Password must be at least 6 characters',
        'operation-not-allowed' => 'Registration is currently unavailable', // Terjadi jika opsi pendaftaran email/password dinonaktifkan di Firebase Console
        _                       => e.message ?? 'Registration failed', // Pesan fallback default jika terjadi error lain
      };

      setState(() => errorMessage = message); // Menampilkan pesan error khusus dari server ke area teks kesalahan di UI
    } catch (e) { // Menangkap jenis error umum lainnya (seperti hilangnya koneksi internet perangkat)
      setState(() => errorMessage = e.toString());
    }

    if (mounted) setState(() => isLoading = false); // Mematikan status pemuatan (loading) setelah seluruh rangkaian proses selesai dieksekusi
  }

  //_______________________
  // BAGIAN KOMPONEN UI: DIALOG SUKSES | BERFUNGSI UNTUK MENAMPILKAN POP-UP NOTIFIKASI KEBERHASILAN
  //_______________________

  void _showSuccessPopup() { // Fungsi untuk merancang dan merender dialog pop-up sukses ke atas layar pengguna
    showDialog(
      context: context,
      barrierDismissible: false, // Mengunci dialog agar tidak bisa ditutup secara acak dengan mengetuk area luar, memaksa pengguna menekan tombol kelanjutan
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Memberikan kelengkungan sudut pada kotak dialog sebesar 20 desimal
        backgroundColor: Colors.white, // Menetapkan warna putih bersih sebagai warna dasar dialog
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32), // Mengatur ruang pembatas internal dialog
          child: Column(
            mainAxisSize: MainAxisSize.min, // Menginstruksikan kotak dialog untuk menciut secara vertikal mengikuti tinggi konten internalnya
            children: [

              Container( // Membangun ornamen lingkaran visual penanda kesuksesan proses
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50), // Menetapkan warna dasar hijau sukses
                  shape: BoxShape.circle, // Memotong sudut kontainer secara simetris menjadi bentuk lingkaran penuh
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 42), // Menyisipkan ikon centang putih di tengah lingkaran hijau
              ),

              const SizedBox(height: 20), // Memberikan jarak vertikal antar elemen

              const Text(
                'Register Succes!', // Menampilkan judul utama teks pop-up sukses
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1B2A), // Menggunakan warna gelap kontras tinggi
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "you've created you account.", // Menampilkan sub-judul deskripsi sukses singkat
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF90A4AE)), // Menggunakan warna abu-abu lembut
              ),

              const SizedBox(height: 24),

              SizedBox( // Membungkus tombol utama dengan batasan dimensi lebar maksimum dan tinggi tetap
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Menghapus lapisan pop-up dialog dari layar terlebih dahulu

                    Navigator.pushReplacement( // Mengalihkan layar aktif ke LoginScreen dan menghapus RegisterScreen dari tumpukan histori navigasi
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27B9F2), // Warna dasar tombol biru cerah
                    elevation: 0, // Menghilangkan bayangan default tombol agar terlihat flat modern
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), // Sudut lengkung tombol berbentuk kotak membulat
                  ),
                  child: const Text(
                    'CONTINUE', // Label penuntun pada tombol eksekusi
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2, // Memberikan kelonggaran spasi antar karakter huruf agar terlihat tegas
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //_______________________
  // BAGIAN KOMPONEN UI: DEKORASI INPUT | BERFUNGSI SEBAGAI TEMPLATE GAYA VISUAL UNTUK KOLOM TEKS
  //_______________________

  InputDecoration _inputDecoration({ // Fungsi pembantu untuk standardisasi dekorasi objek TextField di halaman registrasi
    required String hint, 
    required IconData icon, 
  }) {
    return InputDecoration(
      hintText: hint, // Menetapkan teks petunjuk samar di dalam kolom input
      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 15), // Format visual teks petunjuk berwarna abu-abu muda
      suffixIcon: Icon(icon, color: const Color(0xFF90A4AE), size: 22),   // Menempatkan ikon fungsional secara spesifik di sudut KANAN kolom input teks
      filled: true, // Mengizinkan pewarnaan background diaktifkan
      fillColor: Colors.white, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17), // Memberikan bantalan internal agar teks tidak menempel kaku pada garis tepi
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none, // Menghilangkan garis batas default (borderless style)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none, // Menghilangkan garis batas saat field dalam kondisi pasif (tidak diklik)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF27B9F2), width: 2), // Menampilkan garis batas tepi berwarna biru setebal 2px saat user aktif mengetik
      ),
    );
  }

  //_______________________
  // BAGIAN ROOT WIDGET UTAMA (BUILD) | BERFUNGSI MENGGABUNGKAN SELURUH POTONGAN KOMPONEN MENJADI STRUKTUR LAYAR REGISTRASI
  //_______________________

  @override
  Widget build(BuildContext context) { // Metode utama perakitan UI pohon komponen (widget tree) yang dieksekusi setiap kali ada perubahan status internal halaman
    final double screenWidth  = MediaQuery.of(context).size.width;  // Menyimpan parameter nilai dimensi lebar layar fisik perangkat
    final double screenHeight = MediaQuery.of(context).size.height; // Menyimpan parameter nilai dimensi tinggi layar fisik perangkat

    return Scaffold(
      backgroundColor: Colors.white, // Menetapkan warna latar belakang halaman putih bersih
      resizeToAvoidBottomInset: true, // Menginstruksikan agar tata letak halaman otomatis bergeser ke atas saat keyboard virtual muncul, menghindari tertutupnya kolom input
      body: SafeArea( // Mengamankan area konten dari intervensi fisik notch kamera, status bar atas, atau area navigasi bawah perangkat pintar
        child: Column(
          children: [
            Expanded( // Menyita sisa ruang kosong vertikal agar halaman dapat dikendalikan sepenuhnya oleh komponen scroll internal
              child: SingleChildScrollView( // Mengaktifkan fungsi mekanika gulir pada layar form pendaftaran
                physics: const ClampingScrollPhysics(), // Menghilangkan efek pantulan elastis (bounce effect) saat guliran menyentuh batas tepi atas maupun bawah layar
                child: ConstrainedBox( // Mengunci dimensi ukuran ruang agar tata letak konten memiliki kepastian batas minimum tinggi
                  constraints: BoxConstraints(
                    minHeight: screenHeight
                        - MediaQuery.of(context).padding.top    // Menghitung tinggi bersih dengan memotong porsi ukuran status bar atas
                        - MediaQuery.of(context).padding.bottom, // Memotong porsi ukuran bilah navigasi bawaan sistem operasi di bagian bawah
                  ),
                  child: IntrinsicHeight( // Memaksa komponen Column di dalamnya untuk menyesuaikan tinggi secara dinamis sesuai kapasitas riil yang tersedia
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Memaksa seluruh widget anak horizontal untuk meregang memenuhi lebar penuh halaman
                      children: [

                        SizedBox(height: screenHeight * 0.10), // Menyediakan ruang kosong vertikal di atas logo sebesar 10% dari tinggi total layar

                        // ── Konten Visual: Logo Aplikasi ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Center(
                            child: Image.asset(
                              'images/logo-contacta.PNG', // Memuat berkas gambar logo internal dari direktori aset proyek aplikasi
                              width: screenWidth * 0.72, // Mengunci lebar visual logo agar konstan sebesar 72% dari total lebar layar
                              fit: BoxFit.contain, // Memastikan gambar mempertahankan rasio aslinya tanpa mengalami distorsi atau pemotongan bingkai
                            ),
                          ),
                        ),

                        const Spacer(), // Bertindak sebagai pegas fleksibel yang mendorong modul formulir di bawahnya untuk menetap di posisi terbawah layar

                        // ── Konten Formulir: Kontainer Input Data Registrasi ──
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDDF0F8), // Menetapkan warna dasar kontainer berupa biru muda lembut
                            borderRadius: BorderRadius.only(
                              topLeft:  Radius.circular(36), // Memberikan efek lengkungan asimetris pada sudut kiri atas kontainer
                              topRight: Radius.circular(36), // Memberikan efek lengkungan asimetris pada sudut kanan atas kontainer
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 36), // Mengatur kerapatan spasi pembatas internal formulir
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Mengatur agar seluruh label teks penanda bersandar rata kiri
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              const Center( // Menempatkan teks judul operasional formulir tepat di sumbu tengah horizontal
                                child: Text(
                                  'SIGN UP', // Judul fungsional modul pendaftaran akun
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900, // Ketebalan huruf maksimum untuk penegasan visual utama
                                    color: Color(0xFF0D1B2A), 
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Komponen Input: Nama Lengkap ──
                              const Text('Full Name'), // Label penanda di atas kolom input nama
                              const SizedBox(height: 8),
                              TextField(
                                controller: _nameController, // Menghubungkan kolom ketik dengan pengontrol variabel nama lengkap
                                decoration: _inputDecoration(
                                  hint: 'your name....',
                                  icon: Icons.edit_outlined, // Menyertakan ikon bertema pensil edit di sudut kanan kolom teks
                                ),
                              ),

                              const SizedBox(height: 18),

                              // ── Komponen Input: Alamat Email ──
                              const Text('Email'), // Label penanda di atas kolom input email
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController, // Menghubungkan kolom ketik dengan pengontrol variabel alamat email
                                keyboardType: TextInputType.emailAddress, // Menginstruksikan sistem keyboard menampilkan tata letak tombol khusus alamat email (tombol '@' instan)
                                decoration: _inputDecoration(
                                  hint: 'your email....',
                                  icon: Icons.account_circle_outlined, // Menyertakan ikon lingkaran profil di sudut kanan kolom teks
                                ),
                              ),

                              const SizedBox(height: 18),

                              // ── Komponen Input: Kata Sandi (Password) ──
                              const Text('Password'), // Label penanda di atas kolom input password
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController, // Menghubungkan kolom ketik dengan pengontrol variabel kata sandi
                                obscureText: true, // Mengunci privasi, menyamarkan huruf ketikan pengguna menjadi karakter sensor bintang/titik solid
                                decoration: _inputDecoration(
                                  hint: 'your password....',
                                  icon: Icons.lock_outline, // Menyertakan ikon gembok terkunci di sudut kanan kolom teks
                                ),
                              ),

                              // Komponen Kondisional: Area Penampilan Pesan Kesalahan Server / Validasi Lokal
                              if (errorMessage.isNotEmpty) // Blok ini hanya akan diproduksi dan dirender jika string variabel errorMessage memiliki isi teks
                                Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Center(
                                    child: Text(
                                      errorMessage, // Menampilkan isi pesan kesalahan aktual kepada pengguna
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.red, // Menggunakan warna merah tegas sebagai indikator universal terjadinya kesalahan
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 22),

                              // ── Komponen Navigasi: Tautan Pengalihan Kembali ke Login ──
                              Center(
                                child: Wrap( // Membungkus barisan teks agar otomatis turun ke baris baru secara rapi apabila ruang lebar layar menyempit (anti-broken layout)
                                  children: [
                                    const Text('Already have an account? '),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context), // Mengeluarkan halaman pendaftaran dari tumpukan rute, otomatis kembali ke halaman login sebelumnya
                                      child: const Text(
                                        'Login here', // Label teks yang bertindak sebagai tautan interaktif
                                        style: TextStyle(
                                          color: Color(0xFF1565C0), // Warna biru tua khas elemen hyperlink internet resmi
                                          decoration: TextDecoration.underline, // Memberikan aksen garis bawah penanda tautan interaktif yang valid
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              // ── Komponen Eksekusi Utama: Tombol SIGN UP Bergradasi Visual ──
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: DecoratedBox( // Menggunakan DecoratedBox untuk merender efek gradasi warna modern yang tidak didukung langsung oleh ElevatedButton bawaan
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient( // Menerapkan pencampuran warna linier menyilang dari arah kiri ke kanan
                                      colors: [
                                        Color(0xFF26C6E8), // Gradasi awal bernuansa biru cyan terang
                                        Color(0xFF1E90FF), // Gradasi akhir bernuansa biru dodger solid
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14), // Kelengkungan sudut tombol diselaraskan dengan estetika kontainer input
                                  ),
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _register, // Mematikan fungsi klik tombol secara mutlak (disabled) jika proses transaksi server sedang berjalan (loading)
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent, // Menyetel transparan penuh agar lapisan efek gradasi dari DecoratedBox di bawahnya terpancar sempurna
                                      elevation: 0, // Memangkas bayangan tombol agar menyatu dengan latar kontainer
                                    ),
                                    child: isLoading // Validasi ternary untuk penentuan muatan visual di dalam tombol utama
                                        ? const CircularProgressIndicator(color: Colors.white) // Menampilkan indikator loading berputar melingkar warna putih jika status asinkron aktif
                                        : const Text(
                                            'SIGN UP', // Menampilkan teks label utama jika tombol dalam posisi siap dieksekusi oleh user
                                            style: TextStyle(color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}