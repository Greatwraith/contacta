// kontak_list_screen.dart

// ════════════════════════════════════════════════════════════════
// BAGIAN IMPORTS
// Mengimpor material design, database Firestore, sistem Auth,
// serta layar-layar dan model internal aplikasi Contacta.
// ════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'category_screen.dart';
import 'add_edit_kontak_screen.dart';
import 'kontak_model.dart';
import 'profile_screen.dart';

// ════════════════════════════════════════════════════════════════
// WIDGET UTAMA (STATEFUL)
// Halaman utama yang menampung daftar kontak, navigasi tab,
// dan melacak status apakah pop-up sukses login perlu muncul.
// ════════════════════════════════════════════════════════════════
class KontakListScreen extends StatefulWidget {
  final bool showSuccessPopup; // Menerima instruksi dari layar sebelumnya apakah harus menampilkan pop-up sukses login

  const KontakListScreen({
    super.key,
    this.showSuccessPopup = false, // Secara default bernilai false jika tidak dikirim dari layar login
  });

  @override
  State<KontakListScreen> createState() => _KontakListScreenState();
}

// ════════════════════════════════════════════════════════════════
// STATE DARI KONTAK LIST SCREEN
// Mengelola seluruh data kontak, pelacakan tab, pencarian,
// mode hapus, hingga pengelompokkan alfabetis.
// ════════════════════════════════════════════════════════════════
class _KontakListScreenState extends State<KontakListScreen> {
  // Mengambil ID unik User (UID) yang sedang login saat ini dari Firebase Authentication
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // Jalur referensi koleksi database Firestore khusus untuk menyimpan kontak user tersebut.
  // Struktur: users -> [UID User] -> kontak
  late final CollectionReference kontakCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('kontak');

  // Variabel Manajemen State & Kendali UI
  int _currentIndex = 0; // Melacak indeks tab bawah yang sedang aktif (0: Home/Kontak, 1: Category, 2: Profile)

  final TextEditingController _searchController = TextEditingController(); // Controller untuk mendeteksi input di kolom pencarian

  String _searchQuery = ''; // Menyimpan teks pencarian yang sudah diubah ke huruf kecil
  bool _isDeleteMode = false; // Status mode hapus (jika true, icon silang merah akan muncul di setiap kontak)
  bool _isAddMode = false; // Status pelacak ketika alur penambahan kontak baru sedang berjalan ke layar berikutnya
  int _categoryResetKey = 0; // Kunci angka penanda yang akan terus meningkat untuk memaksa widget CategoryScreen melakukan refresh total saat ditinggalkan

  @override
  void initState() {
    super.initState();

    // Memeriksa parameter jika diarahkan untuk memunculkan pop-up sukses
    if (widget.showSuccessPopup) {
      // Menunggu satu frame UI selesai dirender sepenuhnya sebelum menampilkan dialog agar tidak terjadi bentrokan konteks (context error)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog();
      });
    }
  }

  @override
  void dispose() {
    // Menghapus controller dari memori begitu layar ini dihancurkan untuk mencegah kebocoran memori (memory leak)
    _searchController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  // METODE DIALOG & NOTIFIKASI (POPUPS)
  // ════════════════════════════════════════════════════════════════

  // Menampilkan pop-up dialog transparan penanda berhasil login
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa menutup dialog secara tidak sengaja dengan mengklik area luar luar pop-up
      barrierColor: Colors.black.withOpacity(0.35), // Tingkat kegelapan latar belakang luar dialog
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Membuat latar dasar bawaan dialog menjadi transparan agar bentuk kustom di dalamnya terlihat rapi
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Mengatur tinggi kontainer dialog agar fleksibel mengikuti tinggi konten dalamnya
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 70,
                  color: Color(0xFF27AE60), // Icon centang hijau sukses
                ),
                const SizedBox(height: 20),
                const Text(
                  'Login Success!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome back to Contacta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 28),
                // Tombol Batal/Lanjut di dalam pop-up sukses login
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context), // Menutup dialog sukses saat ditekan
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27B9F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Menampilkan konfirmasi hapus kontak dan mengeksekusi penghapusan di Firestore
  Future<void> _deleteContact(Kontak kontak) async {
    // Menampilkan dialog konfirmasi YES/NO dan menangkap nilai balikan berupa boolean (true/false)
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Are you sure you want to remove?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    // Tombol batal hapus (NO)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false), // Mengirimkan nilai false saat ditutup
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEAEA),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          alignment: Alignment.center,
                          child: const Text('NO'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Tombol setuju hapus (YES)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true), // Mengirimkan nilai true saat ditutup
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF36A9F5),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          alignment: Alignment.center,
                          child: const Text('YES'),
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

    // Jika user mengonfirmasi klik YES, jalankan operasi hapus dokumen di database
    if (confirm == true) {
      try {
        // Menghapus dokumen spesifik berdasarkan id kontak dari subkoleksi Firestore
        await kontakCollection.doc(kontak.id).delete();

        // Jika widget masih terpasang aktif di screen tree, tampilkan snackbar hijau penanda sukses
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact removed successfully'),
              backgroundColor: Color.fromRGBO(76, 175, 80, 1), // Warna hijau sukses
            ),
          );
        }
      } catch (e) {
        debugPrint('_deleteContact error: $e'); // Mencetak galat di log debug konsol

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // FUNGSI ALUR NAVIGASI & ALGORITMA DATA
  // ════════════════════════════════════════════════════════════════

  // Mengelola status tombol tambah (+) selagi mengarahkan user ke layar tambah kontak
  Future<void> _addContact() async {
    setState(() => _isAddMode = true); // Mengubah status tombol tambah menjadi aktif/tertekan (biru)

    try {
      // Mengarahkan navigasi menuju halaman formulir tambah/edit kontak baru
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddEditKontakScreen(),
        ),
      );
    } finally {
      // Blok finally menjamin status _isAddMode dikembalikan ke normal (false) apa pun hasil operasinya (sukses/batal)
      if (mounted) setState(() => _isAddMode = false);
    }
  }

  // Algoritma pengelompokkan daftar kontak secara dinamis berdasarkan abjad huruf pertama nama kontak
  Map<String, List<Kontak>> _groupContactsByLetter(List<Kontak> contacts) {
    Map<String, List<Kontak>> grouped = {}; // Inisialisasi Map penampung kelompok huruf dan daftar kontaknya

    for (var kontak in contacts) {
      // Mengambil huruf pertama dari nama kontak dan mengubahnya menjadi kapital. Jika nama kosong, beri simbol '#'
      String firstLetter =
          kontak.name.isNotEmpty ? kontak.name[0].toUpperCase() : '#';

      // Jika key huruf abjad ini belum ada di dalam Map, daftarkan key baru tersebut dengan list kosong
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }

      // Memasukkan model objek kontak ke dalam kelompok list abjad yang sesuai
      grouped[firstLetter]!.add(kontak);
    }

    // Mengambil semua key huruf abjad yang terkumpul, lalu diurutkan secara alfabetis (A-Z)
    var sortedKeys = grouped.keys.toList()..sort();

    // Mengembalikan Map baru yang terstruktur rapi sesuai urutan abjad yang sudah disortir
    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGET COMPONENTS (KOMPONEN UI REUSABLE)
  // ════════════════════════════════════════════════════════════════

  // Komponen tombol aksi kapsul melingkar untuk memicu mode hapus atau tambah kontak
  Widget _buildActionButton({
    required IconData icon, // Parameter icon yang ingin dimuat di tengah tombol
    required VoidCallback? onTap, // Fungsi callback ketika tombol dieksekusi
    bool isActive = false,  // Indikator status tombol aktif (latar biru)
    bool disabled = false,  // Indikator status tombol terkunci (latar abu-abu dan memblokir tap)
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap, // Jika status disabled bernilai true, fungsi tap dimatikan total
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFFF5F5F5)    // Warna background abu-abu saat terkunci
              : isActive
                  ? const Color(0xFFDDF1FF) // Warna background biru muda saat aktif tertekan
                  : Colors.white, // Putih dalam kondisi normal
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: disabled
                ? Colors.grey.shade400     // Garis tepi abu-abu jika terkunci
                : isActive
                    ? const Color(0xFF2196F3) // Garis tepi biru jika aktif
                    : Colors.black, // Hitam normal
            width: 1.2,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 24,
            color: disabled
                ? Colors.grey // Warna icon abu-abu jika terkunci
                : isActive
                    ? const Color(0xFF1976D2) // Warna icon biru tua jika aktif
                    : Colors.black, // Hitam normal
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SUB-LAYAR (HOME, CATEGORY WRAPPER, STATES)
  // ════════════════════════════════════════════════════════════════

  // Tampilan halaman utama (Tab Kontak) yang berisi header, bilah pencarian, dan list data real-time
  Widget _buildHomeScreen() {
    return Column(
      children: [
        // --- BAGIAN HEADER ATAS & SEARCH BAR ---
        Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'My Contacts', // Judul utama tab Home
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),
              // Barisan tombol aksi hapus massal dan tambah kontak
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Tombol Aktivasi Mode Hapus (Icon Sampah)
                    // - Menyala biru muda ketika _isDeleteMode aktif
                    // - Terkunci (abu-abu) saat user sedang dalam alur menambah kontak baru
                    _buildActionButton(
                      icon: Icons.delete,
                      isActive: _isDeleteMode,
                      disabled: _isAddMode,
                      onTap: () =>
                          setState(() => _isDeleteMode = !_isDeleteMode), // Melakukan toggle status on/off mode hapus
                    ),
                    const Spacer(),
                    // Tombol Tambah Kontak (Icon Plus)
                    // - Menyala biru muda saat navigasi tambah berjalan
                    // - Terkunci (abu-abu) jika mode hapus sedang dinyalakan
                    _buildActionButton(
                      icon: Icons.add,
                      isActive: _isAddMode,
                      disabled: _isDeleteMode,
                      onTap: _addContact,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Kotak input pencarian nama kontak
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.black,
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase(); // Menyimpan setiap input ketikan dalam format huruf kecil agar pencarian fleksibel
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[700],
                        size: 24,
                      ),
                      border: InputBorder.none, // Menghilangkan border bawaan TextField agar kontainer luar yang menghiasinya
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),

        // --- BAGIAN AREA LIST REAL-TIME (FIRESTORE STREAM) ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Menghubungkan aliran data (stream) langsung ke Firestore, otomatis berurutan sesuai alfabet nama kontak
            stream: kontakCollection.orderBy('name').snapshots(),
            builder: (context, snapshot) {
              // Validasi jika koneksi atau kueri mengalami kegagalan/error
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // Menampilkan animasi loading melingkar saat data sedang dalam proses penjemputan dari server
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Validasi jika koleksi data belum ada dokumen atau kosong total
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // Mengonversi seluruh dokumen mentah BSON/JSON dari Firestore menjadi struktur objek model kumpulan kelas objek Kontak
              List<Kontak> allContacts = snapshot.data!.docs
                  .map((doc) => Kontak.fromDocument(doc))
                  .toList();

              // Menyaring list kontak berdasarkan data string kueri pencarian yang diketik user
              List<Kontak> filteredContacts = _searchQuery.isEmpty
                  ? allContacts // Tampilkan semua jika kolom search kosong
                  : allContacts
                      .where(
                          (k) => k.name.toLowerCase().contains(_searchQuery)) // Filter nama yang mengandung query kata kunci
                      .toList();

              // Validasi jika pencarian tidak membuahkan hasil kecocokan nama kontak
              if (filteredContacts.isEmpty) {
                return _buildSearchNotFound();
              }

              // Mengelompokkan list data hasil penyaringan akhir berdasarkan awalan huruf alfabetnya
              Map<String, List<Kontak>> groupedContacts =
                  _groupContactsByLetter(filteredContacts);

              // Merender list view vertikal untuk menampilkan data kelompok abjad dan item-item kontaknya
              return ListView.builder(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 0,
                  bottom: 20,
                ),
                itemCount: groupedContacts.length, // Menghitung total ada berapa kelompok huruf abjad yang aktif
                itemBuilder: (context, index) {
                  String letter = groupedContacts.keys.elementAt(index); // Mengambil nama huruf kunci (misal: 'A', 'B', 'M')
                  List<Kontak> contacts = groupedContacts[letter]!; // Mengambil daftar kontak yang masuk kelompok huruf tersebut

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label Header Huruf Kelompok Abjad (A, B, C, dst)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          top: 2,
                          bottom: 6,
                        ),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Melakukan teknik mapping penyebaran array (...) untuk mencetak deretan komponen item kontak di bawah huruf tersebut
                      ...contacts.map((kontak) => _buildContactItem(kontak)),

                      const SizedBox(height: 8),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Tampilan komponen satu baris item kontak di dalam daftar list
  Widget _buildContactItem(Kontak kontak) {
    return GestureDetector(
      onTap: () {
        // Jika mode hapus sedang aktif, mematikan fungsi klik masuk detail agar tidak sengaja berpindah layar
        if (_isDeleteMode) return;

        // Jika kondisi normal, klik pada kontak akan membuka layar pengeditan/detail dengan membawa data kontak terpilih
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditKontakScreen(kontak: kontak),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF2196F3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person,
              color: Color(0xFF2196F3),
              size: 24,
            ),
            const SizedBox(width: 14),
            // Menampilkan Nama Kontak dengan properti ellipsis agar teks otomatis terpotong titik-titik jika terlalu panjang
            Expanded(
              child: Text(
                kontak.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17),
              ),
            ),
            // Jika mode hapus (Delete Mode) menyala, sematkan icon silang (X) merah di ujung kanan baris item kontak
            if (_isDeleteMode)
              GestureDetector(
                onTap: () => _deleteContact(kontak), // Menjalankan fungsi pemicu konfirmasi hapus data
                child: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Tampilan placeholder saat database kontak kosong melompong
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No contacts yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first contact to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          // Link pintas teks untuk melompat langsung ke halaman pengisian kontak baru
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditKontakScreen(),
                ),
              );
            },
            child: const Text(
              'Add Contacts',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2196F3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tampilan placeholder saat hasil ketikan pencarian tidak ada yang cocok dengan data kontak apa pun
  Widget _buildSearchNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'Contact not found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Try searching with another name',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Membungkus layar `CategoryScreen` dan menyematkan ValueKey dinamis
  Widget _buildCategoryScreen() {
    return CategoryScreen(
      key: ValueKey(_categoryResetKey), // Dengan menempelkan key berbasis angka counter, widget dipaksa membuat ulang state-nya dari awal saat key-nya naik
      onRequestTabChange: (index) {
        // Menerima umpan balik perubahan tab jika ada aksi dari dalam CategoryScreen untuk memindahkan halaman utama
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // METODE BUILD UTAMA (STRUKTUR ROOT LAYAR)
  // Menerapkan Scaffold, susunan IndexedStack, dan BottomNavigationBar.
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        // IndexedStack sangat berguna untuk menumpuk halaman (Home, Category, Profile) 
        // tanpa menghancurkan state internal layar tersebut, sehingga ketika user berpindah tab, posisi scroll dan ketikan tetap terjaga.
        child: IndexedStack(
          index: _currentIndex, // Menampilkan anak widget sesuai indeks tab yang aktif saat ini
          children: [
            _buildHomeScreen(), // Indeks 0: Tampilan Daftar Kontak Utama
            _buildCategoryScreen(), // Indeks 1: Bungkus Layar Manajemen Kategori
            const ProfileScreen(), // Indeks 2: Layar Detail Profil Pengguna (Konstan)
          ],
        ),
      ),

      // Komponen Bilah Navigasi Bawah
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Memberikan efek bayangan halus di atas bilah menu navigasi
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex, // Sorot posisi item ikon menu yang aktif saat ini
          onTap: (index) {
            // Jika user menekan tombol tab yang memang sedang dia buka saat ini, hentikan proses (abaikan)
            if (index == _currentIndex) return;
            
            setState(() {
              // LOGIKA MEMBERSIHKAN STATUS JIKA MENINGGALKAN TAB KONTAK (HOME)
              if (_currentIndex == 0) {
                _isDeleteMode = false; // Mematikan status mode hapus secara otomatis agar bersih saat kembali nanti
                _isAddMode = false;
              }
              // LOGIKA ME-RESET REBUILD JIKA MENINGGALKAN TAB CATEGORY
              if (_currentIndex == 1) {
                _categoryResetKey++; // Menaikkan nilai angka key agar CategoryScreen dipaksa refresh total saat ditinggalkan
              }
              _currentIndex = index; // Mengalihkan indeks halaman aktif ke halaman baru yang baru saja diklik user
            });
          },
          type: BottomNavigationBarType.fixed, // Tipe bar tetap (tidak bergeser posisinya saat diklik)
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2196F3), // Warna ikon menu saat terpilih (Biru)
          unselectedItemColor: Colors.grey[600], // Warna ikon menu saat tidak aktif
          selectedFontSize: 13,
          unselectedFontSize: 13,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 26),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 26),
              label: 'Category',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}