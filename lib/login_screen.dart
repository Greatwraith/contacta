// login_screen.dart

// ════════════════════════════════════════════════════════════════
// BAGIAN IMPORTS
// firebase_auth: Mengelola komunikasi ke Firebase untuk autentikasi.
// shared_preferences: Menyimpan data sesi (email/password) secara lokal di memori perangkat.
// ════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'register_screen.dart';
import 'kontak_list_screen.dart';

// ════════════════════════════════════════════════════════════════
// KELAS UTAMA: LoginScreen
// Layar ini menggunakan StatefulWidget karena memiliki tampilan
// yang bisa berubah (seperti checkbox remember me dan animasi loading).
// ════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Instance FirebaseAuth untuk memanggil fungsi-fungsi autentikasi
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controller untuk membaca dan mengontrol teks yang diinput oleh pengguna
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variabel state untuk mengatur perubahan UI
  bool rememberMe = false; // Status checkbox remember me
  bool isLoading = false; // Penentu apakah animasi loading sedang berjalan
  String errorMessage = ''; // Menyimpan pesan error jika login gagal

  // ════════════════════════════════════════════════════════════════
  // SIKLUS HIDUP WIDGET (LIFECYCLE)
  // ════════════════════════════════════════════════════════════════
  
  @override
  void initState() {
    super.initState();
    // Dijalankan sekali saat layar pertama kali dibuka
    _checkLoginStatus();
    _loadRememberMe();
  }

  @override
  void dispose() {
    // Membersihkan controller dari memori saat layar ditutup untuk mencegah memory leak
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  // LOGIKA AUTENTIKASI & SESI
  // ════════════════════════════════════════════════════════════════

  // Mengecek apakah pengguna sudah login sebelumnya
  void _checkLoginStatus() {
    User? user = _auth.currentUser;

    if (user != null) {
      // Jika sesi login masih ada, langsung arahkan ke halaman utama
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const KontakListScreen(),
          ),
        );
      });
    }
  }

  // Mengambil data preferensi "Remember Me" dari penyimpanan lokal
  Future<void> _loadRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool savedRemember = prefs.getBool('remember_me') ?? false;
    String savedEmail = prefs.getString('saved_email') ?? '';

    setState(() {
      rememberMe = savedRemember;
      if (savedRemember) {
        _emailController.text = savedEmail; // Isi otomatis email jika sebelumnya dicentang
      }
    });
  }

  // Validasi format email menggunakan Regular Expression (Regex)
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  // Fungsi utama untuk memproses login
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Validasi input lokal
    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please fill all fields');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => errorMessage = 'Invalid email format');
      return;
    }

    // 2. Tampilkan indikator loading dan bersihkan pesan error
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // 3. Permintaan login ke server Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 4. Menyimpan sesi preferensi pengguna secara lokal
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', email);
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('saved_email');
      }

      // Menyimpan password untuk kebutuhan validasi ulang di fitur edit profil nanti
      await prefs.setString('user_password', password);

      // 5. Pindah ke halaman utama jika login berhasil
      if (userCredential.user != null) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const KontakListScreen(
                showSuccessPopup: true,
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // 6. Penanganan error spesifik dari Firebase
      final message = switch (e.code) {
        'invalid-email' => 'Invalid email format',
        'user-not-found' => 'No account found with this email',
        'wrong-password' => 'Incorrect password',
        'invalid-credential' => 'Incorrect email or password',
        'user-disabled' => 'This account has been disabled',
        'too-many-requests' => 'Too many attempts. Please try again later',
        _ => e.message ?? 'Login failed',
      };

      setState(() => errorMessage = message);
    } catch (e) {
      // Menangani error umum di luar Firebase
      setState(() => errorMessage = e.toString());
    }

    // Mematikan indikator loading setelah proses selesai (baik sukses maupun gagal)
    if (mounted) setState(() => isLoading = false);
  }

  // ════════════════════════════════════════════════════════════════
  // UI & LAYOUTING
  // ════════════════════════════════════════════════════════════════

  // Fungsi pembantu untuk membuat desain input (TextField) yang seragam
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 15),
      suffixIcon: Icon(icon, color: const Color(0xFF90A4AE), size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF27B9F2), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil dimensi layar perangkat untuk keperluan layout responsif
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // Mencegah UI tertutup oleh keyboard
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Memastikan tinggi minimum sesuai dengan ruang layar yang tersedia
                    minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: screenHeight * 0.10),

                        // Bagian Logo
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Center(
                            child: Image.asset(
                              'images/logo-contacta.PNG',
                              width: screenWidth * 0.72,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // Spacer mendorong elemen di bawahnya agar turun ke dasar layar
                        const Spacer(),

                        // Bagian Kartu Formulir Login
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDDF0F8),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(36),
                              topRight: Radius.circular(36),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Center(
                                child: Text('LOGIN', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0D1B2A), letterSpacing: 0.5)),
                              ),

                              const SizedBox(height: 24),

                              // Input Field: Email
                              const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(hint: 'your email....', icon: Icons.account_circle_outlined),
                              ),

                              const SizedBox(height: 18),

                              // Input Field: Password
                              const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: true, // Menyembunyikan teks password
                                decoration: _inputDecoration(hint: 'your password....', icon: Icons.lock_outline),
                              ),

                              const SizedBox(height: 14),

                              // Checkbox: Remember Me
                              Row(
                                children: [
                                  SizedBox(
                                    width: 22, height: 22,
                                    child: Checkbox(
                                      value: rememberMe,
                                      activeColor: const Color(0xFF27B9F2),
                                      onChanged: (value) => setState(() => rememberMe = value ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Remember me', style: TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
                                ],
                              ),

                              // Menampilkan pesan error jika variabel errorMessage tidak kosong
                              if (errorMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Center(child: Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13))),
                                ),

                              const SizedBox(height: 22),

                              // Tombol Aksi: Login
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF26C6E8), Color(0xFF1E90FF)]),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ElevatedButton(
                                    // Menonaktifkan tombol saat loading berjalan
                                    onPressed: isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
                                    child: isLoading
                                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                                        : const Text('LOGIN', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Navigasi ke Layar Registrasi
                              Center(
                                child: Wrap(
                                  children: [
                                    const Text("Don't have an account? ", style: TextStyle(fontSize: 15, color: Color(0xFF3A3A3A))),
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                                      child: const Text('Register here', style: TextStyle(color: Color(0xFF1565C0), fontSize: 15, decoration: TextDecoration.underline)),
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