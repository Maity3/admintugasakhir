import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:sobatternak_admin_web/pages/Kandang/perawatanKandang.dart';

class DetailKandangPage extends StatefulWidget {
  final Map<String, dynamic> kandangData;

  DetailKandangPage({required this.kandangData, required String kandangId});

  @override
  _DetailKandangPageState createState() => _DetailKandangPageState();
}

class _DetailKandangPageState extends State<DetailKandangPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final DatabaseReference userRef =
      FirebaseDatabase.instance.reference().child('users');
  int _stockKandang = 0; // Menyimpan jumlah stok kandang
  List<Map<String, dynamic>> _riwayatPerawatan =[]; // Menyimpan riwayat perawatan

  @override
  void initState() {
    super.initState();
    _fetchKandangData(); // Ambil data kandang saat inisialisasi
    _fetchRiwayatPerawatan(); // Ambil riwayat perawatan saat inisialisasi
  }

  int _getKapasitas(String ukuranKandang) {
    switch (ukuranKandang) {
      case "4x3":
        return 6;
      case "6x4":
        return 8;
      case "8x6":
        return 12;
      default:
        return 0;
    }
  }

  String _getStatusKepemilikan(String? ownerId) {
    return (ownerId == null || ownerId.isEmpty)
        ? 'Belum Dimiliki'
        : 'Sudah Dimiliki';
  }

  Future<String> _getUserName(String userId) async {
    DataSnapshot snapshot = await userRef.child(userId).get();
    if (snapshot.exists && snapshot.value != null) {
      Map<String, dynamic> userData =
          Map<String, dynamic>.from(snapshot.value as Map);
      print('User   data: $userData');
      return userData['name']?.toString() ?? 'Belum dimiliki';
    }
    print('User   not found or data is null');
    return 'Belum dimiliki';
  }

  Future<void> _fetchKandangData() async {
    try {
      DatabaseReference kandangRef = _database
          .ref()
          .child("kandang/${widget.kandangData['nomor_kandang']}");
      DataSnapshot snapshot = await kandangRef.get();
      if (snapshot.exists) {
        var kandangData = snapshot.value as Map?;
        if (kandangData != null) {
          setState(() {
            _stockKandang = _getKapasitas(kandangData['ukuran_kandang'] ?? '');
          });
        } else {
          print("Kandang data is null");
        }
      } else {
        print("Kandang not found");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> _fetchRiwayatPerawatan() async {
  try {
    DatabaseReference riwayatRef = _database
        .ref()
        .child("riwayat_perawatan/${widget.kandangData['nomor_kandang']}");
    DataSnapshot snapshot = await riwayatRef.get();
    
    if (snapshot.exists) {
      var riwayatData = snapshot.value as Map<dynamic, dynamic>?;
      if (riwayatData != null) {
        setState(() {
          _riwayatPerawatan = riwayatData.entries.map((entry) {
            var data = entry.value as Map<dynamic, dynamic>;
            
            // Parse the date string sesuai dengan format yang disimpan
            String tanggal = data['tanggal'] ?? '';
            String formattedDate;
            
            try {
              // Format yang digunakan saat menyimpan adalah dd-MM-yyyy
              // Jadi kita perlu parse dengan format yang sama
              DateFormat inputFormat = DateFormat('dd-MM-yyyy');
              DateTime dateTime = inputFormat.parse(tanggal);
              
              // Kemudian format untuk ditampilkan
              formattedDate = DateFormat('dd-MMM-yyyy').format(dateTime);
            } catch (e) {
              print("Date parsing error: $e");
              formattedDate = tanggal; // Tampilkan format asli jika gagal parse
            }

            // Format the currency
            final currencyFormat = NumberFormat.currency(
              locale: 'id',
              symbol: 'Rp ',
              decimalDigits: 0
            );

            return {
              'tanggal': formattedDate,
              'perawatan': data['perawatan'] ?? 'Tidak ada data',
              'tarif': currencyFormat.format(data['tarif'] ?? 0),
            };
          }).toList();

          // Sort by date (most recent first)
          _riwayatPerawatan.sort((a, b) {
            try {
              // Parse dengan format yang ditampilkan
              DateTime dateA = DateFormat('dd-MMM-yyyy').parse(a['tanggal']);
              DateTime dateB = DateFormat('dd-MMM-yyyy').parse(b['tanggal']);
              return dateB.compareTo(dateA);
            } catch (e) {
              print("Error sorting dates: $e");
              return 0;
            }
          });
        });
      } else {
        print("Riwayat perawatan data is null");
      }
    } else {
      print("Riwayat perawatan not found");
    }
  } catch (e) {
    print("Error fetching riwayat perawatan: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    String ukuranKandang = widget.kandangData['ukuran_kandang'] ?? '';
    String statusKepemilikan =_getStatusKepemilikan(widget.kandangData['ownerId '] ?? '');
    String statusDisplay = statusKepemilikan;
    String kategori = widget.kandangData['kategori'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kandangData['Detail Kandang'] ?? 'Detail Kandang'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _fetchKandangData();
              _fetchRiwayatPerawatan(); // Refresh riwayat perawatan
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Nomor Kandang'),
              controller: TextEditingController(
                  text: widget.kandangData['nomor_kandang'] ?? ''),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Nama Kandang'),
              controller: TextEditingController(
                  text: widget.kandangData['nama_kandang'] ?? ''),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Lokasi Kandang'),
              controller: TextEditingController(
                  text: widget.kandangData['lokasi_kandang'] ?? ''),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Kapasitas'),
              controller: TextEditingController(text: _stockKandang.toString()),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Ukuran Kandang'),
              controller: TextEditingController(text: ukuranKandang),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Kategori'),
              controller: TextEditingController(text: kategori),
              readOnly: true,
            ),
            SizedBox(height: 8),
            FutureBuilder<String>(
              future: _getUserName(widget.kandangData['ownerId'] ?? ''),
              builder: (context, snapshot) {
                return TextField(
                  decoration: InputDecoration(labelText: 'Status Kepemilikan'),
                  controller: TextEditingController(
                      text: snapshot.data != null
                          ? 'Dimiliki oleh ${snapshot.data}'
                          : 'Belum Dimiliki'),
                  readOnly: true,
                );
              },
            ),
            SizedBox(height: 16),
            Text(
              'Riwayat Perawatan Kandang',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _riwayatPerawatan.isEmpty
                ? Center(child: Text('Tidak ada riwayat perawatan.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Perawatan')),
                        DataColumn(label: Text('Harga')),
                      ],
                      rows: _riwayatPerawatan.map((riwayat) {
                        return DataRow(
                          cells: [
                            DataCell(Text(riwayat['tanggal'] ??
                                'Tanggal tidak tersedia')),
                            DataCell(
                              Text(
                                riwayat['perawatan'] is List
                                    ? (riwayat['perawatan'] as List).join(', ')
                                    : riwayat['perawatan'].toString(),
                              ),
                            ),
                            DataCell(Text(riwayat['tarif'].toString())),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PerawatanKandangPage(
                            kandangId: widget.kandangData['nomor_kandang'],
                            ownerId: widget.kandangData['ownerId'] ?? '',
                          )),
                );
              },
              child: Text('Perawatan Kandang'),
            ),
          ],
        ),
      ),
    );
  }
}
