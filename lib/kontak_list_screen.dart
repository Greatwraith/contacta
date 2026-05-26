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
  final bool showSuccessPopup; // Parameter bertipe boolean yang dikirim dari layar Login untuk memberi instruksi kepada layar ini agar menampilkan pop-up konfirmasi sukses login setelah frame pertama selesai dirender

  const KontakListScreen({
    super.key,
    this.showSuccessPopup = false, // Nilai default-nya adalah false, artinya jika layar ini dibuka tanpa mengirimkan parameter apapun, pop-up tidak akan pernah ditampilkan secara otomatis
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
  // Mengambil ID unik User (UID) yang sedang login saat ini dari Firebase Authentication.
  // UID ini bersifat unik per akun dan tidak akan pernah berubah selama akun tersebut hidup,
  // sehingga aman digunakan sebagai kunci utama (primary key) untuk memisahkan data antar pengguna di Firestore.
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // Jalur referensi koleksi database Firestore yang bersifat spesifik dan terisolasi hanya untuk menyimpan
  // data kontak milik user yang sedang login. Kata kunci 'late' digunakan karena nilai ini baru bisa
  // diinisialisasi setelah variabel 'uid' di atasnya sudah tersedia.
  // Struktur path hierarki Firestore-nya adalah: users -> [UID User] -> kontak
  late final CollectionReference kontakCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('kontak');

  // ─── Variabel Manajemen State & Kendali UI ───

  int _currentIndex = 0; // Nilai integer yang melacak tab navigasi bawah mana yang sedang aktif ditampilkan.
  // Nilai 0 = Tab Home (Daftar Kontak), nilai 1 = Tab Category, nilai 2 = Tab Profile.
  // Setiap kali nilai ini berubah lewat setState(), IndexedStack akan otomatis memperlihatkan child widget yang sesuai.

  final TextEditingController _searchController = TextEditingController(); // Controller yang terhubung ke widget TextField pencarian.
  // Bertanggung jawab membaca nilai teks yang diketik user secara real-time dan bisa digunakan pula untuk mengosongkan field secara programatik.

  String _searchQuery = ''; // Variabel penampung kata kunci pencarian yang sedang aktif diketik user, disimpan dalam format huruf kecil semua (lowercase).
  // Format huruf kecil digunakan agar algoritma filter bersifat case-insensitive (tidak membedakan huruf besar/kecil).

  bool _isDeleteMode = false; // Penanda status boolean apakah mode penghapusan massal sedang aktif atau tidak.
  // Jika bernilai true, setiap item kontak dalam daftar akan menampilkan tombol ikon silang (X) merah di sisi kanannya,
  // dan klik pada item kontak akan dinonaktifkan agar tidak membuka layar edit secara tidak sengaja.

  bool _isAddMode = false; // Penanda status boolean yang menjadi true tepat saat aplikasi sedang dalam proses menavigasi ke layar penambahan kontak baru.
  // Tujuannya adalah mengunci/menonaktifkan tombol Delete agar kedua aksi tidak bisa dijalankan bersamaan,
  // dan mengubah tampilan tombol Add menjadi biru aktif selama proses navigasi berlangsung.

  int _categoryResetKey = 0; // Sebuah counter integer sederhana yang digunakan sebagai ValueKey dinamis untuk widget CategoryScreen.
  // Setiap kali user meninggalkan tab Category, counter ini dinaikkan satu angka.
  // Perubahan nilai key memaksa Flutter untuk menghancurkan widget lama dan membangun ulang CategoryScreen dari awal (fresh state),
  // sehingga data dan tampilan di dalamnya selalu terasa segar dan tidak stale (basi).

  @override
  void initState() {
    super.initState();

    // Memeriksa nilai parameter 'showSuccessPopup' yang dikirim dari layar Login.
    // Jika bernilai true, itu berarti user baru saja berhasil login dan berhak mendapatkan umpan balik visual berupa pop-up sukses.
    if (widget.showSuccessPopup) {
      // Penundaan satu frame dengan addPostFrameCallback wajib dilakukan di sini.
      // Memanggil showDialog() langsung di dalam initState() berbahaya karena widget belum sepenuhnya terpasang di pohon widget (widget tree),
      // sehingga 'context' belum siap untuk digunakan dan akan melempar error. Callback ini memastikan dialog baru ditampilkan setelah build() pertama rampung.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog();
      });
    }
  }

  @override
  void dispose() {
    // Memanggil .dispose() pada TextEditingController adalah kewajiban untuk mencegah memory leak.
    // Jika controller tidak dibuang saat widget dihancurkan, listener internal di dalamnya akan terus hidup
    // di memori meskipun widget sudah tidak ada, yang lama-kelamaan bisa menyebabkan performa aplikasi menurun.
    _searchController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════
  // METODE DIALOG & NOTIFIKASI (POPUPS)
  // ════════════════════════════════════════════════════════════════

  // Menampilkan pop-up dialog transparan penanda berhasil login.
  // Method ini dipanggil otomatis dari initState() jika parameter showSuccessPopup bernilai true.
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Properti ini sengaja diset false agar user tidak bisa secara tidak sengaja menutup dialog hanya dengan mengetuk area gelap di luar kotak pop-up. User dipaksa menekan tombol CONTINUE.
      barrierColor: Colors.black.withOpacity(0.35), // Mengatur tingkat kegelapan (opacity) overlay hitam yang menutupi layar di belakang dialog. Nilai 0.35 dipilih agar latar belakang tetap sedikit terlihat namun fokus tetap terarah ke dialog.
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Membuat background bawaan komponen Dialog menjadi transparan total. Ini diperlukan agar Container kustom di dalamnya yang memiliki rounded corner terlihat rapi tanpa ada persegi panjang putih bawaan yang mengganggu di belakangnya.
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Sangat penting! Properti ini membuat Column hanya mengambil tinggi sebesar yang dibutuhkan oleh konten di dalamnya, bukan mengembang memenuhi seluruh tinggi layar seperti perilaku default-nya.
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 70,
                  color: Color(0xFF27AE60), // Ikon centang lingkaran berwarna hijau Material Design yang secara universal melambangkan keberhasilan atau konfirmasi positif.
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
                // ─── Tombol Aksi Utama di Pop-up Sukses Login ───
                SizedBox(
                  width: double.infinity, // Memaksa tombol memiliki lebar penuh sesuai lebar Container induknya, bukan hanya selebar teks labelnya.
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context), // Menutup dialog dari tumpukan navigasi (navigation stack) saat user menekan tombol ini. Tidak ada data apapun yang perlu dikembalikan sehingga cukup menggunakan pop() tanpa argumen tambahan.
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

  // Menampilkan dialog konfirmasi dua pilihan (YES/NO) sebelum menghapus kontak,
  // lalu mengeksekusi operasi penghapusan dokumen di Firestore jika user memilih YES.
  // Method ini bersifat async karena menunggu dua hal: pilihan user dari dialog, dan respons dari server Firestore.
  Future<void> _deleteContact(Kontak kontak) async {
    // showDialog dikonfigurasi dengan generic type <bool> agar nilai kembaliannya (return value)
    // bisa ditangkap langsung sebagai boolean. Nilai null bisa muncul jika dialog ditutup paksa tanpa memilih.
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Sama seperti dialog sukses, user tidak boleh menutup dialog ini sembarangan agar tidak terjadi penghapusan yang tidak disengaja atau sebaliknya, penghapusan yang gagal dikonfirmasi.
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
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    // ─── Tombol Batal / Tidak Jadi Hapus (NO) ───
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false), // Menutup dialog dan mengembalikan nilai boolean 'false' ke pemanggil (variabel 'confirm' di atas). Nilai false berarti user membatalkan niat untuk menghapus.
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEAEA),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
  'NO',
  style: TextStyle(
    color: Colors.black, // Mengubah warna tulisan menjadi putih
    fontWeight: FontWeight.bold, // Membuat tulisan menjadi tebal
    fontSize: 16, // Menambahkan ukuran font yang lebih besar untuk meningkatkan keterbacaan dan memberikan bobot visual yang setara dengan tombol YES di sebelahnya.
  ),
),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // ─── Tombol Setuju Hapus (YES) ───
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true), // Menutup dialog dan mengembalikan nilai boolean 'true' ke pemanggil (variabel 'confirm' di atas). Nilai true berarti user telah menyetujui penghapusan dan proses bisa dilanjutkan.
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF42AAFF),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
  'YES',
  style: TextStyle(
    color: Colors.white, // Mengubah warna tulisan menjadi putih
    fontWeight: FontWeight.bold, // Membuat tulisan menjadi tebal
    fontSize: 16, // Menambahkan ukuran font yang lebih besar untuk meningkatkan keterbacaan dan memberikan bobot visual yang setara dengan tombol YES di sebelahnya.
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

    // Blok kondisi ini berjalan HANYA jika user benar-benar mengklik tombol YES (nilai confirm == true).
    // Jika confirm adalah false (klik NO) atau null (dialog ditutup paksa), seluruh blok ini akan dilewati.
    if (confirm == true) {
      try {
        // Mengakses koleksi kontak Firestore, lalu menarget dokumen yang spesifik menggunakan ID unik kontak tersebut,
        // dan menjalankan perintah delete() untuk menghapus seluruh data dokumen itu dari server Firestore secara permanen.
        await kontakCollection.doc(kontak.id).delete();

        // Pemeriksaan 'mounted' adalah praktik wajib setelah operasi async di Flutter.
        // Ada kemungkinan user berpindah halaman atau menutup aplikasi saat perintah delete() masih berjalan di server.
        // Jika widget sudah tidak aktif di tree, memanggil ScaffoldMessenger akan melempar error.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact removed successfully'),
              backgroundColor: Color.fromRGBO(76, 175, 80, 1), // Warna hijau Material (Green 500) yang secara konsisten digunakan sebagai penanda operasi berhasil di seluruh aplikasi ini.
            ),
          );
        }
      } catch (e) {
        debugPrint('_deleteContact error: $e'); // Mencetak pesan galat secara detail ke konsol output selama sesi debugging. Fungsi debugPrint lebih aman dari print() karena otomatis memotong output yang terlalu panjang agar tidak membanjiri log konsol.

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'), // Menampilkan pesan error dari exception secara langsung kepada user agar mereka memahami penyebab kegagalan, seperti tidak ada koneksi internet atau izin Firestore yang ditolak.
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

  // Mengelola perubahan status visual tombol tambah (+) selagi mengarahkan user ke layar formulir tambah kontak baru.
  // Method ini bersifat async agar bisa menunggu (await) proses navigasi selesai sebelum mereset state kembali ke normal.
  Future<void> _addContact() async {
    setState(() => _isAddMode = true); // Mengubah state _isAddMode menjadi true tepat sebelum navigasi dimulai. Perubahan ini akan memicu rebuild UI yang membuat tampilan tombol Add berubah menjadi biru (aktif) dan tombol Delete menjadi abu-abu (terkunci).

    try {
      // Mendorong (push) layar AddEditKontakScreen ke atas tumpukan navigasi. Kata kunci 'await' di sini sangat penting:
      // eksekusi kode akan berhenti dan menunggu di baris ini sampai user kembali (pop) dari layar AddEditKontakScreen,
      // baik karena menekan tombol kembali, menekan tombol simpan, atau aksi apapun yang menutup layar tersebut.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddEditKontakScreen(),
        ),
      );
    } finally {
      // Blok 'finally' adalah garansi absolut bahwa kode di dalamnya SELALU akan dijalankan,
      // tidak peduli apakah blok 'try' di atasnya selesai dengan normal, atau melempar exception/error.
      // Ini memastikan status _isAddMode PASTI kembali ke false setelah navigasi selesai dalam kondisi apapun,
      // sehingga tombol-tombol UI tidak akan pernah terjebak dalam kondisi terkunci selamanya.
      if (mounted) setState(() => _isAddMode = false);
    }
  }

  // Algoritma yang bertanggung jawab mengelompokkan list kontak secara dinamis berdasarkan huruf pertama nama masing-masing kontak,
  // menghasilkan struktur data Map yang terurut secara alfabetis untuk kemudian dirender sebagai daftar berindeks abjad.
  Map<String, List<Kontak>> _groupContactsByLetter(List<Kontak> contacts) {
    Map<String, List<Kontak>> grouped = {}; // Inisialisasi Map kosong sebagai wadah hasil pengelompokan. Tipe data Map<String, List<Kontak>> berarti setiap 'kunci' (key) berupa huruf abjad (misal: 'A', 'B') memetakan ke sebuah 'nilai' (value) berupa list objek Kontak.

    for (var kontak in contacts) {
      // Mengambil karakter pertama (indeks 0) dari string nama kontak dan mengkonversinya ke huruf kapital menggunakan toUpperCase().
      // Operator ternary di sini menangani edge case: jika nama kontak ternyata berupa string kosong (''),
      // mengakses indeks [0] akan menyebabkan RangeError. Simbol '#' digunakan sebagai kelompok penampung khusus untuk kasus tersebut.
      String firstLetter =
          kontak.name.isNotEmpty ? kontak.name[0].toUpperCase() : '#';

      // Pengecekan apakah key huruf abjad ini sudah pernah dibuat sebelumnya di dalam Map.
      // Jika belum ada (belum pernah ada kontak dengan huruf awal ini), buat entry baru dengan value berupa list kosong terlebih dahulu.
      // Ini mencegah NullPointerException ketika mencoba langsung menambahkan kontak ke list yang belum ada.
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }

      // Setelah dipastikan key-nya ada dan list-nya siap, masukkan objek kontak ke dalam kelompok list abjad yang sesuai.
      // Tanda seru (!) setelah grouped[firstLetter] adalah null assertion operator, untuk memberi tahu Dart bahwa nilai di sini dijamin tidak null.
      grouped[firstLetter]!.add(kontak);
    }

    // Mengambil semua key (huruf-huruf abjad) yang berhasil terkumpul dari Map, mengubahnya menjadi List,
    // lalu mengurutkannya secara alfabetis menggunakan method sort() bawaan Dart.
    // Operator cascade (..) memungkinkan pemanggilan sort() langsung pada hasil toList() dalam satu baris yang ringkas.
    var sortedKeys = grouped.keys.toList()..sort();

    // Membangun dan mengembalikan Map baru yang terstruktur rapi dengan urutan yang sudah disortir A-Z.
    // Sintaks collection for ini sangat idiomatis di Dart: untuk setiap key yang sudah terurut,
    // ambil value-nya dari Map asal (grouped) dan masukkan ke Map baru yang akan dikembalikan.
    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGET COMPONENTS (KOMPONEN UI REUSABLE)
  // ════════════════════════════════════════════════════════════════

  // Komponen tombol kapsul melingkar yang dapat digunakan kembali (reusable) untuk memicu mode hapus maupun mode tambah kontak.
  // Dirancang dengan tiga kondisi visual yang berbeda: normal (putih), aktif (biru muda), dan terkunci/disabled (abu-abu).
  Widget _buildActionButton({
    required IconData icon, // Parameter wajib yang menentukan jenis ikon Material Design yang akan ditampilkan di tengah-tengah tombol kapsul ini.
    required VoidCallback? onTap, // Parameter wajib yang berisi fungsi callback yang akan dipanggil ketika tombol ditekan. Bertipe nullable (VoidCallback?) karena bisa diset null secara eksplisit untuk menonaktifkan respons tap.
    bool isActive = false,  // Parameter opsional untuk menandai tombol dalam keadaan 'ditekan/aktif'. Jika true, latar tombol berubah menjadi biru muda dan ikonnya menjadi biru tua sebagai umpan balik visual.
    bool disabled = false,  // Parameter opsional untuk mengunci tombol sepenuhnya. Jika true, fungsi onTap dimatikan (null), dan seluruh tampilan tombol berubah menjadi abu-abu untuk menandakan tombol tidak dapat diinteraksi.
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap, // Evaluasi kondisi: jika 'disabled' bernilai true, properti onTap diset ke null yang secara otomatis membuat GestureDetector mengabaikan semua sentuhan. Jika false, fungsi callback diteruskan normal.
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFFF5F5F5)    // Abu-abu sangat terang (#F5F5F5) digunakan sebagai latar tombol yang terkunci/nonaktif, memberikan kesan 'tidak bisa ditekan' secara visual.
              : isActive
                  ? const Color(0xFFDDF1FF) // Biru muda transparan (#DDF1FF) digunakan sebagai latar tombol yang sedang dalam kondisi aktif/ditekan, memberikan umpan balik visual yang jelas kepada user.
                  : Colors.white, // Putih bersih digunakan sebagai latar tombol dalam kondisi normal, siap untuk ditekan.
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: disabled
                ? Colors.grey.shade400     // Garis tepi abu-abu sedang menandakan tombol tidak aktif dan tidak bisa diinteraksi.
                : isActive
                    ? const Color(0xFF2196F3) // Garis tepi biru Material Design (Blue 500) untuk memperkuat kesan tombol yang sedang aktif.
                    : Colors.black, // Garis tepi hitam yang tegas untuk tampilan tombol dalam kondisi normal.
            width: 1.2,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 24,
            color: disabled
                ? Colors.grey // Ikon abu-abu tengah menandakan aksi yang terkait tidak tersedia saat ini, konsisten dengan latar dan garis tepinya.
                : isActive
                    ? const Color(0xFF1976D2) // Biru tua (Blue 700) untuk ikon saat tombol aktif, sedikit lebih gelap dari border biru agar ikon terbaca dengan jelas di atas latar biru muda.
                    : Colors.black, // Ikon hitam dalam kondisi normal, kontras tinggi terhadap latar putih.
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SUB-LAYAR (HOME, CATEGORY WRAPPER, STATES)
  // ════════════════════════════════════════════════════════════════

  // Membangun tampilan lengkap halaman utama (Tab Home) yang terdiri dari
  // header judul, baris tombol aksi, bilah pencarian, dan area list kontak real-time berbasis stream Firestore.
  Widget _buildHomeScreen() {
    return Column(
      children: [
        // ─── AREA HEADER ATAS & BILAH PENCARIAN ───
        Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'My Contacts', // Judul halaman utama yang selalu terlihat di bagian atas tab Home, berfungsi sebagai orientasi visual bagi user.
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 24),
              // Baris yang memuat dua tombol aksi utama (Delete dan Add) yang diposisikan berseberangan di ujung kiri dan kanan layar.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // ─── Tombol Aktivasi Mode Hapus Massal (Ikon Tempat Sampah) ───
                    // Berubah menjadi biru muda saat _isDeleteMode aktif sebagai indikator mode sedang berjalan.
                    // Berubah menjadi abu-abu dan terkunci saat _isAddMode aktif untuk mencegah konflik dua aksi sekaligus.
                    _buildActionButton(
                      icon: Icons.delete,
                      isActive: _isDeleteMode,
                      disabled: _isAddMode,
                      onTap: () =>
                          setState(() => _isDeleteMode = !_isDeleteMode), // Operator NOT (!) melakukan toggle: jika _isDeleteMode saat ini true maka jadi false, dan sebaliknya. setState() memastikan UI diperbarui seketika setelah nilai berubah.
                    ),
                    const Spacer(), // Widget Spacer mendorong tombol Delete sejauh mungkin ke kiri dan tombol Add sejauh mungkin ke kanan, menciptakan tata letak yang seimbang dan estetis.
                    // ─── Tombol Navigasi ke Layar Tambah Kontak Baru (Ikon Plus) ───
                    // Berubah menjadi biru muda saat _isAddMode aktif, menandakan navigasi sedang berlangsung.
                    // Berubah menjadi abu-abu dan terkunci saat _isDeleteMode aktif untuk mencegah konflik dua aksi bersamaan.
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
              // ─── Kotak Input Pencarian Nama Kontak ───
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
                        _searchQuery = value.toLowerCase(); // Setiap karakter yang diketik user langsung diubah ke huruf kecil sebelum disimpan ke _searchQuery. Ini memastikan perbandingan string yang dilakukan di algoritma filter nantinya tidak sensitif terhadap perbedaan huruf kapital/kecil (case-insensitive matching).
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
                      border: InputBorder.none, // Menghilangkan garis bawah dan border kotak bawaan dari TextField. Ini dilakukan karena dekorasi visual (rounded border hitam) sudah ditangani oleh Container pembungkusnya di luar, sehingga tidak perlu border ganda yang membingungkan.
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

        // ─── AREA DAFTAR KONTAK REAL-TIME (FIRESTORE STREAM) ───
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Stream dari Firestore ini berperilaku seperti saluran data hidup (live data channel).
            // Setiap kali ada penambahan, perubahan, atau penghapusan dokumen di koleksi 'kontak' milik user,
            // StreamBuilder secara otomatis menerima snapshot terbaru dan memicu rebuild UI tanpa perlu pull/refresh manual.
            // orderBy('name') memastikan data selalu datang dalam urutan abjad dari server, bukan diurutkan di sisi klien.
            stream: kontakCollection.orderBy('name').snapshots(),
            builder: (context, snapshot) {
              // Kondisi pertama yang perlu dicek adalah error. Ini bisa terjadi karena berbagai sebab:
              // aturan keamanan Firestore (Security Rules) yang memblokir akses, tidak ada koneksi internet,
              // atau query yang tidak valid. Menampilkan pesan error membantu debugging.
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // ConnectionState.waiting artinya request ke Firestore sudah dikirim dan aplikasi sedang menunggu
              // respons pertama dari server. Selama proses ini, spinner loading ditampilkan agar user mengetahui
              // aplikasi sedang bekerja, bukan hang atau freeze.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Dua kondisi ini dicek bersamaan: apakah snapshot sama sekali tidak punya data (hasData == false),
              // atau apakah list dokumennya ada tapi kosong (docs.isEmpty). Keduanya menghasilkan tampilan empty state yang sama.
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // Proses konversi: mengambil seluruh list dokumen mentah (QueryDocumentSnapshot) dari Firestore
              // dan mengubahnya satu per satu menjadi objek Kontak menggunakan factory constructor Kontak.fromDocument().
              // Hasilnya adalah list of strongly-typed Kontak objects yang jauh lebih mudah dan aman untuk dimanipulasi.
              List<Kontak> allContacts = snapshot.data!.docs
                  .map((doc) => Kontak.fromDocument(doc))
                  .toList();

              // Proses penyaringan (filtering) daftar kontak berdasarkan kata kunci pencarian.
              // Operator ternary: jika _searchQuery kosong (user belum mengetik apapun), tampilkan semua kontak tanpa filter.
              // Jika ada kata kunci, gunakan .where() untuk hanya menyertakan kontak yang namanya (dalam format lowercase) mengandung string _searchQuery.
              List<Kontak> filteredContacts = _searchQuery.isEmpty
                  ? allContacts
                  : allContacts
                      .where(
                          (k) => k.name.toLowerCase().contains(_searchQuery))
                      .toList();

              // Kondisi ini terjadi ketika user sudah mengetik sesuatu di kolom pencarian
              // namun tidak ada satu pun kontak yang namanya cocok dengan kata kunci tersebut.
              if (filteredContacts.isEmpty) {
                return _buildSearchNotFound();
              }

              // Melempar list kontak hasil filter ke dalam method algoritma pengelompokan abjad.
              // Hasilnya adalah Map terurut yang siap untuk dirender menjadi tampilan daftar berindeks huruf.
              Map<String, List<Kontak>> groupedContacts =
                  _groupContactsByLetter(filteredContacts);

              // ListView.builder digunakan (bukan ListView biasa) karena ia membangun item secara lazy (on-demand).
              // Hanya item yang terlihat di layar yang dirender, sehingga performa tetap optimal meskipun
              // ada ratusan kelompok huruf dan ribuan kontak sekalipun.
              return ListView.builder(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 0,
                  bottom: 20,
                ),
                itemCount: groupedContacts.length, // Jumlah total item di ListView sama dengan jumlah kelompok huruf abjad yang aktif (misal: jika hanya ada kontak berawalan A, B, M, dan Z, maka itemCount adalah 4).
                itemBuilder: (context, index) {
                  String letter = groupedContacts.keys.elementAt(index); // Mengambil huruf kunci pada posisi indeks tertentu dari Map yang sudah terurut. elementAt() diperlukan karena Map tidak bisa diakses langsung dengan indeks integer seperti List.
                  List<Kontak> contacts = groupedContacts[letter]!; // Mengambil seluruh daftar kontak yang tergabung dalam kelompok huruf tersebut untuk kemudian dirender satu per satu.

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Label Header Huruf Kelompok Abjad ───
                      // Teks besar ini (A, B, C, dst) berfungsi sebagai pemisah visual antar kelompok kontak,
                      // memudahkan user untuk secara cepat melompat ke bagian nama yang mereka cari.
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
                      // Spread operator (...) digunakan untuk 'meledakkan' (spread) hasil dari .map() berupa Iterable<Widget>
                      // menjadi elemen-elemen individual yang disisipkan langsung ke dalam List<Widget> milik Column.
                      // Ini menghindari kebutuhan untuk membungkus list kontak dengan Column atau ListView tambahan yang bersarang.
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

  // Membangun tampilan satu baris kartu item kontak individual yang akan ditampilkan di dalam daftar list.
  // Setiap kartu menampilkan ikon orang, nama kontak, dan secara kondisional menampilkan tombol hapus jika mode delete aktif.
  Widget _buildContactItem(Kontak kontak) {
    return GestureDetector(
      onTap: () {
        // Guard clause pertama: jika mode hapus sedang aktif, abaikan seluruh aksi tap pada kartu kontak ini.
        // Ini mencegah user secara tidak sengaja membuka layar edit kontak saat mereka sebenarnya sedang ingin menghapus kontak tersebut.
        if (_isDeleteMode) return;

        // Jika mode hapus tidak aktif, tap pada kartu kontak akan membuka layar AddEditKontakScreen
        // sambil membawa (pass) objek kontak yang dipilih sebagai argumen, sehingga layar tersebut tahu
        // bahwa ini adalah operasi EDIT (bukan tambah baru) dan bisa mengisi formulir dengan data yang sudah ada.
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
            // Widget Expanded memastikan teks nama kontak mendapatkan semua ruang horizontal yang tersisa di baris,
            // setelah ikon dan (jika ada) tombol hapus mendapatkan jatah ruangnya masing-masing.
            Expanded(
              child: Text(
                kontak.name,
                overflow: TextOverflow.ellipsis, // Jika nama kontak terlalu panjang dan melampaui lebar yang tersedia, teks akan otomatis dipotong dan diganti dengan titik-titik (...) di ujungnya alih-alih overflow (meluap keluar batas) atau memaksa baris baru.
                style: const TextStyle(fontSize: 17),
              ),
            ),
            // Penggunaan 'if' statement di dalam collection List Flutter ini sangat elegan:
            // widget ikon silang merah HANYA akan dimasukkan ke dalam Row jika kondisi _isDeleteMode bernilai true.
            // Jika false, widget ini tidak dirender sama sekali, berbeda dengan menggunakan Opacity atau Visibility yang tetap mengalokasikan ruang.
            if (_isDeleteMode)
              GestureDetector(
                onTap: () => _deleteContact(kontak), // Meneruskan seluruh objek kontak (termasuk ID-nya) ke method _deleteContact agar proses konfirmasi dialog dan penghapusan Firestore bisa menarget dokumen yang tepat.
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

  // Membangun tampilan layar kosong (empty state) yang informatif ketika user belum memiliki kontak sama sekali di database.
  // Dilengkapi dengan teks panduan dan tautan pintas untuk langsung mulai menambahkan kontak pertama.
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
          // Teks berwarna biru ini berfungsi sebagai tautan (hyperlink-style button) yang memberikan jalan pintas
          // langsung ke layar formulir tambah kontak baru tanpa user perlu kembali menekan tombol (+) di header.
          // Ini meningkatkan UX dengan mengurangi jumlah tap yang dibutuhkan untuk memulai.
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

  // Membangun tampilan layar "tidak ditemukan" yang informatif ketika kata kunci pencarian user
  // tidak menghasilkan kecocokan dengan nama kontak manapun yang ada di database.
  Widget _buildSearchNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 70,
            color: Colors.grey[400], // Ikon besar berwarna abu-abu pudar dipilih agar terasa 'kosong' dan 'tidak ada hasil', sesuai dengan makna visual yang ingin disampaikan kepada user.
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

  // Membungkus widget CategoryScreen di dalam sebuah method tersendiri sambil menyematkan ValueKey dinamis.
  // Teknik ini adalah cara standar di Flutter untuk mengontrol siklus hidup (lifecycle) sebuah widget dari luar.
  Widget _buildCategoryScreen() {
    return CategoryScreen(
      key: ValueKey(_categoryResetKey), // ValueKey yang berbasis nilai integer counter ini adalah kunci dari mekanisme reset. Flutter membandingkan key lama dan key baru pada setiap rebuild: jika key berubah (karena _categoryResetKey naik), Flutter mengetahui bahwa ini adalah widget yang 'berbeda' dan akan menghancurkan state lama lalu membangun ulang CategoryScreen dari nol dengan state yang bersih.
      onRequestTabChange: (index) {
        // Callback function ini bertindak sebagai 'jembatan komunikasi' dari child ke parent.
        // Jika ada aksi di dalam CategoryScreen yang membutuhkan perpindahan tab di halaman utama ini
        // (misalnya menekan tombol yang seharusnya kembali ke tab Home), CategoryScreen bisa memanggil
        // callback ini untuk meminta KontakListScreen memperbarui _currentIndex-nya.
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
        // IndexedStack adalah pilihan yang jauh lebih baik dibanding PageView atau Navigator bersarang
        // untuk multi-tab seperti ini. Alasannya: IndexedStack membangun semua child sekaligus di awal,
        // tetapi hanya menampilkan satu anak (sesuai 'index') pada satu waktu.
        // State internal masing-masing halaman (scroll position, data yang sudah diload, dll) TIDAK dihancurkan
        // saat user berpindah tab, berbeda dengan pendekatan lain yang merebuild widget dari awal setiap kali tab aktif berubah.
        child: IndexedStack(
          index: _currentIndex, // Properti ini menentukan child mana yang saat ini 'terlihat'. Saat _currentIndex berubah via setState(), IndexedStack secara instan mengganti child yang ditampilkan tanpa animasi dan tanpa kehilangan state.
          children: [
            _buildHomeScreen(), // Indeks 0: Widget daftar kontak utama beserta fitur pencarian dan mode hapusnya.
            _buildCategoryScreen(), // Indeks 1: Widget manajemen kategori yang dibungkus dengan ValueKey untuk mendukung mekanisme refresh otomatis.
            const ProfileScreen(), // Indeks 2: Widget profil pengguna bersifat const karena tidak menerima parameter dinamis dan tidak perlu direbuild.
          ],
        ),
      ),

      // ─── BILAH NAVIGASI BAWAH (BOTTOM NAVIGATION BAR) ───
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Bayangan sangat halus (opacity 5%) yang diproyeksikan ke atas bilah navigasi. Secara visual memisahkan area konten dan area navigasi tanpa menggunakan garis pembatas (divider) yang terasa kaku.
              blurRadius: 10,
              offset: const Offset(0, -2), // Offset negatif pada sumbu Y memproyeksikan bayangan ke arah atas (bukan ke bawah seperti biasanya), karena bilah navigasi berada di bagian bawah layar.
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex, // Mengirimkan nilai _currentIndex ke BottomNavigationBar agar ikon dan label menu yang sedang aktif ditampilkan dengan warna biru (selectedItemColor) dan font tebal (selectedLabelStyle).
          onTap: (index) {
            // Guard clause: jika user mengetuk item navigasi yang memang sedang aktif saat ini,
            // tidak ada yang perlu dilakukan. Menghentikan eksekusi di sini mencegah setState() dipanggil sia-sia
            // dan mencegah logika cleanup di bawah berjalan tanpa alasan.
            if (index == _currentIndex) return;
            
            setState(() {
              // ─── LOGIKA PEMBERSIHAN STATE SAAT MENINGGALKAN TAB HOME ───
              // Jika user sedang berada di tab 0 (Home) dan memilih pindah ke tab lain,
              // mode hapus dan mode tambah direset ke false agar tidak 'bocor' ke sesi berikutnya.
              // Bayangkan jika mode delete dibiarkan aktif saat user kembali ke tab Home, tentu membingungkan.
              if (_currentIndex == 0) {
                _isDeleteMode = false;
                _isAddMode = false;
              }
              // ─── LOGIKA RESET PAKSA SAAT MENINGGALKAN TAB CATEGORY ───
              // Setiap kali user meninggalkan tab Category (indeks 1), counter ini dinaikkan satu angka.
              // Kenaikan nilai counter yang terikat sebagai ValueKey di _buildCategoryScreen() akan
              // memaksa Flutter menganggap CategoryScreen sebagai widget baru yang perlu dibangun ulang dari awal,
              // secara efektif mereset semua state di dalamnya (filter yang dipilih, scroll position, dll).
              if (_currentIndex == 1) {
                _categoryResetKey++;
              }
              _currentIndex = index; // Memperbarui indeks tab aktif ke tab yang baru saja dipilih user. Perubahan ini akan memicu rebuild() yang membuat IndexedStack menampilkan child yang sesuai dan BottomNavigationBar menyorot item yang tepat.
            });
          },
          type: BottomNavigationBarType.fixed, // Tipe 'fixed' menjaga semua item navigasi tetap di posisinya yang statis dan tidak bergerak atau berubah ukuran saat salah satunya dipilih, berbeda dengan tipe 'shifting' yang memiliki animasi lebih dramatis.
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2196F3), // Warna biru Material Design (Blue 500) yang diaplikasikan pada ikon dan label menu yang sedang aktif, memberikan sinyal visual yang jelas kepada user tentang posisi mereka saat ini.
          unselectedItemColor: Colors.grey[600], // Warna abu-abu gelap untuk ikon dan label yang tidak aktif, masih cukup terlihat namun tidak mencolok sehingga perhatian tetap terarah ke item yang aktif.
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