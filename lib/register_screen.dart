// register_screen.dart
import 'package:flutter/material.dart'; // Import Flutter Material untuk semua widget UI
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth untuk proses registrasi akun
import 'login_screen.dart'; // Import halaman login (untuk diarahkan setelah register berhasil)

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance Firebase Auth untuk proses buat akun baru

  // Controller untuk setiap field input, akan dibersihkan di dispose()
  final TextEditingController _nameController     = TextEditingController(); // Controller field nama lengkap
  final TextEditingController _emailController    = TextEditingController(); // Controller field email
  final TextEditingController _passwordController = TextEditingController(); // Controller field password

  bool isLoading     = false; // true = sedang proses registrasi ke Firebase (tampilkan spinner)
  String errorMessage = '';   // Pesan error yang ditampilkan di bawah form jika ada validasi gagal

  @override
  void dispose() {
    // Bersihkan semua controller dari memori saat halaman ditutup (cegah memory leak)
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Cek apakah format email valid menggunakan regex standar (harus ada @, domain, dan ekstensi)
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  // Proses registrasi akun baru: validasi input → buat akun di Firebase → logout → tampilkan popup sukses
  Future<void> _register() async {
    final name     = _nameController.text.trim();     // Ambil nama, hapus spasi di awal/akhir
    final email    = _emailController.text.trim();    // Ambil email, hapus spasi di awal/akhir
    final password = _passwordController.text.trim(); // Ambil password, hapus spasi di awal/akhir

    // ── Validasi lokal sebelum kirim ke Firebase ──────────────────────────────

    if (name.isEmpty) {
      setState(() => errorMessage = 'Please enter your full name');
      return; // Hentikan proses jika nama kosong
    }

    if (email.isEmpty) {
      setState(() => errorMessage = 'Please enter your email');
      return; // Hentikan proses jika email kosong
    }

    if (!_isValidEmail(email)) {
      setState(() => errorMessage = 'Invalid email format');
      return; // Hentikan proses jika format email tidak valid
    }

    if (password.isEmpty) {
      setState(() => errorMessage = 'Please enter a password');
      return; // Hentikan proses jika password kosong
    }

    if (password.length < 6) {
      setState(() => errorMessage = 'Password must be at least 6 characters');
      return; // Hentikan proses jika password kurang dari 6 karakter
    }

    // Semua validasi lokal lolos: aktifkan loading dan kosongkan pesan error
    setState(() {
      isLoading     = true;
      errorMessage  = '';
    });

    try {
      // Buat akun baru di Firebase Auth dengan email dan password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan nama lengkap ke displayName profil Firebase Auth
      await userCredential.user?.updateDisplayName(name);

      // Paksa logout setelah register agar user tidak langsung masuk otomatis
      // User harus login manual setelah register berhasil
      await _auth.signOut();

      if (context.mounted) {
        _showSuccessPopup(); // Tampilkan popup sukses setelah semua proses selesai
      }
    } on FirebaseAuthException catch (e) {
      // Tangkap error spesifik dari Firebase Auth dan tampilkan pesan yang sesuai
      final message = switch (e.code) {
        'invalid-email'         => 'Invalid email format',
        'email-already-in-use'  => 'Email is already in use',        // Email sudah terdaftar
        'weak-password'         => 'Password must be at least 6 characters',
        'operation-not-allowed' => 'Registration is currently unavailable', // Registrasi dinonaktifkan di Firebase Console
        _                       => e.message ?? 'Registration failed', // Error lain yang tidak terduga
      };

      setState(() => errorMessage = message); // Tampilkan pesan error di UI
    } catch (e) {
      setState(() => errorMessage = e.toString()); // Tangkap error umum di luar Firebase
    }

    if (mounted) setState(() => isLoading = false); // Matikan loading apapun hasilnya
  }

  // Tampilkan popup sukses setelah akun berhasil dibuat
  // Popup tidak bisa ditutup dengan mengetuk area luar (barrierDismissible: false)
  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // User wajib tekan tombol CONTINUE, tidak bisa tap di luar
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Dialog hanya setinggi kontennya
            children: [

              // Ikon centang hijau di dalam lingkaran sebagai tanda sukses
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50), // Hijau
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 42),
              ),

              const SizedBox(height: 20),

              // Judul popup
              const Text(
                'Register Succes!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1B2A), // Hitam tua
                ),
              ),

              const SizedBox(height: 8),

              // Subjudul popup
              const Text(
                "you've created you account.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF90A4AE)), // Abu-abu
              ),

              const SizedBox(height: 24),

              // Tombol CONTINUE: tutup popup lalu pindah ke halaman Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog popup terlebih dahulu

                    Navigator.pushReplacement( // Ganti halaman saat ini dengan LoginScreen
                      context,                 // pushReplacement agar RegisterScreen tidak bisa di-back
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27B9F2), // Biru terang
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2, // Jarak antar huruf sedikit lebih lebar
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

  // Styling seragam untuk semua field input di form registrasi
  // Perbedaan dari layar lain: ikon di KANAN (suffixIcon), bukan di kiri
  InputDecoration _inputDecoration({
    required String hint,   // Teks placeholder yang tampil saat field kosong
    required IconData icon, // Ikon yang ditampilkan di sisi kanan field
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 15), // Placeholder abu-abu muda
      suffixIcon: Icon(icon, color: const Color(0xFF90A4AE), size: 22),   // Ikon di sisi KANAN field
      filled: true,
      fillColor: Colors.white, // Background field putih
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none, // Tidak ada garis border default
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none, // Tidak ada garis border saat field aktif tapi tidak difokus
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF27B9F2), width: 2), // Garis biru tebal 2px saat field difokus
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth  = MediaQuery.of(context).size.width;  // Lebar layar dalam pixel
    final double screenHeight = MediaQuery.of(context).size.height; // Tinggi layar dalam pixel

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Layar otomatis naik saat keyboard muncul agar form tetap terlihat
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(), // Scroll berhenti tepat di tepi (tidak ada efek bounce)
                child: ConstrainedBox(
                  // Pastikan konten minimal setinggi layar agar Spacer berfungsi dengan benar
                  constraints: BoxConstraints(
                    minHeight: screenHeight
                        - MediaQuery.of(context).padding.top    // Kurangi status bar atas
                        - MediaQuery.of(context).padding.bottom, // Kurangi navigation bar bawah
                  ),
                  child: IntrinsicHeight(
                    // IntrinsicHeight memaksa Column anak untuk mengisi tinggi yang tersedia
                    // sehingga Spacer bisa mendorong form ke bawah dengan benar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        SizedBox(height: screenHeight * 0.10), // Jarak atas sebelum logo (10% tinggi layar)

                        // ── Logo aplikasi di bagian atas ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Center(
                            child: Image.asset(
                              'images/logo-contacta.PNG',
                              width: screenWidth * 0.72, // Logo selebar 72% dari lebar layar
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const Spacer(), // Dorong form ke bawah, logo tetap di atas

                        // ── Form registrasi: background biru muda, sudut atas membulat ──
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDDF0F8), // Background biru muda
                            borderRadius: BorderRadius.only(
                              topLeft:  Radius.circular(36), // Sudut kiri atas membulat
                              topRight: Radius.circular(36), // Sudut kanan atas membulat
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              // Judul form "SIGN UP" di tengah
                              const Center(
                                child: Text(
                                  'SIGN UP',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0D1B2A), // Hitam tua
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Field Nama Lengkap ──
                              const Text('Full Name'), // Label di atas field
                              const SizedBox(height: 8),
                              TextField(
                                controller: _nameController,
                                decoration: _inputDecoration(
                                  hint: 'your name....',
                                  icon: Icons.edit_outlined, // Ikon pensil di kanan
                                ),
                              ),

                              const SizedBox(height: 18),

                              // ── Field Email ──
                              const Text('Email'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress, // Keyboard otomatis tampilkan tombol '@'
                                decoration: _inputDecoration(
                                  hint: 'your email....',
                                  icon: Icons.account_circle_outlined, // Ikon profil di kanan
                                ),
                              ),

                              const SizedBox(height: 18),

                              // ── Field Password ──
                              const Text('Password'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: true, // Sembunyikan karakter password (tampil sebagai ***)
                                decoration: _inputDecoration(
                                  hint: 'your password....',
                                  icon: Icons.lock_outline, // Ikon gembok di kanan
                                ),
                              ),

                              // Tampilkan pesan error di bawah field password (hanya jika ada error)
                              if (errorMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Center(
                                    child: Text(
                                      errorMessage,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 22),

                              // Teks "Already have an account? Login here"
                              // Wrap digunakan agar teks bisa pindah baris jika layar sempit
                              Center(
                                child: Wrap(
                                  children: [
                                    const Text('Already have an account? '),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context), // Kembali ke halaman Login
                                      child: const Text(
                                        'Login here',
                                        style: TextStyle(
                                          color: Color(0xFF1565C0),           // Biru tua
                                          decoration: TextDecoration.underline, // Garis bawah tanda link
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              // ── Tombol SIGN UP dengan gradient biru ──
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    // Gradient dari biru cyan ke biru tua (kiri ke kanan)
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF26C6E8), // Biru cyan
                                        Color(0xFF1E90FF), // Biru tua
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _register, // Nonaktif saat loading
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent, // Transparan agar gradient terlihat
                                      elevation: 0,
                                    ),
                                    // Tampilkan spinner saat loading, teks "SIGN UP" saat tidak loading
                                    child: isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text(
                                            'SIGN UP',
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