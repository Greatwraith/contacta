// login_screen.dart

//_______________________
// IMPORT DEPENDENCIES
//_______________________

import 'package:flutter/material.dart'; // Mengimpor library utama Flutter untuk membangun UI (Material Design), menyediakan widget dasar seperti Scaffold, TextField, Column, dll
import 'package:firebase_auth/firebase_auth.dart'; // Mengimpor Firebase Authentication untuk mengurus segala proses autentikasi (login, logout, cek sesi pengguna) ke server Firebase
import 'package:shared_preferences/shared_preferences.dart'; // Mengimpor package Shared Preferences untuk menyimpan data-data ringan (seperti string, boolean) secara lokal di memori HP agar tidak hilang saat aplikasi ditutup

import 'register_screen.dart'; // Mengimpor file register_screen.dart agar pengguna bisa diarahkan ke halaman pendaftaran jika belum memiliki akun
import 'kontak_list_screen.dart'; // Mengimpor file kontak_list_screen.dart sebagai halaman tujuan utama setelah pengguna berhasil login

//_______________________
// CLASS STATEFULWIDGET UTAMA
//_______________________

class LoginScreen extends StatefulWidget { // Menggunakan StatefulWidget karena halaman ini memiliki data yang bisa berubah-ubah dan memengaruhi tampilan secara langsung (seperti centang checkbox, teks error, dan animasi loading)
  const LoginScreen({super.key}); // Constructor standar Flutter untuk widget ini

  @override
  State<LoginScreen> createState() => _LoginScreenState(); // Membuat dan menghubungkan class State (_LoginScreenState) yang akan menjadi tempat kita menaruh seluruh variabel dan logika aplikasi untuk layar ini
}

//_______________________
// CLASS STATE — LOGIKA & VARIABEL UTAMA
//_______________________

class _LoginScreenState extends State<LoginScreen> { 
  
  //_______________________
  // VARIABEL & CONTROLLERS
  //_______________________

  final FirebaseAuth _auth = FirebaseAuth.instance; // Membuat instance/objek tunggal dari FirebaseAuth agar kita bisa memanggil fungsi-fungsi Firebase (seperti signIn, currentUser) di dalam class ini

  final TextEditingController _emailController = TextEditingController(); // Membuat controller untuk memantau, menangkap, dan mengubah teks yang diketik oleh pengguna di dalam kolom input Email
  final TextEditingController _passwordController = TextEditingController(); // Membuat controller untuk memantau, menangkap, dan mengubah teks yang diketik oleh pengguna di dalam kolom input Password

  bool rememberMe = false; // Variabel boolean untuk menyimpan status checkbox 'Remember me'. Default-nya false (tidak dicentang)
  bool isLoading = false; // Variabel boolean untuk menandai apakah aplikasi sedang memproses login ke server. Jika true, tombol akan berubah menjadi animasi loading
  String errorMessage = ''; // Variabel String untuk menyimpan pesan error (misal: "Password salah"). Akan ditampilkan ke layar jika login gagal

  //_______________________
  // SIKLUS HIDUP WIDGET (LIFECYCLE)
  //_______________________
  
  @override
  void initState() { // Method bawaan Flutter yang dipanggil HANYA SEKALI tepat ketika halaman ini pertama kali dimuat ke layar. Tempat yang pas untuk inisialisasi awal
    super.initState();
    _checkLoginStatus(); // Memanggil fungsi untuk mengecek apakah sebelumnya pengguna sudah login dan belum logout
    _loadRememberMe(); // Memanggil fungsi untuk mengecek apakah sebelumnya pengguna pernah mencentang 'Remember me'
  }

  @override
  void dispose() { // Method bawaan Flutter yang otomatis dipanggil sesaat sebelum halaman ini dihancurkan/ditutup permanen
    _emailController.dispose(); // Wajib melepaskan controller email dari memori sistem untuk mencegah memori bocor (memory leak) yang bisa membuat aplikasi menjadi lambat
    _passwordController.dispose(); // Wajib melepaskan controller password dari memori sistem
    super.dispose();
  }

  //_______________________
  // LOGIKA AUTENTIKASI & SESI
  //_______________________

  void _checkLoginStatus() { // Fungsi untuk mengecek sesi aktif pengguna
    User? user = _auth.currentUser; // Meminta Firebase untuk mengecek apakah ada data user yang sedang aktif saat ini. Menggunakan 'User?' karena hasilnya bisa null jika belum ada yang login

    if (user != null) { // Jika hasilnya tidak null (berarti ada pengguna yang masih login)
      WidgetsBinding.instance.addPostFrameCallback((_) { // Memastikan proses perpindahan halaman dilakukan SETELAH seluruh tampilan (UI) selesai di-render dengan sempurna untuk mencegah error tabrakan frame
        Navigator.pushReplacement( // Berpindah ke halaman KontakListScreen, dan menghapus LoginScreen dari tumpukan histori (pushReplacement), sehingga user tidak bisa kembali ke halaman login dengan tombol 'Back' di HP
          context,
          MaterialPageRoute(
            builder: (context) => const KontakListScreen(),
          ),
        );
      });
    }
  }

  Future<void> _loadRememberMe() async { // Fungsi asinkron (berjalan di background) untuk memuat data preferensi 'Remember me' dari penyimpanan lokal memori HP
    SharedPreferences prefs = await SharedPreferences.getInstance(); // Mengakses memori penyimpanan lokal HP pengguna

    bool savedRemember = prefs.getBool('remember_me') ?? false; // Mengambil nilai boolean dengan kunci 'remember_me'. Jika kunci tersebut belum pernah dibuat, gunakan nilai default 'false'
    String savedEmail = prefs.getString('saved_email') ?? ''; // Mengambil teks email yang terakhir disimpan. Jika kosong, gunakan string kosong ''

    setState(() { // Memanggil setState agar UI diperbarui dengan data terbaru yang baru saja diambil
      rememberMe = savedRemember; // Mengubah status variabel rememberMe dengan data dari memori HP
      if (savedRemember) { // Jika ternyata memori HP bilang user pernah mencentang 'Remember me'
        _emailController.text = savedEmail; // Isi otomatis teks di kolom input Email dengan email yang tersimpan di HP
      }
    });
  }

  bool _isValidEmail(String email) { // Fungsi kecil untuk mengecek apakah format tulisan yang dimasukkan benar-benar menyerupai format email
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email); // Menggunakan Regular Expression (Regex) untuk mengecek secara spesifik apakah ada karakter '@' dan titik '.' di tempat yang semestinya
  }

  Future<void> _login() async { // Fungsi asinkron utama yang akan dijalankan ketika pengguna menekan tombol LOGIN
    final email = _emailController.text.trim(); // Mengambil teks dari input email dan menggunakan trim() untuk menghapus spasi yang tidak sengaja terketik di awal atau akhir kata
    final password = _passwordController.text.trim(); // Mengambil teks dari input password dan menghapus spasi ekstra

    if (email.isEmpty || password.isEmpty) { // Validasi lokal: Cek apakah kolom email atau password masih kosong
      setState(() => errorMessage = 'Please fill all fields'); // Jika ada yang kosong, munculkan pesan error dan hentikan proses
      return; // Berhenti mengeksekusi kode di bawahnya dan keluar dari fungsi ini
    }

    if (!_isValidEmail(email)) { // Validasi lokal: Mengecek apakah format penulisan emailnya salah menggunakan fungsi regex di atas
      setState(() => errorMessage = 'Invalid email format'); // Jika salah format, munculkan pesan error
      return;
    }

    setState(() { // Memanggil setState untuk mengubah tampilan UI sebelum menghubungi server
      isLoading = true; // Mengubah status loading menjadi true agar tombol login berubah jadi ikon muter-muter
      errorMessage = ''; // Mengosongkan pesan error sisa dari percobaan login sebelumnya (jika ada)
    });

    try { // Membuka blok 'try' untuk mencoba melakukan login ke server. Jika terjadi error di dalam blok ini, akan langsung ditangkap oleh blok 'catch' di bawah
      UserCredential userCredential = await _auth.signInWithEmailAndPassword( // Meminta Firebase untuk mencocokkan email dan password ini ke database server mereka
        email: email,
        password: password,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance(); // Mengakses penyimpanan memori lokal HP lagi
      if (rememberMe) { // Mengecek apakah pengguna saat ini sedang mencentang kotak 'Remember me'
        await prefs.setBool('remember_me', true); // Jika iya, simpan status true ke memori HP
        await prefs.setString('saved_email', email); // Dan simpan alamat email yang berhasil login ini ke memori HP
      } else { 
        await prefs.setBool('remember_me', false); // Jika tidak dicentang, simpan status false ke memori HP
        await prefs.remove('saved_email'); // Dan HAPUS email yang mungkin sebelumnya pernah tersimpan di HP
      }

      await prefs.setString('user_password', password); // Menyimpan password yang berhasil login ke dalam memori HP. (Catatan: Ini digunakan untuk mempermudah validasi ulang jika suatu saat user ingin edit profil)

      if (userCredential.user != null) { // Jika proses dari Firebase berhasil dan data user benar-benar ada
        if (context.mounted) { // Memastikan bahwa layar login ini masih terbuka di HP pengguna sebelum kita melakukan navigasi perpindahan layar (mencegah error)
          Navigator.pushReplacement( // Berpindah ke layar daftar kontak dan menghapus layar login dari riwayat (user tidak bisa pencet tombol 'back' untuk kembali ke login)
            context,
            MaterialPageRoute(
              builder: (context) => const KontakListScreen(
                showSuccessPopup: true, // Mengirim data ke halaman kontak untuk memunculkan notifikasi/popup "Login Berhasil" di sana
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) { // Blok khusus untuk menangkap error yang DIKIRIM OLEH FIREBASE (seperti password salah, akun tidak ada, dll)
      final message = switch (e.code) { // Menggunakan 'switch' expression bergaya modern Dart untuk mengubah kode error Firebase yang kaku menjadi pesan yang ramah pengguna
        'invalid-email' => 'Invalid email format',
        'user-not-found' => 'No account found with this email',
        'wrong-password' => 'Incorrect password',
        'invalid-credential' => 'Incorrect email or password',
        'user-disabled' => 'This account has been disabled',
        'too-many-requests' => 'Too many attempts. Please try again later',
        _ => e.message ?? 'Login failed', // Jika kode error tidak masuk daftar di atas, tampilkan pesan bawaan Firebase, atau fallback ke teks 'Login failed'
      };

      setState(() => errorMessage = message); // Menampilkan pesan error hasil terjemahan tadi ke layar pengguna
    } catch (e) { // Blok untuk menangkap error UMUM lainnya yang bukan berasal dari Firebase (contoh: HP tiba-tiba tidak ada internet)
      setState(() => errorMessage = e.toString()); // Menampilkan error umum tersebut ke layar dalam bentuk teks string
    }

    if (mounted) setState(() => isLoading = false); // Terlepas dari apakah login tadi sukses atau gagal, kita mematikan status loading (menjadi false) agar tombol kembali normal dan bisa ditekan lagi
  }

  //_______________________
  // UI & LAYOUTING HELPER
  //_______________________

  InputDecoration _inputDecoration({ // Fungsi pembantu (helper) untuk menyeragamkan desain tampilan kolom input (TextField) agar kode tidak berulang dan lebih rapi
    required String hint, // Parameter wajib: teks bayangan (hint) yang muncul saat input kosong
    required IconData icon, // Parameter wajib: ikon yang akan dipasang di sebelah kanan kolom input
  }) {
    return InputDecoration(
      hintText: hint, // Memasang teks hint dari parameter
      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 15), // Memberi warna abu-abu kebiruan terang pada teks hint
      suffixIcon: Icon(icon, color: const Color(0xFF90A4AE), size: 22), // Memasang ikon dari parameter dan menaruhnya di akhir/kanan kolom (suffixIcon)
      filled: true, // Mengaktifkan warna latar belakang untuk kolom input
      fillColor: Colors.white, // Menentukan warna latar belakang kolom input menjadi putih
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17), // Memberikan jarak ruang di dalam kolom input agar teks tidak menempel ke garis tepi
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), // Menentukan desain sudut melengkung (14) tanpa ada garis tepi (borderSide.none)
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), // Tampilan batas ketika kolom input sedang tidak disentuh
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF27B9F2), width: 2)), // Tampilan batas ketika kolom input sedang diklik/disentuh: memunculkan garis pinggir berwarna biru muda setebal 2 pixel
    );
  }

  //_______________________
  // BUILD METHOD - TAMPILAN UTAMA
  //_______________________

  @override
  Widget build(BuildContext context) { // Method inti dari Flutter untuk menggambar seluruh tampilan UI (Widget) ke layar HP
    final double screenWidth = MediaQuery.of(context).size.width; // Membaca ukuran lebar layar HP saat ini untuk membuat desain yang responsif (menyesuaikan ukuran HP)
    final double screenHeight = MediaQuery.of(context).size.height; // Membaca ukuran tinggi layar HP saat ini

    return Scaffold( // Widget fondasi utama sebuah halaman material design, menyediakan latar belakang putih dasar
      backgroundColor: Colors.white, // Memastikan warna paling dasar aplikasi ini berwarna putih
      resizeToAvoidBottomInset: true, // Sangat penting: Memastikan layar akan otomatis terangkat/mengecil agar kolom input dan tombol tidak tertutup oleh keyboard HP saat sedang mengetik
      body: SafeArea( // Membungkus konten agar tidak tertimpa oleh poni layar (notch), status bar (jam/baterai di atas), atau tombol navigasi bawaan HP di bagian bawah
        child: Column( // Menyusun anak-anak widget di dalamnya secara vertikal dari atas ke bawah
          children: [
            Expanded( // Menyuruh widget di dalamnya untuk mengambil SELURUH SISA ruang vertikal yang tersedia di layar
              child: SingleChildScrollView( // Membungkus konten dengan scroll agar layar bisa digeser/di-scroll ke bawah saat keyboard HP muncul, mencegah error 'pixel overflow' (garis kuning hitam)
                physics: const ClampingScrollPhysics(), // Mengatur gaya scroll. Clamping berarti scroll akan langsung berhenti tanpa efek memantul berlebihan saat mentok atas/bawah
                child: ConstrainedBox( // Memberikan batasan ukuran pada widget di dalamnya
                  constraints: BoxConstraints(
                    minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom, // Memaksa tinggi minimum area ini agar SETIDAKNYA seukuran layar HP (dikurangi tinggi notch dan navigasi bawah), memastikan desain tetap penuh walau isinya sedikit
                  ),
                  child: IntrinsicHeight( // Bekerja sama dengan ConstrainedBox dan Spacer untuk memastikan elemen-elemen di dalamnya didorong dengan proporsional memenuhi layar
                    child: Column( // Menyusun konten isi (logo dan form login) secara vertikal
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Memaksa anak-anak widget di dalamnya untuk melebar memenuhi batas kiri-kanan layar
                      children: [
                        SizedBox(height: screenHeight * 0.10), // Membuat ruang kosong transparan di bagian atas (mengambil 10% dari tinggi layar HP) untuk mendorong logo sedikit ke tengah

                        //_______________________
                        // BAGIAN LOGO
                        //_______________________
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24), // Memberi jarak tepi kiri dan kanan sejauh 24 pixel khusus untuk logo
                          child: Center( // Memastikan gambar logo berada tepat di tengah secara horizontal
                            child: Image.asset(
                              'images/logo-contacta.PNG', // Mengambil gambar logo dari folder lokal aplikasi
                              width: screenWidth * 0.72, // Lebar logo diatur menjadi 72% dari total lebar layar HP
                              fit: BoxFit.contain, // Memastikan gambar tidak gepeng, akan selalu menjaga proporsi aslinya
                            ),
                          ),
                        ),

                        const Spacer(), // Widget sakti: berfungsi seperti per, akan meregang sekuat-kuatnya untuk mendorong bagian logo ke atas dan bagian form login mentok ke bawah layar

                        //_______________________
                        // BAGIAN KARTU FORMULIR LOGIN
                        //_______________________
                        Container(
                          width: double.infinity, // Memaksa container form ini melebarkan dirinya selebar layar penuh
                          decoration: const BoxDecoration(
                            color: Color(0xFFDDF0F8), // Memberikan warna latar belakang biru sangat muda ke dalam form container
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(36), // Membentuk lengkungan hanya pada sudut KIRI ATAS sebesar 36 pixel
                              topRight: Radius.circular(36), // Membentuk lengkungan hanya pada sudut KANAN ATAS sebesar 36 pixel
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 36), // Memberikan ruang di dalam kotak form: Kiri 24, Atas 32, Kanan 24, Bawah 36
                          child: Column( // Menyusun label teks dan kolom input ke bawah
                            crossAxisAlignment: CrossAxisAlignment.start, // Meratakan semua isi form ke arah kiri
                            mainAxisSize: MainAxisSize.min, // Meminta agar tinggi Column ini hanya sebesar total isi yang ada di dalamnya, tidak lebih
                            children: [
                              const Center( // Menempatkan teks judul di tengah
                                child: Text('LOGIN', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0D1B2A), letterSpacing: 0.5)), // Styling teks LOGIN tebal dan besar
                              ),

                              const SizedBox(height: 24), // Memberikan jarak pemisah antara judul LOGIN dan form pertama (Email)

                              //_______________________
                              // INPUT FIELD: EMAIL
                              //_______________________
                              const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))), // Teks label untuk kolom email
                              const SizedBox(height: 8), // Jarak kecil antara label dan kotak input
                              TextField( // Kotak input teks
                                controller: _emailController, // Menghubungkan kotak input dengan controller email yang sudah kita buat di atas
                                keyboardType: TextInputType.emailAddress, // Mengubah tipe keyboard HP khusus untuk email (menampilkan tombol '@' dan '.com' dengan lebih mudah)
                                decoration: _inputDecoration(hint: 'your email....', icon: Icons.account_circle_outlined), // Memanggil fungsi desain yang dibuat di atas
                              ),

                              const SizedBox(height: 18), // Jarak antar form email dan form password

                              //_______________________
                              // INPUT FIELD: PASSWORD
                              //_______________________
                              const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))), // Teks label untuk kolom password
                              const SizedBox(height: 8), // Jarak kecil antara label dan kotak input
                              TextField(
                                controller: _passwordController, // Menghubungkan kotak input dengan controller password
                                obscureText: true, // Sangat Penting: Mengubah huruf yang diketik menjadi titik-titik bulat agar password tidak terlihat orang lain
                                decoration: _inputDecoration(hint: 'your password....', icon: Icons.lock_outline), // Memanggil fungsi desain tampilan
                              ),

                              const SizedBox(height: 14), // Jarak pemisah menuju opsi remember me

                              //_______________________
                              // CHECKBOX: REMEMBER ME
                              //_______________________
                              Row( // Menyusun checkbox dan teksnya menyamping dari kiri ke kanan
                                children: [
                                  SizedBox( // Membatasi ukuran sentuh area Checkbox menjadi kotak ukuran 22x22
                                    width: 22, height: 22,
                                    child: Checkbox( // Widget kotak centang
                                      value: rememberMe, // Nilai yang menentukan apakah kotak sedang dicentang atau tidak, mengambil dari variabel state kita
                                      activeColor: const Color(0xFF27B9F2), // Warna centang menjadi biru jika aktif
                                      onChanged: (value) => setState(() => rememberMe = value ?? false), // Fungsi yang otomatis dipanggil saat user menyentuh kotak centang, mengubah variabel state dan memaksa layar me-refresh (setState)
                                    ),
                                  ),
                                  const SizedBox(width: 10), // Memberi jarak pemisah horizontal antara kotak centang dan tulisannya
                                  const Text('Remember me', style: TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))), // Teks label di sebelah kotak centang
                                ],
                              ),

                              //_______________________
                              // PESAN ERROR (MUNCUL DINAMIS)
                              //_______________________
                              if (errorMessage.isNotEmpty) // Baris ini adalah operator logika bawaan Dart di UI. Artinya: UI di bawah (Padding) HANYA AKAN DIGAMBAR JIKA isi teks 'errorMessage' tidak kosong
                                Padding(
                                  padding: const EdgeInsets.only(top: 14), // Menambahkan jarak sedikit di atas teks error
                                  child: Center(child: Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13))), // Menampilkan pesan error berwarna merah di tengah layar
                                ),

                              const SizedBox(height: 22), // Jarak ke tombol login

                              //_______________________
                              // TOMBOL AKSI: LOGIN
                              //_______________________
                              SizedBox(
                                width: double.infinity, // Memaksa tombol agar melebar memenuhi sisa ruang kiri ke kanan
                                height: 54, // Menetapkan tinggi tombol sebesar 54 pixel (sangat nyaman untuk disentuh jari)
                                child: DecoratedBox( // Widget untuk menggambar dekorasi kompleks, di sini kita mau bikin warna tombol bergradasi
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF26C6E8), Color(0xFF1E90FF)]), // Membuat efek gradasi warna dari biru muda ke biru laut
                                    borderRadius: BorderRadius.circular(14), // Membuat ujung sudut tombol melengkung
                                  ),
                                  child: ElevatedButton( // Widget tombol utamanya
                                    onPressed: isLoading ? null : _login, // Logika Cerdas: Jika aplikasi sedang 'loading' (true), tombol akan dinonaktifkan (null). Jika tidak loading, menekan tombol akan memanggil fungsi '_login'
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0), // Menghilangkan warna background dan bayangan bawaan tombol agar warna gradasi dari DecoratedBox di belakangnya bisa terlihat jelas
                                    child: isLoading // Memeriksa status loading
                                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5) // Jika isLoading true: Ganti tulisan jadi animasi muter-muter (loading) warna putih
                                        : const Text('LOGIN', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)), // Jika isLoading false: Tampilkan tulisan LOGIN normal
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24), // Jarak bagian paling bawah dengan menu pendaftaran

                              //_______________________
                              // NAVIGASI: MENU REGISTRASI
                              //_______________________
                              Center( // Meratakan seluruh bagian teks ini di tengah
                                child: Wrap( // Wrap berguna jika layarnya sangat kecil dan teks kepanjangan, teks sisanya otomatis turun ke baris bawah dengan rapi (tidak terpotong)
                                  children: [
                                    const Text("Don't have an account? ", style: TextStyle(fontSize: 15, color: Color(0xFF3A3A3A))), // Teks biasa
                                    GestureDetector( // Widget spesial transparan untuk menangkap sentuhan jari pada teks di dalamnya
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())), // Fungsi yang dijalankan saat disentuh: Buka layar pendaftaran (RegisterScreen) di atas layar saat ini
                                      child: const Text('Register here', style: TextStyle(color: Color(0xFF1565C0), fontSize: 15, decoration: TextDecoration.underline)), // Teks bergaya link (biru dan bergaris bawah) agar terlihat bisa diklik
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}