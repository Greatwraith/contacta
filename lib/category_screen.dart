// category_screen.dart

// ════════════════════════════════════════════════════════════════
// BAGIAN IMPORTS
// Mengimpor semua library dan file eksternal yang dibutuhkan layar ini.
// ════════════════════════════════════════════════════════════════
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk berinteraksi dengan database Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Untuk mendapatkan data user yang sedang login (Authentication)
import 'package:flutter/material.dart'; // Widget dasar UI dari Flutter

import 'category_model.dart'; // Mengimpor model data kategori yang sudah dibuat sebelumnya
import 'category_detail_screen.dart'; // Mengimpor layar detail kategori untuk navigasi

// ════════════════════════════════════════════════════════════════
// WIDGET UTAMA (STATEFUL)
// Menggunakan StatefulWidget karena layar ini bersifat dinamis 
// (ada pencarian, mode edit, dan pembaruan data real-time).
// ════════════════════════════════════════════════════════════════
class CategoryScreen extends StatefulWidget {
  // Callback (fungsi operan) untuk meminta perubahan tab di navigasi utama jika diperlukan
  final void Function(int) onRequestTabChange;

  const CategoryScreen({
    super.key,
    required this.onRequestTabChange, // Parameter ini wajib diisi saat memanggil layar ini
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

// ════════════════════════════════════════════════════════════════
// STATE DARI CATEGORY SCREEN
// Di sinilah semua logika, variabel, dan UI didefinisikan.
// ════════════════════════════════════════════════════════════════
class _CategoryScreenState extends State<CategoryScreen> {
  // Mengambil UID (User ID) unik dari user yang saat ini sedang login melalui Firebase Auth
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // Mendefinisikan referensi (jalur) ke koleksi 'categories' milik user tersebut di Firestore.
  // Strukturnya: users -> [UID] -> categories
  late final CollectionReference _categoryCollection =
      FirebaseFirestore.instance
          .collection('users') // Masuk ke koleksi users
          .doc(uid) // Masuk ke dokumen spesifik milik user yang login
          .collection('categories'); // Masuk ke sub-koleksi kategori milik user tersebut

  // Controller untuk menangani teks yang diketik di kolom pencarian
  final TextEditingController _searchController = TextEditingController();

  // Variabel-variabel State (Kondisi UI saat ini)
  String _searchQuery = ''; // Menyimpan kata kunci pencarian
  bool _isConfigureMode = false; // Status apakah tombol "Build/Edit" sedang aktif
  bool _isAddMode = false; // Status apakah proses tambah data (ADD) sedang berlangsung

  @override
  void dispose() {
    // Membersihkan controller dari memori saat layar ditutup untuk mencegah memory leak
    _searchController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  // FUNGSI BANTUAN (HELPERS)
  // ════════════════════════════════════════════════════════════════

  // Menampilkan notifikasi kecil di bawah layar (Snackbar)
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // Mengatur lebar dialog secara responsif berdasarkan lebar layar perangkat
  double _responsiveWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width; // Mengambil ukuran lebar layar
    if (width >= 430) {
      return width * 0.82; // Untuk layar besar, gunakan 82% lebar layar
    } else if (width >= 390) {
      return width * 0.84; // Untuk layar sedang, gunakan 84% lebar layar
    } else {
      return width * 0.88; // Untuk layar kecil, gunakan 88% lebar layar
    }
  }

  // ════════════════════════════════════════════════════════════════
  // POP-UP DIALOGS (MODALS)
  // ════════════════════════════════════════════════════════════════

  // Menampilkan dialog konfirmasi (Yes/No)
  Future<bool?> _showConfirmDialog({
    required String title, // Judul pertanyaan konfirmasi
    Color yesColor = const Color(0xFF42AAFF), // Warna default tombol YES (biru)
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User tidak bisa menutup dialog dengan menekan area luar
      barrierColor: Colors.black.withOpacity(0.35), // Warna latar belakang saat dialog muncul
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Membuat sudut dialog membulat
        ),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 34),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Tinggi dialog menyesuaikan isi kontennya
            children: [
              Text(
                title, // Menampilkan judul pertanyaan
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  // Tombol NO (Batal)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false), // Mengembalikan nilai false jika ditekan
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0), // Warna abu-abu
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
                  const SizedBox(width: 12),
                  // Tombol YES (Setuju)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true), // Mengembalikan nilai true jika ditekan
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: yesColor, // Warna menyesuaikan parameter (merah untuk delete, biru untuk hal lain)
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

  // Menampilkan dialog untuk menginput nama kategori (untuk Add atau Edit)
  Future<String?> _showNameInputDialog({
    String title = 'New Category',
    String initialValue = '', // Nilai awal teks (kosong untuk tambah, terisi nama lama untuk edit)
  }) async {
    final TextEditingController controller =
        TextEditingController(text: initialValue); // Memasukkan nilai awal ke dalam controller

    final String? name = await showDialog<String>(
      context: context,
      barrierDismissible: true, // User BISA menutup dengan klik di luar area
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        final dialogWidth = _responsiveWidth(ctx); // Memanggil fungsi bantuan untuk lebar responsif

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, // Judul dialog ("New Category" atau "Edit Category")
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),
                // Kolom Input (TextField)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: true, // Keyboard otomatis muncul
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Category name...', // Teks bayangan jika kosong
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 15),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 1.1),
                      ),
                      enabledBorder: OutlineInputBorder( // Desain border saat tidak fokus
                        borderRadius: BorderRadius.circular(22),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 1.1),
                      ),
                      focusedBorder: OutlineInputBorder( // Desain border saat diklik/fokus (Biru)
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                            color: Color(0xFF2196F3), width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    // Tombol CANCEL
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, null), // Kembalikan nilai null (batal)
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol NEXT (Lanjut)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final val = controller.text.trim(); // Hapus spasi di awal & akhir input
                          if (val.isEmpty) return; // Jika kosong, tombol tidak melakukan apa-apa
                          Navigator.pop(ctx, val); // Kembalikan teks yang diketik
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF42AAFF),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'NEXT',
                            style: TextStyle(
                              fontSize: 14,
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
        );
      },
    );

    controller.dispose(); // Hapus controller setelah pop-up tertutup
    return name; // Mengembalikan hasil input user (bisa string atau null)
  }

  // ════════════════════════════════════════════════════════════════
  // OPERASI CRUD FIREBASE (CREATE, UPDATE, DELETE)
  // ════════════════════════════════════════════════════════════════

  // [CREATE] Menambahkan kategori baru ke Firestore
  Future<void> _addCategory() async {
    setState(() => _isAddMode = true); // Ubah status tombol (+) menjadi aktif/tertekan

    try {
      // 1. Minta user memasukkan nama kategori
      final name = await _showNameInputDialog(title: 'New Category');
      if (name == null || name.isEmpty) return; // Batal jika input kosong

      // 2. Minta konfirmasi apakah yakin ingin membuat
      final bool? confirm =
          await _showConfirmDialog(title: 'Create this Category?');
      if (confirm != true) return; // Batal jika jawab NO

      // 3. Simpan data ke Firestore (menghasilkan ID otomatis)
      await _categoryCollection.add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(), // Gunakan waktu server Firestore
        'updatedAt': FieldValue.serverTimestamp(), // Gunakan waktu server Firestore
      });

      if (mounted) _showSnackbar('Category created successfully', Colors.green); // Berhasil
    } catch (e) {
      if (mounted) _showSnackbar('Failed to create category', Colors.red); // Gagal
    } finally {
      if (mounted) setState(() => _isAddMode = false); // Kembalikan status tombol (+) ke normal
    }
  }

  // [UPDATE] Mengubah nama kategori yang sudah ada
  Future<void> _editCategory(CategoryModel category) async {
    // 1. Tampilkan input dialog yang sudah diisi nama kategori yang ada
    final name = await _showNameInputDialog(
      title: 'Edit Category',
      initialValue: category.name,
    );

    if (name == null || name.isEmpty) return;

    // 2. Minta konfirmasi
    final bool? confirm = await _showConfirmDialog(title: 'Save changes?');
    if (confirm != true) return;

    try {
      // 3. Perbarui dokumen spesifik di Firestore berdasarkan ID kategori
      await _categoryCollection.doc(category.id).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(), // Update waktu pembaruan terakhir
      });

      if (mounted) _showSnackbar('Category updated successfully', Colors.green);
    } catch (e) {
      if (mounted) _showSnackbar('Failed to update category', Colors.red);
    }
  }

  // [DELETE] Menghapus kategori (dan sub-koleksi kontaknya)
  Future<void> _deleteCategory(CategoryModel category) async {
    // 1. Minta konfirmasi dengan tombol warna merah (bahaya)
    final bool? confirm = await _showConfirmDialog(
      title: 'Are you sure you want to delete?',
      yesColor: const Color(0xFFE53935), // Warna Merah
    );

    if (confirm != true) return;

    try {
      // PERHATIAN: Di Firestore, menghapus dokumen induk TIDAK otomatis menghapus sub-koleksinya.
      // Jadi, kita harus mengambil semua kontak di dalam kategori ini, lalu menghapusnya satu per satu.
      final contactsSnap = await _categoryCollection
          .doc(category.id)
          .collection('contacts')
          .get();

      // Loop untuk menghapus semua dokumen kontak di dalam kategori ini
      for (final doc in contactsSnap.docs) {
        await doc.reference.delete();
      }

      // Setelah isinya bersih, baru hapus dokumen kategorinya sendiri
      await _categoryCollection.doc(category.id).delete();

      if (mounted) _showSnackbar('Category deleted successfully', Colors.green);
    } catch (e) {
      if (mounted) _showSnackbar('Failed to delete category', Colors.red);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGET COMPONENTS (BAGIAN-BAGIAN UI)
  // ════════════════════════════════════════════════════════════════

  // Komponen pembuat tombol aksi (Configure & Add) dengan styling khusus
  Widget _buildActionButton({
    required Widget child, // Icon yang ada di dalam tombol
    required VoidCallback? onTap, // Fungsi yang dijalankan saat ditekan
    bool isActive = false,  // Jika true: tombol jadi biru (menandakan mode aktif)
    bool disabled = false,  // Jika true: tombol jadi abu-abu pucat dan tidak bisa ditekan
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap, // Matikan klik jika disabled
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFFF5F5F5)   // Background abu-abu jika dinonaktifkan
              : isActive
                  ? const Color(0xFFDDF1FF) // Background biru muda jika sedang aktif
                  : Colors.white, // Putih jika normal
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: disabled
                ? Colors.grey.shade400     // Border abu-abu jika dinonaktifkan
                : isActive
                    ? const Color(0xFF2196F3) // Border biru jika sedang aktif
                    : Colors.black, // Hitam jika normal
            width: 1.2,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }

  // Tampilan 1 baris item Kategori di dalam list
  Widget _buildCategoryItem(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        if (_isConfigureMode) {
          // Jika mode "Obeng" (Edit) sedang menyala, klik kategori akan memunculkan pop-up edit
          _editCategory(category);
        } else {
          // Jika mode normal, klik kategori akan pindah layar ke CategoryDetailScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryDetailScreen(
                category: category,
                onRequestTabChange: widget.onRequestTabChange,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), // Jarak antar kotak kategori
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25), // Sudut bulat
          border: Border.all(color: const Color(0xFF2196F3), width: 1.5), // Garis tepi biru
        ),
        child: Row(
          children: [
            // Jika dalam Configure Mode, tampilkan icon pensil kecil di sebelah kiri teks
            if (_isConfigureMode) ...[
              const Icon(Icons.edit_outlined, size: 20, color: Colors.black87),
              const SizedBox(width: 12),
            ],
            // Nama Kategori (Expanded agar memenuhi ruang sisa ke kanan)
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            // Bagian paling kanan kotak:
            if (_isConfigureMode)
              // Jika mode Edit: Tampilkan icon silang (X) merah untuk menghapus kategori
              GestureDetector(
                onTap: () => _deleteCategory(category),
                child: const Icon(Icons.close, color: Colors.red, size: 26),
              )
            else
              // Jika normal: Tampilkan icon panah ke kanan (menandakan bisa masuk ke dalam detail)
              const Icon(Icons.chevron_right,
                  color: Color(0xFF2196F3), size: 26),
          ],
        ),
      ),
    );
  }

  // Tampilan yang muncul jika belum ada kategori sama sekali
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No categories yet',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            'Add your first category to get started',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          // Tombol jalan pintas untuk langsung menambah kategori
          GestureDetector(
            onTap: _addCategory,
            child: const Text(
              'Add Categories',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  // Tampilan yang muncul jika hasil pencarian tidak ditemukan
  Widget _buildSearchNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'Category not found',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            'Try searching with another name',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD METHOD (RENDERING UI UTAMA)
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- BAGIAN ATAS (HEADER, TOMBOL AKSI, DAN SEARCH BAR) ---
        Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'My Categories', // Judul Halaman
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),
              // Barisan tombol aksi (Configure & Add)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // TOMBOL CONFIGURE (Icon Obeng)
                    // - Menyala biru jika _isConfigureMode adalah true
                    // - Mati (abu-abu) jika proses Add sedang berlangsung
                    _buildActionButton(
                      isActive: _isConfigureMode,
                      disabled: _isAddMode,
                      child: Icon(
                        Icons.build_outlined,
                        size: 24,
                        color: _isAddMode
                            ? Colors.grey
                            : _isConfigureMode
                                ? const Color(0xFF1976D2)
                                : Colors.black,
                      ),
                      onTap: () =>
                          setState(() => _isConfigureMode = !_isConfigureMode), // Mengubah status (toggle) on/off
                    ),
                    const Spacer(), // Memberi jarak agar tombol ada di kiri dan kanan layar
                    
                    // TOMBOL ADD (Icon +)
                    // - Menyala biru saat proses Add berjalan
                    // - Mati (abu-abu) saat Configure mode sedang menyala
                    _buildActionButton(
                      isActive: _isAddMode,
                      disabled: _isConfigureMode,
                      child: Icon(
                        Icons.add,
                        size: 24,
                        color: _isConfigureMode
                            ? Colors.grey
                            : _isAddMode
                                ? const Color(0xFF1976D2)
                                : Colors.black,
                      ),
                      onTap: _addCategory, // Memanggil fungsi tambah kategori
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // KOLOM PENCARIAN (Search Bar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.black, width: 1.2),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      // Setiap kali user mengetik, perbarui state pencarian (_searchQuery) dalam huruf kecil agar tidak case-sensitive
                      setState(() => _searchQuery = v.toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 16),
                      prefixIcon:
                          Icon(Icons.search, color: Colors.grey[700], size: 24),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Colors.black12), // Garis pemisah bawah header
              const SizedBox(height: 8),
            ],
          ),
        ),

        // --- BAGIAN BAWAH (LIST KATEGORI DARI FIREBASE) ---
        // Expanded agar ListView mengambil seluruh sisa tinggi layar ke bawah
        Expanded(
          // StreamBuilder sangat penting di sini! Ini yang membuat list kategori otomatis 
          // memperbarui dirinya sendiri (real-time) setiap kali ada data yang ditambah/diedit/dihapus di Firestore.
          child: StreamBuilder<QuerySnapshot>(
            stream: _categoryCollection
                .orderBy('createdAt', descending: true) // Mengurutkan list: yang paling baru dibuat ada di atas
                .snapshots(), // Membuka "keran air" koneksi real-time ke Firestore
            builder: (context, snapshot) {
              // Jika terjadi error saat memuat data dari Firebase
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // Jika data masih dalam proses diambil (loading)
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator()); // Tampilkan loading muter
              }

              // Jika koneksi berhasil tapi tidak ada dokumen satupun di dalam koleksi
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState(); // Tampilkan layar "No categories yet"
              }

              // Mapping (mengonversi) data mentah Firestore menjadi List of CategoryModel
              final categories = snapshot.data!.docs
                  .map((d) => CategoryModel.fromDocument(d))
                  .toList();

              // Menyaring (Filter) list kategori berdasarkan kata yang diketik di Search Bar
              final filtered = _searchQuery.isEmpty
                  ? categories // Jika tidak mencari apa-apa, tampilkan semua
                  : categories
                      .where((c) =>
                          c.name.toLowerCase().contains(_searchQuery)) // Cari yang mengandung kata kunci
                      .toList();

              // Jika user mencari sesuatu tapi tidak ada hasilnya di list yang terfilter
              if (filtered.isEmpty) {
                return _buildSearchNotFound();
              }

              // Membangun daftar tampilan kategori secara efisien (hanya merender yang terlihat di layar)
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: filtered.length, // Jumlah kotak yang dibuat sesuai dengan jumlah data yang tersaring
                itemBuilder: (_, i) => _buildCategoryItem(filtered[i]), // Mencetak setiap kotak kategori
              );
            },
          ),
        ),
      ],
    );
  }
}