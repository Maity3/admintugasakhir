import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:sobatternak_admin_web/pages/Hewan/Detail_Hewan.dart';
import 'package:sobatternak_admin_web/pages/Hewan/Tambah_Hewan.dart';
import 'package:sobatternak_admin_web/pages/Hewan/pemberitahuan_hewan.dart';

class HewanPage extends StatefulWidget {
  final String kandangId;

  HewanPage({required this.kandangId});

  @override
  _HewanPageState createState() => _HewanPageState();
}

class _HewanPageState extends State<HewanPage> {
  final DatabaseReference hewanRef = FirebaseDatabase.instance.reference().child('hewan');
  final DatabaseReference kandangRef = FirebaseDatabase.instance.reference().child('kandang');
  final DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users');
  final DatabaseReference bobotRef = FirebaseDatabase.instance.reference().child('bobot');
  final DatabaseReference riwayatRef = FirebaseDatabase.instance.reference().child('riwayat_hewan'); // Tambahan untuk riwayat
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _hewanList = [];
  List<Map<String, dynamic>> _bobotList = [];
  List<Map<String, dynamic>> _riwayatMatiList = []; // List untuk riwayat hewan mati
  List<Map<String, dynamic>> _riwayatDijualList = []; // List untuk riwayat hewan dijual
  int _stockHewan = 0;
  int _stockMati = 0;
  int _stockDijual = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchData();
  }

  void _checkAuthAndFetchData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      print("Email pengguna: ${user.email}");
      if (user.email == 'admin1@gmail.com') {
        _fetchHewanData();
        _fetchRiwayatData(); // Tambahan untuk mengambil data riwayat
      } else {
        print("Pengguna tidak memiliki izin");
      }
    } else {
      print("Pengguna tidak terautentikasi");
    }
  }

  // Fungsi baru untuk mengambil data riwayat hewan
  void _fetchRiwayatData() async {
    try {
      DataSnapshot snapshot = await riwayatRef.get();
      if (snapshot.exists && snapshot.value != null) {
        Map<String, dynamic> riwayatData = Map<String, dynamic>.from(snapshot.value as Map);
        
        List<Map<String, dynamic>> riwayatMatiList = [];
        List<Map<String, dynamic>> riwayatDijualList = [];
        
        riwayatData.forEach((key, value) {
          if (value is Map) {
            Map<String, dynamic> riwayat = Map<String, dynamic>.from(value);
            riwayat['id'] = key; // Tambahkan ID untuk referensi
            
            String alasanKeluar = riwayat['alasan_keluar']?.toString().toLowerCase() ?? '';
            
            if (alasanKeluar == 'mati') {
              riwayatMatiList.add(riwayat);
            } else if (alasanKeluar == 'dijual') {
              riwayatDijualList.add(riwayat);
            }
          }
        });
        
        // Urutkan berdasarkan timestamp_moved (terbaru dulu)
        riwayatMatiList.sort((a, b) {
          int timestampA = a['timestamp_moved'] ?? 0;
          int timestampB = b['timestamp_moved'] ?? 0;
          return timestampB.compareTo(timestampA);
        });
        
        riwayatDijualList.sort((a, b) {
          int timestampA = a['timestamp_moved'] ?? 0;
          int timestampB = b['timestamp_moved'] ?? 0;
          return timestampB.compareTo(timestampA);
        });
        
        setState(() {
          _riwayatMatiList = riwayatMatiList;
          _riwayatDijualList = riwayatDijualList;
          _stockMati = riwayatMatiList.length;
          _stockDijual = riwayatDijualList.length;
        });
        
        print("Riwayat hewan mati: ${riwayatMatiList.length}");
        print("Riwayat hewan dijual: ${riwayatDijualList.length}");
      }
    } catch (e) {
      print("Error mengambil data riwayat: $e");
    }
  }

  Future<String> _getBobotHewan(String nomorHewan) async {
    try {
      // Ambil semua data bobot
      DataSnapshot snapshot = await bobotRef.get();
      
      if (snapshot.exists && snapshot.value != null) {
        // Konversi data ke Map<String, dynamic>
        Map<String, dynamic> allBobotData = Map<String, dynamic>.from(snapshot.value as Map);
        print('Semua data bobot: $allBobotData');

        // Filter data berdasarkan nomor_hewan
        List<Map<String, dynamic>> filteredData = [];
        allBobotData.forEach((key, value) {
          // Konversi value ke Map<String, dynamic>
          if (value is Map<dynamic, dynamic>) {
            Map<String, dynamic> bobotEntry = Map<String, dynamic>.from(value);
            if (bobotEntry['nomor_hewan'] == nomorHewan) {
              filteredData.add(bobotEntry);
            }
          }
        });

        // Jika ada data yang sesuai
        if (filteredData.isNotEmpty) {
          // Ambil data terbaru berdasarkan tanggal
          filteredData.sort((a, b) => b['tanggal'].compareTo(a['tanggal']));
          String latestBobot = filteredData.first['bobot']?.toString() ?? 'Belum dimiliki';
          String latestTanggal = filteredData.first['tanggal'] ?? 'Tanggal tidak tersedia';
          print('Bobot terbaru untuk $nomorHewan: $latestBobot, Tanggal: $latestTanggal');
          return 'Bobot: $latestBobot Kg, Tanggal: $latestTanggal';
        } else {
          print('Tidak ada data ditemukan untuk nomor hewan: $nomorHewan');
          return 'Belum dimiliki';
        }
      } else {
        print('Tidak ada data bobot ditemukan');
        return 'Belum dimiliki';
      }
    } catch (e) {
      print("Error saat mengambil data: $e");
      return 'Belum dimiliki';
    }
  }

  Future<List<Map<String, dynamic>>> fetchHewanData() async {
    try {
      DataSnapshot snapshot = await hewanRef.get();
      if (snapshot.exists) {
        List<Map<String, dynamic>> hewanList = [];
        snapshot.children.forEach((child) {
          var hewanData = child.value as Map?;
          if (hewanData != null) {
            Map<String, dynamic> hewan = Map<String, dynamic>.from(hewanData);
            // Tambahkan ID untuk referensi
            hewan['id'] = child.key;
            hewanList.add(hewan);
          }
        });
        print("Data hewan diambil dari Firebase: $hewanList");
        return hewanList;
      } else {
        print("Tidak ada data tersedia");
        return [];
      }
    } catch (e) {
      print("Kesalahan mengambil data: $e");
      return [];
    }
  }

  void _fetchHewanData() async {
    List<Map<String, dynamic>> allHewanList = await fetchHewanData();
    
    // Filter hewan yang masih aktif (bukan Mati atau Dijual)
    List<Map<String, dynamic>> activeHewanList = allHewanList.where((hewan) {
      String kesehatan = hewan['kesehatan']?.toString().toLowerCase() ?? 'sehat';
      return kesehatan != 'mati' && kesehatan != 'dijual';
    }).toList();

    setState(() {
      _hewanList = activeHewanList;
      _stockHewan = activeHewanList.length;
    });

    // Ambil data riwayat untuk update statistik yang akurat
    _fetchRiwayatData();
  }
  
  Future<String> _getUserName(String userId) async {
    DataSnapshot snapshot = await userRef.child(userId).get();
    if (snapshot.exists && snapshot.value != null) {
      Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
      print('User data: $userData');
      return userData['name']?.toString() ?? 'Belum dimiliki';
    }
    print('User not found or data is null');
    return 'Belum dimiliki';
  }

  Future<String> _getKandangName(String kandangId) async { 
    DataSnapshot snapshot = await kandangRef.child(kandangId).get();
    if (snapshot.exists && snapshot.value != null) {
      Map<String, dynamic> kandangData = Map<String, dynamic>.from(snapshot.value as Map);
      print('Kandang data: $kandangData');
      return kandangData['nama_kandang']?.toString() ?? 'Belum dimiliki';
    }
    print('Kandang not found or data is null');
    return 'Belum dimiliki';
  }

  // Helper function untuk format harga ke Rupiah
  String formatRupiah(dynamic price) {
    if (price == null) return 'Harga tidak tersedia';
    
    // Jika price adalah string, konversi ke int
    int numericPrice;
    if (price is String) {
      numericPrice = int.tryParse(price) ?? 0;
    } else if (price is int) {
      numericPrice = price;
    } else if (price is double) {
      numericPrice = price.toInt();
    } else {
      return 'Harga tidak valid';
    }
    
    final formatCurrency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(numericPrice);
  }

  // Fungsi untuk mendapatkan warna status kesehatan
  Color _getStatusColor(String kesehatan) {
    switch (kesehatan.toLowerCase()) {
      case 'sehat':
        return Colors.green;
      case 'sakit':
        return Colors.orange;
      case 'mati':
        return Colors.red;
      case 'dijual':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Fungsi untuk menampilkan detail riwayat hewan
  void _showRiwayatDetail(BuildContext context, String type) {
    List<Map<String, dynamic>> dataList = type == 'mati' ? _riwayatMatiList : _riwayatDijualList;
    String title = type == 'mati' ? 'Riwayat Hewan Mati' : 'Riwayat Hewan Dijual';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: type == 'mati' ? Colors.red.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: type == 'mati' ? Colors.red.shade800 : Colors.blue.shade800,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: dataList.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada data riwayat ${type}',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: dataList.length,
                          itemBuilder: (context, index) {
                            final riwayat = dataList[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: type == 'mati' ? Colors.red.shade200 : Colors.blue.shade200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Nomor Hewan: ${riwayat['nomor_hewan'] ?? 'N/A'}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: type == 'mati' ? Colors.red : Colors.blue,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          type == 'mati' ? 'MATI' : 'DIJUAL',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text("Jenis: ${riwayat['jenis_hewan'] ?? 'N/A'}"),
                                  Text("Kelamin: ${riwayat['jenis_kelamin'] ?? 'N/A'}"),
                                  Text("Umur: ${riwayat['umur_hewan'] ?? 'N/A'} Bulan"),
                                  Text("Kandang: ${riwayat['kandangid'] ?? 'N/A'}"),
                                  Text("Tanggal Masuk: ${riwayat['tanggal_masuk'] ?? 'N/A'}"),
                                  Text("Tanggal Keluar: ${riwayat['tanggal_keluar'] ?? 'N/A'}"),
                                  
                                  if (type == 'mati') ...[
                                    SizedBox(height: 8),
                                    Text(
                                      "Detail Kematian:",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                    ),
                                    if (riwayat['tanggal_sakit'] != null)
                                      Text("Tanggal Sakit: ${riwayat['tanggal_sakit']}"),
                                    if (riwayat['penyebab_kematian'] != null)
                                      Text("Penyebab: ${riwayat['penyebab_kematian']}"),
                                    if (riwayat['keluhan'] != null)
                                      Text("Keluhan: ${riwayat['keluhan']}"),
                                    if (riwayat['penanganan'] != null)
                                      Text("Penanganan: ${riwayat['penanganan']}"),
                                    if (riwayat['biaya_perawatan'] != null)
                                      Text("Biaya Perawatan: ${formatRupiah(riwayat['biaya_perawatan'])}"),
                                    if (riwayat['gejala'] != null && riwayat['gejala'] is Map) ...[
                                      Text("Gejala:", style: TextStyle(fontWeight: FontWeight.w500)),
                                      ...((riwayat['gejala'] as Map).entries.where((entry) => entry.value == true).map((entry) => 
                                        Text("  • ${entry.key}", style: TextStyle(fontSize: 12)))),
                                    ],
                                  ],
                                  
                                  if (type == 'dijual') ...[
                                    SizedBox(height: 8),
                                    Text(
                                      "Detail Penjualan:",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                                    ),
                                    if (riwayat['harga_jual'] != null)
                                      Text(
                                        "Harga Jual: ${formatRupiah(riwayat['harga_jual'])}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    if (riwayat['keterangan_jual'] != null)
                                      Text("Keterangan: ${riwayat['keterangan_jual']}"),
                                  ],
                                  
                                  SizedBox(height: 8),
                                  FutureBuilder<String>(
                                    future: _getUserName(riwayat['ownerId'] ?? ''),
                                    builder: (context, snapshot) {
                                      return Text(
                                        "Pemilik: ${snapshot.data ?? 'Belum dimiliki'}",
                                        style: TextStyle(fontStyle: FontStyle.italic),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Hewan Aktif"),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PemberitahuanHewan()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TambahHewanForm()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  _fetchHewanData();
                  _fetchRiwayatData();
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          if (_stockMati > 0 || _stockDijual > 0)
            Container(
              margin: EdgeInsets.all(8.0),
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text("Stock Aktif", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("$_stockHewan", style: TextStyle(fontSize: 18, color: Colors.green)),
                    ],
                  ),
                  if (_stockMati > 0)
                    GestureDetector(
                      onTap: () => _showRiwayatDetail(context, 'mati'),
                      child: Column(
                        children: [
                          Text("Mati", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("$_stockMati", style: TextStyle(fontSize: 18, color: Colors.red)),
                          Text("(Tap untuk detail)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  if (_stockDijual > 0)
                    GestureDetector(
                      onTap: () => _showRiwayatDetail(context, 'dijual'),
                      child: Column(
                        children: [
                          Text("Dijual", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("$_stockDijual", style: TextStyle(fontSize: 18, color: Colors.blue)),
                          Text("(Tap untuk detail)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          // List Hewan Aktif
          Expanded(
            child: _hewanList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Memuat data hewan aktif..."),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _hewanList.length,
                    itemBuilder: (context, index) {
                      final hewan = _hewanList[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailHewanPage(
                                nomorHewan: hewan['nomor_hewan'],
                              ),
                            ),
                          );
                          print("Hewan dipilih: ${hewan['jenis_hewan']}");
                        },
                        child: Container(
                          margin: EdgeInsets.all(8.0),
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                            // Tambahkan border berwarna sesuai status
                            border: Border.all(
                              color: _getStatusColor(hewan['kesehatan'] ?? 'sehat'),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Nomor Hewan: ${hewan['nomor_hewan']}"),
                                        Text("Jenis Hewan: ${hewan['jenis_hewan']}"),
                                        Text("Jenis Kelamin: ${hewan['jenis_kelamin']}"),
                                        FutureBuilder<String>(
                                          future: _getBobotHewan(hewan['nomor_hewan']),
                                          builder: (context, snapshot) {
                                            return Text("${snapshot.data ?? 'Belum dimiliki'}");
                                          },
                                        ),
                                        Text("Umur Hewan: ${hewan['umur_hewan']} Bulan"),
                                        Row(
                                          children: [
                                            Text("Status: "),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(hewan['kesehatan'] ?? 'sehat'),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                "${hewan['kesehatan'] ?? 'Sehat'}",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text("Kategori: ${hewan['kategori']}"),
                                        Text("Tanggal Masuk: ${hewan['tanggal_masuk']}"),
                                        Text("Status: ${hewan['status'] ?? 'Belum Dimiliki'}"),
                                      ],
                                    ),
                                  ),
                                  // Bagian harga kambing di sisi kanan
                                  if (hewan['harga'] != null)
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${hewan['update_harga_info'] ?? 'Update Harga Kambing Mei 2025'}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade800,
                                                fontSize: 12,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              formatRupiah(hewan['harga']),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.green.shade800,
                                              ),
                                            ),
                                            Text(
                                              "${hewan['jenis_kelamin']}, ${hewan['umur_hewan']} bulan",
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 10),
                              // Informasi pemilik dan kandang
                              Row(
                                children: [
                                  Expanded(
                                    child: FutureBuilder<String>(
                                      future: _getUserName(hewan['ownerId'] ?? ''),
                                      builder: (context, snapshot) {
                                        return Text("Dimiliki oleh: ${snapshot.data ?? 'Belum Dimiliki'}");
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: FutureBuilder<String>(
                                      future: _getKandangName(hewan['kandangId'] ?? ''),
                                      builder: (context, snapshot) {
                                        return Text("Kandang: ${snapshot.data ?? 'Belum ditentukan'}");
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}