// add_edit_kontak_screen.dart

//_______________________
// IMPORT DEPENDENCIES
//_______________________

import 'package:cloud_firestore/cloud_firestore.dart'; // Mengimpor package Cloud Firestore dari Firebase, digunakan untuk semua operasi database NoSQL seperti menyimpan data baru (add), membaca data (get/stream), memperbarui data (update), dan menghapus data (delete) secara real-time dari server Firebase
import 'package:firebase_auth/firebase_auth.dart'; // Mengimpor package Firebase Authentication, digunakan untuk mengelola autentikasi pengguna — khususnya di sini untuk mendapatkan UID (User ID unik) dari akun pengguna yang sedang aktif/login, agar data kontak tersimpan secara terpisah per pengguna
import 'package:flutter/material.dart'; // Mengimpor seluruh library Material Design dari Flutter, yang menyediakan ratusan widget siap pakai seperti Scaffold (kerangka halaman), AppBar (bilah atas), TextFormField (kolom input teks), Column, Row, Container, Icon, Text, GestureDetector, dan lain-lain

import 'kontak_model.dart'; // Mengimpor file model data Kontak yang berisi class Kontak — sebuah blueprint/struktur yang mendefinisikan properti data kontak (id, name, phone, email, notes) beserta method untuk konversi dari/ke Firestore document

//_______________________
// CLASS STATEFULWIDGET UTAMA
//_______________________

class AddEditKontakScreen extends StatefulWidget { // Mendefinisikan class layar Add/Edit Kontak sebagai StatefulWidget, artinya layar ini mampu menyimpan dan merespons perubahan data internal (state) yang memengaruhi tampilan UI secara dinamis
  final Kontak? kontak; // Deklarasi properti 'kontak' bertipe Kontak yang bersifat nullable (ditandai dengan '?'), artinya boleh berisi null. Digunakan sebagai parameter masukan: jika null berarti layar dibuka dalam mode TAMBAH KONTAK BARU, jika berisi data Kontak berarti layar dibuka dalam mode LIHAT DETAIL atau EDIT kontak yang sudah ada

  const AddEditKontakScreen({super.key, this.kontak}); // Constructor class ini menerima dua parameter: 'super.key' yang diwariskan dari parent class Widget (digunakan Flutter secara internal untuk identifikasi dan optimisasi widget tree), dan 'this.kontak' yang bersifat opsional (boleh tidak diisi, default null) untuk membawa data kontak dari layar sebelumnya

  @override
  State<AddEditKontakScreen> createState() => _AddEditKontakScreenState(); // Meng-override method createState() yang wajib ada di setiap StatefulWidget. Method ini bertanggung jawab membuat dan mengembalikan instance dari class State pasangannya (_AddEditKontakScreenState), tempat semua logika bisnis dan variabel state sesungguhnya disimpan dan dikelola
}

//_______________________
// CLASS STATE — LOGIKA & VARIABEL UTAMA
//_______________________

class _AddEditKontakScreenState extends State<AddEditKontakScreen> { // Mendefinisikan class State yang berpasangan dengan AddEditKontakScreen. Class ini mewarisi State<AddEditKontakScreen> sehingga memiliki akses ke properti 'widget' untuk membaca data dari parent widget (seperti widget.kontak). Semua variabel, controller, dan method logika disimpan di sini

  //_______________________
  // FORM KEY & TEXT CONTROLLERS
  //_______________________

  final _formKey = GlobalKey<FormState>(); // Membuat sebuah GlobalKey bertipe FormState yang berfungsi sebagai pegangan/handle terhadap widget Form di dalam build(). Digunakan untuk memicu validasi semua field secara bersamaan melalui '_formKey.currentState!.validate()', serta untuk mereset field jika diperlukan

  late TextEditingController _nameController; // Deklarasi controller untuk mengelola teks pada field 'Nama Lengkap'. Kata 'late' berarti variabel ini tidak diinisialisasi saat deklarasi, melainkan akan diinisialisasi di dalam method initState() setelah widget selesai dikonfigurasi dan data kontak (jika ada) sudah tersedia
  late TextEditingController _phoneController; // Deklarasi controller untuk mengelola teks pada field 'Nomor Telepon'. Sama seperti _nameController, diinisialisasi di initState() dengan nilai awal dari data kontak yang ada, atau string kosong jika tambah baru
  late TextEditingController _emailController; // Deklarasi controller untuk mengelola teks pada field 'Email'. Bertanggung jawab membaca, menulis, dan memantau perubahan teks di field email secara programatik
  late TextEditingController _notesController; // Deklarasi controller untuk mengelola teks pada field 'Catatan/Notes'. Field ini bersifat multiline (bisa lebih dari satu baris), sehingga controllernya mengelola teks yang lebih panjang

  //_______________________
  // REFERENSI FIRESTORE & AUTENTIKASI
  //_______________________

  late final CollectionReference kontakCollection = FirebaseFirestore.instance // Membuat referensi langsung ke sub-koleksi 'kontak' milik pengguna yang sedang login di Firestore. Referensi ini bersifat 'late final' artinya hanya diinisialisasi sekali dan tidak bisa diubah setelahnya. Digunakan berulang kali dalam operasi CRUD (Create, Read, Update, Delete) tanpa perlu menulis ulang path yang panjang
      .collection('users') // Mengarahkan path ke koleksi tingkat pertama bernama 'users' di dalam database Firestore — koleksi ini menyimpan dokumen untuk setiap pengguna terdaftar
      .doc(FirebaseAuth.instance.currentUser!.uid) // Mengarahkan path ke dokumen spesifik di dalam koleksi 'users' yang ID-nya sama dengan UID pengguna yang sedang login. Tanda '!' berarti kita yakin pengguna sudah login (tidak null) karena layar ini hanya bisa diakses setelah autentikasi berhasil
      .collection('kontak'); // Mengarahkan path ke sub-koleksi 'kontak' yang berada di dalam dokumen pengguna tersebut — inilah koleksi yang menyimpan semua data kontak milik pengguna

  final uid = FirebaseAuth.instance.currentUser!.uid; // Mengambil UID (User ID unik berbentuk string) dari pengguna yang sedang aktif login melalui Firebase Authentication, lalu menyimpannya ke variabel 'uid'. Disimpan terpisah agar tidak perlu memanggil 'FirebaseAuth.instance.currentUser!.uid' berulang kali di dalam method seperti _loadAssignedCategories()

  //_______________________
  // VARIABEL STATE
  //_______________________

  bool isEditing = false; // Variabel boolean yang menentukan apakah layar saat ini berada dalam mode EDIT (true) atau mode LIHAT DETAIL (false). Nilainya di-toggle oleh tombol Edit di AppBar dan dikembalikan ke false oleh tombol Close saat dalam mode edit kontak yang sudah ada. Nilai ini memengaruhi apakah field input bisa diedit atau hanya bisa dibaca (readOnly)
  bool _isLoading = false; // Variabel boolean yang menandakan apakah sedang ada proses asinkron berjalan di latar belakang (seperti menyimpan data ke Firestore). Saat true, tombol-tombol aksi dinonaktifkan dan ikon centang diganti dengan CircularProgressIndicator, mencegah pengguna melakukan double-submit

  //_______________________
  // GETTER — MODE LAYAR
  //_______________________

  bool get isDetailMode => widget.kontak != null && !isEditing; // Getter (properti kalkulasi) yang mengembalikan nilai true hanya jika DUA kondisi terpenuhi secara bersamaan: (1) ada data kontak yang dikirim dari layar sebelumnya (widget.kontak != null), DAN (2) mode edit sedang tidak aktif (!isEditing). Getter ini digunakan di berbagai tempat di build() untuk menentukan apa yang ditampilkan (nama besar vs field input nama, tombol Edit vs tombol Simpan, dll)

  //_______________________
  // VARIABEL KATEGORI
  //_______________________

  List<String> assignedCategories = []; // List (daftar) berisi nama-nama kategori yang telah ditetapkan/di-assign ke kontak yang sedang dibuka. Awalnya kosong, kemudian diisi oleh method _loadAssignedCategories() yang dipanggil di initState() jika ada data kontak. Digunakan untuk menampilkan chip-chip kategori di bagian bawah form

  //_______________________
  // INISIALISASI — initState()
  //_______________________

  @override
  void initState() { // Method lifecycle Flutter yang dipanggil SATU KALI secara otomatis tepat setelah widget pertama kali dimasukkan ke dalam widget tree, sebelum build() pertama kali dieksekusi. Tempat yang tepat untuk melakukan inisialisasi awal seperti membuat controller, mengatur nilai default, dan memulai operasi async pertama
    super.initState(); // Wajib dipanggil sebagai baris pertama di initState() untuk memastikan inisialisasi dari class parent (State<AddEditKontakScreen>) berjalan dengan benar sebelum kode kita dieksekusi

    _nameController = TextEditingController(text: widget.kontak?.name ?? ''); // Menginisialisasi controller nama dengan teks awal. Menggunakan operator null-aware '?.' untuk mengakses properti 'name' dari widget.kontak hanya jika tidak null. Operator '??' (null coalescing) memastikan jika widget.kontak null (mode tambah baru), nilai awalnya adalah string kosong '' bukan null
    _phoneController = TextEditingController(text: widget.kontak?.phone ?? ''); // Menginisialisasi controller telepon dengan teks awal dari data kontak yang ada. Pola yang sama: jika kontak ada ambil nomornya, jika tidak ada mulai dengan field kosong agar user bisa langsung mengetik
    _emailController = TextEditingController(text: widget.kontak?.email ?? ''); // Menginisialisasi controller email dengan teks awal dari data kontak yang ada. Jika mode tambah baru (kontak null), field email dimulai kosong
    _notesController = TextEditingController(text: widget.kontak?.notes ?? ''); // Menginisialisasi controller notes/catatan dengan teks awal dari data kontak. Field notes bisa berisi teks panjang multiline, yang juga diisi dari data Firestore jika ada

    isEditing = widget.kontak == null; // Menentukan nilai awal isEditing berdasarkan ada tidaknya data kontak: jika widget.kontak == null berarti mode TAMBAH BARU maka isEditing = true (langsung bisa mengedit), jika widget.kontak != null berarti mode DETAIL/EDIT maka isEditing = false (mulai dengan mode lihat dulu)

    if (widget.kontak != null) { // Pemeriksaan kondisi: apakah ada data kontak yang dikirimkan ke layar ini? Jika iya, berarti kita sedang membuka kontak yang sudah ada (mode detail atau edit), sehingga perlu memuat data kategori yang terkait
      _loadAssignedCategories(); // Memanggil method asinkron untuk mengambil data kategori yang sudah di-assign ke kontak ini dari Firestore. Method ini berjalan di background dan akan memperbarui UI melalui setState() saat selesai
    }
  }

  //_______________________
  // LOAD KATEGORI YANG DI-ASSIGN
  //_______________________

  Future<void> _loadAssignedCategories() async { // Method asinkron yang bertugas mengambil data dari Firestore untuk menemukan kategori-kategori mana saja yang sudah mengandung kontak ini. Mengembalikan Future<void> karena tidak perlu mengembalikan nilai secara langsung — hasilnya dimasukkan ke state melalui setState()
    try { // Membuka blok try-catch untuk menangani kemungkinan error yang terjadi selama operasi Firestore berlangsung, seperti tidak ada koneksi internet, aturan keamanan Firestore menolak akses, atau timeout
      final categoriesSnapshot = await FirebaseFirestore.instance // Memulai query ke Firestore untuk mengambil semua dokumen kategori milik pengguna. Kata kunci 'await' memastikan eksekusi kode menunggu hingga data berhasil diambil dari server sebelum melanjutkan ke baris berikutnya
          .collection('users') // Mengarah ke koleksi root 'users' di database Firestore
          .doc(uid) // Mengarah ke dokumen pengguna yang sedang login menggunakan UID yang sudah disimpan
          .collection('categories') // Mengarah ke sub-koleksi 'categories' milik pengguna — berisi semua kategori yang pernah dibuat pengguna (misal: Keluarga, Teman, Kerja, dll)
          .get(); // Mengeksekusi query dan mengambil semua dokumen sekaligus dalam bentuk QuerySnapshot, bukan stream real-time

      List<String> temp = []; // Membuat list sementara bertipe String untuk mengumpulkan nama-nama kategori yang terbukti mengandung kontak ini, sebelum di-set ke state assignedCategories

      for (final categoryDoc in categoriesSnapshot.docs) { // Melakukan iterasi (perulangan) untuk setiap dokumen kategori yang ditemukan di dalam QuerySnapshot. Setiap iterasi memeriksa satu kategori apakah kontak ini termasuk di dalamnya
        final contactDoc = await FirebaseFirestore.instance // Melakukan query tambahan untuk setiap kategori: mengecek apakah ada dokumen kontak dengan ID yang sama di dalam sub-koleksi 'contacts' dari kategori tersebut. Ini adalah pendekatan denormalisasi di Firestore
            .collection('users') // Mengarah ke koleksi 'users' di database
            .doc(uid) // Mengarah ke dokumen pengguna yang sedang login
            .collection('categories') // Mengarah ke koleksi 'categories' milik pengguna
            .doc(categoryDoc.id) // Mengarah ke dokumen kategori yang sedang diiterasi sekarang menggunakan ID dokumen kategori tersebut
            .collection('contacts') // Mengarah ke sub-koleksi 'contacts' di dalam dokumen kategori ini — berisi referensi kontak yang masuk ke kategori ini
            .doc(widget.kontak!.id) // Mengarah ke dokumen dengan ID yang sama dengan ID kontak yang sedang dibuka. Tanda '!' aman digunakan karena method ini hanya dipanggil saat widget.kontak tidak null (sudah dicek di initState)
            .get(); // Mengeksekusi query get() untuk satu dokumen spesifik. Hasilnya adalah DocumentSnapshot yang bisa dicek dengan .exists

        if (contactDoc.exists) { // Memeriksa apakah dokumen kontak BENAR-BENAR ADA di dalam sub-koleksi 'contacts' dari kategori ini. Jika .exists bernilai true, berarti kontak ini memang sudah di-assign ke kategori tersebut
          final categoryName = categoryDoc.data()['name']; // Mengambil nilai field 'name' dari data dokumen kategori (categoryDoc). Method data() mengembalikan Map<String, dynamic>, lalu kita akses key 'name' untuk mendapat nama kategori sebagai String

          if (categoryName != null) { // Melakukan pengecekan null safety sebelum menambahkan ke list, untuk menghindari crash jika karena alasan tertentu field 'name' tidak ada atau bernilai null di dokumen Firestore
            temp.add(categoryName); // Menambahkan nama kategori yang valid ke list sementara 'temp'. Setelah semua kategori selesai diiterasi, list ini akan dimasukkan ke state
          }
        }
      }

      if (mounted) { // Memeriksa apakah widget masih terpasang di widget tree pada saat ini. Pengecekan ini penting karena operasi Firestore di atas bersifat asinkron — ada kemungkinan user sudah menutup layar sebelum data selesai diambil. Memanggil setState() pada widget yang sudah di-dispose akan menyebabkan error
        setState(() { // Memanggil setState() untuk memberitahu Flutter bahwa ada perubahan data yang perlu direspons dengan mem-rebuild UI (memanggil ulang method build())
          assignedCategories = temp; // Memindahkan isi list sementara 'temp' ke variabel state 'assignedCategories'. Setelah ini, UI akan diperbarui dan chip-chip kategori akan muncul di layar
        });
      }
    } catch (e) { // Blok catch yang menangkap semua jenis exception/error yang terjadi selama eksekusi blok try di atas, seperti FirebaseException, SocketException (tidak ada internet), dll
      debugPrint('_loadAssignedCategories error: $e'); // Mencetak detail pesan error ke konsol Flutter (hanya terlihat saat mode debug/development). Dalam produksi, sebaiknya error ini juga dilaporkan ke layanan monitoring seperti Firebase Crashlytics
    }
  }

  //_______________________
  // LIFECYCLE — dispose()
  //_______________________

  @override
  void dispose() { // Method lifecycle Flutter yang dipanggil secara otomatis sesaat sebelum State object dihapus permanen dari memori (ketika widget dikeluarkan dari widget tree). Wajib digunakan untuk membersihkan resource yang dibuat secara manual agar tidak terjadi memory leak
    _nameController.dispose(); // Melepaskan resource yang dialokasikan oleh TextEditingController nama dari memori. Setiap controller yang dibuat dengan 'TextEditingController()' HARUS di-dispose secara manual untuk mencegah kebocoran memori (memory leak) karena Flutter tidak membersihkannya secara otomatis
    _phoneController.dispose(); // Melepaskan resource controller telepon dari memori. Jika tidak di-dispose, controller akan terus menempati memori meskipun layar sudah ditutup
    _emailController.dispose(); // Melepaskan resource controller email dari memori. Best practice: setiap controller yang dibuat di initState() harus di-dispose di sini
    _notesController.dispose(); // Melepaskan resource controller notes dari memori. Ini adalah controller terakhir yang perlu dibersihkan
    super.dispose(); // Wajib dipanggil sebagai baris TERAKHIR di dispose() untuk menjalankan proses pembersihan dari class parent (State), memastikan semua resource internal Flutter juga dibebaskan dengan benar
  }

  //_______________________
  // HELPER — SNACKBAR
  //_______________________

  void _showSnackbar(String message, Color color) { // Method helper (pembantu) yang dibuat untuk menampilkan notifikasi singkat (SnackBar) di bagian bawah layar kepada pengguna. Menerima dua parameter: 'message' untuk isi pesan teks, dan 'color' untuk warna background SnackBar (merah untuk error, hijau untuk sukses)
    ScaffoldMessenger.of(context).showSnackBar( // ScaffoldMessenger adalah widget yang bertanggung jawab mengelola dan menampilkan SnackBar. Method 'of(context)' mencari ScaffoldMessenger terdekat di atas widget tree. Kemudian memanggil showSnackBar() untuk menampilkan notifikasi
      SnackBar(content: Text(message), backgroundColor: color), // Membuat objek SnackBar dengan dua properti: 'content' berisi widget Text yang menampilkan pesan, dan 'backgroundColor' untuk mewarnai background sesuai konteks (merah = gagal, hijau = berhasil)
    );
  }

  //_______________________
  // PENGECEKAN PERUBAHAN BELUM TERSIMPAN
  //_______________________

  bool _hasUnsavedChanges() { // Method yang bertugas mendeteksi apakah pengguna telah membuat perubahan apa pun pada form yang BELUM disimpan ke Firestore. Dipanggil oleh _handleClose() untuk memutuskan apakah perlu menampilkan dialog konfirmasi 'Discard changes?' atau tidak
    if (widget.kontak == null) { // Memeriksa apakah layar ini dibuka dalam mode TAMBAH BARU (tidak ada data kontak sebelumnya). Dalam mode ini, 'perubahan' berarti pengguna sudah mengetik sesuatu di field manapun
      return _nameController.text.trim().isNotEmpty || // Mengembalikan true (ada perubahan) jika field nama tidak kosong setelah menghapus spasi di awal/akhir dengan trim(). Menggunakan operator '||' (OR) sehingga cukup satu field yang berisi teks untuk dianggap 'ada perubahan'
          _phoneController.text.trim().isNotEmpty || // Mengembalikan true jika field telepon tidak kosong — pengguna sudah mengetik nomor telepon
          _emailController.text.trim().isNotEmpty || // Mengembalikan true jika field email tidak kosong — pengguna sudah mengetik alamat email
          _notesController.text.trim().isNotEmpty; // Mengembalikan true jika field notes tidak kosong — pengguna sudah mengetik catatan. Ini adalah kondisi terakhir dalam OR chain
    }

    return _nameController.text != widget.kontak!.name || // Untuk mode EDIT (ada data kontak sebelumnya): mengembalikan true jika teks di controller nama BERBEDA dari nama asli yang tersimpan di objek kontak. Perbandingan langsung string tanpa trim() agar spasi yang sengaja ditambah/dihapus juga terdeteksi sebagai perubahan
        _phoneController.text != widget.kontak!.phone || // Mengembalikan true jika nomor telepon di controller berbeda dari nomor asli — ada perubahan pada field telepon
        _emailController.text != widget.kontak!.email || // Mengembalikan true jika email di controller berbeda dari email asli — ada perubahan pada field email
        _notesController.text != widget.kontak!.notes; // Mengembalikan true jika catatan di controller berbeda dari catatan asli — ada perubahan pada field notes. Ini adalah kondisi terakhir
  }

  //_______________________
  // DIALOG KONFIRMASI
  //_______________________

  Future<bool?> _showConfirmDialog(String title) { // Method yang menampilkan dialog popup konfirmasi kepada pengguna dan menunggu respons mereka. Mengembalikan Future<bool?> karena: true = pengguna menekan YES, false = pengguna menekan NO, null = pengguna menutup dialog dengan cara lain (misal tap di luar dialog)
    return showDialog<bool>( // Flutter's built-in showDialog() yang menampilkan dialog di atas layar saat ini. Tipe generik <bool> menentukan tipe data yang dikembalikan oleh Navigator.pop() di dalam dialog
      context: context, // Memberikan BuildContext agar showDialog() tahu posisi dalam widget tree untuk menampilkan dialog dengan tepat di atas konten yang benar
      builder: (context) { // Builder function (callback) yang dipanggil untuk membangun tampilan visual dialog. Menerima context baru khusus untuk dialog ini
        return Dialog( // Widget Dialog dari Flutter yang otomatis menambahkan overlay gelap di belakang dan menampilkan konten di tengah layar
          shape: RoundedRectangleBorder( // Mengatur bentuk keseluruhan dialog menggunakan RoundedRectangleBorder untuk mendapatkan sudut-sudut yang membulat
            borderRadius: BorderRadius.circular(28), // Mengatur radius sudut sebesar 28 pixel pada semua pojok dialog, memberikan tampilan modern dan ramah pengguna (tidak kotak tajam)
          ),
          backgroundColor: Colors.white, // Mengatur warna background dialog menjadi putih bersih agar konten (judul dan tombol) mudah dibaca dan terlihat jelas
          child: Padding( // Menambahkan jarak/ruang kosong (padding) di sisi dalam dialog antara tepi dialog dan kontennya
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24), // Padding asimetris: kiri=24, atas=28 (lebih besar untuk memberi ruang napas di atas judul), kanan=24, bawah=24
            child: Column( // Menyusun semua elemen di dalam dialog (judul dan baris tombol) secara vertikal dari atas ke bawah
              mainAxisSize: MainAxisSize.min, // Mengatur Column agar ukurannya hanya sebesar konten yang ada di dalamnya (tidak mengembang memenuhi seluruh tinggi dialog/layar)
              children: [
                Text( // Widget Text untuk menampilkan judul pertanyaan konfirmasi di bagian atas dialog
                  title, // Mengisi teks dengan nilai parameter 'title' yang dikirim saat method _showConfirmDialog() dipanggil (misal: 'Discard changes?' atau 'Add this Contact?')
                  textAlign: TextAlign.center, // Menyelaraskan teks judul ke tengah secara horizontal agar terlihat terpusat dan profesional
                  style: const TextStyle( // Mendefinisikan gaya visual teks judul dialog
                    fontSize: 20, // Ukuran teks judul 20 sp (scale-independent pixels) — cukup besar agar mudah dibaca
                    fontWeight: FontWeight.bold, // Ketebalan font bold untuk menegaskan bahwa ini adalah pertanyaan penting yang butuh perhatian
                    color: Colors.black, // Warna teks hitam pekat untuk kontras maksimal terhadap background putih
                  ),
                ),
                const SizedBox(height: 20), // Widget pemisah vertikal transparan setinggi 20 pixel, memberikan ruang antara teks judul dan baris tombol di bawahnya
                Row( // Menyusun tombol NO dan YES secara horizontal berdampingan dalam satu baris
                  children: [
                    Expanded( // Membuat tombol NO mengambil setengah dari lebar Row yang tersedia secara proporsional
                      child: GestureDetector( // Widget pendeteksi gesture (sentuhan/tap) yang membungkus tampilan tombol NO untuk merespons interaksi pengguna
                        onTap: () => Navigator.pop(context, false), // Callback yang dipanggil saat tombol NO ditekan: menutup dialog menggunakan Navigator.pop() dan mengembalikan nilai boolean 'false' sebagai hasil pilihan pengguna kepada pemanggil _showConfirmDialog()
                        child: Container( // Container yang berfungsi sebagai tampilan visual tombol NO (tidak menggunakan ElevatedButton agar desain sepenuhnya dikustomisasi)
                          padding: const EdgeInsets.symmetric(vertical: 14), // Padding atas-bawah 14 pixel di dalam tombol NO agar tombol memiliki ketinggian yang cukup untuk mudah ditekan (touch target yang baik)
                          decoration: BoxDecoration( // Dekorasi visual untuk tombol NO menggunakan BoxDecoration yang fleksibel
                            color: const Color(0xFFE0E0E0), // Warna background tombol NO adalah abu-abu muda (E0E0E0) — warna netral yang mengindikasikan aksi 'batalkan/tidak'
                            borderRadius: BorderRadius.circular(50), // Radius sudut 50 pixel membuat tombol berbentuk seperti pil (pill-shape) yang modern
                          ),
                          alignment: Alignment.center, // Menempatkan teks 'NO' tepat di tengah container secara horizontal maupun vertikal
                          child: const Text( // Teks label yang ditampilkan di dalam tombol NO
                            'NO', // Label tombol: singkat dan jelas untuk menolak/membatalkan aksi
                            style: TextStyle( // Gaya visual teks tombol NO
                              fontSize: 16, // Ukuran font 16 sp — cukup besar untuk tombol aksi
                              fontWeight: FontWeight.bold, // Tebal/bold agar teks tombol terlihat tegas dan mudah dibaca
                              color: Colors.black, // Warna teks hitam yang kontras dengan background abu-abu
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Widget pemisah horizontal transparan selebar 12 pixel, memberikan jarak antara tombol NO dan tombol YES agar keduanya tidak terlalu rapat
                    Expanded( // Membuat tombol YES mengambil setengah lebar Row yang tersisa secara proporsional (seimbang dengan tombol NO)
                      child: GestureDetector( // Widget pendeteksi gesture yang membungkus tampilan tombol YES
                        onTap: () => Navigator.pop(context, true), // Callback yang dipanggil saat tombol YES ditekan: menutup dialog dan mengembalikan nilai boolean 'true' kepada pemanggil, menandakan pengguna setuju/mengkonfirmasi aksi
                        child: Container( // Container sebagai tampilan visual tombol YES yang dikustomisasi penuh
                          padding: const EdgeInsets.symmetric(vertical: 14), // Padding atas-bawah 14 pixel — sama dengan tombol NO untuk konsistensi ukuran dan kemudahan ditekan
                          decoration: BoxDecoration( // Dekorasi visual untuk tombol YES
                            color: const Color(0xFF42AAFF), // Warna background tombol YES adalah biru cerah (42AAFF) — warna yang mengindikasikan aksi positif/konfirmasi
                            borderRadius: BorderRadius.circular(50), // Radius 50 pixel untuk bentuk pil yang konsisten dengan tombol NO
                          ),
                          alignment: Alignment.center, // Menempatkan teks 'YES' tepat di tengah container
                          child: const Text( // Teks label yang ditampilkan di dalam tombol YES
                            'YES', // Label tombol: singkat dan jelas untuk menyetujui/mengkonfirmasi aksi
                            style: TextStyle( // Gaya visual teks tombol YES
                              fontSize: 16, // Ukuran font 16 sp — konsisten dengan tombol NO
                              fontWeight: FontWeight.bold, // Tebal/bold agar tombol terlihat tegas
                              color: Colors.white, // Warna teks putih yang kontras dengan background biru cerah
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

  //_______________________
  // LOGIKA SIMPAN KONTAK
  //_______________________

  Future<void> _saveContact() async { // Method asinkron yang menangani seluruh alur proses penyimpanan data kontak ke Firestore, termasuk validasi form, konfirmasi pengguna, dan penanganan error. Dipanggil saat pengguna menekan tombol centang di AppBar
    if (_isLoading) return; // Pemeriksaan pengaman (guard clause): jika proses penyimpanan sebelumnya masih berjalan (_isLoading = true), langsung hentikan eksekusi method ini untuk mencegah double-submit atau race condition pada Firestore

    if (_nameController.text.trim().isEmpty) { // Melakukan validasi manual khusus untuk field nama: mengambil teks dari controller, menghapus spasi di awal/akhir dengan trim(), lalu memeriksa apakah hasilnya adalah string kosong. Nama kontak adalah field yang WAJIB diisi
      _showSnackbar('Contact name cannot be empty', Colors.red); // Jika nama kosong, tampilkan SnackBar berwarna merah dengan pesan error yang informatif kepada pengguna
      return; // Hentikan eksekusi method di sini karena validasi gagal — tidak lanjut ke proses simpan
    }

    if (_formKey.currentState!.validate()) { // Memicu validasi pada semua field yang ada di dalam widget Form yang diikat dengan _formKey. Method validate() akan memanggil semua fungsi 'validator' yang terdapat pada setiap TextFormField. Mengembalikan true jika semua validasi lolos, false jika ada yang gagal
      final bool? confirm = await _showConfirmDialog( // Menampilkan dialog konfirmasi kepada pengguna dan menunggu respons mereka menggunakan 'await'. Nilai kembalian bisa: true (YES), false (NO), atau null (dialog ditutup tanpa memilih)
        widget.kontak != null ? 'Save changes?' : 'Add this Contact?', // Menentukan judul dialog secara dinamis berdasarkan mode: 'Save changes?' untuk mode edit kontak yang sudah ada, 'Add this Contact?' untuk mode tambah kontak baru
      );

      if (confirm != true) return; // Jika pengguna TIDAK memilih YES (memilih NO atau menutup dialog — nilai confirm adalah false atau null), hentikan proses penyimpanan dan kembalikan kontrol ke pengguna

      setState(() => _isLoading = true); // Mengaktifkan state loading dengan mengubah _isLoading menjadi true, yang akan memicu rebuild UI: tombol centang berubah menjadi CircularProgressIndicator dan semua tombol aksi dinonaktifkan

      try { // Membuka blok try untuk menangkap semua kemungkinan error yang terjadi selama operasi tulis ke Firestore berlangsung
        if (widget.kontak != null) { // Memeriksa apakah ini operasi UPDATE (mode edit): jika ada data kontak sebelumnya (widget.kontak tidak null), maka kita perlu memperbarui dokumen yang sudah ada
          await kontakCollection.doc(widget.kontak!.id).update({ // Mengeksekusi operasi update di Firestore: mencari dokumen dengan ID yang sama dengan ID kontak, lalu memperbarui field-field yang ditentukan. Hanya field yang ada di Map ini yang akan diubah; field lain tetap
            'name': _nameController.text.trim(), // Menyimpan nilai terbaru field nama ke Firestore setelah menghapus spasi tidak perlu di awal/akhir dengan trim()
            'phone': _phoneController.text.trim(), // Menyimpan nilai terbaru field telepon ke Firestore setelah di-trim
            'email': _emailController.text.trim(), // Menyimpan nilai terbaru field email ke Firestore setelah di-trim
            'notes': _notesController.text.trim(), // Menyimpan nilai terbaru field catatan ke Firestore setelah di-trim
            'updated_at': FieldValue.serverTimestamp(), // Menggunakan FieldValue.serverTimestamp() untuk menyimpan waktu server Firestore saat operasi update ini dieksekusi. Lebih akurat daripada waktu perangkat karena tidak terpengaruh perbedaan zona waktu atau clock perangkat yang salah
          });
        } else { // Jika widget.kontak == null, berarti ini operasi INSERT/CREATE (mode tambah kontak baru): perlu membuat dokumen baru di Firestore
          await kontakCollection.add({ // Mengeksekusi operasi add() di Firestore yang secara otomatis membuat dokumen baru dengan ID unik yang di-generate oleh Firestore (tidak perlu menentukan ID sendiri)
            'name': _nameController.text.trim(), // Menyimpan nama kontak baru yang dimasukkan pengguna ke dokumen Firestore baru setelah di-trim
            'phone': _phoneController.text.trim(), // Menyimpan nomor telepon kontak baru ke dokumen Firestore baru setelah di-trim
            'email': _emailController.text.trim(), // Menyimpan email kontak baru ke dokumen Firestore baru setelah di-trim
            'notes': _notesController.text.trim(), // Menyimpan catatan kontak baru ke dokumen Firestore baru setelah di-trim
            'created_at': FieldValue.serverTimestamp(), // Menyimpan timestamp waktu pembuatan dokumen menggunakan waktu server Firestore — akan digunakan untuk sorting atau audit trail
            'updated_at': FieldValue.serverTimestamp(), // Menyimpan timestamp waktu update yang nilainya sama dengan created_at pada saat kontak pertama kali dibuat. Akan diperbarui setiap kali data kontak diedit di masa mendatang
          });
        }

        if (context.mounted) { // Memeriksa apakah BuildContext masih valid dan widget masih terpasang di tree sebelum melakukan operasi UI (snackbar dan navigator). Penting karena operasi Firestore di atas bersifat async dan ada kemungkinan layar sudah ditutup
          _showSnackbar( // Memanggil method helper untuk menampilkan SnackBar notifikasi keberhasilan kepada pengguna
            widget.kontak != null // Memilih pesan sukses yang tepat berdasarkan operasi yang baru dilakukan
                ? 'Contact updated successfully' // Pesan sukses untuk operasi UPDATE (edit kontak yang sudah ada berhasil disimpan)
                : 'Contact added successfully', // Pesan sukses untuk operasi CREATE (kontak baru berhasil ditambahkan)
            const Color.fromRGBO(76, 175, 80, 1), // Warna hijau Material (RGB: 76, 175, 80) untuk SnackBar sukses — warna hijau secara universal mengindikasikan keberhasilan
          );

          Navigator.pop(context); // Menutup layar AddEditKontakScreen saat ini dan kembali ke layar sebelumnya (biasanya daftar kontak). Dilakukan SETELAH menampilkan SnackBar sukses
        }
      } catch (e) { // Blok catch yang menangkap semua jenis error/exception yang mungkin terjadi selama operasi Firestore (update/add), seperti FirebaseException, NetworkException, dll
        debugPrint('_saveContact error: $e'); // Mencetak detail error lengkap ke konsol debug Flutter untuk membantu proses troubleshooting dan debugging saat development. Tidak terlihat oleh pengguna akhir

        if (mounted) { // Memeriksa apakah widget masih ada di tree sebelum menampilkan SnackBar error
          _showSnackbar('Failed to save: ${e.toString()}', Colors.red); // Menampilkan SnackBar berwarna merah dengan pesan error yang informatif (termasuk detail error dari exception) agar pengguna tahu bahwa penyimpanan gagal
        }
      } finally { // Blok finally yang SELALU dieksekusi terlepas dari apakah try berhasil atau catch menangkap error. Digunakan untuk cleanup yang harus dilakukan dalam kondisi apapun
        if (mounted) { // Memeriksa apakah widget masih ada sebelum memanggil setState(), karena widget bisa saja sudah di-dispose jika pengguna menavigasi pergi dengan cepat
          setState(() => _isLoading = false); // Menonaktifkan state loading dengan mengubah _isLoading kembali menjadi false. UI akan kembali normal: tombol centang muncul kembali dan semua tombol aktif lagi
        }
      }
    }
  }

  //_______________________
  // LOGIKA TOMBOL CLOSE / KEMBALI
  //_______________________

  Future<void> _handleClose() async { // Method asinkron yang menangani aksi ketika pengguna menekan tombol close (X) di AppBar. Logikanya berbeda tergantung kondisi: apakah ada perubahan yang belum disimpan, apakah sedang edit kontak yang ada, atau hanya tambah baru
    if (isEditing && _hasUnsavedChanges()) { // Memeriksa DUA kondisi sekaligus: (1) apakah sedang dalam mode edit (isEditing = true), DAN (2) apakah ada perubahan yang sudah dibuat tapi belum disimpan. Jika keduanya terpenuhi, perlu konfirmasi sebelum menutup
      final bool? confirm = await _showConfirmDialog('Discard changes?'); // Menampilkan dialog konfirmasi kepada pengguna dengan pertanyaan 'Discard changes?' (Buang perubahan?) dan menunggu jawaban
      if (confirm != true) return; // Jika pengguna memilih NO (tidak mau membuang perubahan) atau menutup dialog, batalkan penutupan layar dan kembalikan kontrol ke pengguna agar mereka bisa melanjutkan editing
    }

    if (widget.kontak != null && isEditing) { // Memeriksa kondisi spesifik: apakah ini adalah skenario EDIT KONTAK YANG SUDAH ADA (bukan tambah baru) yang sedang dalam mode edit. Jika ya, maka close seharusnya kembali ke mode DETAIL, bukan keluar dari layar sepenuhnya
      setState(() { // Memanggil setState() untuk memperbarui semua variabel state sekaligus dan memicu rebuild UI
        isEditing = false; // Menonaktifkan mode edit (kembali ke mode detail/read-only) — AppBar akan berubah: tombol centang hilang, tombol Edit muncul
        _nameController.text = widget.kontak!.name; // Mengembalikan teks di controller nama ke nilai ASLI dari data kontak (sebelum diedit), membuang semua perubahan yang belum disimpan
        _phoneController.text = widget.kontak!.phone; // Mengembalikan teks telepon ke nilai asli — perubahan yang dibuat pengguna di field ini dibuang
        _emailController.text = widget.kontak!.email; // Mengembalikan teks email ke nilai asli — perubahan di field ini dibuang
        _notesController.text = widget.kontak!.notes; // Mengembalikan teks notes ke nilai asli — perubahan di field ini dibuang
      });
      return; // Hentikan eksekusi method di sini — tidak perlu Navigator.pop() karena kita hanya kembali ke mode detail, bukan menutup layar
    }

    if (context.mounted) Navigator.pop(context); // Jika bukan skenario edit kontak yang ada (yaitu mode tambah baru atau mode detail tanpa perubahan), tutup layar sepenuhnya dan kembali ke layar sebelumnya di navigation stack
  }

  //_______________________
  // HELPER — DEKORASI INPUT FIELD
  //_______________________

  InputDecoration _inputDecoration({ // Method helper yang bertugas membuat dan mengembalikan objek InputDecoration dengan styling seragam untuk semua field input di form. Dengan memusatkan dekorasi di satu method, perubahan styling hanya perlu dilakukan di satu tempat (DRY — Don't Repeat Yourself)
    required String hint, // Parameter wajib bertipe String: teks placeholder yang akan muncul di dalam field saat field masih kosong, memberi petunjuk kepada pengguna tentang data apa yang harus dimasukkan
    required IconData icon, // Parameter wajib bertipe IconData: data ikon yang akan ditampilkan di sisi kiri field (prefix icon) sebagai visual indicator konteks field tersebut
  }) {
    return InputDecoration( // Membuat dan mengembalikan objek InputDecoration yang berisi semua konfigurasi tampilan field input
      hintText: hint, // Menetapkan teks placeholder sesuai parameter 'hint' yang dikirimkan — muncul dengan warna abu-abu saat field kosong dan hilang saat pengguna mulai mengetik
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16), // Mendefinisikan gaya teks placeholder: warna abu-abu terang (shade 400) dan ukuran font 16 sp, memberikan tampilan elegan dan tidak terlalu mencolok
      prefixIcon: Icon(icon, color: Colors.grey[700], size: 22), // Menampilkan ikon di sisi kiri field sebelum area input teks: menggunakan data ikon dari parameter, berwarna abu-abu gelap (shade 700), berukuran 22 pixel
      filled: true, // Mengaktifkan warna latar belakang (fill color) pada field input. Tanpa ini, fillColor diabaikan dan field akan transparan
      fillColor: Colors.white, // Menetapkan warna latar belakang field menjadi putih bersih, menciptakan tampilan card-like yang menonjol dari background layar
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Mengatur padding di dalam area konten field (antara border dan teks yang diketik): 20 pixel kiri-kanan untuk jarak dari ikon prefix, 16 pixel atas-bawah untuk ketinggian yang nyaman
      border: OutlineInputBorder( // Mendefinisikan border default yang digunakan saat state field tidak ditentukan secara spesifik
        borderRadius: BorderRadius.circular(25), // Radius sudut 25 pixel menciptakan tampilan field yang membulat di semua pojok
        borderSide: const BorderSide(color: Colors.black, width: 1.2), // Garis border berwarna hitam dengan ketebalan 1.2 pixel — tipis tapi tetap terlihat jelas
      ),
      enabledBorder: OutlineInputBorder( // Mendefinisikan border yang ditampilkan saat field dalam keadaan AKTIF (bisa diinteraksi) tetapi tidak sedang dalam fokus (belum diklik pengguna)
        borderRadius: BorderRadius.circular(25), // Radius sudut 25 pixel konsisten dengan border lainnya
        borderSide: const BorderSide(color: Colors.black, width: 1.2), // Border hitam tipis 1.2 pixel — sama dengan border default
      ),
      focusedBorder: OutlineInputBorder( // Mendefinisikan border yang ditampilkan saat field SEDANG DIFOKUS (diklik/aktif dan keyboard muncul) — memberikan visual feedback kepada pengguna bahwa field ini yang sedang aktif
        borderRadius: BorderRadius.circular(25), // Radius sudut 25 pixel konsisten
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5), // Border berubah menjadi biru Material (2196F3) dengan ketebalan sedikit lebih tebal (1.5 pixel) untuk memberi penekanan visual bahwa field ini sedang aktif
      ),
    );
  }

  //_______________________
  // HELPER — BUILD TEXT FIELD
  //_______________________

  Widget _buildTextField({ // Method helper yang membuat dan mengembalikan widget TextFormField dengan konfigurasi dan styling standar yang sudah ditentukan. Menggunakan _inputDecoration() untuk konsistensi tampilan di seluruh form
    required TextEditingController controller, // Parameter wajib: objek TextEditingController yang akan dihubungkan ke TextFormField ini untuk mengelola dan membaca teks
    required String hint, // Parameter wajib: teks placeholder yang diteruskan ke _inputDecoration()
    required IconData icon, // Parameter wajib: data ikon yang diteruskan ke _inputDecoration()
    int maxLines = 1, // Parameter opsional dengan nilai default 1: jumlah baris maksimal yang bisa ditampilkan di field. Field single-line menggunakan default ini; field notes menggunakan maxLines lebih besar
    TextInputType? keyboardType, // Parameter opsional bertipe TextInputType: menentukan jenis keyboard virtual yang muncul saat field ini difokus (misal: TextInputType.phone untuk keyboard angka, TextInputType.emailAddress untuk keyboard email)
    String? Function(String?)? validator, // Parameter opsional berupa fungsi validasi: dipanggil oleh Form saat validate() dieksekusi. Menerima String? (teks saat ini) dan mengembalikan String? pesan error (jika tidak null berarti validasi gagal) atau null (jika validasi lulus)
  }) {
    return TextFormField( // Mengembalikan widget TextFormField yang terintegrasi dengan Form melalui _formKey — berbeda dari TextField biasa, TextFormField mendukung validasi dan Form state management
      controller: controller, // Menghubungkan TextFormField dengan controller yang diberikan sebagai parameter, memungkinkan pembacaan dan penulisan teks secara programatik
      readOnly: !isEditing, // Properti yang sangat penting: field hanya bisa DIEDIT jika 'isEditing' bernilai true. Jika isEditing = false (mode detail), field menjadi read-only — teks bisa dibaca tapi tidak bisa diubah. Keyboard tidak muncul saat readOnly = true
      maxLines: maxLines, // Mengatur jumlah baris maksimal yang ditampilkan sesuai parameter. Untuk field biasa (nama, telepon, email) defaultnya 1 baris
      keyboardType: keyboardType, // Meneruskan tipe keyboard ke TextFormField. Null jika tidak ditentukan (menggunakan keyboard default teks biasa)
      validator: validator, // Meneruskan fungsi validasi ke TextFormField. Null jika tidak ada validasi khusus (selain pengecekan manual di _saveContact)
      decoration: _inputDecoration(hint: hint, icon: icon), // Menerapkan dekorasi visual standar yang sudah dikonfigurasi di method _inputDecoration(), dengan hint text dan ikon yang sesuai untuk field ini
    );
  }

  //_______________________
  // HELPER — BUILD NOTES FIELD (KHUSUS)
  //_______________________

  Widget _buildNotesField() { // Method khusus untuk membangun field Notes yang memiliki tampilan unik berbeda dari field-field lainnya: menggunakan label teks yang diposisikan di DALAM area field (bukan di atas field), sehingga terlihat seperti notes pad
    return Stack( // Menggunakan widget Stack yang memungkinkan penumpukan widget secara overlap — TextFormField ditempatkan sebagai lapisan bawah, dan label 'Notes..' ditempatkan sebagai lapisan atas di posisi tertentu
      children: [
        TextFormField( // Widget input teks multiline untuk field catatan, ditempatkan di lapisan paling bawah dalam Stack
          controller: _notesController, // Menghubungkan field dengan controller notes yang sudah diinisialisasi di initState()
          readOnly: !isEditing, // Field catatan juga hanya bisa diedit saat isEditing = true, sama seperti field-field lainnya
          maxLines: 5, // Mengatur maksimal 5 baris teks yang bisa ditampilkan sekaligus di field — membuat field ini secara visual lebih tinggi dari field biasa (single-line)
          style: const TextStyle(fontSize: 16, color: Colors.black), // Mendefinisikan gaya teks yang diketik pengguna: ukuran 16 sp dan warna hitam untuk keterbacaan yang baik
          decoration: InputDecoration( // Dekorasi khusus untuk field notes — tidak menggunakan _inputDecoration() karena layoutnya berbeda (label di dalam, bukan prefix icon di kiri)
            filled: true, // Mengaktifkan fill color untuk field notes
            fillColor: Colors.white, // Background putih untuk field notes, konsisten dengan field lainnya
            contentPadding: const EdgeInsets.fromLTRB(16, 68, 16, 16), // Padding asimetris yang sangat penting: kiri=16, ATAS=68 (sangat besar), kanan=16, bawah=16. Padding atas yang besar (68px) ini sengaja dibuat untuk memberi ruang bagi label 'Notes..' yang diposisikan secara absolute di atas area konten
            border: OutlineInputBorder( // Border default field notes
              borderRadius: BorderRadius.circular(20), // Radius sudut 20 pixel (sedikit lebih kecil dari field lain yang 25, karena field ini lebih besar secara keseluruhan)
              borderSide: const BorderSide(color: Colors.black, width: 1.2), // Border hitam tipis 1.2 pixel
            ),
            enabledBorder: OutlineInputBorder( // Border saat field notes aktif tidak difokus
              borderRadius: BorderRadius.circular(20), // Radius sudut 20 pixel konsisten
              borderSide: const BorderSide(color: Colors.black, width: 1.2), // Border hitam tipis 1.2 pixel
            ),
            focusedBorder: OutlineInputBorder( // Border saat field notes sedang difokus/aktif diklik
              borderRadius: BorderRadius.circular(20), // Radius sudut 20 pixel konsisten
              borderSide: const BorderSide( // Mendefinisikan gaya garis border saat fokus
                color: Color(0xFF2196F3), // Warna berubah menjadi biru Material saat field aktif, memberi visual feedback
                width: 1.5, // Sedikit lebih tebal (1.5 pixel) dari border normal untuk penekanan
              ),
            ),
          ),
        ),
        Positioned( // Widget yang memposisikan child-nya secara absolute (tepat) di dalam Stack berdasarkan koordinat yang ditentukan
          top: 16, // Menempatkan label 'Notes..' sejauh 16 pixel dari tepi atas Stack (yaitu dari tepi atas field notes)
          left: 16, // Menempatkan label 'Notes..' sejauh 16 pixel dari tepi kiri Stack, sejajar dengan padding kiri konten field
          child: Text( // Widget teks yang menampilkan label 'Notes..' sebagai penanda field catatan
            'Notes..', // Teks label yang ditampilkan di sudut kiri atas field notes, berfungsi sebagai placeholder yang selalu terlihat (tidak hilang saat user mengetik seperti hintText biasa)
            style: TextStyle(color: Colors.grey[400], fontSize: 16), // Styling label: warna abu-abu terang (shade 400) yang tidak mengganggu, ukuran 16 sp, konsisten dengan hintText field lainnya
          ),
        ),
      ],
    );
  }

  //_______________________
  // BUILD — TAMPILAN UTAMA LAYAR
  //_______________________

  @override
  Widget build(BuildContext context) { // Method build() yang di-override dari class State. Dipanggil oleh Flutter setiap kali ada perubahan state (setelah setState()) atau ketika widget perlu di-render ulang. Harus mengembalikan widget yang merepresentasikan tampilan layar saat ini
    return Scaffold( // Widget Scaffold adalah kerangka struktur halaman standar Flutter yang menyediakan slot-slot terorganisir untuk komponen UI utama seperti appBar, body, floatingActionButton, drawer, bottomNavigationBar, dll
      backgroundColor: Colors.white, // Mengatur warna latar belakang seluruh layar Scaffold menjadi putih bersih, termasuk area di bawah AppBar dan di luar konten body

      //_______________________
      // APP BAR
      //_______________________

      appBar: AppBar( // Widget AppBar yang ditampilkan di bagian paling atas layar, berisi tombol close (leading), judul layar (title), dan tombol aksi (actions) yang berubah sesuai mode layar
        backgroundColor: Colors.white, // Warna background AppBar putih, menyatu dengan warna layar sehingga tidak ada pemisah yang kontras antara AppBar dan konten body
        elevation: 0, // Menghilangkan bayangan (shadow) di bawah AppBar sepenuhnya — nilai 0 berarti tidak ada efek elevasi. Membuat tampilan lebih flat dan modern
        leadingWidth: 80, // Memperlebar area leading (sisi kiri AppBar) menjadi 80 pixel — lebar default biasanya ~56px. Ini memberi ruang lebih untuk tombol close yang berbentuk lingkaran dengan padding
        leading: Padding( // Widget di sisi KIRI AppBar yang berisi tombol close (X) untuk menutup atau kembali dari layar ini
          padding: const EdgeInsets.only(left: 24, top: 6, bottom: 6), // Padding khusus untuk tombol close: 24 pixel dari kiri layar agar tidak terlalu mepet tepi, 6 pixel atas-bawah untuk memastikan tombol tidak menyentuh tepi AppBar
          child: GestureDetector( // Mendeteksi interaksi sentuhan/tap pengguna pada area tombol close, kemudian memicu aksi yang sesuai
            onTap: _isLoading ? null : _handleClose, // Mendefinisikan aksi saat tombol close ditekan. Jika _isLoading = true (sedang ada proses), set null (nonaktif/disabled). Jika tidak loading, panggil _handleClose() yang menangani logika close dengan konfirmasi jika ada perubahan
            child: Container( // Container berbentuk lingkaran yang menjadi tampilan visual tombol close
              width: 42, // Lebar container 42 pixel — ukuran yang cukup untuk touch target yang nyaman
              height: 42, // Tinggi container 42 pixel — sama dengan lebar untuk bentuk lingkaran sempurna
              decoration: const BoxDecoration( // Dekorasi visual container tombol close
                color: Color(0xFFF5F5F5), // Warna background abu-abu sangat muda (hampir putih) untuk tombol, memberi kesan subtle tidak terlalu mencolok
                shape: BoxShape.circle, // Mengubah bentuk container menjadi lingkaran penuh (bukan persegi/default)
              ),
              child: const Icon(Icons.close, color: Colors.black, size: 26), // Ikon X (close/silang) berwarna hitam berukuran 26 pixel yang diletakkan di tengah container lingkaran
            ),
          ),
        ),
        centerTitle: true, // Menempatkan widget title AppBar tepat di tengah secara horizontal, terlepas dari apakah ada leading atau actions di sisinya
        title: Text( // Widget teks yang menampilkan judul AppBar secara dinamis berdasarkan mode layar saat ini
          widget.kontak == null // Pengecekan pertama: apakah tidak ada data kontak (mode tambah baru)?
              ? 'Add Contact' // Jika mode tambah baru (kontak null), tampilkan judul 'Add Contact'
              : isEditing // Jika ada kontak, pengecekan kedua: apakah sedang dalam mode edit?
                  ? 'Edit Contact' // Jika mode edit kontak yang sudah ada, tampilkan 'Edit Contact'
                  : 'Contact Detail', // Jika mode lihat detail (ada kontak, tidak edit), tampilkan 'Contact Detail'
          style: const TextStyle( // Mendefinisikan gaya visual teks judul AppBar
            fontSize: 20, // Ukuran font 20 sp — cukup besar untuk judul halaman yang terlihat jelas
            fontWeight: FontWeight.w600, // Semi-bold (weight 600) — sedikit lebih tebal dari normal tapi tidak terlalu bold, memberikan tampilan judul yang berwibawa
            color: Colors.black, // Warna teks hitam untuk kontras maksimal terhadap background putih AppBar
          ),
        ),
        actions: [ // Daftar widget yang ditempatkan di sisi KANAN AppBar. Flutter akan menampilkan widget-widget ini secara horizontal dari kiri ke kanan di area kanan AppBar

          //_______________________
          // TOMBOL EDIT (mode detail)
          //_______________________

          if (isDetailMode) // Conditional rendering menggunakan Dart collection-if: tombol Edit HANYA ditampilkan jika layar sedang dalam mode detail (ada kontak dan tidak sedang edit). Jika mode tambah baru atau mode edit, tombol ini tidak muncul
            Padding( // Padding di sekitar tombol Edit untuk memberi jarak dari tepi AppBar
              padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10), // Padding kanan 16 pixel agar tombol tidak mepet tepi kanan layar, atas-bawah 10 pixel agar tombol tidak terlalu tinggi memenuhi AppBar
              child: GestureDetector( // Mendeteksi tap pada tombol Edit
                onTap: _isLoading // Menentukan aksi tap berdasarkan state loading
                    ? null // Jika sedang loading, nonaktifkan tap (tidak ada aksi)
                    : () { // Jika tidak loading, jalankan fungsi anonim ini saat tombol Edit ditekan
                        setState(() { // Memperbarui state untuk mengaktifkan mode edit
                          isEditing = true; // Mengubah isEditing menjadi true — UI akan rebuild: field berubah dari read-only ke editable, tombol Edit diganti tombol Simpan (centang), judul AppBar berubah menjadi 'Edit Contact'
                        });
                      },
                child: Container( // Container yang menjadi tampilan visual tombol Edit
                  width: 92, // Lebar tombol Edit 92 pixel — cukup untuk menampilkan teks 'Edit' dengan padding yang nyaman di kiri-kanan
                  alignment: Alignment.center, // Menempatkan teks 'Edit' tepat di tengah container secara horizontal dan vertikal
                  decoration: BoxDecoration( // Dekorasi visual container tombol Edit
                    color: const Color(0xFFF1F1F1), // Warna background abu-abu sangat muda (F1F1F1) untuk tombol Edit — lebih gelap sedikit dari background putih AppBar agar tombol terlihat
                    borderRadius: BorderRadius.circular(18), // Radius sudut 18 pixel — tombol Edit tidak sepenuhnya bulat seperti pil, lebih persegi panjang membulat (rounded rectangle)
                  ),
                  child: const Text( // Teks label di dalam tombol Edit
                    'Edit', // Label tombol yang jelas menunjukkan fungsi tombol
                    style: TextStyle( // Gaya visual teks tombol Edit
                      color: Colors.black, // Warna hitam untuk kontras terhadap background abu-abu muda
                      fontSize: 16, // Ukuran font 16 sp yang cukup besar untuk tombol
                      fontWeight: FontWeight.w700, // Bold (weight 700) agar teks tombol terlihat tegas dan mudah dibaca
                    ),
                  ),
                ),
              ),
            ),

          //_______________________
          // TOMBOL SIMPAN (mode edit)
          //_______________________

          if (isEditing) // Conditional rendering: tombol Simpan (centang) HANYA ditampilkan saat layar dalam mode edit (isEditing = true). Saat mode detail, tombol ini tidak ada dan digantikan tombol Edit
            Padding( // Padding di sekitar tombol Simpan
              padding: const EdgeInsets.only(right: 16, top: 6, bottom: 6), // Padding kanan 16 pixel dari tepi layar, atas-bawah 6 pixel untuk sedikit ruang vertikal dalam AppBar
              child: GestureDetector( // Mendeteksi tap pada tombol Simpan
                onTap: _isLoading ? null : _saveContact, // Saat tombol Simpan ditekan: jika sedang loading nonaktifkan (null), jika tidak loading panggil _saveContact() untuk menyimpan data ke Firestore
                child: Container( // Container lingkaran yang menjadi tampilan visual tombol Simpan
                  width: 62, // Lebar container 62 pixel
                  height: 62, // Tinggi container 62 pixel — sama dengan lebar untuk membentuk lingkaran sempurna
                  decoration: const BoxDecoration( // Dekorasi visual tombol Simpan
                    color: Color(0xFFE3F2FD), // Warna background biru sangat muda (E3F2FD — Material Blue 50) yang lembut dan tidak terlalu mencolok namun tetap mengindikasikan aksi positif
                    shape: BoxShape.circle, // Bentuk lingkaran penuh untuk tombol Simpan
                  ),
                  child: _isLoading // Menampilkan konten yang berbeda di dalam tombol berdasarkan state loading: loading indicator atau ikon centang
                      ? const Padding( // Jika _isLoading = true: tampilkan CircularProgressIndicator sebagai indikator bahwa proses penyimpanan sedang berjalan
                          padding: EdgeInsets.all(16), // Padding 16 pixel di semua sisi agar CircularProgressIndicator tidak terlalu besar dan memiliki ruang di dalam lingkaran tombol
                          child: CircularProgressIndicator( // Widget loading spinner melingkar dari Material Design
                            strokeWidth: 2, // Ketebalan garis loading spinner 2 pixel — tipis dan elegan agar sesuai dengan ukuran tombol yang tidak terlalu besar
                            color: Color(0xFF2196F3), // Warna spinner biru Material (2196F3) yang konsisten dengan tema warna aplikasi
                          ),
                        )
                      : const Icon( // Jika _isLoading = false: tampilkan ikon centang sebagai tombol simpan
                          Icons.check, // Material icon centang (✓) yang secara universal dikenali sebagai 'simpan' atau 'konfirmasi'
                          color: Color(0xFF2196F3), // Warna ikon centang biru Material, konsisten dengan warna tema dan border focused field
                          size: 32, // Ukuran ikon centang 32 pixel — cukup besar untuk mudah dilihat di dalam tombol lingkaran berdiameter 62 pixel
                        ),
                ),
              ),
            ),
        ],
      ),

      //_______________________
      // BODY — KONTEN UTAMA
      //_______________________

      body: SingleChildScrollView( // Widget wrapper yang memungkinkan konten di dalamnya dapat di-scroll secara vertikal jika total tinggi konten melebihi tinggi layar yang tersedia — penting untuk layar form yang bisa sangat panjang atau saat keyboard virtual muncul
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Padding di sekeliling konten scrollable: 20 pixel kiri-kanan agar konten tidak mepet tepi layar, 24 pixel atas-bawah untuk memberi ruang napas
        child: Form( // Widget Form yang membungkus semua field input, memungkinkan validasi terpusat melalui _formKey. Semua TextFormField di dalam Form ini akan divalidasi serentak saat _formKey.currentState!.validate() dipanggil
          key: _formKey, // Menghubungkan widget Form dengan GlobalKey _formKey agar bisa dikontrol secara programatik dari method _saveContact()
          child: Column( // Menyusun semua elemen form secara vertikal dari atas ke bawah dalam satu kolom
            children: [

              //_______________________
              // AVATAR / FOTO PROFIL
              //_______________________

              Container( // Container berbentuk lingkaran yang berfungsi sebagai avatar/foto profil kontak
                width: 120, // Lebar container 120 pixel
                height: 120, // Tinggi container 120 pixel — sama dengan lebar untuk bentuk lingkaran sempurna
                decoration: BoxDecoration( // Dekorasi visual container avatar
                  shape: BoxShape.circle, // Mengubah bentuk container menjadi lingkaran penuh
                  border: Border.all(color: Colors.black, width: 2), // Menambahkan garis border hitam tebal 2 pixel mengelilingi lingkaran avatar sebagai bingkai/frame
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.black), // Ikon siluet orang sebagai placeholder foto profil kontak. Ukuran 60 pixel dan berwarna hitam. Saat ini belum ada fitur upload foto, sehingga ikon ini digunakan sebagai default
              ),

              //_______________________
              // TAMPILAN MODE DETAIL
              //_______________________

              if (isDetailMode) ...[ // Conditional rendering menggunakan spread operator '...[]': blok widget ini HANYA ditampilkan saat isDetailMode = true (ada kontak dan tidak sedang edit). Spread operator memungkinkan penambahan beberapa widget sekaligus ke dalam children list
                const SizedBox(height: 16), // Spasi vertikal 16 pixel antara avatar dan teks nama kontak di mode detail

                Text( // Menampilkan nama kontak dalam ukuran besar di bawah avatar — layout khas untuk halaman profil/detail kontak
                  _nameController.text, // Mengambil teks nama saat ini dari controller (yang sudah diisi di initState() dari data Firestore)
                  style: const TextStyle( // Gaya visual teks nama kontak di mode detail
                    fontSize: 22, // Ukuran font besar 22 sp untuk nama kontak sebagai elemen heading/judul
                    fontWeight: FontWeight.bold, // Tebal/bold agar nama kontak terlihat sebagai informasi utama halaman
                    color: Colors.black, // Warna hitam untuk keterbacaan maksimal
                  ),
                ),

                const SizedBox(height: 32), // Spasi vertikal 32 pixel setelah nama kontak dan sebelum field informasi lainnya (telepon, email, dll) — memberi pemisah visual yang cukup

              //_______________________
              // TAMPILAN MODE TAMBAH/EDIT
              //_______________________

              ] else ...[ // Blok ini ditampilkan saat BUKAN mode detail (yaitu mode tambah baru atau mode edit). Perbedaan utama: menampilkan TextFormField nama di sini, bukan teks nama statis
                const SizedBox(height: 40), // Spasi vertikal 40 pixel antara avatar dan field nama — lebih besar dari mode detail karena ada field input yang lebih besar secara visual

                _buildTextField( // Memanggil method helper untuk membangun field input nama menggunakan konfigurasi standar
                  controller: _nameController, // Menghubungkan dengan controller nama yang mengelola nilai teks field ini
                  hint: 'Full name.....', // Teks placeholder untuk field nama yang memberitahu pengguna format yang diharapkan
                  icon: Icons.person, // Ikon siluet orang di sisi kiri field nama, secara visual mengindikasikan bahwa ini adalah field nama
                ),

                const SizedBox(height: 12), // Spasi vertikal 12 pixel antara field nama dan field telepon di bawahnya
              ],

              //_______________________
              // FIELD TELEPON
              //_______________________

              _buildTextField( // Membangun field input nomor telepon menggunakan method helper standar. Field ini selalu tampil terlepas dari mode (detail/tambah/edit)
                controller: _phoneController, // Menghubungkan dengan controller telepon yang menyimpan dan mengelola nilai nomor telepon
                hint: 'Phone number.....', // Teks placeholder yang menunjukkan bahwa field ini untuk nomor telepon
                icon: Icons.phone, // Ikon telepon di kiri field yang secara visual mengidentifikasi fungsi field ini
                keyboardType: TextInputType.phone, // Menentukan jenis keyboard yang muncul: keyboard numpad/telepon yang hanya menampilkan angka dan simbol telepon (+, -, (, )) saat field ini difokus di perangkat mobile
              ),

              const SizedBox(height: 12), // Spasi vertikal 12 pixel antara field telepon dan field email

              //_______________________
              // FIELD EMAIL
              //_______________________

              _buildTextField( // Membangun field input alamat email menggunakan method helper standar
                controller: _emailController, // Menghubungkan dengan controller email yang menyimpan nilai alamat email
                hint: 'Email.....', // Teks placeholder yang menunjukkan bahwa field ini untuk alamat email
                icon: Icons.email, // Ikon amplop/email di kiri field sebagai visual identifier
                keyboardType: TextInputType.emailAddress, // Jenis keyboard email yang menampilkan tombol '@' dan '.' secara mudah diakses, memudahkan pengguna mengetik alamat email di perangkat mobile
              ),

              const SizedBox(height: 12), // Spasi vertikal 12 pixel antara field email dan field notes

              //_______________________
              // FIELD NOTES
              //_______________________

              _buildNotesField(), // Memanggil method khusus untuk membangun field Notes dengan tampilan unik (label 'Notes..' di sudut kiri atas dan field multiline lebih tinggi dari field biasa)

              const SizedBox(height: 12), // Spasi vertikal 12 pixel antara field notes dan container informasi kategori

              //_______________________
              // CONTAINER KATEGORI
              //_______________________

              Container( // Container yang menampilkan informasi kategori mana saja yang sudah di-assign/ditetapkan untuk kontak ini
                padding: const EdgeInsets.symmetric( // Padding di dalam container kategori
                  horizontal: 16, // Padding kiri-kanan 16 pixel agar konten tidak mepet tepi container
                  vertical: 14, // Padding atas-bawah 14 pixel untuk ketinggian container yang nyaman
                ),
                decoration: BoxDecoration( // Dekorasi visual container kategori agar tampak konsisten dengan field-field input di atasnya
                  color: Colors.white, // Background putih konsisten dengan field lainnya
                  borderRadius: BorderRadius.circular(25), // Sudut membulat radius 25 pixel, konsisten dengan field input biasa
                  border: Border.all(color: Colors.black, width: 1.2), // Garis border hitam tebal 1.2 pixel, konsisten dengan enabledBorder pada field input
                ),
                child: Row( // Menyusun ikon kategori dan konten teks secara horizontal dalam satu baris
                  crossAxisAlignment: CrossAxisAlignment.start, // Menyelaraskan ikon dan konten teks ke ATAS — penting karena konten teks (daftar chip kategori) bisa lebih tinggi dari ikon, dan kita ingin ikon tetap di posisi atas, tidak di tengah vertikal
                  children: [
                    Icon( // Ikon visual di sisi kiri container kategori sebagai identifier konteks
                      Icons.people_alt_rounded, // Ikon dua orang/grup yang secara visual mengindikasikan 'kategori/kelompok kontak'
                      color: Colors.grey[700], // Warna abu-abu gelap (shade 700) konsisten dengan ikon-ikon di field input lainnya
                      size: 22, // Ukuran ikon 22 pixel konsisten dengan ukuran ikon di field input
                    ),
                    const SizedBox(width: 12), // Spasi horizontal 12 pixel antara ikon dan area konten teks di sebelah kanannya
                    Expanded( // Widget Expanded membuat Column di dalamnya mengisi sisa lebar Row yang tersedia setelah ikon dan SizedBox. Tanpa Expanded, Column bisa overflow jika chip kategori terlalu banyak
                      child: Column( // Menyusun label 'Assigned to' dan chip-chip kategori secara vertikal
                        crossAxisAlignment: CrossAxisAlignment.start, // Rata kiri untuk semua elemen dalam Column ini
                        children: [
                          Text( // Teks label yang menjelaskan konteks informasi di bawahnya
                            'Assigned to', // Label tetap yang tidak berubah, menunjukkan bahwa konten di bawahnya adalah daftar kategori yang ditetapkan untuk kontak ini
                            style: TextStyle( // Gaya visual teks label 'Assigned to'
                              fontSize: 15, // Ukuran font 15 sp — sedikit lebih kecil dari teks konten, memberi hierarki visual label vs konten
                              color: Colors.grey[600], // Warna abu-abu sedang (shade 600) untuk label agar tidak terlalu mencolok dibanding chip kategori yang lebih berwarna
                            ),
                          ),
                          const SizedBox(height: 6), // Spasi vertikal 6 pixel antara label 'Assigned to' dan konten chip kategori di bawahnya
                          assignedCategories.isEmpty // Memeriksa apakah list assignedCategories kosong (belum ada kategori yang di-assign atau data belum selesai dimuat)
                              ? Text( // Jika kosong: tampilkan teks placeholder 'No category'
                                  'No category', // Teks yang ditampilkan ketika kontak belum di-assign ke kategori manapun
                                  style: TextStyle(color: Colors.grey[500]), // Warna abu-abu muda (shade 500) untuk teks 'No category' — lebih terang dari label untuk menunjukkan ini adalah placeholder bukan konten nyata
                                )
                              : Wrap( // Jika ada kategori: gunakan widget Wrap yang otomatis menempatkan chip-chip ke baris berikutnya jika tidak cukup tempat dalam satu baris (seperti text wrapping)
                                  spacing: 8, // Jarak horizontal antara satu chip dengan chip berikutnya dalam satu baris sebesar 8 pixel
                                  runSpacing: 8, // Jarak vertikal antara satu baris chip dengan baris chip berikutnya sebesar 8 pixel — digunakan saat chip berpindah ke baris baru
                                  children: assignedCategories // Mengambil list nama-nama kategori yang sudah dimuat dari Firestore
                                      .map( // Mentransformasi setiap String nama kategori menjadi widget chip menggunakan method map() dari List
                                        (category) =>
                                            _AssignedChip(text: category), // Membuat instance widget _AssignedChip untuk setiap nama kategori, mengirimkan nama kategori sebagai parameter 'text'
                                      )
                                      .toList(), // Mengkonversi hasil Iterable dari map() menjadi List<Widget> yang diterima oleh properti 'children' dari Wrap
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

//_______________________
// WIDGET CHIP KATEGORI
//_______________________

class _AssignedChip extends StatelessWidget { // Mendefinisikan widget kecil khusus untuk menampilkan satu badge/chip nama kategori. Menggunakan StatelessWidget karena widget ini tidak memiliki state internal yang berubah — hanya menampilkan teks yang diterima dari luar dan tidak perlu diperbarui secara mandiri
  final String text; // Properti final (tidak berubah setelah dibuat) yang menyimpan nama kategori yang akan ditampilkan di dalam chip. Diterima dari parent widget saat chip dibuat

  const _AssignedChip({required this.text}); // Constructor const (bisa di-compile-time optimized) dengan parameter 'text' yang wajib diisi — tidak bisa membuat _AssignedChip tanpa memberikan nama kategori

  @override
  Widget build(BuildContext context) { // Method build() yang membangun dan mengembalikan tampilan visual chip kategori. Dipanggil sekali saat chip pertama dibuat dan tidak perlu dipanggil ulang karena tidak ada state yang berubah
    return Container( // Container utama yang menjadi tampilan fisik chip kategori — berbentuk persegi panjang dengan sudut sangat membulat menyerupai badge/tag
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), // Padding di dalam chip: 12 pixel kiri-kanan agar teks memiliki ruang di samping kiri dan kanan, 5 pixel atas-bawah untuk ketinggian chip yang proporsional
      decoration: BoxDecoration( // Dekorasi visual chip kategori yang memberi tampilan badge berwarna
        color: const Color(0xFFE3F2FD), // Warna background chip adalah biru sangat muda (Material Blue 50 — E3F2FD), memberikan tampilan badge yang lembut dan tidak terlalu mencolok
        borderRadius: BorderRadius.circular(20), // Radius sudut 20 pixel menciptakan bentuk pil (pill shape) yang khas untuk chip/badge — semua pojok sangat membulat
      ),
      child: Text( // Widget teks yang menampilkan nama kategori di dalam chip
        text, // Isi teks dari properti 'text' yang diterima constructor — nama kategori yang akan ditampilkan
        style: const TextStyle( // Gaya visual teks nama kategori di dalam chip
          fontSize: 14, // Ukuran font 14 sp — sedikit lebih kecil dari teks konten biasa untuk chip yang kompak
          fontWeight: FontWeight.w500, // Medium weight (500) — sedikit lebih tebal dari normal tapi tidak se-bold teks judul, memberikan keterbacaan baik pada ukuran font kecil
          color: Color(0xFF1976D2), // Warna teks biru tua (Material Blue 700 — 1976D2) yang kontras terhadap background biru muda chip, menciptakan tampilan chip yang estetis dan mudah dibaca
        ),
      ),
    );
  }
}