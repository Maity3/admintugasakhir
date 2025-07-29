import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:sobatternak_admin_web/pages/Hewan/Detail_Hewan_User.dart';
import 'package:sobatternak_admin_web/pages/Hewan/Hewan.dart';
import 'package:sobatternak_admin_web/pages/Pakan/Detail_Pakan.dart';
import 'package:sobatternak_admin_web/pages/Pakan/Detail_pakan_User.dart';
// Import the DetailHewanPage

class KandangUserPage extends StatefulWidget {
  final Map<String, String> kandangData;
  final String userId;

  KandangUserPage({required this.kandangData, required this.userId});

  @override
  _KandangUserPageState createState() => _KandangUserPageState();
}

class _KandangUserPageState extends State<KandangUserPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  List<Map<String, dynamic>> _dataPakan = [];
  List<Map<String, dynamic>> _riwayatPerawatan =[];

  @override
  void initState() {
    super.initState();
    _fetchDataPakan();
    _fetchRiwayatPerawatan();
    // Gunakan userId dari widget, bukan dari currentUser
    print("User ID: ${widget.userId}");
    print("Kandang ID: ${widget.kandangData['id']}");
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

  Future<void> tambahHewanKeKandangPengguna(
      String kandangId, String hewanId, Map<String, dynamic> dataHewan) async {
    try {
      // Referensi ini harusnya langsung menuju ke 'hewans' di dalam kandang yang spesifik
      DatabaseReference hewanRef = _database
          .ref()
          .child("users")
          .child(widget.userId)
          .child("kandangs")
          .child(kandangId)
          .child("hewans")
          .child(hewanId);
      await hewanRef.set(dataHewan);
      print("Hewan berhasil ditambahkan ke kandang: $kandangId");
    } catch (e) {
      print("Kesalahan saat menambahkan hewan ke kandang: $e");
      rethrow;
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
              // Format date
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

  Future<void> _fetchDataPakan() async {
    try {
      DatabaseReference pakanRef = _database
          .ref()
          // .child("users")
          // .child(widget
          //     .userId) // Gunakan widget.userId bukan _auth.currentUser!.uid
          // .child("kandangs")
          // .child(widget.kandangData["nomor_kandang"])
          .child("pakans"); // Pastikan _kandangId sudah di-fetch sebelumnya

      DataSnapshot snapshot = await pakanRef.get();
      if (snapshot.exists && snapshot.value != null) {
        print("Data pakan ditemukan: ${snapshot.value}");
        setState(() {
          _dataPakan = (snapshot.value as Map<dynamic, dynamic>)
              .entries
              .map((e) => {
                    'id': e.key,
                    ...Map<String, dynamic>.from(
                        e.value as Map<dynamic, dynamic>)
                  })
              .toList();
        });
      } else {
        print("Belum ada data pakan");
        setState(() {
          _dataPakan = [];
        });
      }
    } catch (e) {
      print("Kesalahan mengambil data pakan: $e");
      setState(() {
        _dataPakan = [];
      });
    }
  }

  Future<void> _tambahHewan(BuildContext context) async {
    List<Map<String, String>> hewanList = await _fetchHewanNames();

    if (hewanList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada hewan tersedia')),
      );
      return;
    }

    String? selectedHewan;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pilih Hewan"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<String>(
                value: selectedHewan,
                hint: Text("Pilih Hewan"),
                items: hewanList.map((Map<String, String> hewan) {
                  return DropdownMenuItem<String>(
                    value: hewan['id'],
                    child: Text(hewan['nomor'] ?? 'Tidak diketahui'),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedHewan = newValue;
                  });
                },
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Tutup"),
            ),
            TextButton(
              onPressed: () async {
                if (selectedHewan != null) {
                  try {
                    await _saveSelectedHewan(
                        selectedHewan!, widget.kandangData['id']!);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Hewan berhasil ditambahkan ke kandang')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menambahkan hewan: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pilih hewan yang valid')),
                  );
                }
              },
              child: Text("Pilih"),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, String>>> _fetchHewanNames() async {
    DatabaseReference hewanRef = _database.ref().child("hewan");
    DataSnapshot snapshot = await hewanRef.get();

    List<Map<String, String>> hewanList = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> hewanData = snapshot.value as Map<dynamic, dynamic>;
      hewanData.forEach((key, value) {
        if (value['jenis_hewan'] != null) {
          hewanList.add(
              {'id': key, 'nomor': value['nomor_hewan'] ?? 'Tidak diketahui'});
        }
      });
    }

    return hewanList;
  }

  Future<void> _saveSelectedHewan(String hewanId, String kandangId) async {
    try {
      // Ambil data hewan lengkap dari database
      DatabaseReference hewanRef =
          _database.ref().child("hewan").child(hewanId);
      DataSnapshot hewanSnapshot = await hewanRef.get();

      if (hewanSnapshot.exists) {
        Map<String, dynamic> hewanData =
            Map<String, dynamic>.from(hewanSnapshot.value as Map);

        // Simpan data hewan lengkap di dalam kandang
        DatabaseReference kandangHewanRef = _database
            .ref()
            .child("hewans")
            .child(hewanId);

        await kandangHewanRef.set({
          ...hewanData,
          'ownerId' : widget.userId,
          'kandangid': kandangId,
        });  // Menyimpan data hewan lengkap di dalam kandang

        // Update data hewan untuk menunjukkan lokasi dan kepemilikan
        await hewanRef.update({
          'ownerId': widget.userId,
          'kandangId': kandangId,
        }).catchError((error) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            print("Mengabaikan error izin saat update hewan: ${error.message}");
          } else {
            throw error;
          }
        });
      } else {
        print("Data hewan tidak ditemukan");
      }
    } catch (e) {
      print("Kesalahan: $e");
      rethrow;
    }
  }

  void _navigateToDetailHewan(String hewanId) {
    String userId = widget.userId;
    print(
        "Navigasi ke detail hewan dengan hewanId: $hewanId dan userId: $userId");

    if (userId.isEmpty || hewanId.isEmpty) {
      print("Error: userId atau hewanId kosong");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailHewanUserPage(
          hewanId: hewanId,
          userId: userId,
          kandangId: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kapasitas = _getKapasitas(widget.kandangData['ukuran_kandang']!);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kandangData['Detail Kandang'] ?? 'Detail Kandang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Nomor Kandang'),
              controller: TextEditingController(
                  text: widget.kandangData['nomor_kandang']),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Nama Kandang'),
              controller: TextEditingController(
                  text: widget.kandangData['nama_kandang']),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Lokasi Kandang'),
              controller: TextEditingController(
                  text: widget.kandangData['lokasi_kandang']),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Kapasitas'),
              controller: TextEditingController(text: kapasitas.toString()),
              readOnly: true,
            ),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(labelText: 'Ukuran Kandang'),
              controller: TextEditingController(
                  text: widget.kandangData['ukuran_kandang']),
              readOnly: true,
            ),
            SizedBox(height: 16),
            Text(
              "Hewan di Kandang:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            StreamBuilder<DatabaseEvent>(
              stream: _database
                  .ref()
                  // .child("users")
                  // .child(widget.userId)
                  // .child("kandangs")
                  // .child(widget.kandangData['id']!)
                  .child("hewans")
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Terjadi kesalahan: ${snapshot.error}");
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map<dynamic, dynamic> hewanData =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List<Map<String, String>> hewanList = [];

                  hewanData.forEach((key, value) {
                    if (value is Map &&
                        value['kandangid'] == widget.kandangData['id']) {
                      // Filter hewan berdasarkan kandangId yang dipilih
                      hewanList.add({
                        'id': key,
                        'nomor_hewan':
                            value['nomor_hewan'] ?? 'Tidak diketahui',
                        'jenis_hewan':
                            value['jenis_hewan'] ?? 'Tidak diketahui',
                        'kandangid': value['kandangid'] ?? 'Tidak diketahui',
                        // Tambahkan field lain yang diperlukan
                      });
                    }
                  });

                  if (hewanList.isEmpty) {
                    return Text("Tidak ada hewan di kandang ini");
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: hewanList.map((hewan) {
                        return GestureDetector(
                          onTap: () => _navigateToDetailHewan(hewan['id']!),
                          child: Container(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  "${hewan['nomor_hewan']}",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  return Text("Belum ada hewan di database");
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tambahHewan(context),
              child: Text("Tambah Hewan"),
            ),
            SizedBox(height: 16),
            Text('Data Pakan', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _dataPakan.isEmpty
                ? Text('Belum ada data pakan')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Jenis Pakan')),
                        DataColumn(label: Text('Jumlah Kg')),
                        DataColumn(label: Text('Total Harga')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: _dataPakan
                          .where((pakan) =>
                              pakan['kandangId'] ==
                              widget.kandangData['nomor_kandang'])
                          .where((pakan) => pakan['ownerId'] == widget.userId)
                          .where((pakan) => pakan['status'] == 'dimiliki')
                          .map((pakan) => DataRow(
                                cells: [
                                  DataCell(Text(pakan['jenis_pakan'] ?? ''),
                                      onTap: () {
                                    Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailPakanUserPage(
                                        pakan: Map<String, dynamic>.from(pakan),
                                        pakanId: pakan['id'] ?? '',
                                      ),
                                    ),
                                  );
                                  }),
                                  DataCell(
                                      Text(pakan['jumlah_kg']?.toString() ??
                                          '0'), onTap: () {
                                    Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailPakanUserPage(
                                        pakan: Map<String, dynamic>.from(pakan),
                                        pakanId: pakan['id'] ?? '',
                                      ),
                                    ),
                                  );
                                  }),
                                  DataCell(
                                      Text(((pakan['jumlah_kg'] ?? 0) *
                                              (pakan['harga_per_kilo'] ?? 0))
                                          .toString()),
                                          ),
                                  DataCell(Text(pakan['status'] ?? ''),
                                      onTap: () {
                                    Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailPakanUserPage(
                                        pakan: Map<String, dynamic>.from(pakan),
                                        pakanId: pakan['id'] ?? '',
                                      ),
                                    ),
                                  );
                                  }),
                                ],
                              ))
                          .toList(),
                    ),
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
          ],
        ),
      ),
    );
  }
}
