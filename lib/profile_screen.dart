// profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore untuk database
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth untuk login/user
import 'package:flutter/material.dart'; // Import UI Material Flutter
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences untuk simpan data lokal

import 'login_screen.dart'; // Import halaman login

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance Firebase Auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Instance Firestore

  final TextEditingController _nameController = TextEditingController(); // Controller untuk field nama
  final TextEditingController _emailController = TextEditingController(); // Controller untuk field email
  final TextEditingController _passwordController = TextEditingController(); // Controller untuk field password

  bool _isEditing = false; // Status mode: true = sedang edit, false = mode lihat
  bool _isLoading = false; // true = sedang proses simpan ke Firebase
  bool _obscurePassword = true; // true = password disembunyikan, false = password terlihat

  String _originalName = ''; // Backup nama asli sebelum diedit (untuk cancel edit)
  String _originalEmail = ''; // Backup email asli sebelum diedit (untuk cancel edit)

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Ambil data user dari Firebase saat halaman pertama dibuka
  }

  @override
  void dispose() {
    // Bersihkan semua controller dari memori saat halaman ditutup
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Ambil data nama & email user dari Firestore dan Firebase Auth
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return; // Jika tidak ada user yang login, hentikan fungsi

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get(); // Ambil dokumen user dari Firestore

      if (mounted) {
        setState(() {
          _nameController.text = doc.data()?['name'] ?? user.displayName ?? ''; // Prioritas: Firestore → displayName → kosong
          _emailController.text = user.email ?? '';
          _originalName = _nameController.text; // Simpan backup untuk keperluan cancel edit
          _originalEmail = _emailController.text;
        });
      }
    } catch (_) {
      // Jika Firestore gagal, gunakan data langsung dari Firebase Auth sebagai fallback
      if (mounted) {
        setState(() {
          _nameController.text = user.displayName ?? '';
          _emailController.text = user.email ?? '';
          _originalName = _nameController.text;
          _originalEmail = _emailController.text;
        });
      }
    }
  }

  // Ambil password yang tersimpan di lokal (SharedPreferences) saat mode edit dibuka
  Future<void> _loadSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('user_password') ?? '';

    if (mounted) {
      _passwordController.text = savedPassword; // Isi field password dengan data lokal
    }
  }

  // Tampilkan pesan singkat di bawah layar (snackbar)
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // Simpan perubahan profil (nama, email, password) ke Firebase
  Future<void> _saveProfile() async {
    final sw = MediaQuery.of(context).size.width;

    final newPass = _passwordController.text.trim();
    final newEmail = _emailController.text.trim();

    // Validasi password: jika diisi, minimal 6 karakter
    if (newPass.isNotEmpty && newPass.length < 6) {
      _showSnackbar('Password must be at least 6 characters', Colors.red);
      return;
    }

    // Validasi format email menggunakan regex standar
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (newEmail.isNotEmpty && !emailRegex.hasMatch(newEmail)) {
      _showSnackbar('Invalid email format', Colors.red);
      return;
    }

    // Tampilkan dialog konfirmasi sebelum menyimpan
    final bool? confirm = await _showConfirmDialog(
      context: context,
      sw: sw,
      title: 'Save changes?',
      yesColor: const Color(0xFF42AAFF), // Tombol YES berwarna biru
    );

    if (confirm != true) return; // Batal jika user pilih NO

    setState(() => _isLoading = true); // Aktifkan loading indicator

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update nama di Firebase Auth
      await user.updateDisplayName(_nameController.text.trim());

      // Update password hanya jika field password diisi
      if (newPass.isNotEmpty) {
        await user.updatePassword(newPass);

        // Simpan password baru ke SharedPreferences (lokal)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_password', newPass);
      }

      // Kirim email verifikasi ke email baru jika email berubah
      if (newEmail.isNotEmpty && newEmail != _originalEmail) {
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      // Simpan nama & email ke Firestore (merge: tidak menghapus field lain)
      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': newEmail,
        'updated_at': FieldValue.serverTimestamp(), // Waktu update otomatis dari server
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isEditing = false; // Kembali ke mode lihat setelah berhasil simpan
          _originalName = _nameController.text; // Update backup dengan data terbaru
          _originalEmail = newEmail;
          _passwordController.clear(); // Kosongkan field password setelah disimpan
        });

        _showSnackbar('Profile updated successfully', Colors.green);
      }
    } on FirebaseAuthException catch (e) {
      // Tangkap error khusus Firebase Auth dan tampilkan pesan yang sesuai
      final message = switch (e.code) {
        'weak-password'        => 'Password must be at least 6 characters',
        'invalid-email'        => 'Invalid email format',
        'email-already-in-use' => 'Email is already in use',
        'requires-recent-login'=> 'Please login again before changing sensitive data',
        _                      => 'Error: ${e.message ?? e.code}',
      };

      if (mounted) _showSnackbar(message, Colors.red);
    } catch (e) {
      if (mounted) _showSnackbar('Failed to save: ${e.toString()}', Colors.red);
    }

    if (mounted) setState(() => _isLoading = false); // Matikan loading apapun hasilnya
  }

  // Proses logout: konfirmasi dulu, lalu sign out dan arahkan ke LoginScreen
  Future<void> _logout() async {
    final sw = MediaQuery.of(context).size.width;

    final bool? confirm = await _showConfirmDialog(
      context: context,
      sw: sw,
      title: 'Are you sure you want to Logout?',
      yesColor: const Color(0xFFE53935), // Tombol YES berwarna merah (tanda bahaya)
    );

    if (confirm != true) return; // Batal jika user pilih NO

    await _auth.signOut(); // Logout dari Firebase Auth

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false, // Hapus semua halaman sebelumnya dari history navigasi
      );
    }
  }

  // Batalkan mode edit: kembalikan semua field ke data asli sebelum diedit
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _nameController.text = _originalName; // Kembalikan ke nama sebelum diedit
      _emailController.text = _originalEmail; // Kembalikan ke email sebelum diedit
      _passwordController.clear(); // Kosongkan field password
    });
  }

  // Dialog konfirmasi YES/NO yang bisa dipakai untuk logout maupun simpan profil
  // Parameter yesColor mengatur warna tombol YES (biru untuk simpan, merah untuk logout)
  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required double sw,
    required String title,
    required Color yesColor,
  }) {
    final dialogWidth = sw * 0.72; // Lebar dialog = 72% dari lebar layar

    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: (sw - dialogWidth) / 2, // Otomatis center secara horizontal
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Tinggi dialog menyesuaikan isi
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  // Tombol NO: kembalikan false (batal)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0), // Abu-abu
                          borderRadius: BorderRadius.circular(50),
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

                  const SizedBox(width: 10),

                  // Tombol YES: kembalikan true (konfirmasi)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: yesColor, // Warna tombol YES dari parameter (biru/merah)
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

  // Styling seragam untuk semua field input (border kapsul, ikon kiri, hint abu-abu)
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon, // Opsional: ikon di sisi kanan (contoh: tombol mata untuk password)
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
      prefixIcon: Icon(icon, color: Colors.grey[700], size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30), // Bentuk kapsul
        borderSide: const BorderSide(color: Colors.black, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.black, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5), // Biru saat difokus
      ),
    );
  }

  // Buat field input teks dengan styling seragam
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,      // true = field tidak bisa diedit (mode lihat)
    bool obscureText = false,   // true = teks disembunyikan (untuk password)
    Widget? suffixIcon,         // Opsional: ikon kanan (tombol mata password)
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: _inputDecoration(
        hint: hint,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  // Tombol LOG OUT berwarna merah di bagian bawah mode lihat profil
  Widget _buildLogoutButton(double scale) {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity, // Lebar penuh mengikuti parent
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE), // Background merah sangat muda
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFF3B0A), width: 1.2), // Garis tepi merah
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.logout, color: Color(0xFFFF3B0A), size: 22), // Ikon logout merah
            const SizedBox(width: 6),
            Text(
              'LOG OUT',
              style: TextStyle(
                color: const Color(0xFFFF3B0A),
                fontSize: 16 * scale, // Ukuran font mengikuti skala layar
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                height: 1,
                shadows: const [
                  Shadow(color: Color(0xFFFF3B0A), offset: Offset(0.3, 0)), // Efek shadow merah tipis
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header atas halaman: berisi tombol cancel (kiri), judul tengah, dan tombol edit/simpan (kanan)
  Widget _buildHeader(double sw, double sh, double scale) {
    return Padding(
      padding: EdgeInsets.fromLTRB(sw * 0.055, sh * 0.018, sw * 0.055, 0),
      child: Stack(
        alignment: Alignment.center, // Judul ditengahkan relatif terhadap Stack
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              // Tombol cancel (X) di kiri — hanya muncul saat mode edit aktif
              SizedBox(
                width: 60, // Lebar area dikunci agar layout tidak bergeser
                child: _isEditing
                    ? GestureDetector(
                        onTap: _cancelEdit,
                        child: Container(
                          width: 42 * scale,
                          height: 42 * scale,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F1F1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 24 * scale, color: Colors.black),
                        ),
                      )
                    : const SizedBox(), // Kosong jika tidak mode edit
              ),

              // Tombol simpan (centang) atau Edit (oval) di kanan
              SizedBox(
                width: 90,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _isEditing
                      // Mode edit: tampilkan tombol centang untuk simpan profil
                      ? GestureDetector(
                          onTap: _isLoading ? null : _saveProfile, // Nonaktif saat loading
                          child: Container(
                            width: 42 * scale,
                            height: 42 * scale,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDFF0FF), // Background biru muda
                              shape: BoxShape.circle,
                            ),
                            child: _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(strokeWidth: 2), // Spinner loading
                                  )
                                : Icon(Icons.check, color: const Color(0xFF1E5BFF), size: 26 * scale),
                          ),
                        )
                      // Mode lihat: tampilkan tombol oval "Edit"
                      : GestureDetector(
                          onTap: () {
                            setState(() => _isEditing = true); // Aktifkan mode edit
                            _loadSavedPassword(); // Muat password tersimpan dari lokal
                          },
                          child: Container(
                            width: 64 * scale,
                            height: 34 * scale,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E5E5), // Background abu-abu
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

          // Judul "Edit profile" di tengah — hanya muncul saat mode edit aktif
          if (_isEditing)
            Center(
              child: Text(
                'Edit profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Konten mode LIHAT: tampilkan nama user, email (read-only), dan tombol logout
  Widget _buildViewMode(double sw, double sh, double scale) {
    return Column(
      children: [
        SizedBox(height: sh * 0.02),

        // Nama user, jika kosong tampilkan 'User' sebagai default
        Text(
          _nameController.text.isEmpty ? 'User' : _nameController.text,
          style: TextStyle(fontSize: 26 * scale, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: sh * 0.04),

        // Field email dikunci (tidak bisa diedit) di mode lihat
        _buildField(
          controller: _emailController,
          hint: 'Email',
          icon: Icons.email,
          readOnly: true,
        ),

        const SizedBox(height: 10),

        _buildLogoutButton(scale),
      ],
    );
  }

  // Konten mode EDIT: form input nama, email, dan password yang bisa diubah
  Widget _buildEditMode(double sh) {
    return Column(
      children: [
        SizedBox(height: sh * 0.05),

        // Field nama (bisa diedit)
        _buildField(
          controller: _nameController,
          hint: 'John Doe',
          icon: Icons.person,
        ),

        SizedBox(height: sh * 0.018),

        // Field email (bisa diedit), keyboard otomatis muncul tombol '@'
        _buildField(
          controller: _emailController,
          hint: 'myemail@gmail.com',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),

        SizedBox(height: sh * 0.018),

        // Field password dengan tombol mata untuk show/hide password
        _buildField(
          controller: _passwordController,
          hint: '********',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword, // Sembunyikan atau tampilkan teks
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword), // Toggle show/hide
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility, // Ikon berubah sesuai state
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq    = MediaQuery.of(context);
    final sw    = mq.size.width;  // Lebar layar dalam pixel
    final sh    = mq.size.height; // Tinggi layar dalam pixel
    final scale = (sw / 390).clamp(0.85, 1.2); // Skala font responsif (basis: layar 390px)
    final hPad  = sw * 0.055; // Padding horizontal halaman = 5.5% dari lebar layar
    final avatarSize     = sw * 0.31; // Diameter avatar = 31% lebar layar
    final avatarIconSize = sw * 0.16; // Ukuran ikon di dalam avatar = 16% lebar layar

    return Column(
      children: [

        // Header: tombol cancel, judul, tombol edit/simpan
        _buildHeader(sw, sh, scale),

        // Body: bisa di-scroll, berisi avatar + konten mode lihat atau edit
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              children: [
                SizedBox(height: sh * 0.045),

                // Avatar lingkaran hitam dengan ikon orang putih di tengah
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: avatarIconSize),
                ),

                // Tampilkan konten sesuai mode aktif
                if (!_isEditing) _buildViewMode(sw, sh, scale), // Mode lihat
                if (_isEditing)  _buildEditMode(sh),             // Mode edit

                SizedBox(height: sh * 0.04), // Spasi bawah untuk kenyamanan scroll
              ],
            ),
          ),
        ),
      ],
    );
  }
}