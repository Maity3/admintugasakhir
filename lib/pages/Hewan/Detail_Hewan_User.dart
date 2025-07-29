import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Tambahkan import intl untuk format mata uang

class DetailHewanUserPage extends StatefulWidget {
  final String hewanId;
  final String userId;
  final String kandangId;

  DetailHewanUserPage(
      {required this.hewanId, required this.userId, required this.kandangId});

  @override
  _DetailHewanUserPageState createState() => _DetailHewanUserPageState();
}

class _DetailHewanUserPageState extends State<DetailHewanUserPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final DatabaseReference bobotRef = FirebaseDatabase.instance.reference().child('bobot');
  final DatabaseReference hargaRef = FirebaseDatabase.instance.reference().child('harga'); // Tambahkan referensi ke node harga
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _hewanData;
  List<Map<String, dynamic>> _riwayatKesehatan = [];
  String? _kandangId;
  String _currentPrice = 'Belum ditetapkan'; // Variabel untuk menyimpan harga terkini
  String _priceUpdateInfo = ''; // Variabel untuk menyimpan info update harga

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchData();
    print(
        "User ID yang digunakan: ${widget.userId}"); // Memastikan ID pengguna yang benar digunakan
  }

  Future<void> tambahHewanKeKandangPengguna(
      String kandangId, String hewanId, Map<String, dynamic> dataHewan) async {
    try {
      // Pastikan referensi database menggunakan widget.userId untuk mengakses data yang benar
      DatabaseReference hewanRef = _database
          .ref()
          .child("users")
          .child(widget.userId)
          .child("kandangs")
          .child(kandangId)
          .child("hewans")
          .child(hewanId);
      await hewanRef.set(dataHewan);
      print(
          "Hewan berhasil ditambahkan ke kandang: $kandangId dengan ID pengguna: ${widget.userId}");
    } catch (e) {
      print("Kesalahan saat menambahkan hewan ke kandang: $e");
      rethrow;
    }
  }

  void _checkAuthAndFetchData() async {
    User? user = _auth.currentUser;

    print("Current Authenticated User ID: ${user?.uid}");
    print("Accessing Data for User ID: ${widget.userId}");
    if (user != null) {
      await _fetchKandangId(); // Tambahkan fungsi untuk mengambil ID kandang
      if (_kandangId != null) {
        await _fetchHewanData();
        await _fetchRiwayatKesehatan(); // Ganti _fetchPakanData dengan _fetchRiwayatKesehatan
        await _fetchHargaHewan(widget.hewanId); // Tambahkan pemanggilan fungsi untuk mengambil harga hewan
      } else {
        print("Pengguna tidak terotentikasi");
      }
    } else {
      print("Pengguna tidak terotentikasi atau ID pengguna tidak cocok");
    }
  }

  // Metode untuk mengambil data harga dari hewan
  Future<void> _fetchHargaHewan(String nomorHewan) async {
    try {
      // Pertama, coba ambil harga dari dokumen hewan langsung (jika menggunakan format baru)
      DatabaseReference hewanRef = _database.ref().child("hewans/$nomorHewan");
      DataSnapshot snapshot = await hewanRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        Map<String, dynamic> hewanData = Map<String, dynamic>.from(snapshot.value as Map);
        
      // Cek apakah data hewan memiliki field harga
        if (hewanData.containsKey('harga')) {
          // Format harga dengan currency
          double price = double.parse(hewanData['harga']?.toString() ?? '0');
          final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          String formattedPrice = formatCurrency.format(price);
          
          // Tambahkan info update harga jika ada
          String updateInfo = '';
          if (hewanData.containsKey('update_harga_info') && hewanData['update_harga_info'] != null) {
            updateInfo = hewanData['update_harga_info'];
          }
          
          setState(() {
            _currentPrice = formattedPrice;
            _priceUpdateInfo = updateInfo;
          });
          return; // Keluar dari fungsi jika sudah mendapatkan harga
        }
      }
      
      // Jika tidak ada harga di dokumen hewan, coba ambil dari node harga terpisah
      DataSnapshot hargaSnapshot = await hargaRef.get();
      
      if (hargaSnapshot.exists && hargaSnapshot.value != null) {
        Map<String, dynamic> allHargaData = Map<String, dynamic>.from(hargaSnapshot.value as Map);
        List<Map<String, dynamic>> filteredData = [];

        allHargaData.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            Map<String, dynamic> hargaEntry = Map<String, dynamic>.from(value);
            if (hargaEntry['nomor_hewan'] == nomorHewan) {
              hargaEntry['key'] = key; // Simpan key untuk referensi
              filteredData.add(hargaEntry);
            }
          }
        });

        if (filteredData.isNotEmpty) {
          // Urutkan berdasarkan tanggal terbaru jika ada field tanggal
          if (filteredData.first.containsKey('tanggal')) {
            filteredData.sort((a, b) => DateTime.parse(b['tanggal'])
                .compareTo(DateTime.parse(a['tanggal'])));
          }
          
          // Format harga dengan currency
          double price = double.parse(filteredData.first['harga']?.toString() ?? '0');
          final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          String formattedPrice = formatCurrency.format(price);
          
          setState(() {
            _currentPrice = formattedPrice;
            if (filteredData.first.containsKey('update_info')) {
              _priceUpdateInfo = filteredData.first['update_info'];
            }
          });
        }
      }
    } catch (e) {
      print("Error saat mengambil data harga: $e");
    }
  }

  Future<String> _getBobotHewan(String nomorHewan) async {
    try {
      DataSnapshot snapshot = await bobotRef.get();

      if (snapshot.exists && snapshot.value != null) {
        Map<String, dynamic> allBobotData =
            Map<String, dynamic>.from(snapshot.value as Map);
        List<Map<String, dynamic>> filteredData = [];

        allBobotData.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            Map<String, dynamic> bobotEntry = Map<String, dynamic>.from(value);
            if (bobotEntry['nomor_hewan'] == nomorHewan) {
              bobotEntry['key'] = key; // Save the key for reference
              filteredData.add(bobotEntry);
            }
          }
        });

        if (filteredData.isNotEmpty) {
          // Sort by date in descending order
          filteredData.sort((a, b) => DateTime.parse(b['tanggal'])
              .compareTo(DateTime.parse(a['tanggal'])));
          String latestBobot =
              filteredData.first['bobot']?.toString() ?? 'Belum dimiliki';
          String latestTanggal =
              filteredData.first['tanggal'] ?? 'Tanggal tidak tersedia';
          return '$latestBobot';
        }
      }
      return 'Belum dimiliki';
    } catch (e) {
      print("Error saat mengambil data: $e");
      return 'Belum dimiliki';
    }
  }

  Future<void> _fetchKandangId() async {
    try {
      DatabaseReference userRef =
          _database.ref().child("users").child(widget.userId).child("kandangs");
      DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> kandangs =
            snapshot.value as Map<dynamic, dynamic>;
        _kandangId = kandangs.keys.first.toString();
        print(
            "ID Kandang: $_kandangId"); // Asumsikan kita mengambil ID kandang pertama
      } else {
        print("Tidak ada kandang ditemukan");
      }
    } catch (e) {
      print("Kesalahan mengambil ID kandang: $e");
    }
  }

  Future<void> _fetchHewanData() async {
    try {
      // Update referensi untuk mengikuti struktur database yang benar
      DatabaseReference hewanRef = _database
          .ref()
          // .child("users")
          // .child(widget.userId)
          // .child("kandangs")
          // .child(_kandangId!) // Pastikan _kandangId sudah di-fetch sebelumnya
          .child("hewans")
          .child(widget.hewanId);

      DataSnapshot snapshot = await hewanRef.get();
      if (snapshot.exists) {
        print("Data hewan ditemukan: ${snapshot.value}");
        setState(() {
          _hewanData = Map<String, dynamic>.from(snapshot.value as Map);
        });
      } else {
        print("Data hewan tidak tersedia untuk ID: ${widget.hewanId}");
      }
    } catch (e) {
      print("Kesalahan mengambil data hewan: $e");
    }
  }

  Future<void> _fetchRiwayatKesehatan() async {
    try {
      if (_hewanData == null) {
        print("Data hewan tidak tersedia");
        return;
      }

      DatabaseReference kesehatanRef =
          _database.ref().child("laporan_kesehatan");

      DataSnapshot snapshot = await kesehatanRef.get();
      if (snapshot.exists && snapshot.value != null) {
        setState(() {
          _riwayatKesehatan = (snapshot.value as Map<dynamic, dynamic>)
              .entries
              .map((e) => {
                    'id': e.key,
                    ...Map<String, dynamic>.from(
                        e.value as Map<dynamic, dynamic>)
                  })
              .toList();
        });
      } else {
        print("Belum ada data riwayat kesehatan");
        setState(() {
          _riwayatKesehatan = [];
        });
      }
    } catch (e) {
      print("Kesalahan mengambil data riwayat kesehatan: $e");
      setState(() {
        _riwayatKesehatan = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hewanData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Detail Hewan'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Hewan'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: TextEditingController(
                  text: 'Jenis Hewan: ${_hewanData!['jenis_hewan']}'),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              controller: TextEditingController(
                  text: 'Nomor Hewan: ${_hewanData!['nomor_hewan']}'),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              controller: TextEditingController(
                  text: 'Kelamin: ${_hewanData!['jenis_kelamin']}'),
              readOnly: true,
            ),
            SizedBox(height: 8),
            FutureBuilder<String>(
              future: _getBobotHewan(_hewanData?['nomor_hewan']),
              builder: (context, snapshot) {
                return TextField(
                  controller: TextEditingController(
                      text: 'Bobot: ${snapshot.data ?? 'Belum dimiliki'} Kg'),
                  readOnly: true,
                );
              },
            ),
            SizedBox(height: 8),
            // Tambahkan field untuk menampilkan harga
            TextField(
              controller: TextEditingController(
                  text: 'Harga: $_currentPrice'),
              readOnly: true,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                suffixIcon: _priceUpdateInfo.isNotEmpty ? 
                  Tooltip(
                    message: _priceUpdateInfo,
                    child: Icon(Icons.info_outline),
                  ) : null,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: TextEditingController(
                  text: 'Umur Hewan: ${_hewanData!['umur_hewan']} Bulan'),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              controller: TextEditingController(
                  text: 'Status: ${_hewanData!['kesehatan']}'),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              controller: TextEditingController(
                  text: 'Kategori: ${_hewanData!['kategori']}'),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              controller: TextEditingController(
                  text: 'Tanggal Masuk: ${_hewanData!['tanggal_masuk']}'),
              readOnly: true,
            ),
            SizedBox(height: 10),
            // SizedBox(height: 20),
            // Text('Riwayat Kesehatan',
            //     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // SizedBox(height: 10),
            // _hewanData!['kesehatan'] == 'Sehat'
            //     ? Text('Hewan dalam keadaan sehat')
            //     : _riwayatKesehatan.isEmpty
            //         ? Text('Belum ada data riwayat kesehatan')
            //         : SingleChildScrollView(
            //             scrollDirection: Axis.horizontal,
            //             child: DataTable(
            //               columns: [
            //                 DataColumn(label: Text('Tanggal')),
            //                 DataColumn(label: Text('Gejala')),
            //                 DataColumn(label: Text('Estimasi Sembuh')),
            //                 DataColumn(label: Text('Keterangan')),
            //               ],
            //               rows: _riwayatKesehatan.map((kesehatan) => DataRow(
            //                         cells: [
            //                           DataCell(Text(
            //                               kesehatan['tanggal_sakit'] ?? '')),
            //                           DataCell(Text(kesehatan['gejala']
            //                               .toString()
            //                               .replaceAll('true', '')
            //                               .replaceAll('false', '')
            //                               .replaceAll('{', '')
            //                               .replaceAll('}', '')
            //                               .replaceAll(',', ', ')
            //                               .replaceAll(':', ''))),
            //                           DataCell(Text(
            //                               kesehatan['estimasi_sembuh'] ?? '')),
            //                           DataCell(Text(
            //                               kesehatan['deskripsi_keluhan'] ??
            //                                   '')),
            //                         ],
            //                       ))
            //                   .toList(),
            //             ),
            //           ),
          ],
        ),
      ),
    );
  }
}